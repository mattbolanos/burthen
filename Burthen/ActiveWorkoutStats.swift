//
//  ActiveWorkoutStats.swift
//  Burthen
//

import SwiftUI

struct ActiveWorkoutStats: View {
  let workout: Workout

  var body: some View {
    HStack(alignment: .top, spacing: LayoutMetrics.Spacing.doubleExtraLarge) {
      VStack(alignment: .leading, spacing: LayoutMetrics.Spacing.extraSmall) {
        Text("Elapsed")
          .font(.subheadline)
          .foregroundStyle(.secondary)

        Text(
          timerInterval: workout.startedAt...(workout.endedAt ?? Date.distantFuture),
          pauseTime: workout.endedAt,
          countsDown: false,
          showsHours: true
        )
        .font(.title2.weight(.semibold))
        .monospacedDigit()
        .foregroundStyle(.primary)
      }

      Spacer(minLength: LayoutMetrics.Spacing.small)

      VStack(alignment: .trailing, spacing: LayoutMetrics.Spacing.extraSmall) {
        Text("Total")
          .font(.subheadline)
          .foregroundStyle(.secondary)

        TrainingLoadText(load: workout.volumeLoad)
          .font(.title2.weight(.semibold))
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
