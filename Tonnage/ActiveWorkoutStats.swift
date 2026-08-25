//
//  ActiveWorkoutStats.swift
//  Tonnage
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
          timerInterval: workout.startedAt...Date.distantFuture,
          countsDown: false,
          showsHours: true
        )
        .font(.title2.weight(.semibold))
        .monospacedDigit()
        .foregroundStyle(.primary)
      }

      VStack(alignment: .leading, spacing: LayoutMetrics.Spacing.extraSmall) {
        Text("Total")
          .font(.subheadline)
          .foregroundStyle(.secondary)

        TrainingLoadText(load: workout.volumeLoad)
          .font(.title2.weight(.semibold))
      }

      Spacer(minLength: LayoutMetrics.Spacing.small)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
