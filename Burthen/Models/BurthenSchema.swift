//
//  BurthenSchema.swift
//  Burthen
//


import SwiftData

enum BurthenSchema {
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
