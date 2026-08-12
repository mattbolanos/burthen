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
  @State private var homeNavigationPath: [NewWorkoutRoute] = []

  private var activeWorkout: Workout? {
    workouts.first { $0.status == .inProgress }
  }

  private var workoutActivityDescriptor: WorkoutActivityDescriptor? {
    activeWorkout.map {
      WorkoutActivityDescriptor(
        id: $0.id,
        name: $0.displayName,
        startedAt: $0.startedAt
      )
    }
  }

  var body: some View {
    TabView(selection: $selection) {
      if let activeWorkout {
        Tab("Workout", systemImage: "dumbbell.fill", value: AppTab.activeWorkout) {
          ActiveWorkoutView(
            workout: activeWorkout,
            onDiscard: showHome
          )
            .tint(nil)
        }
      }

      Tab("Home", systemImage: "house", value: AppTab.home) {
        HomeView(
          navigationPath: $homeNavigationPath,
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
    .task(id: activeWorkout?.id) {
      await WorkoutActivityManager.synchronize(
        with: workoutActivityDescriptor
      )
    }
  }

  private func activeWorkoutDidChange(_: UUID?, _ newID: UUID?) {
    if newID != nil {
      selection = .activeWorkout
    } else if selection == .activeWorkout {
      showHome()
    }
  }

  private func showActiveWorkout() {
    guard activeWorkout != nil else { return }
    selection = .activeWorkout
  }

  private func showHome() {
    homeNavigationPath.removeAll()
    selection = .home
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
