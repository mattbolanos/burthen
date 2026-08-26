//
//  BlankWorkoutView.swift
//  Burthen
//

import SwiftData
import SwiftUI

struct BlankWorkoutView: View {
  @Environment(\.modelContext) private var modelContext

  @State private var exercises: [BlankWorkoutExerciseDraft] = []
  @State private var presentedSheet: BlankWorkoutSheet?
  @State private var isShowingError = false
  @State private var errorMessage = ""

  var body: some View {
    List {
      if !exercises.isEmpty {
        Section {
          ForEach(exercises) { draft in
            BlankWorkoutExerciseRow(exercise: draft.exercise)
              .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(
                  "Delete Exercise",
                  systemImage: "trash",
                  role: .destructive
                ) {
                  removeExercise(draft)
                }
                .labelStyle(.iconOnly)
              }
          }
          .onDelete(perform: removeExercises)
          .onMove(perform: moveExercises)
        } header: {
          SectionHeader("Exercises")
        }

        BlankWorkoutActions(
          saveTemplate: presentTemplateEditor,
          startWorkout: startWorkout
        )
        .listRowInsets(.init())
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
      }
    }
    .overlay {
      if exercises.isEmpty {
        BlankWorkoutEmptyState(
          createExercise: addExercise,
          chooseExercises: selectExercises
        )
        .padding(.horizontal, LayoutMetrics.Padding.horizontalContent)
      }
    }
    .navigationTitle("Blank Workout")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      if !exercises.isEmpty {
        ToolbarItemGroup(placement: .topBarTrailing) {
          EditButton()
          Button(
            "Add Exercises",
            systemImage: "plus",
            action: selectExercises
          )
        }
      }
    }
    .sheet(item: $presentedSheet) { sheet in
      switch sheet {
      case .exercisePicker:
        BlankWorkoutExercisePicker(exercises: $exercises)
      case .newExercise:
        AddExerciseView(onAdd: appendExercise)
      case .template(let seed):
        AddWorkoutTemplateView(seed: seed)
      }
    }
    .alert("Workout Couldn’t Be Started", isPresented: $isShowingError) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(errorMessage)
    }
  }

  private func selectExercises() {
    presentedSheet = .exercisePicker
  }

  private func addExercise() {
    presentedSheet = .newExercise
  }

  private func appendExercise(_ exercise: Exercise) {
    exercises.append(BlankWorkoutExerciseDraft(exercise: exercise))
  }

  private func removeExercises(at offsets: IndexSet) {
    exercises.remove(atOffsets: offsets)
  }

  private func removeExercise(_ exercise: BlankWorkoutExerciseDraft) {
    exercises.removeAll { $0.id == exercise.id }
  }

  private func moveExercises(from offsets: IndexSet, to destination: Int) {
    exercises.move(fromOffsets: offsets, toOffset: destination)
  }

  private func presentTemplateEditor() {
    presentedSheet = .template(
      WorkoutTemplateSeed(exercises: exercises.map(\.exercise))
    )
  }

  private func startWorkout() {
    guard !exercises.isEmpty else { return }

    do {
      let store = TrainingDataStore(modelContext: modelContext)
      let workout = try store.startWorkout()
      for draft in exercises {
        try store.addExercise(draft.exercise, to: workout)
      }
      try modelContext.save()
    } catch {
      modelContext.rollback()
      errorMessage = blankWorkoutErrorMessage(for: error)
      isShowingError = true
    }
  }
}

private enum BlankWorkoutSheet: Identifiable {
  case exercisePicker
  case newExercise
  case template(WorkoutTemplateSeed)

  var id: String {
    switch self {
    case .exercisePicker:
      "exercise-picker"
    case .newExercise:
      "new-exercise"
    case .template(let seed):
      "template-\(seed.id)"
    }
  }
}

private struct BlankWorkoutActions: View {
  let saveTemplate: () -> Void
  let startWorkout: () -> Void

  var body: some View {
    VStack(spacing: LayoutMetrics.Spacing.small) {
      Button(action: saveTemplate) {
        Label(
          "Save as Template",
          systemImage: "rectangle.stack.badge.plus"
        )
        .frame(maxWidth: .infinity)
      }
      .buttonStyle(.glass)
      .controlSize(.large)
      .accessibilityHint(
        "Creates a reusable template from these exercises."
      )

      Button(action: startWorkout) {
        Text("Start Workout")
          .font(.headline)
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.glassProminent)
      .controlSize(.large)
      .accessibilityHint("Starts a workout with these exercises.")
    }
  }
}

private struct BlankWorkoutEmptyState: View {
  let createExercise: () -> Void
  let chooseExercises: () -> Void

  var body: some View {
    ContentUnavailableView {
      ContentUnavailableLogoLabel(title: "No Exercises Yet")
    } description: {
      Text("Create a new exercise or add existing ones from your library.")
    } actions: {
      ViewThatFits(in: .horizontal) {
        HStack(spacing: LayoutMetrics.Spacing.small) {
          Button("New Exercise", action: createExercise)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.pink)
            .fixedSize(horizontal: true, vertical: false)

          Button("Add Existing", action: chooseExercises)
            .buttonStyle(.bordered)
            .controlSize(.large)
            .fixedSize(horizontal: true, vertical: false)
        }

        VStack(spacing: LayoutMetrics.Spacing.small) {
          Button(action: createExercise) {
            Text("New Exercise")
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.large)
          .tint(.pink)

          Button(action: chooseExercises) {
            Text("Add Existing")
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.bordered)
          .controlSize(.large)
        }
      }
    }
  }
}

private struct BlankWorkoutExercisePicker: View {
  @Environment(\.dismiss) private var dismiss

  @Query(
    filter: #Predicate<Exercise> { !$0.isArchived },
    sort: \Exercise.name
  )
  private var activeExercises: [Exercise]

  @Binding var exercises: [BlankWorkoutExerciseDraft]
  @State private var selectedExerciseIDs: Set<UUID> = []
  @State private var searchText = ""
  @State private var isAddingExercise = false

  private var existingExerciseIDs: Set<UUID> {
    Set(exercises.map { $0.exercise.id })
  }

  private var filteredExercises: [Exercise] {
    guard !searchText.isEmpty else { return activeExercises }
    return activeExercises.filter { exercise in
      exercise.name.localizedStandardContains(searchText)
    }
  }

  var body: some View {
    NavigationStack {
      List {
        if !filteredExercises.isEmpty {
          Section {
            Button(
              "New Exercise",
              systemImage: "plus",
              action: addExercise
            )
          }

          Section {
            ForEach(filteredExercises) { exercise in
              Button {
                toggleSelection(of: exercise)
              } label: {
                BlankWorkoutExercisePickerRow(
                  exercise: exercise,
                  isAlreadyAdded: existingExerciseIDs.contains(exercise.id),
                  isSelected: selectedExerciseIDs.contains(exercise.id)
                )
              }
              .buttonStyle(.plain)
              .disabled(existingExerciseIDs.contains(exercise.id))
              .accessibilityValue(accessibilityValue(for: exercise))
            }
          }
        }
      }
      .overlay {
        if activeExercises.isEmpty {
          ContentUnavailableView {
            ContentUnavailableLogoLabel(title: "No Exercises")
          } description: {
            Text("Create an exercise to add it to this workout.")
          } actions: {
            Button("New Exercise", systemImage: "plus", action: addExercise)
              .buttonStyle(.borderedProminent)
              .controlSize(.large)
              .tint(.pink)
          }
        } else if filteredExercises.isEmpty {
          ContentUnavailableView {
            Label("No Results", systemImage: "magnifyingglass")
          } description: {
            Text("No exercises match “\(searchText)”.")
          } actions: {
            Button("New Exercise", systemImage: "plus", action: addExercise)
              .buttonStyle(.borderedProminent)
              .controlSize(.large)
              .tint(.pink)
          }
        }
      }
      .searchable(text: $searchText, prompt: "Search Exercises")
      .navigationTitle("Exercises")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel", action: dismiss.callAsFunction)
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Add", action: addSelectedExercises)
            .disabled(selectedExerciseIDs.isEmpty)
        }
      }
      .sheet(isPresented: $isAddingExercise) {
        AddExerciseView(onAdd: selectNewExercise)
      }
    }
  }

  private func accessibilityValue(for exercise: Exercise) -> String {
    if existingExerciseIDs.contains(exercise.id) {
      "Already added"
    } else if selectedExerciseIDs.contains(exercise.id) {
      "Selected"
    } else {
      "Not selected"
    }
  }

  private func addExercise() {
    isAddingExercise = true
  }

  private func selectNewExercise(_ exercise: Exercise) {
    searchText = ""
    selectedExerciseIDs.insert(exercise.id)
  }

  private func toggleSelection(of exercise: Exercise) {
    if selectedExerciseIDs.contains(exercise.id) {
      selectedExerciseIDs.remove(exercise.id)
    } else {
      selectedExerciseIDs.insert(exercise.id)
    }
  }

  private func addSelectedExercises() {
    for exercise in activeExercises where selectedExerciseIDs.contains(exercise.id) {
      exercises.append(BlankWorkoutExerciseDraft(exercise: exercise))
    }
    dismiss()
  }
}

private struct BlankWorkoutExercisePickerRow: View {
  let exercise: Exercise
  let isAlreadyAdded: Bool
  let isSelected: Bool

  var body: some View {
    HStack {
      BlankWorkoutExerciseRow(exercise: exercise)

      Spacer()

      if isAlreadyAdded {
        Image(systemName: "checkmark.circle.fill")
          .font(.title3)
          .foregroundStyle(.secondary)
          .accessibilityHidden(true)
      } else if isSelected {
        Image(systemName: "checkmark.circle.fill")
          .font(.title3)
          .foregroundStyle(.tint)
          .accessibilityHidden(true)
      } else {
        Image(systemName: "circle")
          .font(.title3)
          .foregroundStyle(.tertiary)
          .accessibilityHidden(true)
      }
    }
    .contentShape(.rect)
  }
}

private struct BlankWorkoutExerciseRow: View {
  let exercise: Exercise

  var body: some View {
    VStack(alignment: .leading, spacing: LayoutMetrics.Spacing.extraSmall) {
      Text(exercise.name)
        .foregroundStyle(.primary)
      Text(exercise.blankWorkoutTrackingSummary)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .accessibilityElement(children: .combine)
  }
}

private struct BlankWorkoutExerciseDraft: Identifiable {
  let id = UUID()
  let exercise: Exercise
}

private extension Exercise {
  var blankWorkoutTrackingSummary: String {
    let load = switch loadMode {
    case .externalResistance: "External resistance"
    case .bodyweight: "Bodyweight"
    }
    let repetitions = repetitionMode == .perSide ? "Per side" : "Standard reps"
    return "\(load) · \(repetitions)"
  }
}

private func blankWorkoutErrorMessage(for error: Error) -> String {
  guard let modelError = error as? WorkoutModelError else {
    return error.localizedDescription
  }

  return switch modelError {
  case .activeWorkoutExists:
    "Finish or discard the active workout before starting another one."
  case .exerciseIsArchived:
    "One of these exercises is no longer available. Remove it and try again."
  default:
    "The workout couldn’t be started."
  }
}

#Preview {
  NavigationStack {
    BlankWorkoutView()
  }
  .modelContainer(for: BurthenSchema.models, inMemory: true)
}
