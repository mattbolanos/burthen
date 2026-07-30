//
//  TemplateExercise.swift
//  Tonnage
//


import Foundation
import SwiftData

@Model
final class TemplateExercise {
  var id: UUID = UUID()
  var position = 0
  var plannedWorkingSetCount: Int?
  var template: WorkoutTemplate?
  var exercise: Exercise?

  init(
    id: UUID = UUID(),
    position: Int,
    plannedWorkingSetCount: Int? = nil,
    template: WorkoutTemplate? = nil,
    exercise: Exercise? = nil
  ) throws {
    guard position >= 0 else { throw WorkoutModelError.invalidPosition }
    if let plannedWorkingSetCount, plannedWorkingSetCount <= 0 {
      throw WorkoutModelError.invalidPlannedSetCount
    }

    self.id = id
    self.position = position
    self.plannedWorkingSetCount = plannedWorkingSetCount
    self.template = template
    self.exercise = exercise
  }
}
