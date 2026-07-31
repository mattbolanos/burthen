//
//  ContentView.swift
//  Tonnage
//
//  Created by Matt Bolaños on 7/25/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
  @Query(sort: \Workout.startedAt, order: .reverse)
  private var workouts: [Workout]

  @State private var selection = AppTab.home

  private var activeWorkout: Workout? {
    workouts.first { $0.status == .inProgress }
  }

  var body: some View {
    TabView(selection: $selection) {
      if let activeWorkout {
        Tab("Workout", systemImage: "dumbbell.fill", value: AppTab.activeWorkout) {
          ActiveWorkoutView(workout: activeWorkout)
        }
      }

      Tab("Home", systemImage: "house", value: AppTab.home) {
        HomeView()
      }

      Tab("Settings", systemImage: "gearshape", value: AppTab.settings) {
        SettingsView()
      }
    }
    .onChange(
      of: activeWorkout?.id,
      initial: true,
      activeWorkoutDidChange
    )
  }

  private func activeWorkoutDidChange(_: UUID?, _ newID: UUID?) {
    if newID != nil {
      selection = .activeWorkout
    } else if selection == .activeWorkout {
      selection = .home
    }
  }
}

private enum AppTab: Hashable {
  case activeWorkout
  case home
  case settings
}

private struct HomeView: View {
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
    .modelContainer(for: TonnageSchema.models, inMemory: true)
}
