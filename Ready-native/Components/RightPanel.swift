import SwiftUI
import AppKit

// MARK: - RightPanel (macOS)

class RightPanel: ObservableObject {
    @Published fileprivate var allDays: [DayModel] = SampleData.days
    @Published var currentDayIndex = 0
    @Published var activeMeetingId: UUID? = nil
    @Published var isNavigatingForward = true
    
    fileprivate var currentDays: [DayModel] {
        Array(allDays.dropFirst(currentDayIndex).prefix(2))
    }
    
    var currentMonthTitle: String {
        guard !currentDays.isEmpty else { return "September 2025" }
        let firstDay = currentDays[0]
        // Extract month and year from the first day's date
        return "September 2025" // This would be calculated from actual date in a real app
    }
    
    func previousDays() {
        // Move to previous 2 days
        if currentDayIndex > 0 {
            // Use a small delay to avoid publishing during view updates
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.isNavigatingForward = false
                    self.currentDayIndex = max(0, self.currentDayIndex - 2)
                }
            }
        }
    }
    
    func nextDays() {
        // Move to next 2 days
        if currentDayIndex + 2 < allDays.count {
            // Use a small delay to avoid publishing during view updates
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.isNavigatingForward = true
                    self.currentDayIndex = min(self.allDays.count - 2, self.currentDayIndex + 2)
                }
            }
        }
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
                onNextDays: rightPanel.nextDays
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
                                activeMeetingId: $rightPanel.activeMeetingId
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
            .id("\(rightPanel.currentDayIndex)-\(rightPanel.isNavigatingForward)") // Force re-creation to trigger animation
            .transition(.asymmetric(
                insertion: rightPanel.isNavigatingForward ? .move(edge: .trailing).combined(with: .opacity) : .move(edge: .leading).combined(with: .opacity),
                removal: rightPanel.isNavigatingForward ? .move(edge: .leading).combined(with: .opacity) : .move(edge: .trailing).combined(with: .opacity)
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
    @Binding var activeMeetingId: UUID?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(day.items) { item in
                switch item.kind {
                case .meeting(let meeting):
                    MeetingCard(meeting: meeting, isActive: activeMeetingId == meeting.id, onToggle: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            activeMeetingId = activeMeetingId == meeting.id ? nil : meeting.id
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
    
    var body: some View {
        HStack(alignment: .center) {
            Text(monthTitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(red: 74/255, green: 73/255, blue: 71/255))

            Spacer()

            HStack(spacing: 8) {
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

// MARK: - Day Column

private struct DayColumnView: View {
    let day: DayModel
    let activeMeetingId: UUID?
    let onMeetingToggle: (UUID) -> Void

    var body: some View {
        VStack(spacing: 0) {
            DayHeaderView(weekday: day.weekday, dayNumber: day.dayNumber, isToday: day.isToday)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 0) {
                ForEach(day.items) { item in
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
    let weekday: String
    let dayNumber: Int
    let isToday: Bool
    var items: [DayItem]
}

private struct DayItem: Identifiable {
    enum Kind {
        case meeting(Meeting)
        case banner(String)
        case breakNote(String)
    }

    let id = UUID()
    let kind: Kind
}

private struct Meeting: Identifiable {
    let id = UUID()
    var timeRange: String?
    var title: String?
    var subtitle: String?
    var detail: String?
    var isCurrent: Bool = false
}

// MARK: - Sample Data (replace with real feed)

private enum SampleData {
    static let days: [DayModel] = {
        let kurtDetail =
        """
        Kurt mentioned wanting to spend more time outdoors, so you scheduled a hike at Mount Tamalpais. The plan is to continue your conversation from last week's call about early-stage product strategy and potential collaborators.
        """
        
        let sarahDetail =
        """
        Sarah reached out via LinkedIn after seeing your post about the new product launch. She's interested in discussing potential partnership opportunities between her startup and your company. She was referred by mutual connection Alex Chen.
        """
        
        let designDetail =
        """
        Weekly design review session with the product team. We'll be reviewing the new user interface mockups for the mobile app and discussing feedback from last week's user testing sessions. Bring your laptop for live demos.
        """
        
        let clientDetail =
        """
        Quarterly business review with TechCorp. They've been our biggest client for 2 years and this meeting will cover contract renewal discussions, upcoming project roadmap, and addressing their recent concerns about response times.
        """
        
        let standupDetail =
        """
        Daily standup with the engineering team. We'll review yesterday's progress, discuss any blockers, and plan today's tasks. Focus on the authentication system bug that was reported yesterday.
        """
        
        let strategyDetail =
        """
        Monthly strategy session with the leadership team. We'll be reviewing Q4 performance metrics, discussing budget allocation for next quarter, and planning the company retreat in March. Sarah will present the marketing proposal.
        """
        
        let codeReviewDetail =
        """
        Code review session for the new payment integration feature. We'll be going through the pull requests from the last sprint and ensuring code quality standards. Focus on security best practices and performance optimization.
        """
        
        let investorDetail =
        """
        Investor update call with our lead investor from Sequoia Capital. We'll be discussing our Q4 growth metrics, upcoming product launches, and the Series B funding round that's planned for next quarter.
        """

        let monday = DayModel(
            weekday: "Mon",
            dayNumber: 1,
            isToday: true,
            items: [
                .init(kind: .meeting(Meeting(timeRange: "8 – 9 AM",
                                             title: "Daily Standup",
                                             detail: standupDetail))),
                .init(kind: .breakNote("1 hour break")),
                .init(kind: .meeting(Meeting(timeRange: "11:45 AM – 1 PM",
                                             title: "1:1 w/Kurt",
                                             detail: kurtDetail,
                                             isCurrent: true))),
                .init(kind: .breakNote("30 min break")),
                .init(kind: .meeting(Meeting(timeRange: "1:30 – 2:45 PM",
                                             title: "Design Review",
                                             detail: designDetail))),
                .init(kind: .breakNote("15 min break")),
                .init(kind: .meeting(Meeting(timeRange: "3:00 – 4:00 PM",
                                             title: "Client Call - TechCorp",
                                             detail: clientDetail))),
                .init(kind: .breakNote("15 min break")),
                .init(kind: .meeting(Meeting(timeRange: "4:15 – 5:00 PM",
                                             title: "Code Review Session",
                                             detail: codeReviewDetail))),
                .init(kind: .breakNote("30 min break")),
                .init(kind: .meeting(Meeting(timeRange: "5:30 – 6:30 PM",
                                             title: "Strategy Planning",
                                             detail: strategyDetail)))
            ])

        let tuesday = DayModel(
            weekday: "Tue",
            dayNumber: 2,
            isToday: false,
            items: [
                .init(kind: .meeting(Meeting(timeRange: "9:00 – 10:00 AM",
                                             title: "Sarah - Partnership Discussion",
                                             detail: sarahDetail))),
                .init(kind: .breakNote("1 hour break")),
                .init(kind: .meeting(Meeting(timeRange: "11:00 AM – 12:00 PM",
                                             title: "Team Sync",
                                             detail: "Weekly team synchronization meeting to align on priorities and discuss any cross-team dependencies."))),
                .init(kind: .breakNote("2 hour break")),
                .init(kind: .meeting(Meeting(timeRange: "2:00 – 3:00 PM",
                                             title: "Investor Update Call",
                                             detail: investorDetail))),
                .init(kind: .breakNote("30 min break")),
                .init(kind: .meeting(Meeting(timeRange: "3:30 – 4:30 PM",
                                             title: "Product Demo Prep",
                                             detail: "Preparation session for tomorrow's product demo to potential clients. Reviewing slides and practicing the presentation flow."))),
                .init(kind: .breakNote("30 min break")),
                .init(kind: .meeting(Meeting(timeRange: "5:00 – 6:00 PM",
                                             title: "Engineering Retrospective",
                                             detail: "Monthly retrospective with the engineering team to discuss what went well, what didn't, and how we can improve our processes.")))
            ])

        let more = (3...8).map { n in
            DayModel(
                weekday: weekday(for: n),
                dayNumber: n,
                isToday: false,
                items: [
                    .init(kind: .meeting(Meeting(timeRange: "9:00 – 10:00 AM",
                                                 title: "Morning Sync",
                                                 detail: "Daily synchronization meeting with the product team to discuss priorities and blockers."))),
                    .init(kind: .breakNote("1 hour break")),
                    .init(kind: .meeting(Meeting(timeRange: "11:00 AM – 12:00 PM",
                                                 title: "Client Workshop",
                                                 detail: "Interactive workshop with key clients to gather feedback on our latest features and understand their needs better."))),
                    .init(kind: .breakNote("2 hour break")),
                    .init(kind: .meeting(Meeting(timeRange: "2:00 – 3:00 PM",
                                                 title: "Technical Architecture Review",
                                                 detail: "Deep dive into our system architecture with the senior engineers to plan scalability improvements."))),
                    .init(kind: .breakNote("1 hour break")),
                    .init(kind: .meeting(Meeting(timeRange: "4:00 – 5:00 PM",
                                                 title: "Marketing Planning",
                                                 detail: "Quarterly marketing planning session to align on campaigns, content strategy, and brand positioning.")))
                ])
        }

        return [monday, tuesday] + more
    }()

    private static func weekday(for day: Int) -> String {
        let names = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
        return names[(day - 1) % names.count]
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
