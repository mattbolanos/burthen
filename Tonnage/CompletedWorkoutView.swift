//
//  CompletedWorkoutView.swift
//  Tonnage
//

import SwiftUI

struct CompletedWorkoutView: View {
  let workout: Workout

  var body: some View {
    let orderedExercises = workout.orderedExercises

    List {
      CompletedWorkoutHeader(workout: workout)

      if orderedExercises.isEmpty {
        ContentUnavailableView(
          "No Exercises",
          systemImage: "dumbbell",
          description: Text("No exercises were recorded for this workout.")
        )
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
      } else {
        ForEach(orderedExercises) { workoutExercise in
          CompletedWorkoutExerciseCard(workoutExercise: workoutExercise)
            .listRowInsets(LayoutMetrics.Insets.cardRow)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .background(Color(uiColor: .systemGroupedBackground))
    .navigationTitle("Workout Summary")
    .navigationBarTitleDisplayMode(.large)
  }
}
