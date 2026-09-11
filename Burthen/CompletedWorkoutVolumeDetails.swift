//
//  CompletedWorkoutVolumeDetails.swift
//  Burthen
//

import SwiftUI

struct CompletedWorkoutVolumeDetails: View {
  let workout: Workout

  var body: some View {
    DisclosureGroup {
      ForEach(workout.orderedExercises) { workoutExercise in
        if let volume = workoutExercise.volumeLoad(in: workout.volumeLoadUnit) {
          LabeledContent(
            workoutExercise.exercise?.name ?? "Unavailable Exercise"
          ) {
            Text(volume.displayText)
              .monospacedDigit()
              .foregroundStyle(.pink)
              .accessibilityLabel(volume.accessibilityText)
          }
          .listRowSeparator(.hidden)
        }
      }
    } label: {
      LabeledContent("Load") {
        Text(workout.volumeLoad?.displayText ?? "Not recorded")
          .monospacedDigit()
          .foregroundStyle(.pink)
          .accessibilityLabel(workout.volumeLoad?.accessibilityText ?? "Not recorded")
      }
    }
    .listRowSeparator(.hidden)
    .accessibilityIdentifier("summary-volume-details")
  }
}
