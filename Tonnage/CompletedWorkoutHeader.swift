//
//  CompletedWorkoutHeader.swift
//  Tonnage
//

import SwiftUI

struct CompletedWorkoutHeader: View {
  let workout: Workout

  var body: some View {
    VStack(alignment: .leading, spacing: LayoutMetrics.Spacing.small) {
      Text(workout.displayName)
        .font(.headline)
        .foregroundStyle(.secondary)

      Text(
        workout.startedAt,
        format: .dateTime
          .weekday(.wide)
          .month(.wide)
          .day()
          .hour()
          .minute()
      )
      .font(.title3.weight(.semibold))

      if let endedAt = workout.endedAt {
        Text("Completed at \(endedAt, format: .dateTime.hour().minute())")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      if let notes = workout.notes {
        Text(notes)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      TrainingLoadText(load: workout.volumeLoad)
        .font(.headline)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, LayoutMetrics.Spacing.small)
    .listRowSeparator(.hidden)
    .listRowBackground(Color.clear)
  }
}
