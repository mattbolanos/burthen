//
//  ExerciseSetEditorRow.swift
//  Tonnage
//

import SwiftUI

struct ExerciseSetEditorRow: View {
  let exerciseSet: ExerciseSet
  let setNumber: Int
  let weightUnit: WeightUnit
  let requiresWeight: Bool
  let canDelete: Bool
  let edit: (ExerciseSet) -> Void
  let remove: (ExerciseSet) -> Void

  var body: some View {
    Button(action: editSet) {
      HStack(spacing: LayoutMetrics.Spacing.medium) {
        Text(setNumber, format: .number)
          .font(.subheadline.weight(.semibold))
          .monospacedDigit()
          .foregroundStyle(.tint)
          .frame(width: LayoutMetrics.Size.setNumberColumn)

        VStack(alignment: .leading, spacing: LayoutMetrics.Spacing.extraSmall) {
          setSummary
            .font(.headline)
            .monospacedDigit()
            .foregroundStyle(.primary)

          Text(setKindSummary)
            .font(.subheadline)
            .foregroundStyle(
              exerciseSet.kind == .warmup ? Color.orange : Color.secondary
            )
        }

        Spacer(minLength: LayoutMetrics.Spacing.small)

        TrainingLoadCompactMetric(load: setVolumeLoad)

        Image(systemName: "chevron.forward")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.tertiary)
          .accessibilityHidden(true)
      }
      .padding(.vertical, LayoutMetrics.Spacing.extraSmall)
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Set \(setNumber)")
    .accessibilityValue(accessibilityValue)
    .accessibilityHint("Opens the set editor")
    .accessibilityInputLabels(["Edit Set \(setNumber)", "Set \(setNumber)"])
    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
      if canDelete {
        Button("Delete Set", systemImage: "trash", role: .destructive, action: removeSet)
          .labelStyle(.iconOnly)
      }
    }
  }

  private var setSummary: Text {
    guard requiresWeight || exerciseSet.weight != nil else {
      return Text("\(exerciseSet.reps) reps")
    }

    guard let weight = exerciseSet.weight else {
      return Text("\(exerciseSet.reps) × — \(weightUnit.displayAbbreviation)")
    }

    return Text(
      "\(exerciseSet.reps) × \(weight, format: .number.precision(.fractionLength(0...1))) \(weightUnit.displayAbbreviation)"
    )
  }

  private var setKindSummary: String {
    switch exerciseSet.kind {
    case .working: "Working"
    case .warmup: "Warm-up"
    }
  }

  private var setVolumeLoad: VolumeLoad? {
    exerciseSet.volumeLoad?.converted(to: weightUnit)
  }

  private var accessibilityValue: String {
    let type = exerciseSet.kind == .warmup
      ? "Warm-up set, excluded from training load"
      : "Working set"

    guard requiresWeight || exerciseSet.weight != nil else {
      return "\(type), \(exerciseSet.reps) repetitions, training load not available"
    }

    guard let weight = exerciseSet.weight else {
      return "\(type), \(exerciseSet.reps) repetitions, no weight, training load not available"
    }

    let setDescription =
      "\(type), \(exerciseSet.reps) repetitions, \(weight) \(weightUnit.spokenName)"

    guard let setVolumeLoad else {
      return "\(setDescription), training load not available"
    }
    return "\(setDescription), training load \(setVolumeLoad.accessibilityText)"
  }

  private func editSet() {
    edit(exerciseSet)
  }

  private func removeSet() {
    remove(exerciseSet)
  }
}
