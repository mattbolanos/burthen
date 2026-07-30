//
//  WorkoutExercise.swift
//  Tonnage
//


import Foundation
import SwiftData

@Model
final class WorkoutExercise {
  var id: UUID = UUID()
  var position = 0
  var plannedWorkingSetCount: Int?
  var workout: Workout?
  var exercise: Exercise?

  @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.workoutExercise)
  var exerciseSets: [ExerciseSet] = []

  init(
    id: UUID = UUID(),
    position: Int,
    plannedWorkingSetCount: Int? = nil,
    workout: Workout? = nil,
    exercise: Exercise? = nil
  ) throws {
    guard position >= 0 else { throw WorkoutModelError.invalidPosition }
    if let plannedWorkingSetCount, plannedWorkingSetCount <= 0 {
      throw WorkoutModelError.invalidPlannedSetCount
    }

    self.id = id
    self.position = position
    self.plannedWorkingSetCount = plannedWorkingSetCount
    self.workout = workout
    self.exercise = exercise
  }

  var orderedSets: [ExerciseSet] {
    exerciseSets.sorted { lhs, rhs in
      if lhs.position == rhs.position {
        lhs.id.uuidString < rhs.id.uuidString
      } else {
        lhs.position < rhs.position
      }
    }
  }

  func addSet(
    kind: ExerciseSetKind = .working,
    reps: Int,
    weight: Decimal? = nil,
    weightUnit: WeightUnit? = nil,
    completedAt: Date? = .now
  ) throws -> ExerciseSet {
    guard let exercise else { throw WorkoutModelError.missingExercise }

    let exerciseSet = ExerciseSet(
      position: nextSetPosition,
      kind: kind,
      reps: reps,
      weight: weight,
      weightUnit: weightUnit,
      completedAt: completedAt,
      workoutExercise: nil
    )
    try exerciseSet.validate(for: exercise)
    exerciseSet.workoutExercise = self
    if !exerciseSets.contains(where: { $0 === exerciseSet }) {
      exerciseSets.append(exerciseSet)
    }

    return exerciseSet
  }

  func volumeLoad(in unit: WeightUnit) -> VolumeLoad? {
    let values = exerciseSets.compactMap { $0.volumeLoad?.converted(to: unit).value }
    guard !values.isEmpty else { return nil }

    return VolumeLoad(value: values.reduce(Decimal.zero, +), unit: unit)
  }

  func validate() throws {
    guard position >= 0 else { throw WorkoutModelError.invalidPosition }
    if let plannedWorkingSetCount, plannedWorkingSetCount <= 0 {
      throw WorkoutModelError.invalidPlannedSetCount
    }
    guard exercise != nil else { throw WorkoutModelError.missingExercise }

    for exerciseSet in exerciseSets {
      try exerciseSet.validate()
    }
  }

  private var nextSetPosition: Int {
    (exerciseSets.map(\.position).max() ?? -1) + 1
  }
}
