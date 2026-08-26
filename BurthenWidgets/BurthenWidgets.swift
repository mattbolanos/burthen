//
//  BurthenWidgets.swift
//  BurthenWidgets
//

import ActivityKit
import Foundation
import SwiftUI
import WidgetKit

@main
struct BurthenWidgets: WidgetBundle {
  var body: some Widget {
    WorkoutActivityWidget()
  }
}

struct WorkoutActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
      VStack(alignment: .leading) {
        Text(context.attributes.workoutName)
          .font(.headline)

        if context.isStale {
          Label(
            "Updating...",
            systemImage: "arrow.trianglehead.2.clockwise"
          )
          .foregroundStyle(.secondary)
        } else {
          Text(
            timerInterval: context.attributes.elapsedTimeRange,
            countsDown: false
          )
          .monospacedDigit()
        }
      }
      .padding()
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.center) {
          Text(context.attributes.workoutName)
            .font(.headline)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text(
            timerInterval: context.attributes.elapsedTimeRange,
            countsDown: false
          )
        }
      } compactLeading: {
        BurthenActivityIcon()
      } compactTrailing: {
        CompactWorkoutDuration(startedAt: context.attributes.startedAt)
          .foregroundStyle(.pink)
      } minimal: {
        BurthenActivityIcon()
      }
    }
  }
}

private struct BurthenActivityIcon: View {
  var body: some View {
    Image("BurthenActivityIcon")
      .accessibilityLabel("Burthen")
  }
}

private struct CompactWorkoutDuration: View {
  private static let minute: TimeInterval = 60

  let startedAt: Date

  var body: some View {
    TimelineView(
      .periodic(from: startedAt, by: Self.minute)
    ) { context in
      Text("\(elapsedMinutes(at: context.date))min")
        .monospacedDigit()
    }
  }

  private func elapsedMinutes(at date: Date) -> Int {
    max(0, Int(date.timeIntervalSince(startedAt) / Self.minute))
  }
}

extension WorkoutActivityAttributes {
  fileprivate static let preview = WorkoutActivityAttributes(
    workoutID: UUID(),
    workoutName: "Push Day",
    startedAt: .now.addingTimeInterval(-485)
  )
}

extension WorkoutActivityAttributes.ContentState {
  fileprivate static let preview = WorkoutActivityAttributes.ContentState(isRunning: true)
}

#Preview("Lock Screen", as: .content, using: WorkoutActivityAttributes.preview) {
  WorkoutActivityWidget()
} contentStates: {
  WorkoutActivityAttributes.ContentState.preview
}

#Preview(
  "Dynamic Island Compact",
  as: .dynamicIsland(.compact),
  using: WorkoutActivityAttributes.preview
) {
  WorkoutActivityWidget()
} contentStates: {
  WorkoutActivityAttributes.ContentState.preview
}

#Preview(
  "Dynamic Island Expanded",
  as: .dynamicIsland(.expanded),
  using: WorkoutActivityAttributes.preview
) {
  WorkoutActivityWidget()
} contentStates: {
  WorkoutActivityAttributes.ContentState.preview
}

#Preview(
  "Dynamic Island Minimal",
  as: .dynamicIsland(.minimal),
  using: WorkoutActivityAttributes.preview
) {
  WorkoutActivityWidget()
} contentStates: {
  WorkoutActivityAttributes.ContentState.preview
}
