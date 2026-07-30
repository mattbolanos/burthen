//
//  TonnageSchema.swift
//  Tonnage
//


import SwiftData

enum TonnageSchema {
  static let models: [any PersistentModel.Type] = [
    Exercise.self,
    ExerciseSet.self,
    TemplateExercise.self,
    Workout.self,
    WorkoutExercise.self,
    WorkoutTemplate.self,
  ]

  static let schema = Schema(models)
}
