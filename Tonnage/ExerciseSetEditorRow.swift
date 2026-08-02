//
//  ExerciseSetEditorRow.swift
//  Tonnage
//

import SwiftData
import SwiftUI

struct ExerciseSetEditorRow: View {
  @Bindable var exerciseSet: ExerciseSet

  let setNumber: Int
  let weightUnit: WeightUnit
  let canDelete: Bool
  let edit: (ExerciseSet) -> Void
  let remove: (ExerciseSet) -> Void

  @ScaledMetric(relativeTo: .body) private var fieldHeight = 44.0

  var body: some View {
    HStack(spacing: 8) {
      Menu {
        Button("Working Set", action: selectWorkingSet)
        Button("Warm-up Set", action: selectWarmupSet)
      } label: {
        Text("\(setNumber)")
          .font(.body.weight(.semibold))
          .monospacedDigit()
          .foregroundStyle(
            exerciseSet.kind == .warmup ? Color.orange : Color.primary
          )
          .frame(width: 44, height: fieldHeight)
          .background(.quaternary, in: .rect(cornerRadius: 10))
      }
      .accessibilityLabel("Set \(setNumber)")
      .accessibilityValue(
        exerciseSet.kind == .warmup ? "Warm-up set" : "Working set"
      )

      Button(action: editSet) {
        HStack(spacing: 8) {
          Text(exerciseSet.reps, format: .number)
            .frame(maxWidth: .infinity, minHeight: fieldHeight)
            .background(.quaternary, in: .rect(cornerRadius: 10))

          Text(
            exerciseSet.weight ?? .zero,
            format: .number.precision(.fractionLength(0...1))
          )
          .frame(maxWidth: .infinity, minHeight: fieldHeight)
          .background(.quaternary, in: .rect(cornerRadius: 10))

          Image(systemName: "chevron.up.chevron.down")
            .font(.caption)
            .foregroundStyle(.tertiary)
            .frame(width: 14)
            .accessibilityHidden(true)
        }
        .monospacedDigit()
        .contentShape(.rect)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Edit set \(setNumber)")
      .accessibilityValue(
        "\(exerciseSet.reps) repetitions, \(exerciseSet.weight ?? .zero, format: .number.precision(.fractionLength(0...1))) \(weightUnit.rawValue)"
      )
      .accessibilityInputLabels(["Edit Set \(setNumber)", "Set \(setNumber)"])
    }
    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
      if canDelete {
        Button("Delete Set", systemImage: "trash", role: .destructive, action: removeSet)
      }
    }
  }

  private func editSet() {
    edit(exerciseSet)
  }

  private func removeSet() {
    remove(exerciseSet)
  }

  private func selectWorkingSet() {
    exerciseSet.kind = .working
    markWorkoutUpdated()
  }

  private func selectWarmupSet() {
    exerciseSet.kind = .warmup
    markWorkoutUpdated()
  }

  private func markWorkoutUpdated() {
    exerciseSet.workoutExercise?.workout?.updatedAt = .now
  }
}
