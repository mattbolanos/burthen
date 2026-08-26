//
//  WorkoutActivityManager.swift
//  Burthen
//

import ActivityKit
import Foundation
import OSLog

struct WorkoutActivityDescriptor: Equatable, Sendable {
  let id: UUID
  let name: String
  let startedAt: Date
}

@MainActor
enum WorkoutActivityManager {
  private static let logger = Logger(
    subsystem: "com.mattbolanos.Burthen",
    category: "WorkoutActivity"
  )

  private static var desiredWorkoutID: UUID?

  static func synchronize(with workout: WorkoutActivityDescriptor?) async {
    desiredWorkoutID = workout?.id

    var matchingActivity: Activity<WorkoutActivityAttributes>?
    for activity in Activity<WorkoutActivityAttributes>.activities {
      if
        let workout,
        activity.attributes.workoutID == workout.id,
        matchingActivity == nil
      {
        matchingActivity = activity
      } else {
        await end(activity)
      }
    }

    if
      let workout,
      desiredWorkoutID == workout.id,
      let matchingActivity
    {
      let refreshedContent = ActivityContent(
        state: WorkoutActivityAttributes.ContentState(isRunning: true),
        staleDate: matchingActivity.attributes.elapsedTimeRange.upperBound
      )
      await matchingActivity.update(refreshedContent)
      return
    }

    guard
      let workout,
      desiredWorkoutID == workout.id,
      ActivityAuthorizationInfo().areActivitiesEnabled
    else { return }

    let attributes = WorkoutActivityAttributes(
      workoutID: workout.id,
      workoutName: workout.name,
      startedAt: workout.startedAt
    )
    let content = ActivityContent(
      state: WorkoutActivityAttributes.ContentState(isRunning: true),
      staleDate: attributes.elapsedTimeRange.upperBound
    )

    do {
      _ = try Activity.request(
        attributes: attributes,
        content: content,
        pushType: nil,
        style: .standard
      )
    } catch {
      logger.error(
        "Unable to start workout Live Activity: \(error.localizedDescription, privacy: .public)"
      )
    }
  }

  private static func end(
    _ activity: Activity<WorkoutActivityAttributes>
  ) async {
    let finalContent = ActivityContent(
      state: WorkoutActivityAttributes.ContentState(isRunning: false),
      staleDate: nil
    )
    await activity.end(finalContent, dismissalPolicy: .immediate)
  }
}
