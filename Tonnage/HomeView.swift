//
//  HomeView.swift
//  Tonnage
//

import SwiftUI

struct HomeView: View {
  let workouts: [Workout]
  let resumeActiveWorkout: () -> Void

  private var activeWorkout: Workout? {
    workouts.first { $0.status == .inProgress }
  }

  private var completedWorkouts: [Workout] {
    workouts
      .filter { $0.status == .completed }
      .sorted(by: isMoreRecentlyCompleted)
  }

  var body: some View {
    let activeWorkout = activeWorkout
    let completedWorkouts = completedWorkouts

    NavigationStack {
      List {
        if let activeWorkout {
          Section {
            Button(action: resumeActiveWorkout) {
              ActiveWorkoutRow(workout: activeWorkout)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Returns to the active workout.")
          } header: {
            SectionHeader("Active")
          }
        }

        if !completedWorkouts.isEmpty {
          Section {
            ForEach(completedWorkouts) { workout in
              CompletedWorkoutRow(workout: workout)
            }
          } header: {
            SectionHeader("Recent")
          }
        }
      }
      .overlay {
        if activeWorkout == nil, completedWorkouts.isEmpty {
          ContentUnavailableView(
            "No Workouts Yet",
            systemImage: "dumbbell",
            description: Text("Start a blank workout or choose a template to begin.")
          )
        }
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
          .disabled(activeWorkout != nil)
          .accessibilityHint(
            activeWorkout == nil
              ? "Choose how to start a workout."
              : "Finish or discard the active workout before starting another one."
          )
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

  private func isMoreRecentlyCompleted(_ lhs: Workout, _ rhs: Workout) -> Bool {
    let lhsDate = lhs.endedAt ?? lhs.updatedAt
    let rhsDate = rhs.endedAt ?? rhs.updatedAt

    if lhsDate == rhsDate {
      return lhs.id.uuidString > rhs.id.uuidString
    }
    return lhsDate > rhsDate
  }
}

private struct ActiveWorkoutRow: View {
  let workout: Workout

  var body: some View {
    HStack(spacing: LayoutMetrics.Spacing.large) {
      VStack(alignment: .leading, spacing: LayoutMetrics.Spacing.extraSmall) {
        Text(workout.displayName)
          .font(.headline)
          .foregroundStyle(.primary)

        Text(
          workout.startedAt,
          format: .dateTime
            .weekday(.abbreviated)
            .month(.abbreviated)
            .day()
            .hour()
            .minute()
        )
        .font(.subheadline)
        .foregroundStyle(.secondary)
      }

      Spacer(minLength: LayoutMetrics.Spacing.small)

      Image(systemName: "play.fill")
        .font(.title3.weight(.semibold))
        .foregroundStyle(.green)
        .frame(
          width: LayoutMetrics.Size.resumeWorkoutButton,
          height: LayoutMetrics.Size.resumeWorkoutButton
        )
        .background {
          Circle()
            .fill(Color.green.opacity(0.18))
        }
        .accessibilityLabel("Resume")
    }
    .frame(minHeight: LayoutMetrics.Size.workoutRowContentHeight)
    .padding(.vertical, LayoutMetrics.Spacing.extraSmall)
    .contentShape(.rect)
    .accessibilityElement(children: .combine)
  }
}

private struct CompletedWorkoutRow: View {
  let workout: Workout

  var body: some View {
    VStack(alignment: .leading, spacing: LayoutMetrics.Spacing.extraSmall) {
      Text(workout.displayName)
        .font(.headline)
        .foregroundStyle(.primary)

      Text(
        workout.endedAt ?? workout.updatedAt,
        format: .dateTime
          .weekday(.abbreviated)
          .month(.abbreviated)
          .day()
          .hour()
          .minute()
      )
      .font(.subheadline)
      .foregroundStyle(.secondary)
    }
    .frame(
      maxWidth: .infinity,
      minHeight: LayoutMetrics.Size.workoutRowContentHeight,
      alignment: .leading
    )
    .padding(.vertical, LayoutMetrics.Spacing.extraSmall)
    .accessibilityElement(children: .combine)
  }
}

#Preview {
  HomeView(workouts: [], resumeActiveWorkout: {})
}
