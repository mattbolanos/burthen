//
//  WorkoutTemplateEditorView.swift
//  Tonnage
//

import SwiftData
import SwiftUI

struct AddWorkoutTemplateView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  @State private var draft = WorkoutTemplateDraft()
  @State private var isShowingError = false
  @State private var errorMessage = ""

  var body: some View {
    NavigationStack {
      WorkoutTemplateForm(draft: $draft)
        .navigationTitle("New Template")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel", action: dismiss.callAsFunction)
          }
          ToolbarItemGroup(placement: .topBarTrailing) {
            Button("Add", action: save)
              .disabled(!draft.isValid)
          }
        }
        .alert("Template Couldn’t Be Added", isPresented: $isShowingError) {
          Button("OK", role: .cancel) {}
        } message: {
          Text(errorMessage)
        }
    }
  }

  private func save() {
    do {
      _ = try TrainingDataStore(modelContext: modelContext).createTemplate(
        name: draft.normalizedName,
        notes: draft.normalizedNotes,
        exercises: draft.exercisePlans
      )
      try modelContext.save()
      dismiss()
    } catch {
      errorMessage = templateErrorMessage(for: error)
      isShowingError = true
    }
  }
}

struct EditWorkoutTemplateView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  let template: WorkoutTemplate

  @State private var draft: WorkoutTemplateDraft
  @State private var isShowingError = false
  @State private var errorMessage = ""

  init(template: WorkoutTemplate) {
    self.template = template
    _draft = State(initialValue: WorkoutTemplateDraft(template: template))
  }

  private var canSave: Bool {
    draft.isValid && draft.signature != template.editorSignature
  }

  var body: some View {
    WorkoutTemplateForm(
      draft: $draft,
      showsArchivedNotice: template.isArchived
    )
    .navigationTitle("Edit Template")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItemGroup(placement: .topBarTrailing) {
        EditButton()
        Button("Save", action: save)
          .disabled(!canSave)
      }
    }
    .alert("Template Couldn’t Be Updated", isPresented: $isShowingError) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(errorMessage)
    }
  }

  private func save() {
    do {
      try TrainingDataStore(modelContext: modelContext).updateTemplate(
        template,
        name: draft.normalizedName,
        notes: draft.normalizedNotes,
        exercises: draft.exercisePlans
      )
      try modelContext.save()
      dismiss()
    } catch {
      errorMessage = templateErrorMessage(for: error)
      isShowingError = true
    }
  }
}

private struct WorkoutTemplateForm: View {
  @Binding var draft: WorkoutTemplateDraft
  let showsArchivedNotice: Bool

  @State private var isSelectingExercises = false

  init(
    draft: Binding<WorkoutTemplateDraft>,
    showsArchivedNotice: Bool = false
  ) {
    _draft = draft
    self.showsArchivedNotice = showsArchivedNotice
  }

  var body: some View {
    Form {
      if showsArchivedNotice {
        Section {
          Label("Archived", systemImage: "archivebox")
            .foregroundStyle(.secondary)
        } footer: {
          Text("Restore this template from the template list to use it for new workouts.")
        }
      }

      Section {
        TextField("Name", text: $draft.name)
          .textInputAutocapitalization(.words)

        TextField("Notes", text: $draft.notes, axis: .vertical)
          .lineLimit(2...5)
      } header: {
        SectionHeader("Template")
      }

      Section {
        if !draft.exercises.isEmpty {
          ForEach($draft.exercises) { $exercise in
            TemplateExerciseEditorRow(item: $exercise)
              .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(
                  "Delete Exercise",
                  systemImage: "trash",
                  role: .destructive
                ) {
                  removeExercise(exercise)
                }
                .labelStyle(.iconOnly)
              }
          }
          .onDelete(perform: removeExercises)
          .onMove(perform: moveExercises)
        }

        Button(
          "Add Exercises",
          systemImage: "plus",
          action: selectExercises
        )
      } header: {
        SectionHeader("Exercises")
      } footer: {
        if draft.exercises.isEmpty {
          Text("Add exercises in the order you want to perform them.")
        } else if draft.hasUnavailableExercises {
          Text("Remove archived exercises before saving this template.")
            .foregroundStyle(.orange)
        }
      }
    }
    .sheet(isPresented: $isSelectingExercises) {
      TemplateExerciseSelectionView(selectedExercises: $draft.exercises)
    }
  }

  private func selectExercises() {
    isSelectingExercises = true
  }

  private func removeExercises(at offsets: IndexSet) {
    draft.exercises.remove(atOffsets: offsets)
  }

  private func removeExercise(_ exercise: TemplateExerciseDraft) {
    draft.exercises.removeAll { $0.id == exercise.id }
  }

  private func moveExercises(from offsets: IndexSet, to destination: Int) {
    draft.exercises.move(fromOffsets: offsets, toOffset: destination)
  }
}

private struct TemplateExerciseEditorRow: View {
  @Binding var item: TemplateExerciseDraft

  var body: some View {
    VStack(alignment: .leading, spacing: LayoutMetrics.Spacing.small) {
      HStack {
        Text(item.exercise.name)
        Spacer()
        if item.exercise.isArchived {
          Label("Archived", systemImage: "archivebox")
            .font(.caption)
            .foregroundStyle(.orange)
        }
      }

      Stepper(
        "Working Sets: \(item.plannedWorkingSetCount)",
        value: $item.plannedWorkingSetCount,
        in: 1...20
      )
      .font(.subheadline)
    }
  }
}

private struct TemplateExerciseSelectionView: View {
  @Environment(\.dismiss) private var dismiss

  @Query(
    filter: #Predicate<Exercise> { !$0.isArchived },
    sort: \Exercise.name
  )
  private var activeExercises: [Exercise]

  @Binding var selectedExercises: [TemplateExerciseDraft]
  @State private var pendingExerciseIDs: Set<UUID> = []

  private var existingExerciseIDs: Set<UUID> {
    Set(selectedExercises.map { $0.exercise.id })
  }

  var body: some View {
    NavigationStack {
      List(activeExercises) { exercise in
        TemplateExerciseSelectionRow(
          exercise: exercise,
          isAlreadyAdded: existingExerciseIDs.contains(exercise.id),
          pendingExerciseIDs: $pendingExerciseIDs
        )
      }
      .overlay {
        if activeExercises.isEmpty {
          ContentUnavailableView(
            "No Exercises",
            systemImage: "dumbbell",
            description: Text("Add exercises in Settings before building a template.")
          )
        }
      }
      .navigationTitle("Add Exercises")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel", action: dismiss.callAsFunction)
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Add", action: addSelectedExercises)
            .disabled(pendingExerciseIDs.isEmpty)
        }
      }
    }
  }

  private func addSelectedExercises() {
    for exercise in activeExercises where pendingExerciseIDs.contains(exercise.id) {
      selectedExercises.append(TemplateExerciseDraft(exercise: exercise))
    }
    dismiss()
  }
}

private struct TemplateExerciseSelectionRow: View {
  let exercise: Exercise
  let isAlreadyAdded: Bool
  @Binding var pendingExerciseIDs: Set<UUID>

  private var isSelected: Bool {
    pendingExerciseIDs.contains(exercise.id)
  }

  private var accessibilityValue: String {
    if isAlreadyAdded {
      "Already added"
    } else if isSelected {
      "Selected"
    } else {
      "Not selected"
    }
  }

  var body: some View {
    Button(action: toggleSelection) {
      HStack {
        VStack(alignment: .leading, spacing: LayoutMetrics.Spacing.extraSmall) {
          Text(exercise.name)
            .foregroundStyle(.primary)
          Text(exercise.trackingSummary)
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()

        if isAlreadyAdded {
          Image(systemName: "checkmark")
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
        } else if isSelected {
          Image(systemName: "checkmark")
            .fontWeight(.semibold)
            .foregroundStyle(.tint)
        }
      }
      .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .disabled(isAlreadyAdded)
    .accessibilityLabel(exercise.name)
    .accessibilityValue(accessibilityValue)
  }

  private func toggleSelection() {
    if isSelected {
      pendingExerciseIDs.remove(exercise.id)
    } else {
      pendingExerciseIDs.insert(exercise.id)
    }
  }
}

private struct WorkoutTemplateDraft {
  var name = ""
  var notes = ""
  var exercises: [TemplateExerciseDraft] = []

  init() {}

  init(template: WorkoutTemplate) {
    name = template.name
    notes = template.notes ?? ""
    exercises = template.orderedExercises.compactMap { templateExercise in
      guard let exercise = templateExercise.exercise else { return nil }
      return TemplateExerciseDraft(
        id: templateExercise.id,
        exercise: exercise,
        plannedWorkingSetCount: templateExercise.plannedWorkingSetCount ?? 3
      )
    }
  }

  var normalizedName: String {
    name.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var normalizedNotes: String? {
    let normalizedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
    return normalizedNotes.isEmpty ? nil : normalizedNotes
  }

  var hasUnavailableExercises: Bool {
    exercises.contains { $0.exercise.isArchived }
  }

  var isValid: Bool {
    !normalizedName.isEmpty
      && !exercises.isEmpty
      && !hasUnavailableExercises
  }

  var exercisePlans: [TemplateExercisePlan] {
    exercises.map { exercise in
      TemplateExercisePlan(
        exercise: exercise.exercise,
        plannedWorkingSetCount: exercise.plannedWorkingSetCount
      )
    }
  }

  var signature: WorkoutTemplateEditorSignature {
    WorkoutTemplateEditorSignature(
      name: normalizedName,
      notes: normalizedNotes,
      exercises: exercises.map { exercise in
        WorkoutTemplateExerciseSignature(
          exerciseID: exercise.exercise.id,
          plannedWorkingSetCount: exercise.plannedWorkingSetCount
        )
      }
    )
  }
}

private struct TemplateExerciseDraft: Identifiable {
  let id: UUID
  let exercise: Exercise
  var plannedWorkingSetCount: Int

  init(
    id: UUID = UUID(),
    exercise: Exercise,
    plannedWorkingSetCount: Int = 3
  ) {
    self.id = id
    self.exercise = exercise
    self.plannedWorkingSetCount = plannedWorkingSetCount
  }
}

private struct WorkoutTemplateEditorSignature: Equatable {
  let name: String
  let notes: String?
  let exercises: [WorkoutTemplateExerciseSignature]
}

private struct WorkoutTemplateExerciseSignature: Equatable {
  let exerciseID: UUID
  let plannedWorkingSetCount: Int
}

extension WorkoutTemplate {
  fileprivate var editorSignature: WorkoutTemplateEditorSignature {
    WorkoutTemplateEditorSignature(
      name: name,
      notes: notes,
      exercises: orderedExercises.compactMap { templateExercise in
        guard let exercise = templateExercise.exercise else { return nil }
        return WorkoutTemplateExerciseSignature(
          exerciseID: exercise.id,
          plannedWorkingSetCount: templateExercise.plannedWorkingSetCount ?? 3
        )
      }
    )
  }
}

extension Exercise {
  fileprivate var trackingSummary: String {
    let load =
      switch loadMode {
      case .externalResistance: "External Resistance"
      case .bodyweight: "Bodyweight"
      }
    let repetitions =
      switch repetitionMode {
      case .standard: "Standard Reps"
      case .perSide: "Per Side"
      }
    return "\(load) · \(repetitions)"
  }
}

#Preview("New Template") {
  AddWorkoutTemplateView()
    .modelContainer(for: TonnageSchema.models, inMemory: true)
}
