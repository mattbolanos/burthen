//
//  ActiveWorkoutExerciseView.swift
//  Tonnage
//

import SwiftData
import SwiftUI

struct ActiveWorkoutExerciseView: View {
  @Environment(\.modelContext) private var modelContext

  let workoutExercise: WorkoutExercise

  @State private var weightUnit: WeightUnit
  @State private var isShowingError = false
  @State private var errorMessage = ""
  @State private var selectedSet: ExerciseSet?

  init(workoutExercise: WorkoutExercise) {
    self.workoutExercise = workoutExercise
    _weightUnit = State(initialValue: workoutExercise.weightUnit)
  }

  private var exerciseName: String {
    workoutExercise.exercise?.name ?? "Unavailable Exercise"
  }

  var body: some View {
    let orderedSets = workoutExercise.orderedSets

    List {
      Section("Weight Unit") {
        Picker("Weight Unit", selection: $weightUnit) {
          ForEach(WeightUnit.allCases, id: \.self) { unit in
            Text(unit.rawValue)
              .tag(unit)
          }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .onChange(of: weightUnit, updateWeightUnit)
      }

      Section {
        ExerciseSetColumnLabels()

        ForEach(orderedSets.enumerated(), id: \.element.id) { index, exerciseSet in
          ExerciseSetEditorRow(
            exerciseSet: exerciseSet,
            setNumber: index + 1,
            weightUnit: weightUnit,
            canDelete: orderedSets.count > 1,
            edit: editSet,
            remove: removeSet
          )
        }

        Button("Add Set", systemImage: "plus", action: addSet)
      } header: {
        Text("Sets")
      } footer: {
        Text("Tap a row to edit reps and weight. Tap a set number to change its type.")
      }
    }
    .navigationTitle(exerciseName)
    .navigationBarTitleDisplayMode(.large)
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
