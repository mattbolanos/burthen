//
//  ExerciseSetPicker.swift
//  Tonnage
//

import SwiftData
import SwiftUI

struct ExerciseSetPicker: View {
  private static let repetitionRange = 1...49
  private static let wholeWeightRange = 0...399
  private static let persistenceDelay = Duration.milliseconds(300)

  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  let exerciseSet: ExerciseSet
  let setNumber: Int
  let weightUnit: WeightUnit

  @State private var kind: ExerciseSetKind
  @State private var repetitions: Int
  @State private var wholeWeight: Int
  @State private var usesHalfWeight: Bool
  @State private var hasPendingChanges = false
  @State private var persistenceTask: Task<Void, Never>?
  @State private var isShowingError = false
  @State private var errorMessage = ""

  @ScaledMetric(relativeTo: .title2)
  private var unitSpacing = LayoutMetrics.Spacing.small

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
      VStack(spacing: LayoutMetrics.Spacing.medium) {
        VStack(spacing: LayoutMetrics.Spacing.small) {
          Picker("Set Type", selection: $kind) {
            Text("Working")
              .tag(ExerciseSetKind.working)
            Text("Warm-up")
              .tag(ExerciseSetKind.warmup)
          }
          .pickerStyle(.segmented)

        }
        .padding(.bottom, LayoutMetrics.Spacing.extraSmall)

        HStack(spacing: LayoutMetrics.Spacing.large) {
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

        HStack(spacing: LayoutMetrics.Spacing.large) {
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
      .padding(.horizontal, LayoutMetrics.Padding.horizontalContent)
      .navigationTitle("Set \(setNumber)")
      .navigationBarTitleDisplayMode(.inline)
      .onChange(of: kind, scheduleSave)
      .onChange(of: repetitions, scheduleSave)
      .onChange(of: wholeWeight, updateWholeWeight)
      .onChange(of: usesHalfWeight, scheduleSave)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done", action: finish)
        }
      }
      .alert("Set Couldn’t Be Updated", isPresented: $isShowingError) {
      } message: {
        Text(errorMessage)
      }
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
    .onDisappear(perform: savePendingChanges)
  }

  private var weightAccessibilityValue: String {
    let halfSteps = wholeWeight * 2 + (usesHalfWeight ? 1 : 0)
    let weight = Decimal(halfSteps) / 2
    return "\(weight) \(weightUnit.spokenName)"
  }

  private var draftVolumeLoad: VolumeLoad? {
    let halfSteps = wholeWeight * 2 + (usesHalfWeight ? 1 : 0)
    let weight = halfSteps == 0 ? nil : Decimal(halfSteps) / 2

    return VolumeLoad.forSet(
      kind: kind,
      repetitions: repetitions,
      weight: weight,
      unit: weightUnit
    )
  }

  private func enforceWeightLimit() {
    if wholeWeight == Self.wholeWeightRange.upperBound {
      usesHalfWeight = false
    }
  }

  private func updateWholeWeight() {
    enforceWeightLimit()
    scheduleSave()
  }

  private func scheduleSave() {
    hasPendingChanges = true
    persistenceTask?.cancel()
    persistenceTask = Task {
      try? await Task.sleep(for: Self.persistenceDelay)
      guard !Task.isCancelled else { return }
      savePendingChanges()
    }
  }

  private func applyChanges() {
    let halfSteps = wholeWeight * 2 + (usesHalfWeight ? 1 : 0)

    exerciseSet.kind = kind
    exerciseSet.reps = repetitions
    exerciseSet.weight = halfSteps == 0 ? nil : Decimal(halfSteps) / 2
    exerciseSet.weightUnit = halfSteps == 0 ? nil : weightUnit
    exerciseSet.workoutExercise?.workout?.updatedAt = .now
  }

  private func savePendingChanges() {
    persistenceTask?.cancel()
    persistenceTask = nil

    guard hasPendingChanges else { return }

    applyChanges()

    do {
      try modelContext.save()
      hasPendingChanges = false
    } catch {
      errorMessage = activeWorkoutErrorMessage(for: error)
      isShowingError = true
    }
  }

  private func finish() {
    savePendingChanges()
    guard !hasPendingChanges else { return }
    dismiss()
  }
}
