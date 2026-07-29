//
//  ContentView.swift
//  Tonnage
//
//  Created by Matt Bolaños on 7/25/26.
//

import SwiftUI

struct ContentView: View {
  var body: some View {
    NavigationStack {
      ContentUnavailableView {
        Label("No Workouts Yet", systemImage: "dumbbell")
      } description: {
        Text("Add a workout to get started.")
      }
      .navigationTitle("Workouts")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Menu("Add Workout", systemImage: "plus") {
            NavigationLink(value: NewWorkoutRoute.blank) {
              Label("Blank Workout", systemImage: "doc")
            }
            NavigationLink(value: NewWorkoutRoute.templates) {
              Label("Choose a Template", systemImage: "rectangle.stack")
            }
          }
        }
      }
      .navigationDestination(for: NewWorkoutRoute.self) { route in
        switch route {
        case .blank:
          BlankWorkoutView()
        case .templates:
          WorkoutTemplatePickerView()
        }
      }
    }
  }
}

#Preview {
  ContentView()
}
