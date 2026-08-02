//
//  ExerciseSetColumnLabels.swift
//  Tonnage
//

import SwiftUI

struct ExerciseSetColumnLabels: View {
  var body: some View {
    HStack(spacing: 8) {
      Text("SET")
        .frame(width: 44)
      Text("REPS")
        .frame(maxWidth: .infinity)
      Text("WEIGHT")
        .frame(maxWidth: .infinity)
      Color.clear
        .frame(width: 14, height: 1)
    }
    .font(.caption.weight(.semibold))
    .foregroundStyle(.secondary)
    .accessibilityHidden(true)
  }
}
