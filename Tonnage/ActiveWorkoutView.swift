//
//  ActiveWorkoutView.swift
//  Tonnage
//

import SwiftUI

struct ActiveWorkoutView: View {
  let workout: Workout

  var body: some View {
    NavigationStack {
      ContentUnavailableView {
        Label(workout.name ?? "Active Workout", systemImage: "dumbbell.fill")
      } description: {
        Text("The workout editor will live here.")
      }
      .navigationTitle(workout.name ?? "Active Workout")
    }
  }
}

#Preview {
  ActiveWorkoutView(workout: try! Workout(name: "Push Day"))
}
