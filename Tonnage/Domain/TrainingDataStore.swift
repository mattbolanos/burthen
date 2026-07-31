//
//  TrainingDataStore.swift
//  Tonnage
//


import Foundation
import SwiftData

struct ExerciseDeletionImpact: Equatable {
  let workoutEntryCount: Int
  let setCount: Int
  let templateEntryCount: Int

  var hasAssociatedData: Bool {
    workoutEntryCount > 0 || setCount > 0 || templateEntryCount > 0
  }
}

@MainActor
struct TrainingDataStore {
  let modelContext: ModelContext

  func startWorkout(
    name: String? = nil,
    notes: String? = nil,
    startedAt: Date = .now,
    timeZoneIdentifier: String = TimeZone.current.identifier
  ) throws -> Workout {
    try ensureNoActiveWorkout()

    let workout = try Workout(
      name: name,
      notes: notes,
      startedAt: startedAt,
      timeZoneIdentifier: timeZoneIdentifier
    )
    modelContext.insert(workout)
    return workout
  }

  func startWorkout(
    from template: WorkoutTemplate,
    startedAt: Date = .now,
    timeZoneIdentifier: String = TimeZone.current.identifier
  ) throws -> Workout {
    try ensureNoActiveWorkout()

    let workout = try template.makeWorkout(
      startedAt: startedAt,
      timeZoneIdentifier: timeZoneIdentifier,
      createdAt: startedAt
    )
    modelContext.insert(workout)
    return workout
  }

  func createExercise(
    name: String,
    loadMode: ExerciseLoadMode,
    repetitionMode: ExerciseRepetitionMode = .standard,
    origin: ExerciseOrigin = .custom
  ) throws -> Exercise {
    let normalizedName = try validatedName(name)
    let exercises = try modelContext.fetch(FetchDescriptor<Exercise>())
    guard !exercises.contains(where: { !$0.isArchived && namesMatch($0.name, normalizedName) }) else {
      throw WorkoutModelError.duplicateExerciseName
    }

    let exercise = try Exercise(
      name: normalizedName,
      loadMode: loadMode,
      repetitionMode: repetitionMode,
      origin: origin
    )
    modelContext.insert(exercise)
    return exercise
  }

  func updateExercise(
    _ exercise: Exercise,
    name: String,
    loadMode: ExerciseLoadMode,
    repetitionMode: ExerciseRepetitionMode,
    at date: Date = .now
  ) throws {
    guard exercise.origin == .custom else {
      throw WorkoutModelError.seededExerciseIsReadOnly
    }

    let normalizedName = try validatedName(name)
    let exercises = try modelContext.fetch(FetchDescriptor<Exercise>())
    guard !exercises.contains(where: {
      $0 !== exercise
        && !$0.isArchived
        && !exercise.isArchived
        && namesMatch($0.name, normalizedName)
    }) else {
      throw WorkoutModelError.duplicateExerciseName
    }

    let classificationChanged = exercise.loadMode != loadMode
      || exercise.repetitionMode != repetitionMode
    guard !classificationChanged || !exercise.hasHistoricalSets else {
      throw WorkoutModelError.exerciseClassificationInUse
    }

    if exercise.name != normalizedName {
      try exercise.rename(to: normalizedName, at: date)
    }
    if classificationChanged {
      try exercise.updateClassification(
        loadMode: loadMode,
        repetitionMode: repetitionMode,
        at: date
      )
    }
  }

  func createTemplate(
    name: String,
    notes: String? = nil,
    exercises: [TemplateExercisePlan] = []
  ) throws -> WorkoutTemplate {
    let normalizedName = try validatedName(name)
    let templates = try modelContext.fetch(FetchDescriptor<WorkoutTemplate>())
    guard !templates.contains(where: { !$0.isArchived && namesMatch($0.name, normalizedName) }) else {
      throw WorkoutModelError.duplicateTemplateName
    }
    try validate(exercises)

    let template = try WorkoutTemplate(name: normalizedName, notes: notes)
    modelContext.insert(template)
    try append(exercises, to: template)
    return template
  }

  func updateTemplate(
    _ template: WorkoutTemplate,
    name: String,
    notes: String?,
    exercises: [TemplateExercisePlan],
    at date: Date = .now
  ) throws {
    let normalizedName = try validatedName(name)
    let templates = try modelContext.fetch(FetchDescriptor<WorkoutTemplate>())
    guard !templates.contains(where: {
      $0 !== template
        && !$0.isArchived
        && !template.isArchived
        && namesMatch($0.name, normalizedName)
    }) else {
      throw WorkoutModelError.duplicateTemplateName
    }
    try validate(exercises)

    try template.updateDetails(name: normalizedName, notes: notes, at: date)

    let previousExercises = template.templateExercises
    template.templateExercises.removeAll()
    for templateExercise in previousExercises {
      modelContext.delete(templateExercise)
    }
    try append(exercises, to: template, at: date)
  }

  func archive(_ template: WorkoutTemplate) {
    template.archive()
  }

  func restore(_ template: WorkoutTemplate) throws {
    let templates = try modelContext.fetch(FetchDescriptor<WorkoutTemplate>())
    guard !templates.contains(where: {
      $0 !== template && !$0.isArchived && namesMatch($0.name, template.name)
    }) else {
      throw WorkoutModelError.duplicateTemplateName
    }

    template.restore()
  }

  func discard(_ workout: Workout) throws {
    guard workout.status == .inProgress else {
      throw WorkoutModelError.workoutIsNotInProgress
    }
    modelContext.delete(workout)
  }

  func remove(_ template: WorkoutTemplate) {
    if template.canBePermanentlyDeleted {
      modelContext.delete(template)
    } else {
      template.archive()
    }
  }

  func remove(_ exercise: Exercise) throws {
    guard exercise.origin == .custom else {
      throw WorkoutModelError.seededExerciseIsReadOnly
    }

    if exercise.workoutExercises.isEmpty && exercise.templateExercises.isEmpty {
      modelContext.delete(exercise)
    } else {
      try archive(exercise)
    }
  }

  func archive(_ exercise: Exercise) throws {
    guard exercise.origin == .custom else {
      throw WorkoutModelError.seededExerciseIsReadOnly
    }

    try exercise.archive()
  }

  func restore(_ exercise: Exercise) throws {
    guard exercise.origin == .custom else {
      throw WorkoutModelError.seededExerciseIsReadOnly
    }

    let exercises = try modelContext.fetch(FetchDescriptor<Exercise>())
    guard !exercises.contains(where: {
      $0 !== exercise && !$0.isArchived && namesMatch($0.name, exercise.name)
    }) else {
      throw WorkoutModelError.duplicateExerciseName
    }

    exercise.restore()
  }

  func deletionImpact(for exercise: Exercise) -> ExerciseDeletionImpact {
    ExerciseDeletionImpact(
      workoutEntryCount: exercise.workoutExercises.count,
      setCount: exercise.workoutExercises.reduce(0) { count, workoutExercise in
        count + workoutExercise.exerciseSets.count
      },
      templateEntryCount: exercise.templateExercises.count
    )
  }

  func delete(
    _ exercise: Exercise,
    includingAssociatedData: Bool = false
  ) throws {
    guard exercise.origin == .custom else {
      throw WorkoutModelError.seededExerciseIsReadOnly
    }

    let impact = deletionImpact(for: exercise)
    guard includingAssociatedData || !impact.hasAssociatedData else {
      throw WorkoutModelError.exerciseHasAssociatedData
    }

    let workoutEntries = exercise.workoutExercises
    let templateEntries = exercise.templateExercises

    exercise.workoutExercises.removeAll()
    exercise.templateExercises.removeAll()

    for workoutEntry in workoutEntries {
      modelContext.delete(workoutEntry)
    }
    for templateEntry in templateEntries {
      modelContext.delete(templateEntry)
    }

    modelContext.delete(exercise)
  }

  private func ensureNoActiveWorkout() throws {
    let workouts = try modelContext.fetch(FetchDescriptor<Workout>())
    guard !workouts.contains(where: { $0.status == .inProgress }) else {
      throw WorkoutModelError.activeWorkoutExists
    }
  }

  private func validate(_ exercises: [TemplateExercisePlan]) throws {
    var exerciseIDs = Set<UUID>()

    for plan in exercises {
      guard !plan.exercise.isArchived else {
        throw WorkoutModelError.exerciseIsArchived
      }
      if let plannedWorkingSetCount = plan.plannedWorkingSetCount,
         plannedWorkingSetCount <= 0 {
        throw WorkoutModelError.invalidPlannedSetCount
      }
      guard exerciseIDs.insert(plan.exercise.id).inserted else {
        throw WorkoutModelError.duplicateExerciseInTemplate
      }
    }
  }

  private func append(
    _ exercises: [TemplateExercisePlan],
    to template: WorkoutTemplate,
    at date: Date = .now
  ) throws {
    for plan in exercises {
      let templateExercise = try template.addExercise(
        plan.exercise,
        plannedWorkingSetCount: plan.plannedWorkingSetCount,
        at: date
      )
      modelContext.insert(templateExercise)
    }
  }

  private func validatedName(_ name: String) throws -> String {
    let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !normalizedName.isEmpty else { throw WorkoutModelError.emptyName }
    return normalizedName
  }

  private func namesMatch(_ lhs: String, _ rhs: String) -> Bool {
    lhs.compare(
      rhs,
      options: [.caseInsensitive, .diacriticInsensitive],
      range: nil,
      locale: .current
    ) == .orderedSame
  }
}
