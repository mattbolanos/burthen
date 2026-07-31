//
//  AddExerciseView.swift
//  Tonnage
//

import Foundation
import SwiftData
import SwiftUI

struct AddExerciseView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  @State private var name = ""
  @State private var loadMode = ExerciseLoadMode.externalResistance
  @State private var repetitionMode = ExerciseRepetitionMode.standard
  @State private var isShowingError = false
  @State private var errorMessage = ""

  private var canSave: Bool {
    !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var body: some View {
    NavigationStack {
      Form {
        Section("Exercise") {
          TextField("Name", text: $name)
            .textInputAutocapitalization(.words)
        }

        Section("Tracking") {
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
        }
      }
      .navigationTitle("New Exercise")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel", action: dismiss.callAsFunction)
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Add", action: save)
            .disabled(!canSave)
        }
      }
      .alert("Exercise Couldn’t Be Added", isPresented: $isShowingError) {
        Button("OK", role: .cancel) { }
      } message: {
        Text(errorMessage)
      }
    }
  }

  private func save() {
    do {
      _ = try TrainingDataStore(modelContext: modelContext).createExercise(
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
  AddExerciseView()
    .modelContainer(for: TonnageSchema.models, inMemory: true)
}
