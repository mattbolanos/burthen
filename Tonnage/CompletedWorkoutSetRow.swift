//
//  CompletedWorkoutSetRow.swift
//  Tonnage
//

import SwiftUI

struct CompletedWorkoutSetRow: View {
  let exerciseSet: ExerciseSet
  let setNumber: Int

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: LayoutMetrics.Spacing.medium) {
      Text(setNumber, format: .number)
        .font(.subheadline.weight(.semibold))
        .monospacedDigit()
        .foregroundStyle(.pink)
        .frame(width: LayoutMetrics.Size.setNumberColumn)

      VStack(alignment: .leading, spacing: LayoutMetrics.Spacing.extraSmall) {
        setSummary
          .font(.subheadline.weight(.semibold))
          .monospacedDigit()
          .foregroundStyle(.primary)

        Text(setKindLabel)
          .font(.caption)
          .foregroundStyle(
            exerciseSet.kind == .warmup ? Color.orange : Color.secondary
          )
      }

      Spacer(minLength: LayoutMetrics.Spacing.small)

      TrainingLoadText(load: exerciseSet.volumeLoad)
        .font(.subheadline)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Set \(setNumber)")
    .accessibilityValue(accessibilityValue)
  }

  private var setSummary: Text {
    guard let weight = exerciseSet.weight else {
      return Text("\(exerciseSet.reps) reps")
    }

    let weightUnit = exerciseSet.weightUnit ?? .pounds
    return Text(
      "\(exerciseSet.reps) reps at \(weight, format: .number.precision(.fractionLength(0...1))) \(weightUnit.displayAbbreviation)"
    )
  }

  private var setKindLabel: String {
    switch exerciseSet.kind {
    case .working: "Working"
    case .warmup: "Warm-up"
    }
  }

  private var accessibilityValue: String {
    let setKind = exerciseSet.kind == .warmup ? "Warm-up" : "Working"
    let repetitions = "\(exerciseSet.reps) repetitions"
    let loadDescription = switch exerciseSet.volumeLoad {
    case .some(let load): "training load \(load.accessibilityText)"
    case nil where exerciseSet.kind == .warmup: "excluded from training load"
    case nil: "training load not available"
    }

    guard let weight = exerciseSet.weight else {
      return "\(setKind), \(repetitions), \(loadDescription)"
    }

    let weightUnit = exerciseSet.weightUnit ?? .pounds
    let formattedWeight = weight.formatted(
      .number.precision(.fractionLength(0...1))
    )
    return "\(setKind), \(repetitions) at \(formattedWeight) \(weightUnit.spokenName), \(loadDescription)"
  }
}
