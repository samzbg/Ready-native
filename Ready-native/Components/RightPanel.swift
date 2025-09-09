import SwiftUI
import AppKit

// MARK: - RightPanel (macOS)

struct RightPanel: View {
    @State private var days: [DayModel] = SampleData.days
    @State private var activeMeetingId: UUID? = nil

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(monthTitle: "September 2025")
                .padding(.horizontal, 16)
                .padding(.bottom, 20)

            VStack(spacing: 0) {
                // Day headers with full width
                HStack(alignment: .top, spacing: 0) {
                    ForEach(Array(days.prefix(2).enumerated()), id: \.element.id) { index, day in
                        DayHeaderView(weekday: day.weekday, dayNumber: day.dayNumber, isToday: day.isToday)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                }
                
                // Full width horizontal divider
                Divider()
                
                // Day content with same spacing
                HStack(alignment: .top, spacing: 0) {
                    ForEach(Array(days.prefix(2).enumerated()), id: \.element.id) { index, day in
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
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                }
            }
            .overlay(
                // Center vertical divider
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1),
                alignment: .center
            )
        }
        .padding(.top, -18)
        .background(Color.white)
    }
}

// MARK: - Header

private struct HeaderView: View {
    var monthTitle: String

    var body: some View {
        HStack(alignment: .center) {
            Text(monthTitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)

            Spacer()

            HStack(spacing: 8) {
                IconButton(systemName: "chevron.left")
                IconButton(systemName: "chevron.right")
            }
        }
    }
}

private struct IconButton: View {
    let systemName: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
        }
        .buttonStyle(.plain)
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
                .foregroundStyle(.primary)

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
                    .foregroundStyle(isToday ? .white : .primary)
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
            .foregroundColor(Color(red: 166/255, green: 156/255, blue: 142/255))
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

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let time = meeting.timeRange {
                Text(time)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(red: 74/255, green: 73/255, blue: 71/255))
            }

            if let title = meeting.title {
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(red: 74/255, green: 73/255, blue: 71/255))
                    .lineLimit(1)
            }

            if let detail = meeting.detail, isActive {
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 74/255, green: 73/255, blue: 71/255))
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
                .fill(isActive ? Color(red: 236/255, green: 236/255, blue: 234/255) : Color(red: 249/255, green: 249/255, blue: 248/255))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(red: 90/255, green: 89/255, blue: 87/255))
                .frame(width: 5)
                .mask(
                    Rectangle()
                        .frame(width: 3)
                        .offset(x: -1.5)
                ),
            alignment: .leading
        )
        .onTapGesture {
            onToggle()
        }
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
        Kurt mentioned wanting to spend more time outdoors, so you scheduled a hike at Mount Tamalpais. The plan is to continue your conversation from last week’s call about early-stage product strategy and potential collaborators.
        """

        let monday = DayModel(
            weekday: "Mon",
            dayNumber: 1,
            isToday: true,
            items: [
                .init(kind: .meeting(Meeting(timeRange: "8 – 9 AM",
                                             title: "Team check-in"))),
                .init(kind: .banner("Next meeting in 1 min")),
                .init(kind: .meeting(Meeting(timeRange: "11:45 AM – 1 PM",
                                             title: "1:1 w/Kurt",
                                             detail: kurtDetail,
                                             isCurrent: true))),
                .init(kind: .breakNote("30 min break")),
                .init(kind: .meeting(Meeting(timeRange: "1:30 – 2:45 PM",
                                             title: "Meeting name"))),
                .init(kind: .breakNote("30 min break")),
                .init(kind: .meeting(Meeting(timeRange: "3:30 – 4:45 PM",
                                             title: "Meeting name")))
            ])

        let tuesday = DayModel(
            weekday: "Tue",
            dayNumber: 2,
            isToday: false,
            items: [
                .init(kind: .meeting(Meeting(timeRange: "8 – 9 AM", title: "Meeting name"))),
                .init(kind: .breakNote("1 hour break")),
                .init(kind: .meeting(Meeting(timeRange: "9 – 10:30 AM", title: "Meeting name")))
            ])

        let more = (3...8).map { n in
            DayModel(
                weekday: weekday(for: n),
                dayNumber: n,
                isToday: false,
                items: [
                    .init(kind: .meeting(Meeting(timeRange: "9 – 10 AM", title: "Sync"))),
                    .init(kind: .meeting(Meeting(timeRange: "1 – 2 PM", title: "Deep work")))
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
            RightPanel()
                .previewLayout(.fixed(width: 560, height: 820))
                .previewDisplayName("~560pt (2 days)")

            RightPanel()
                .previewLayout(.fixed(width: 980, height: 820))
                .previewDisplayName("~980pt (3 days)")
        }
    }
}
