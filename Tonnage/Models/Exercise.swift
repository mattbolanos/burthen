//
//  Exercise.swift
//  Tonnage
//


import Foundation
import SwiftData

@Model
final class Exercise {
  var id: UUID = UUID()
  var name: String = ""
  var loadMode: ExerciseLoadMode = ExerciseLoadMode.externalResistance
  var repetitionMode: ExerciseRepetitionMode = ExerciseRepetitionMode.standard
  var origin: ExerciseOrigin = ExerciseOrigin.custom
  var isArchived = false
  var createdAt: Date = Date.now
  var updatedAt: Date = Date.now

  @Relationship(deleteRule: .deny, inverse: \WorkoutExercise.exercise)
  var workoutExercises: [WorkoutExercise] = []

  @Relationship(deleteRule: .deny, inverse: \TemplateExercise.exercise)
  var templateExercises: [TemplateExercise] = []

  init(
    id: UUID = UUID(),
    name: String,
    loadMode: ExerciseLoadMode,
    repetitionMode: ExerciseRepetitionMode = .standard,
    origin: ExerciseOrigin = .custom,
    isArchived: Bool = false,
    createdAt: Date = .now,
    updatedAt: Date = .now
  ) throws {
    let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !normalizedName.isEmpty else { throw WorkoutModelError.emptyName }

    self.id = id
    self.name = normalizedName
    self.loadMode = loadMode
    self.repetitionMode = repetitionMode
    self.origin = origin
    self.isArchived = isArchived
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  var hasHistoricalSets: Bool {
    workoutExercises.contains { !$0.exerciseSets.isEmpty }
  }

  func rename(to newName: String, at date: Date = .now) throws {
    guard origin == .custom else { throw WorkoutModelError.seededExerciseIsReadOnly }

    let normalizedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !normalizedName.isEmpty else { throw WorkoutModelError.emptyName }

    name = normalizedName
    updatedAt = date
  }

  func updateClassification(
    loadMode: ExerciseLoadMode,
    repetitionMode: ExerciseRepetitionMode,
    at date: Date = .now
  ) throws {
    guard origin == .custom else { throw WorkoutModelError.seededExerciseIsReadOnly }
    guard !hasHistoricalSets else { throw WorkoutModelError.exerciseClassificationInUse }

    self.loadMode = loadMode
    self.repetitionMode = repetitionMode
    updatedAt = date
  }

  func archive(at date: Date = .now) throws {
    guard origin == .custom else { throw WorkoutModelError.seededExerciseIsReadOnly }
    isArchived = true
    updatedAt = date
  }

  func restore(at date: Date = .now) {
    isArchived = false
    updatedAt = date
  }
}
