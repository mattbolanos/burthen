//
//  CompletedWorkoutView.swift
//  Burthen
//

import SwiftUI

struct CompletedWorkoutView: View {
  let workout: Workout

  var body: some View {
    let orderedExercises = workout.orderedExercises.filter { workoutExercise in
      workoutExercise.exerciseSets.contains { $0.isCompleted }
    }

    List {
      CompletedWorkoutHeader(workout: workout)

      if orderedExercises.isEmpty {
        ContentUnavailableView {
          ContentUnavailableLogoLabel(title: "No Exercises")
        } description: {
          Text("No exercises were recorded for this workout.")
        }
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
