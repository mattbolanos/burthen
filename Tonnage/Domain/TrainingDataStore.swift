//
//  TrainingDataStore.swift
//  Tonnage
//


import Foundation
import SwiftData

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

  func createTemplate(name: String, notes: String? = nil) throws -> WorkoutTemplate {
    let normalizedName = try validatedName(name)
    let templates = try modelContext.fetch(FetchDescriptor<WorkoutTemplate>())
    guard !templates.contains(where: { !$0.isArchived && namesMatch($0.name, normalizedName) }) else {
      throw WorkoutModelError.duplicateTemplateName
    }

    let template = try WorkoutTemplate(name: normalizedName, notes: notes)
    modelContext.insert(template)
    return template
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
      try exercise.archive()
    }
  }

  private func ensureNoActiveWorkout() throws {
    let workouts = try modelContext.fetch(FetchDescriptor<Workout>())
    guard !workouts.contains(where: { $0.status == .inProgress }) else {
      throw WorkoutModelError.activeWorkoutExists
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
