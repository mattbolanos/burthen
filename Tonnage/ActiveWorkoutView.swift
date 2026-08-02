//
//  ActiveWorkoutView.swift
//  Tonnage
//

import SwiftData
import SwiftUI

struct ActiveWorkoutView: View {
  let workout: Workout

  var body: some View {
    NavigationStack {
      GlassEffectContainer(spacing: 16) {
        ActiveWorkoutEditor(workout: workout)
      }
    }
  }
}

private struct ActiveWorkoutEditor: View {
  @Environment(\.modelContext) private var modelContext

  let workout: Workout

  @State private var isSelectingExercise = false
  @State private var isShowingError = false
  @State private var errorMessage = ""

  var body: some View {
    List {
      ActiveWorkoutHeader(workout: workout)

      if workout.orderedExercises.isEmpty {
        ActiveWorkoutEmptyState(addExercise: presentExercisePicker)
      } else {
        ForEach(workout.orderedExercises) { workoutExercise in
          ExerciseCard(workoutExercise: workoutExercise)
            .listRowInsets(
              EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            )
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
        .onDelete(perform: removeExercises)
        .onMove(perform: moveExercises)
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .background(Color(uiColor: .systemGroupedBackground))
    .navigationTitle("Active Workout")
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
      ToolbarItemGroup(placement: .topBarTrailing) {
        EditButton()
        Button(
          "Add Exercise",
          systemImage: "plus",
          action: presentExercisePicker
        )
      }
    }
    .sheet(isPresented: $isSelectingExercise) {
      WorkoutExercisePicker(workout: workout)
    }
    .alert("Workout Couldn’t Be Updated", isPresented: $isShowingError) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(errorMessage)
    }
    .onAppear(perform: prepareWorkout)
  }

  private func presentExercisePicker() {
    isSelectingExercise = true
  }

  private func prepareWorkout() {
    performUpdate {
      try TrainingDataStore(modelContext: modelContext).prepareForEditing(workout)
    }
  }

  private func moveExercises(from offsets: IndexSet, to destination: Int) {
    var orderedExercises = workout.orderedExercises
    orderedExercises.move(fromOffsets: offsets, toOffset: destination)
    performUpdate {
      try TrainingDataStore(modelContext: modelContext).reorderExercises(
        in: workout,
        to: orderedExercises
      )
    }
  }

  private func removeExercises(at offsets: IndexSet) {
    let exercises = offsets.map { workout.orderedExercises[$0] }
    performUpdate {
      let store = TrainingDataStore(modelContext: modelContext)
      for exercise in exercises {
        try store.remove(exercise, from: workout)
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

private struct ActiveWorkoutHeader: View {
  let workout: Workout

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(workout.name ?? "Unplanned Workout")
        .font(.headline)
        .foregroundStyle(.secondary)

      Text(
        workout.startedAt,
        format: .dateTime
          .weekday(.wide)
          .month(.wide)
          .day()
          .hour()
          .minute()
      )
      .font(.title3.weight(.semibold))

      if let notes = workout.notes {
        Text(notes)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, 8)
    .listRowSeparator(.hidden)
    .listRowBackground(Color.clear)
    .accessibilityElement(children: .combine)
  }
}

private struct ActiveWorkoutEmptyState: View {
  let addExercise: () -> Void

  var body: some View {
    ContentUnavailableView {
      Label("No Exercises", systemImage: "dumbbell")
    } description: {
      Text("Add an exercise to start logging this workout.")
    } actions: {
      Button("Add Exercise", systemImage: "plus", action: addExercise)
        .buttonStyle(.borderedProminent)
    }
    .listRowSeparator(.hidden)
    .listRowBackground(Color.clear)
  }
}

private struct WorkoutExercisePicker: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  @Query(
    filter: #Predicate<Exercise> { !$0.isArchived },
    sort: \Exercise.name
  )
  private var activeExercises: [Exercise]

  let workout: Workout

  @State private var isShowingError = false
  @State private var errorMessage = ""

  var body: some View {
    NavigationStack {
      List {
        Section {
          ForEach(activeExercises) { exercise in
            Button {
              add(exercise)
            } label: {
              WorkoutExercisePickerRow(exercise: exercise)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Adds this exercise to the active workout.")
          }
        } footer: {
          Text("An exercise can be added more than once.")
        }
      }
      .overlay {
        if activeExercises.isEmpty {
          ContentUnavailableView(
            "No Exercises",
            systemImage: "dumbbell",
            description: Text("Create an exercise in Settings before adding it here.")
          )
        }
      }
      .navigationTitle("Add Exercise")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel", action: dismiss.callAsFunction)
        }
      }
      .alert("Exercise Couldn’t Be Added", isPresented: $isShowingError) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(errorMessage)
      }
    }
  }

  private func add(_ exercise: Exercise) {
    do {
      _ = try TrainingDataStore(modelContext: modelContext).addExercise(
        exercise,
        to: workout
      )
      try modelContext.save()
      dismiss()
    } catch {
      errorMessage = activeWorkoutErrorMessage(for: error)
      isShowingError = true
    }
  }
}

private struct WorkoutExercisePickerRow: View {
  let exercise: Exercise

  var body: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 3) {
        Text(exercise.name)
          .font(.body.weight(.medium))
          .foregroundStyle(.primary)
        Text(exercise.activeWorkoutTrackingSummary)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()

      Image(systemName: "plus.circle.fill")
        .font(.title3)
        .foregroundStyle(.tint)
        .accessibilityHidden(true)
    }
    .contentShape(.rect)
  }
}

extension Exercise {
  fileprivate var activeWorkoutTrackingSummary: String {
    let load =
      switch loadMode {
      case .externalResistance: "External resistance"
      case .bodyweight: "Bodyweight"
      }
    let repetitions = repetitionMode == .perSide ? "Per side" : "Standard reps"
    return "\(load) · \(repetitions)"
  }
}

func activeWorkoutErrorMessage(for error: Error) -> String {
  guard let modelError = error as? WorkoutModelError else {
    return error.localizedDescription
  }

  return switch modelError {
  case .cannotRemoveLastSet:
    "Each exercise needs at least one set."
  case .exerciseIsArchived:
    "This exercise is no longer available."
  case .workoutIsNotInProgress:
    "Only an active workout can be edited."
  default:
    "The workout couldn’t be updated."
  }
}

#Preview {
  ActiveWorkoutView(workout: try! Workout(name: "Resistance Day A"))
    .modelContainer(for: TonnageSchema.models, inMemory: true)
}
