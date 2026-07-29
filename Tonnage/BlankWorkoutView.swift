//
//  BlankWorkoutView.swift
//  Tonnage
//

import SwiftUI

struct BlankWorkoutView: View {
  var body: some View {
    ContentUnavailableView {
      Label("Blank Workout", systemImage: "dumbbell")
    } description: {
      Text("The workout editor will live here.")
    }
    .navigationTitle("Blank Workout")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  NavigationStack {
    BlankWorkoutView()
  }
}
