//
//  CompletedWorkoutExerciseCard.swift
//  Tonnage
//

import SwiftUI

struct CompletedWorkoutExerciseCard: View {
  let workoutExercise: WorkoutExercise

  var body: some View {
    let orderedSets = workoutExercise.orderedSets

    VStack(alignment: .leading, spacing: LayoutMetrics.Spacing.medium) {
      HStack(alignment: .top, spacing: LayoutMetrics.Spacing.medium) {
        VStack(alignment: .leading, spacing: LayoutMetrics.Spacing.extraSmall) {
          Text(workoutExercise.exercise?.name ?? "Unavailable Exercise")
            .font(.headline)
            .foregroundStyle(.primary)
            .lineLimit(2)

          Text(setCountLabel(for: orderedSets.count))
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer(minLength: LayoutMetrics.Spacing.small)

        TrainingLoadCompactMetric(load: workoutExercise.volumeLoad)
      }

      if orderedSets.isEmpty {
        Text("No sets recorded")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      } else {
        Divider()

        VStack(alignment: .leading, spacing: LayoutMetrics.Spacing.small) {
          ForEach(
            Array(orderedSets.enumerated()),
            id: \.element.id
          ) { index, exerciseSet in
            CompletedWorkoutSetRow(
              exerciseSet: exerciseSet,
              setNumber: index + 1
            )
          }
        }
      }
    }
    .padding(LayoutMetrics.Padding.card)
    .frame(maxWidth: .infinity, alignment: .leading)
    .glassEffect(
      .regular,
      in: .rect(cornerRadius: LayoutMetrics.CornerRadius.card)
    )
  }

  private func setCountLabel(for count: Int) -> String {
    "\(count) \(count == 1 ? "set" : "sets")"
  }
}
