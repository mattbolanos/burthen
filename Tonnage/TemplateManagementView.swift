//
//  TemplateManagementView.swift
//  Tonnage
//

import SwiftData
import SwiftUI

struct TemplateManagementView: View {
  @Environment(\.modelContext) private var modelContext

  @Query(
    filter: #Predicate<WorkoutTemplate> { !$0.isArchived },
    sort: \WorkoutTemplate.name
  )
  private var activeTemplates: [WorkoutTemplate]

  @Query(
    filter: #Predicate<WorkoutTemplate> { $0.isArchived },
    sort: \WorkoutTemplate.name
  )
  private var archivedTemplates: [WorkoutTemplate]

  @State private var isAddingTemplate = false
  @State private var isConfirmingDeletion = false
  @State private var pendingDeletion: WorkoutTemplate?
  @State private var isShowingError = false
  @State private var errorMessage = ""

  private var hasTemplates: Bool {
    !activeTemplates.isEmpty || !archivedTemplates.isEmpty
  }

  var body: some View {
    List {
      if !activeTemplates.isEmpty {
        Section("Active") {
          ForEach(activeTemplates) { template in
            TemplateNavigationRow(template: template)
              .deleteDisabled(!template.canBePermanentlyDeleted)
              .swipeActions(edge: .leading) {
                Button("Archive", systemImage: "archivebox") {
                  archive(template)
                }
                .tint(.orange)
              }
              .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                if template.canBePermanentlyDeleted {
                  Button(
                    "Delete Template",
                    systemImage: "trash",
                    role: .destructive
                  ) {
                    requestDeletion(of: template)
                  }
                  .labelStyle(.iconOnly)
                }
              }
          }
          .onDelete(perform: removeActiveTemplates)
        }
      }

      if !archivedTemplates.isEmpty {
        Section("Archived") {
          ForEach(archivedTemplates) { template in
            TemplateNavigationRow(template: template)
              .deleteDisabled(!template.canBePermanentlyDeleted)
              .swipeActions(edge: .leading) {
                Button("Restore", systemImage: "arrow.uturn.backward") {
                  restore(template)
                }
              }
              .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                if template.canBePermanentlyDeleted {
                  Button(
                    "Delete Template",
                    systemImage: "trash",
                    role: .destructive
                  ) {
                    requestDeletion(of: template)
                  }
                  .labelStyle(.iconOnly)
                }
              }
          }
          .onDelete(perform: removeArchivedTemplates)
        }
      }
    }
    .overlay {
      if !hasTemplates {
        ContentUnavailableView {
          Label("No Templates", systemImage: "rectangle.stack")
        } description: {
          Text("Build a reusable workout from your exercises.")
        } actions: {
          Button("Add Template", systemImage: "plus", action: addTemplate)
            .buttonStyle(.glassProminent)
        }
      }
    }
    .navigationTitle("Workout Templates")
    .toolbar {
      ToolbarItemGroup(placement: .topBarTrailing) {
        EditButton()
        Button("Add Template", systemImage: "plus", action: addTemplate)
      }
    }
    .sheet(isPresented: $isAddingTemplate) {
      AddWorkoutTemplateView()
    }
    .alert(
      "Delete Template?",
      isPresented: $isConfirmingDeletion,
      presenting: pendingDeletion
    ) { template in
      Button("Delete", role: .destructive) {
        delete(template)
      }
      Button("Cancel", role: .cancel, action: cancelDeletion)
    } message: { template in
      Text("This permanently deletes \(template.name). Past workouts aren’t affected.")
    }
    .alert("Template Couldn’t Be Updated", isPresented: $isShowingError) {
      Button("OK", role: .cancel) { }
    } message: {
      Text(errorMessage)
    }
  }

  private func addTemplate() {
    isAddingTemplate = true
  }

  private func removeActiveTemplates(at offsets: IndexSet) {
    guard let template = offsets.lazy
      .map({ activeTemplates[$0] })
      .first(where: \.canBePermanentlyDeleted)
    else { return }

    requestDeletion(of: template)
  }

  private func removeArchivedTemplates(at offsets: IndexSet) {
    guard let template = offsets.lazy
      .map({ archivedTemplates[$0] })
      .first(where: \.canBePermanentlyDeleted)
    else { return }

    requestDeletion(of: template)
  }

  private func requestDeletion(of template: WorkoutTemplate) {
    pendingDeletion = template
    isConfirmingDeletion = true
  }

  private func archive(_ template: WorkoutTemplate) {
    performUpdate {
      TrainingDataStore(modelContext: modelContext).archive(template)
    }
  }

  private func restore(_ template: WorkoutTemplate) {
    performUpdate {
      try TrainingDataStore(modelContext: modelContext).restore(template)
    }
  }

  private func delete(_ template: WorkoutTemplate) {
    performUpdate {
      TrainingDataStore(modelContext: modelContext).remove(template)
    }
    pendingDeletion = nil
  }

  private func cancelDeletion() {
    pendingDeletion = nil
  }

  private func performUpdate(_ update: () throws -> Void) {
    do {
      try update()
      try modelContext.save()
    } catch {
      errorMessage = templateErrorMessage(for: error)
      isShowingError = true
    }
  }
}

private struct TemplateNavigationRow: View {
  let template: WorkoutTemplate

  var body: some View {
    NavigationLink {
      EditWorkoutTemplateView(template: template)
    } label: {
      TemplateRowView(template: template)
    }
  }
}

struct TemplateRowView: View {
  let template: WorkoutTemplate

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(template.name)

      Text(template.summary)
        .font(.caption)
        .foregroundStyle(template.hasUnavailableExercises ? .orange : .secondary)

      if let notes = template.notes {
        Text(notes)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
    }
    .accessibilityElement(children: .combine)
  }
}

extension WorkoutTemplate {
  fileprivate var summary: String {
    let count = orderedExercises.count
    let exerciseSummary = "\(count) \(count == 1 ? "exercise" : "exercises")"
    return hasUnavailableExercises
      ? "\(exerciseSummary) · Needs attention"
      : exerciseSummary
  }
}

func templateErrorMessage(for error: Error) -> String {
  guard let modelError = error as? WorkoutModelError else {
    return error.localizedDescription
  }

  return switch modelError {
  case .activeWorkoutExists:
    "Finish or discard the active workout before starting another one."
  case .duplicateExerciseInTemplate:
    "Each exercise can appear only once in a template."
  case .duplicateTemplateName:
    "An active template already uses this name."
  case .emptyName:
    "Enter a name for the template."
  case .exerciseIsArchived, .missingExercise:
    "Remove unavailable exercises before saving or starting this template."
  case .invalidPlannedSetCount:
    "Working sets must be greater than zero."
  default:
    "The template couldn’t be updated."
  }
}

#Preview {
  NavigationStack {
    TemplateManagementView()
  }
  .modelContainer(for: TonnageSchema.models, inMemory: true)
}
