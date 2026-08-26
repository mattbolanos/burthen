//
//  WorkoutActivityAttributes.swift
//  Burthen
//

import ActivityKit
import Foundation

struct WorkoutActivityAttributes: ActivityAttributes, Hashable, Sendable {
  private static let maximumActiveDuration: TimeInterval = 8 * 60 * 60

  struct ContentState: Codable, Hashable, Sendable {
    let isRunning: Bool
  }

  let workoutID: UUID
  let workoutName: String
  let startedAt: Date

  var elapsedTimeRange: ClosedRange<Date> {
    startedAt...startedAt.addingTimeInterval(Self.maximumActiveDuration)
  }
}
