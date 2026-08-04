//
//  ContentView.swift
//  Tonnage
//
//  Created by Matt Bolaños on 7/25/26.
//

import SwiftData
import SwiftUI

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
            .tint(nil)
        }
      }

      Tab("Home", systemImage: "house", value: AppTab.home) {
        HomeView(
          workouts: workouts,
          resumeActiveWorkout: showActiveWorkout
        )
          .tint(nil)
      }

      Tab("Settings", systemImage: "gearshape", value: AppTab.settings) {
        SettingsView()
          .tint(nil)
      }
    }
    .tint(.pink)
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

  private func showActiveWorkout() {
    guard activeWorkout != nil else { return }
    selection = .activeWorkout
  }
}

private enum AppTab: Hashable {
  case activeWorkout
  case home
  case settings
}

#Preview {
  ContentView()
    .modelContainer(for: TonnageSchema.models, inMemory: true)
}
