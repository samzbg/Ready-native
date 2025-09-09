import SwiftUI
import AppKit
import GRDB

// MARK: - RightPanel (macOS)

class RightPanel: ObservableObject {
    @Published var currentDate = Date()
    @Published var activeMeetingId: String? = nil
    @Published var isNavigatingForward = true
    private var pendingDirection: Bool? = nil
    private var cachedDays: [DayModel] = []
    private var lastCachedDate: Date?
    private let databaseService = DatabaseService.shared
    
    fileprivate var currentDays: [DayModel] {
        let calendar = Calendar.current
        let firstDay = calendar.startOfDay(for: currentDate)
        
        // Check if we need to regenerate the cache
        if lastCachedDate != firstDay {
            let secondDay = calendar.date(byAdding: .day, value: 1, to: firstDay) ?? firstDay
            
            do {
                // Fetch events for both days
                let firstDayEvents = try databaseService.getCalendarEvents(for: firstDay)
                let secondDayEvents = try databaseService.getCalendarEvents(for: secondDay)
                
                print("📅 Fetched \(firstDayEvents.count) events for \(firstDay)")
                print("📅 Fetched \(secondDayEvents.count) events for \(secondDay)")
                
                cachedDays = [
                    DayModel(date: firstDay, events: firstDayEvents),
                    DayModel(date: secondDay, events: secondDayEvents)
                ]
                lastCachedDate = firstDay
            } catch {
                print("❌ Error fetching calendar events: \(error)")
                // Fallback to empty events
                cachedDays = [
                    DayModel(date: firstDay, events: []),
                    DayModel(date: secondDay, events: [])
                ]
                lastCachedDate = firstDay
            }
        }
        
        return cachedDays
    }
    
    var currentMonthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentDate)
    }
    
    var shouldShowTodayButton: Bool {
        let calendar = Calendar.current
        let today = Date()
        let todayStart = calendar.startOfDay(for: today)
        let currentStart = calendar.startOfDay(for: currentDate)
        let nextDayStart = calendar.date(byAdding: .day, value: 1, to: currentStart) ?? currentStart
        
        return !calendar.isDate(todayStart, inSameDayAs: currentStart) && 
               !calendar.isDate(todayStart, inSameDayAs: nextDayStart)
    }
    
    func previousDays() {
        pendingDirection = false
        // Use a small delay to avoid publishing during view updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            withAnimation(.easeInOut(duration: 0.2)) {
                self.isNavigatingForward = false
                self.currentDate = Calendar.current.date(byAdding: .day, value: -2, to: self.currentDate) ?? self.currentDate
            }
            self.pendingDirection = nil
        }
    }
    
    func nextDays() {
        pendingDirection = true
        // Use a small delay to avoid publishing during view updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            withAnimation(.easeInOut(duration: 0.2)) {
                self.isNavigatingForward = true
                self.currentDate = Calendar.current.date(byAdding: .day, value: 2, to: self.currentDate) ?? self.currentDate
            }
            self.pendingDirection = nil
        }
    }
    
    func navigateToToday() {
        let today = Date()
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: today)
        let currentStart = calendar.startOfDay(for: currentDate)
        let nextDayStart = calendar.date(byAdding: .day, value: 1, to: currentStart) ?? currentStart
        
        // Check if today is already in the current view
        if calendar.isDate(todayStart, inSameDayAs: currentStart) || 
           calendar.isDate(todayStart, inSameDayAs: nextDayStart) {
            return // Today is already visible, do nothing
        }
        
        // Determine direction based on whether today is before or after current date
        let isTodayAfter = todayStart > currentStart
        
        pendingDirection = isTodayAfter
        // Use a small delay to avoid publishing during view updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            withAnimation(.easeInOut(duration: 0.2)) {
                self.isNavigatingForward = isTodayAfter
                self.currentDate = today
            }
            self.pendingDirection = nil
        }
    }
    
    func toggleEventActive(_ eventId: String) {
        // Just toggle the UI state - no database operation needed for this demo
        // The activeMeetingId binding already handles the visual state
    }
    
    
    var effectiveDirection: Bool {
        return pendingDirection ?? isNavigatingForward
    }
}

struct RightPanelView: View {
    @ObservedObject var rightPanel: RightPanel
    
    var body: some View {
        VStack(spacing: 0) {
            // Fixed month header
            HeaderView(
                monthTitle: rightPanel.currentMonthTitle,
                onPreviousDays: rightPanel.previousDays,
                onNextDays: rightPanel.nextDays,
                shouldShowTodayButton: rightPanel.shouldShowTodayButton,
                onToday: rightPanel.navigateToToday
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
            .background(Color.white)
            .zIndex(2)

            // Animated content container
            VStack(spacing: 0) {
                // Day headers
                HStack(alignment: .top, spacing: 0) {
                    ForEach(Array(rightPanel.currentDays.enumerated()), id: \.element.id) { index, day in
                        DayHeaderView(weekday: day.weekday, dayNumber: day.dayNumber, isToday: day.isToday)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                }
                .frame(height: 57)
                
                // Full width horizontal divider
                Divider()
                
                // Scrollable content area
                ScrollView(.vertical, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 0) {
                        ForEach(Array(rightPanel.currentDays.enumerated()), id: \.element.id) { index, day in
                            DayColumnContent(
                                day: day,
                                index: index,
                                activeMeetingId: $rightPanel.activeMeetingId,
                                rightPanel: rightPanel
                            )
                        }
                    }
                }
            }
        .overlay(
                // Full-height vertical divider
            Rectangle()
                    .fill(Color.gray.opacity(0.3))
                .frame(width: 1)
                    .frame(maxHeight: .infinity),
                alignment: .center
            )
            .id("\(rightPanel.currentDate.timeIntervalSince1970)-\(rightPanel.effectiveDirection)") // Force re-creation to trigger animation
            .transition(.asymmetric(
                insertion: rightPanel.effectiveDirection ? .move(edge: .trailing).combined(with: .opacity) : .move(edge: .leading).combined(with: .opacity),
                removal: rightPanel.effectiveDirection ? .move(edge: .leading).combined(with: .opacity) : .move(edge: .trailing).combined(with: .opacity)
            ))
            .background(Color.white)
        }
        .padding(.top, -18)
        .background(Color.white)
    }
}

// MARK: - Day Column Content

private struct DayColumnContent: View {
    let day: DayModel
    let index: Int
    @Binding var activeMeetingId: String?
    let rightPanel: RightPanel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(day.items, id: \.id) { item in
                switch item.kind {
                case .meeting(let meeting):
                    MeetingCard(meeting: meeting, isActive: activeMeetingId == meeting.id, onToggle: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            activeMeetingId = activeMeetingId == meeting.id ? nil : meeting.id
                            rightPanel.toggleEventActive(meeting.id)
                        }
                    })
                case .banner(let text):
                    InlineBanner(text: text)
                case .breakNote(let text):
                    BreakNote(text: text)
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(.leading, index == 0 ? 16 : 8)
        .padding(.trailing, index == 1 ? 16 : 8)
        .padding(.top, 8)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

// MARK: - Header

private struct HeaderView: View {
    var monthTitle: String
    var onPreviousDays: () -> Void
    var onNextDays: () -> Void
    var shouldShowTodayButton: Bool
    var onToday: () -> Void
    
    var body: some View {
        HStack(alignment: .center) {
            Text(monthTitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(red: 74/255, green: 73/255, blue: 71/255))

            Spacer()

            HStack(spacing: 8) {
                if shouldShowTodayButton {
                    TodayButton(action: onToday)
                }
                
                IconButton(systemName: "chevron.left", action: onPreviousDays)
                IconButton(systemName: "chevron.right", action: onNextDays)
            }
        }
    }
}

private struct IconButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.primary)
        }
        .frame(width: 24, height: 24)
        .buttonStyle(.bordered)
    }
}

private struct TodayButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Today")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.primary)
        }
        .frame(height: 24)
        .buttonStyle(.bordered)
    }
}

// MARK: - Day Column

private struct DayColumnView: View {
    let day: DayModel
    let activeMeetingId: String?
    let onMeetingToggle: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            DayHeaderView(weekday: day.weekday, dayNumber: day.dayNumber, isToday: day.isToday)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 0) {
                ForEach(day.items, id: \.id) { item in
                    switch item.kind {
                    case .meeting(let meeting):
                        MeetingCard(meeting: meeting, isActive: activeMeetingId == meeting.id, onToggle: {
                            onMeetingToggle(meeting.id)
                        })
                    case .banner(let text):
                        InlineBanner(text: text)
                    case .breakNote(let text):
                        BreakNote(text: text)
                    }
                }
                
                Spacer(minLength: 0)
            }
        }
    }
}

private struct DayHeaderView: View {
    let weekday: String
    let dayNumber: Int
    let isToday: Bool
    
    var body: some View {
        HStack(alignment: .center, spacing: isToday ? 4 : 1) {
            Text(weekday)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(red: 74/255, green: 73/255, blue: 71/255))

            ZStack {
                if isToday {
                    Circle()
                        .fill(Color(red: 181/255, green: 90/255, blue: 75/255))
                        .frame(width: 28, height: 28)
                } else {
                    // Invisible circle to maintain consistent spacing
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 28, height: 28)
                }
                Text("\(dayNumber)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isToday ? .white : Color(red: 74/255, green: 73/255, blue: 71/255))
            }
        }
        .frame(height: 58)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Pieces

private struct InlineBanner: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .regular))
            .foregroundColor(Color(red: 181/255, green: 90/255, blue: 75/255))
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(height: 50)
    }
}

private struct BreakNote: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .regular))
            .foregroundColor(Color(red: 166/255, green: 156/255, blue: 142/255))
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(height: 50)
    }
}

private struct MeetingCard: View {
    let meeting: Meeting
    let isActive: Bool
    let onToggle: () -> Void
    @State private var isHovered = false

    private var backgroundColor: Color {
        if isActive {
            return Color(red: 236/255, green: 236/255, blue: 234/255)
        } else if isHovered {
            return Color(red: 243/255, green: 243/255, blue: 242/255)
        } else {
            return Color(red: 249/255, green: 249/255, blue: 248/255)
        }
    }
    
    private var borderColor: Color {
        isActive ? Color(red: 90/255, green: 89/255, blue: 87/255) : Color(red: 230/255, green: 230/255, blue: 230/255)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let time = meeting.timeRange {
                Text(time)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(textColor)
            }

            if let title = meeting.title {
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(textColor)
                    .lineLimit(1)
            }

            if let detail = meeting.detail, isActive {
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundColor(textColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
                    .padding(.top, 3)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 6)
        .padding(.horizontal, 11)
        .padding(.bottom, 8)
        .frame(height: isActive ? nil : 45, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(borderColor)
                .frame(width: 5)
                .mask(
                    Rectangle()
                        .frame(width: 3)
                        .offset(x: -1.5)
                ),
            alignment: .leading
        )
        .onTapGesture(perform: onToggle)
        .onHover { isHovered = $0 }
    }
    
    private var textColor: Color {
        Color(red: 74/255, green: 73/255, blue: 71/255)
    }
}

// MARK: - Models

private struct DayModel: Identifiable {
    let id = UUID()
    let date: Date
    let weekday: String
    let dayNumber: Int
    let isToday: Bool
    var items: [DayItem]
    
    init(date: Date, events: [CalendarEvent] = []) {
        self.date = date
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "E" // Mon, Tue, etc.
        
        self.weekday = formatter.string(from: date)
        self.dayNumber = calendar.component(.day, from: date)
        self.isToday = calendar.isDateInToday(date)
        self.items = Self.generateItemsFromEvents(events, for: date)
    }
    
    static func generateItemsFromEvents(_ events: [CalendarEvent], for date: Date) -> [DayItem] {
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: date)
        
        var items: [DayItem] = []
        
        // Add meetings for weekdays
        if dayOfWeek >= 2 && dayOfWeek <= 6 { // Monday to Friday
            // Sort events by start time
            let sortedEvents = events.compactMap { event -> (CalendarEvent, Date)? in
                guard let startDateTime = event.start?.dateTime,
                      let startDate = ISO8601DateFormatter().date(from: startDateTime),
                      calendar.isDate(startDate, inSameDayAs: date) else {
                    return nil
                }
                return (event, startDate)
            }.sorted { $0.1 < $1.1 }
            
            // Add meetings and calculate breaks between them
            for (index, (event, _)) in sortedEvents.enumerated() {
                let meeting = Meeting(
                    id: event.id,
                    timeRange: formatTimeRange(start: event.start, end: event.end),
                    title: event.summary,
                    detail: event.description,
                    isCurrent: false
                )
                items.append(DayItem(id: UUID(), kind: .meeting(meeting)))
                
                // Add break note between consecutive meetings
                if index < sortedEvents.count - 1 {
                    let currentEvent = event
                    let nextEvent = sortedEvents[index + 1].0
                    
                    if let breakDuration = calculateBreakDuration(
                        currentEventEnd: currentEvent.end,
                        nextEventStart: nextEvent.start
                    ) {
                        let breakText = formatBreakDuration(breakDuration)
                        items.append(DayItem(id: UUID(), kind: .breakNote(breakText)))
                    }
                }
            }
        }
        
        return items
    }
    
    private static func calculateBreakDuration(currentEventEnd: EventDateTime?, nextEventStart: EventDateTime?) -> TimeInterval? {
        guard let currentEndTime = currentEventEnd?.dateTime,
              let nextStartTime = nextEventStart?.dateTime,
              let currentEndDate = ISO8601DateFormatter().date(from: currentEndTime),
              let nextStartDate = ISO8601DateFormatter().date(from: nextStartTime) else {
            return nil
        }
        
        let breakDuration = nextStartDate.timeIntervalSince(currentEndDate)
        return breakDuration > 0 ? breakDuration : nil
    }
    
    private static func formatBreakDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m break"
        } else if hours > 0 {
            return "\(hours)h break"
        } else if minutes > 0 {
            return "\(minutes)m break"
        } else {
            return "No break"
        }
    }
    
    private static func formatTimeRange(start: EventDateTime?, end: EventDateTime?) -> String? {
        guard let startTime = start?.dateTime,
              let endTime = end?.dateTime,
              let startDate = ISO8601DateFormatter().date(from: startTime),
              let endDate = ISO8601DateFormatter().date(from: endTime) else {
            return nil
        }
        
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startDate)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endDate)
        
        guard let startHour = startComponents.hour,
              let startMinute = startComponents.minute,
              let endHour = endComponents.hour,
              let endMinute = endComponents.minute else {
            return nil
        }
        
        // Determine AM/PM for start and end times
        let startIsAM = startHour < 12
        let endIsAM = endHour < 12
        
        // Format start time
        let startDisplayHour = startHour == 0 ? 12 : (startHour > 12 ? startHour - 12 : startHour)
        let startMinuteStr = startMinute == 0 ? "" : ":\(String(format: "%02d", startMinute))"
        let startPeriod = startIsAM ? "AM" : "PM"
        
        // Format end time
        let endDisplayHour = endHour == 0 ? 12 : (endHour > 12 ? endHour - 12 : endHour)
        let endMinuteStr = endMinute == 0 ? "" : ":\(String(format: "%02d", endMinute))"
        let endPeriod = endIsAM ? "AM" : "PM"
        
        // Build the formatted string
        var startFormatted = "\(startDisplayHour)\(startMinuteStr)"
        var endFormatted = "\(endDisplayHour)\(endMinuteStr)"
        
        // Only show AM/PM for start time if it's different from end time
        if startIsAM != endIsAM {
            startFormatted += " \(startPeriod)"
        }
        
        // Always show AM/PM for end time
        endFormatted += " \(endPeriod)"
        
        return "\(startFormatted) – \(endFormatted)"
    }
}

private struct DayItem: Identifiable {
    enum Kind {
        case meeting(Meeting)
        case banner(String)
        case breakNote(String)
    }

    let id: UUID
    let kind: Kind
    
    init(id: UUID, kind: Kind) {
        self.id = id
        self.kind = kind
    }
}

private struct Meeting: Identifiable {
    let id: String
    var timeRange: String?
    var title: String?
    var subtitle: String?
    var detail: String?
    var isCurrent: Bool = false
    
    init(id: String, timeRange: String? = nil, title: String? = nil, subtitle: String? = nil, detail: String? = nil, isCurrent: Bool = false) {
        self.id = id
        self.timeRange = timeRange
        self.title = title
        self.subtitle = subtitle
        self.detail = detail
        self.isCurrent = isCurrent
    }
}


// MARK: - Preview

struct RightPanel_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RightPanelView(rightPanel: RightPanel())
                .previewLayout(.fixed(width: 560, height: 820))
                .previewDisplayName("~560pt (2 days)")

            RightPanelView(rightPanel: RightPanel())
                .previewLayout(.fixed(width: 980, height: 820))
                .previewDisplayName("~980pt (3 days)")
        }
    }
}
