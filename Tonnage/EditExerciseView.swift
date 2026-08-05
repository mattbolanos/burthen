//
//  EditExerciseView.swift
//  Tonnage
//

import Foundation
import SwiftData
import SwiftUI

struct EditExerciseView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  let exercise: Exercise

  @State private var name: String
  @State private var loadMode: ExerciseLoadMode
  @State private var repetitionMode: ExerciseRepetitionMode
  @State private var isShowingError = false
  @State private var errorMessage = ""

  init(exercise: Exercise) {
    self.exercise = exercise
    _name = State(initialValue: exercise.name)
    _loadMode = State(initialValue: exercise.loadMode)
    _repetitionMode = State(initialValue: exercise.repetitionMode)
  }

  private var isReadOnly: Bool {
    exercise.origin == .seeded
  }

  private var isClassificationLocked: Bool {
    isReadOnly || exercise.hasHistoricalSets
  }

  private var hasChanges: Bool {
    name.trimmingCharacters(in: .whitespacesAndNewlines) != exercise.name
      || loadMode != exercise.loadMode
      || repetitionMode != exercise.repetitionMode
  }

  private var canSave: Bool {
    !isReadOnly
      && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && hasChanges
  }

  var body: some View {
    Form {
      Section {
        TextField("Name", text: $name)
          .textInputAutocapitalization(.words)
          .disabled(isReadOnly)
      } header: {
        SectionHeader("Exercise")
      }

      Section {
        Picker("Load", selection: $loadMode) {
          Text("External Resistance")
            .tag(ExerciseLoadMode.externalResistance)
          Text("Bodyweight")
            .tag(ExerciseLoadMode.bodyweight)
        }

        Picker("Repetitions", selection: $repetitionMode) {
          Text("Standard")
            .tag(ExerciseRepetitionMode.standard)
          Text("Per Side")
            .tag(ExerciseRepetitionMode.perSide)
        }
      } header: {
        SectionHeader("Tracking")
      } footer: {
        if isReadOnly {
          Text("Built-in exercises can’t be edited.")
        } else if exercise.hasHistoricalSets {
          Text("Tracking can’t be changed after sets have been logged, but you can still rename this exercise.")
        }
      }
      .disabled(isClassificationLocked)
    }
    .navigationTitle(isReadOnly ? "Exercise Details" : "Edit Exercise")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      if !isReadOnly {
        ToolbarItem(placement: .confirmationAction) {
          Button("Save", action: save)
            .disabled(!canSave)
        }
      }
    }
    .alert("Exercise Couldn’t Be Updated", isPresented: $isShowingError) {
      Button("OK", role: .cancel) { }
    } message: {
      Text(errorMessage)
    }
  }

  private func save() {
    do {
      try TrainingDataStore(modelContext: modelContext).updateExercise(
        exercise,
        name: name,
        loadMode: loadMode,
        repetitionMode: repetitionMode
      )
      try modelContext.save()
      dismiss()
    } catch {
      errorMessage = exerciseErrorMessage(for: error)
      isShowingError = true
    }
  }
}

#Preview {
  NavigationStack {
    EditExerciseView(
      exercise: try! Exercise(
        name: "Bench Press",
        loadMode: .externalResistance
      )
    )
  }
  .modelContainer(for: TonnageSchema.models, inMemory: true)
}
