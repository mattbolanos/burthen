//
//  WorkoutTemplate.swift
//  Burthen
//


import Foundation
import SwiftData

@Model
final class WorkoutTemplate {
  var id: UUID = UUID()
  var name: String = ""
  var notes: String?
  var isArchived = false
  var createdAt: Date = Date.now
  var updatedAt: Date = Date.now

  @Relationship(deleteRule: .cascade, inverse: \TemplateExercise.template)
  var templateExercises: [TemplateExercise] = []

  @Relationship(deleteRule: .nullify, inverse: \Workout.sourceTemplate)
  var sourceWorkouts: [Workout] = []

  init(
    id: UUID = UUID(),
    name: String,
    notes: String? = nil,
    isArchived: Bool = false,
    createdAt: Date = .now,
    updatedAt: Date = .now
  ) throws {
    let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !normalizedName.isEmpty else { throw WorkoutModelError.emptyName }

    self.id = id
    self.name = normalizedName
    self.notes = notes?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    self.isArchived = isArchived
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  var orderedExercises: [TemplateExercise] {
    templateExercises.sorted { lhs, rhs in
      if lhs.position == rhs.position {
        lhs.id.uuidString < rhs.id.uuidString
      } else {
        lhs.position < rhs.position
      }
    }
  }

  var canBePermanentlyDeleted: Bool {
    sourceWorkouts.isEmpty
  }

  var hasUnavailableExercises: Bool {
    orderedExercises.contains { templateExercise in
      guard let exercise = templateExercise.exercise else { return true }
      return exercise.isArchived
    }
  }

  var isReadyToStart: Bool {
    !isArchived && !orderedExercises.isEmpty && !hasUnavailableExercises
  }

  @discardableResult
  func addExercise(
    _ exercise: Exercise,
    plannedWorkingSetCount: Int? = nil,
    at date: Date = .now
  ) throws -> TemplateExercise {
    guard !exercise.isArchived else { throw WorkoutModelError.exerciseIsArchived }

    let templateExercise = try TemplateExercise(
      position: nextExercisePosition,
      plannedWorkingSetCount: plannedWorkingSetCount,
      template: self,
      exercise: exercise
    )
    templateExercises.append(templateExercise)
    updatedAt = date
    return templateExercise
  }

  func makeWorkout(
    startedAt: Date = .now,
    timeZoneIdentifier: String = TimeZone.current.identifier,
    createdAt: Date = .now
  ) throws -> Workout {
    guard !isArchived else { throw WorkoutModelError.templateIsArchived }

    let workout = try Workout(
      name: name,
      startedAt: startedAt,
      timeZoneIdentifier: timeZoneIdentifier,
      createdAt: createdAt,
      updatedAt: createdAt,
      sourceTemplate: self
    )

    for templateExercise in orderedExercises {
      guard let exercise = templateExercise.exercise else {
        throw WorkoutModelError.missingExercise
      }
      guard !exercise.isArchived else {
        throw WorkoutModelError.exerciseIsArchived
      }

      try workout.addExercise(
        exercise,
        plannedWorkingSetCount: templateExercise.plannedWorkingSetCount,
        at: createdAt
      )
    }

    return workout
  }

  func rename(to newName: String, at date: Date = .now) throws {
    let normalizedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !normalizedName.isEmpty else { throw WorkoutModelError.emptyName }

    name = normalizedName
    updatedAt = date
  }

  func updateDetails(
    name newName: String,
    notes newNotes: String?,
    at date: Date = .now
  ) throws {
    let normalizedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !normalizedName.isEmpty else { throw WorkoutModelError.emptyName }

    name = normalizedName
    notes = newNotes?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    updatedAt = date
  }

  func archive(at date: Date = .now) {
    isArchived = true
    updatedAt = date
  }

  func restore(at date: Date = .now) {
    isArchived = false
    updatedAt = date
  }

  private var nextExercisePosition: Int {
    (templateExercises.map(\.position).max() ?? -1) + 1
  }
}

private extension String {
  var nilIfEmpty: String? {
    isEmpty ? nil : self
  }
}
