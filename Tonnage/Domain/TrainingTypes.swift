//
//  TrainingTypes.swift
//  Tonnage
//


import Foundation

enum WorkoutStatus: String, Codable, CaseIterable {
  case inProgress
  case completed
}

enum ExerciseLoadMode: String, Codable, CaseIterable {
  case externalResistance
  case bodyweight
}

enum ExerciseRepetitionMode: String, Codable, CaseIterable {
  case standard
  case perSide
}

enum ExerciseOrigin: String, Codable, CaseIterable {
  case seeded
  case custom
}

enum ExerciseSetKind: String, Codable, CaseIterable {
  case working
  case warmup
}

enum WeightUnit: String, Codable, CaseIterable {
  case pounds = "lb"
  case kilograms = "kg"

  func convert(_ value: Decimal, to targetUnit: WeightUnit) -> Decimal {
    guard self != targetUnit else { return value }

    let poundsToKilograms = Decimal(45_359_237) / Decimal(100_000_000)

    return switch (self, targetUnit) {
    case (.pounds, .kilograms):
      value * poundsToKilograms
    case (.kilograms, .pounds):
      value / poundsToKilograms
    default:
      value
    }
  }
}

struct VolumeLoad: Equatable {
  let value: Decimal
  let unit: WeightUnit

  func converted(to targetUnit: WeightUnit) -> VolumeLoad {
    VolumeLoad(value: unit.convert(value, to: targetUnit), unit: targetUnit)
  }
}

enum WorkoutModelError: Error, Equatable {
  case activeWorkoutExists
  case cannotRemoveLastSet
  case duplicateExerciseName
  case duplicateExerciseInTemplate
  case duplicateTemplateName
  case emptyName
  case endBeforeStart
  case exerciseHasAssociatedData
  case exerciseClassificationInUse
  case exerciseIsArchived
  case invalidPlannedSetCount
  case invalidPosition
  case invalidReps
  case invalidWeight
  case invalidWeightPrecision
  case missingExercise
  case missingWeight
  case missingWeightUnit
  case seededExerciseIsReadOnly
  case templateIsArchived
  case unexpectedWeightUnit
  case workoutAlreadyCompleted
  case workoutHasNoSets
  case workoutIsNotInProgress
}

struct TemplateExercisePlan {
  let exercise: Exercise
  let plannedWorkingSetCount: Int?
}

extension Decimal {
  var hasAtMostOneFractionalDigit: Bool {
    var source = self
    var rounded = Decimal()
    NSDecimalRound(&rounded, &source, 1, .plain)
    return rounded == self
  }
}
