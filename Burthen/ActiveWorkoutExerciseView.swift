//
//  ActiveWorkoutExerciseView.swift
//  Burthen
//

import SwiftData
import SwiftUI

struct ActiveWorkoutExerciseView: View {
  @Environment(\.modelContext) private var modelContext
  @ScaledMetric(relativeTo: .body)
  private var setNumberColumnWidth = LayoutMetrics.Size.setNumberColumn

  let workoutExercise: WorkoutExercise

  // NavigationLink may initialize this destination while deleting its source row.
  // Defer SwiftData reads until the destination appears so the model is still attached.
  @State private var weightUnit = WeightUnit.pounds
  @State private var isShowingError = false
  @State private var errorMessage = ""
  @State private var selectedSet: ExerciseSet?

  private var exerciseName: String {
    workoutExercise.exercise?.name ?? "Unavailable Exercise"
  }

  private var requiresWeight: Bool {
    workoutExercise.exercise?.loadMode == .externalResistance
  }

  var body: some View {
    let orderedSets = workoutExercise.orderedSets

    List {
      Section {
        Picker("Weight Unit", selection: $weightUnit) {
          ForEach(WeightUnit.allCases, id: \.self) { unit in
            Text(unit.displayAbbreviation)
              .tag(unit)
          }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .onChange(of: weightUnit, updateWeightUnit)
      }
      .listSectionMargins(
        .horizontal,
        LayoutMetrics.Padding.horizontalContent
      )

      Section {
        ForEach(
          Array(orderedSets.enumerated()),
          id: \.element.id
        ) { index, exerciseSet in
          ExerciseSetEditorRow(
            exerciseSet: exerciseSet,
            setNumber: index + 1,
            weightUnit: weightUnit,
            requiresWeight: requiresWeight,
            canDelete: orderedSets.count > 1,
            edit: editSet,
            remove: removeSet
          )
          .deleteDisabled(orderedSets.count <= 1)
        }
        .onDelete(perform: removeSets)

        Button(action: addSet) {
          HStack(
            alignment: .firstTextBaseline,
            spacing: LayoutMetrics.Spacing.medium
          ) {
            Image(systemName: "plus")
              .frame(
                width: setNumberColumnWidth,
                alignment: .leading
              )
              .accessibilityHidden(true)

            Text("Add Set")
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .contentShape(.rect)
        }
        .accessibilityLabel("Add Set")
      } header: {
        SectionHeader("Sets")
      }
      .listSectionMargins(
        .horizontal,
        LayoutMetrics.Padding.horizontalContent
      )
    }
    .contentMargins(
      .top,
      LayoutMetrics.Spacing.small,
      for: .scrollContent
    )
    .listSectionSpacing(.compact)
    .navigationTitle(exerciseName)
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        EditButton()
      }
    }
    .onAppear(perform: prepareWeightUnit)
    .sheet(item: $selectedSet) { exerciseSet in
      ExerciseSetPicker(
        exerciseSet: exerciseSet,
        setNumber: exerciseSet.position + 1,
        weightUnit: weightUnit
      )
    }
    .alert("Workout Couldn’t Be Updated", isPresented: $isShowingError) {
    } message: {
      Text(errorMessage)
    }
  }

  private func prepareWeightUnit() {
    let storedWeightUnit = workoutExercise.weightUnit
    if weightUnit != storedWeightUnit {
      weightUnit = storedWeightUnit
    } else if workoutExercise.requiresWeightUnitUpdate(to: storedWeightUnit) {
      persistWeightUnit(storedWeightUnit)
    }
  }

  private func updateWeightUnit() {
    persistWeightUnit(weightUnit)
  }

  private func persistWeightUnit(_ weightUnit: WeightUnit) {
    performUpdate {
      try TrainingDataStore(modelContext: modelContext).updateWeightUnit(
        for: workoutExercise,
        to: weightUnit
      )
    }
  }

  private func editSet(_ exerciseSet: ExerciseSet) {
    selectedSet = exerciseSet
  }

  private func addSet() {
    performUpdate {
      _ = try TrainingDataStore(modelContext: modelContext).addSet(
        to: workoutExercise
      )
    }
  }

  private func removeSet(_ exerciseSet: ExerciseSet) {
    performUpdate {
      try TrainingDataStore(modelContext: modelContext).remove(
        exerciseSet,
        from: workoutExercise
      )
    }
  }

  private func removeSets(at offsets: IndexSet) {
    let exerciseSets = offsets.map { workoutExercise.orderedSets[$0] }
    guard exerciseSets.count < workoutExercise.exerciseSets.count else { return }

    performUpdate {
      let store = TrainingDataStore(modelContext: modelContext)
      for exerciseSet in exerciseSets {
        try store.remove(exerciseSet, from: workoutExercise)
      }
    }
  }

  private func performUpdate(_ update: () throws -> Void) {
    do {
      try update()
      try modelContext.save()
    } catch {
      errorMessage = activeWorkoutErrorMessage(for: error)
      isShowingError = true
    }
  }
}
