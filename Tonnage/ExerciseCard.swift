//
//  ExerciseCard.swift
//  Tonnage
//

import SwiftUI

struct ExerciseCard: View {
  let workoutExercise: WorkoutExercise

  private var exerciseName: String {
    workoutExercise.exercise?.name ?? "Unavailable Exercise"
  }

  private var setCountLabel: String {
    let setCount = workoutExercise.exerciseSets.count
    return "\(setCount) \(setCount == 1 ? "set" : "sets")"
  }

  var body: some View {
    NavigationLink {
      ActiveWorkoutExerciseView(workoutExercise: workoutExercise)
    } label: {
      VStack(alignment: .leading, spacing: 3) {
        Text(exerciseName)
          .font(.headline)
          .foregroundStyle(.primary)
          .lineLimit(2)
        Text(setCountLabel)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(.rect)
      .accessibilityElement(children: .combine)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 22))
  }
}
