//
//  ActiveWorkoutView.swift
//  Tonnage
//

import SwiftData
import SwiftUI

struct ActiveWorkoutView: View {
  let workout: Workout
  let onDiscard: () -> Void

  var body: some View {
    NavigationStack {
      GlassEffectContainer(spacing: LayoutMetrics.Spacing.large) {
        ActiveWorkoutEditor(
          workout: workout,
          onDiscard: onDiscard
        )
      }
    }
  }
}

private struct ActiveWorkoutEditor: View {
  @Environment(\.modelContext) private var modelContext

  let workout: Workout
  let onDiscard: () -> Void

  @State private var isSelectingExercise = false
  @State private var isConfirmingWorkoutEnd = false
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
            .listRowInsets(LayoutMetrics.Insets.cardRow)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
              Button(
                "Delete Exercise",
                systemImage: "trash",
                role: .destructive
              ) {
                removeExercise(workoutExercise)
              }
              .labelStyle(.iconOnly)
            }
        }
        .onDelete(perform: removeExercises)
        .onMove(perform: moveExercises)
      }

      Button(action: requestWorkoutEnd) {
        Text("End Workout")
          .font(.headline)
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.glass)
      .controlSize(.large)
      .tint(.red)
      .listRowInsets(LayoutMetrics.Insets.finalActionRow)
      .listRowSeparator(.hidden)
      .listRowBackground(Color.clear)
      .accessibilityHint("Shows options to save or discard this workout.")
      .confirmationDialog(
        "End Workout?",
        isPresented: $isConfirmingWorkoutEnd,
        titleVisibility: .visible
      ) {
        Button("Complete Workout", action: saveAndEndWorkout)
        Button("Discard Workout", role: .destructive, action: discardWorkout)
        Button("Continue Workout", role: .cancel) {}
      } message: {
        Text("Save your sets and workout duration, or discard this workout permanently.")
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

  private func requestWorkoutEnd() {
    isConfirmingWorkoutEnd = true
  }

  private func saveAndEndWorkout() {
    performUpdate {
      try workout.complete()
    }
  }

  private func discardWorkout() {
    let didDiscard = performUpdate {
      try TrainingDataStore(modelContext: modelContext).discard(workout)
    }

    if didDiscard {
      onDiscard()
    }
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

  private func removeExercise(_ workoutExercise: WorkoutExercise) {
    performUpdate {
      try TrainingDataStore(modelContext: modelContext).remove(
        workoutExercise,
        from: workout
      )
    }
  }

  @discardableResult
  private func performUpdate(_ update: () throws -> Void) -> Bool {
    do {
      try update()
      try modelContext.save()
      return true
    } catch {
      modelContext.rollback()
      errorMessage = activeWorkoutErrorMessage(for: error)
      isShowingError = true
      return false
    }
  }
}

private struct ActiveWorkoutHeader: View {
  let workout: Workout

  var body: some View {
    VStack(alignment: .leading, spacing: LayoutMetrics.Spacing.small) {
      Text(workout.displayName)
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

      LabeledContent {
        Text(
          timerInterval: workout.startedAt...Date.distantFuture,
          countsDown: false,
          showsHours: true
        )
        .font(.title2.weight(.semibold))
        .monospacedDigit()
        .foregroundStyle(.primary)
      } label: {
        Label("Elapsed", systemImage: "timer")
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, LayoutMetrics.Spacing.small)
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
    HStack(spacing: LayoutMetrics.Spacing.medium) {
      VStack(alignment: .leading, spacing: LayoutMetrics.Spacing.extraSmall) {
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
  case .invalidReps:
    "Enter at least one repetition for every set before saving the workout."
  case .missingExercise:
    "Remove unavailable exercises before saving the workout."
  case .missingWeight:
    "Enter a weight for every weighted set before saving the workout."
  case .missingWeightUnit:
    "Choose a weight unit for every weighted set before saving the workout."
  case .workoutAlreadyCompleted:
    "This workout has already ended."
  case .workoutHasNoSets:
    "Add an exercise before saving the workout, or discard it instead."
  case .workoutIsNotInProgress:
    "Only an active workout can be edited."
  default:
    "The workout couldn’t be updated."
  }
}

#Preview("Active Workout") {
  ActiveWorkoutView(
    workout: try! Workout(
      name: "Push Day",
      notes: "Chest and shoulders",
      startedAt: .now.addingTimeInterval(-3_725)
    ),
    onDiscard: {}
  )
    .modelContainer(for: TonnageSchema.models, inMemory: true)
}
