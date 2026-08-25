//
//  ExerciseSetEditorRow.swift
//  Tonnage
//

import SwiftUI

struct ExerciseSetEditorRow: View {
  @ScaledMetric(relativeTo: .body)
  private var setNumberColumnWidth = LayoutMetrics.Size.setNumberColumn

  let exerciseSet: ExerciseSet
  let setNumber: Int
  let weightUnit: WeightUnit
  let requiresWeight: Bool
  let canDelete: Bool
  let edit: (ExerciseSet) -> Void
  let remove: (ExerciseSet) -> Void

  var body: some View {
    Button(action: editSet) {
      HStack(alignment: .firstTextBaseline, spacing: LayoutMetrics.Spacing.medium) {
        Text(setNumber, format: .number)
          .font(.body.weight(.semibold))
          .monospacedDigit()
          .foregroundStyle(.secondary)
          .frame(
            width: setNumberColumnWidth,
            alignment: .leading
          )

        setSummary
          .font(.body.weight(.semibold))
          .monospacedDigit()
          .foregroundStyle(.primary)

        Spacer(minLength: LayoutMetrics.Spacing.small)

        if exerciseSet.kind == .warmup {
          Text("Warm-up")
            .font(.body.weight(.medium))
            .foregroundStyle(.orange)
            .lineLimit(1)
        } else {
          TrainingLoadText(load: setVolumeLoad)
            .font(.body)
        }

        Image(systemName: "chevron.forward")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.tertiary)
          .accessibilityHidden(true)
      }
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
      return Text("\(exerciseSet.reps) x — \(weightUnit.displayAbbreviation)")
    }

    return Text(
      "\(exerciseSet.reps) x \(weight, format: .number.precision(.fractionLength(0...1))) \(weightUnit.displayAbbreviation)"
    )
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
