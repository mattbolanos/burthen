//
//  ExerciseCard.swift
//  Tonnage
//

import Foundation
import SwiftUI

struct ActiveWorkoutExerciseRoute: Hashable {
  let exerciseID: UUID
}

struct ActiveWorkoutExerciseSummary: Identifiable {
  let id: UUID
  let name: String
  let setCount: Int
  let volumeLoad: VolumeLoad?

  init(workoutExercise: WorkoutExercise) {
    id = workoutExercise.id
    name = workoutExercise.exercise?.name ?? "Unavailable Exercise"
    setCount = workoutExercise.exerciseSets.count
    volumeLoad = workoutExercise.volumeLoad
  }

  var setCountLabel: String {
    "\(setCount) \(setCount == 1 ? "set" : "sets")"
  }
}

struct ExerciseCard: View {
  let exercise: ActiveWorkoutExerciseSummary

  var body: some View {
    NavigationLink(
      value: ActiveWorkoutExerciseRoute(exerciseID: exercise.id)
    ) {
      HStack(spacing: LayoutMetrics.Spacing.medium) {
        VStack(alignment: .leading, spacing: LayoutMetrics.Spacing.extraSmall) {
          Text(exercise.name)
            .font(.headline)
            .foregroundStyle(.primary)
            .lineLimit(2)
          Text(exercise.setCountLabel)
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer(minLength: LayoutMetrics.Spacing.small)

        TrainingLoadText(load: exercise.volumeLoad)
          .font(.subheadline.weight(.semibold))
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(.rect)
      .accessibilityElement(children: .combine)
    }
    .padding(LayoutMetrics.Padding.card)
    .frame(maxWidth: .infinity, alignment: .leading)
    .glassEffect(
      .regular.interactive(),
      in: .rect(cornerRadius: LayoutMetrics.CornerRadius.card)
    )
  }
}
