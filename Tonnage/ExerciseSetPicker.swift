//
//  ExerciseSetPicker.swift
//  Tonnage
//

import SwiftData
import SwiftUI

struct ExerciseSetPicker: View {
  private static let repetitionRange = 1...99
  private static let wholeWeightRange = 0...499

  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  let exerciseSet: ExerciseSet
  let setNumber: Int
  let weightUnit: WeightUnit

  @State private var kind: ExerciseSetKind
  @State private var repetitions: Int
  @State private var wholeWeight: Int
  @State private var usesHalfWeight: Bool
  @State private var isShowingError = false
  @State private var errorMessage = ""

  @ScaledMetric(relativeTo: .title2) private var unitSpacing = 6.0

  init(
    exerciseSet: ExerciseSet,
    setNumber: Int,
    weightUnit: WeightUnit
  ) {
    self.exerciseSet = exerciseSet
    self.setNumber = setNumber
    self.weightUnit = weightUnit

    let weight = NSDecimalNumber(decimal: exerciseSet.weight ?? .zero).doubleValue
    let halfSteps = min(
      max(Int((weight * 2).rounded()), 0),
      Self.wholeWeightRange.upperBound * 2
    )

    _kind = State(initialValue: exerciseSet.kind)
    _repetitions = State(
      initialValue: min(max(exerciseSet.reps, 1), Self.repetitionRange.upperBound)
    )
    _wholeWeight = State(initialValue: halfSteps / 2)
    _usesHalfWeight = State(initialValue: !halfSteps.isMultiple(of: 2))
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 12) {
        VStack(spacing: 8) {
          Picker("Set Type", selection: $kind) {
            Text("Working")
              .tag(ExerciseSetKind.working)
            Text("Warm-up")
              .tag(ExerciseSetKind.warmup)
          }
          .pickerStyle(.segmented)

          Label(setTypeDescription, systemImage: setTypeSymbol)
            .font(.footnote)
            .foregroundStyle(kind == .warmup ? Color.orange : Color.secondary)
        }
        .padding(.bottom, 4)

        HStack(spacing: 16) {
          ZStack {
            Picker("Repetitions", selection: $repetitions) {
              ForEach(Self.repetitionRange, id: \.self) { repetition in
                HStack(spacing: unitSpacing) {
                  ZStack(alignment: .trailing) {
                    Text(Self.repetitionRange.upperBound, format: .number)
                      .hidden()
                    Text(repetition, format: .number)
                  }
                  Text("reps")
                    .hidden()
                }
                .fixedSize(horizontal: true, vertical: false)
                .tag(repetition)
              }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            .accessibilityValue("\(repetitions) repetitions")

            HStack(spacing: unitSpacing) {
              Text(Self.repetitionRange.upperBound, format: .number)
                .hidden()
              Text("reps")
            }
            .fixedSize(horizontal: true, vertical: false)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
          }
          .font(.title2)
          .monospacedDigit()
          .frame(maxWidth: .infinity)

          ZStack {
            Picker("Weight", selection: $wholeWeight) {
              ForEach(Self.wholeWeightRange, id: \.self) { weight in
                HStack(spacing: unitSpacing) {
                  HStack(spacing: 0) {
                    ZStack(alignment: .trailing) {
                      Text(Self.wholeWeightRange.upperBound, format: .number)
                        .hidden()
                      Text(weight, format: .number)
                    }
                    if usesHalfWeight {
                      Text(".5")
                        .hidden()
                    }
                  }
                  Text(weightUnit.displayAbbreviation)
                    .hidden()
                }
                .fixedSize(horizontal: true, vertical: false)
                .tag(weight)
              }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            .accessibilityValue(weightAccessibilityValue)

            HStack(spacing: unitSpacing) {
              HStack(spacing: 0) {
                Text(Self.wholeWeightRange.upperBound, format: .number)
                  .hidden()
                if usesHalfWeight {
                  Text(".5")
                }
              }
              Text(weightUnit.displayAbbreviation)
            }
            .fixedSize(horizontal: true, vertical: false)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
          }
          .font(.title2)
          .monospacedDigit()
          .frame(maxWidth: .infinity)
        }

        HStack(spacing: 16) {
          Color.clear
            .frame(maxWidth: .infinity, maxHeight: 0)

          Toggle(isOn: $usesHalfWeight) {
            Text("+ ½ \(weightUnit.displayAbbreviation)")
              .frame(maxWidth: .infinity)
          }
          .toggleStyle(.button)
          .buttonStyle(.bordered)
          .disabled(wholeWeight == Self.wholeWeightRange.upperBound)
          .frame(maxWidth: .infinity)
        }
      }
      .padding(.horizontal)
      .navigationTitle("Set \(setNumber)")
      .navigationBarTitleDisplayMode(.inline)
      .onChange(of: wholeWeight, enforceWeightLimit)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel", action: dismiss.callAsFunction)
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Done", action: save)
        }
      }
      .alert("Set Couldn’t Be Updated", isPresented: $isShowingError) {
      } message: {
        Text(errorMessage)
      }
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
  }

  private var weightAccessibilityValue: String {
    let halfSteps = wholeWeight * 2 + (usesHalfWeight ? 1 : 0)
    let weight = Decimal(halfSteps) / 2
    return "\(weight) \(weightUnit.spokenName)"
  }

  private var setTypeDescription: String {
    switch kind {
    case .working: "Counts toward workout load"
    case .warmup: "Excluded from workout load"
    }
  }

  private var setTypeSymbol: String {
    switch kind {
    case .working: "checkmark.circle.fill"
    case .warmup: "flame.fill"
    }
  }

  private func enforceWeightLimit() {
    if wholeWeight == Self.wholeWeightRange.upperBound {
      usesHalfWeight = false
    }
  }

  private func save() {
    let halfSteps = wholeWeight * 2 + (usesHalfWeight ? 1 : 0)

    exerciseSet.kind = kind
    exerciseSet.reps = repetitions
    exerciseSet.weight = halfSteps == 0 ? nil : Decimal(halfSteps) / 2
    exerciseSet.weightUnit = halfSteps == 0 ? nil : weightUnit
    exerciseSet.workoutExercise?.workout?.updatedAt = .now

    do {
      try modelContext.save()
      dismiss()
    } catch {
      errorMessage = activeWorkoutErrorMessage(for: error)
      isShowingError = true
    }
  }
}
