//
//  SettingsView.swift
//  Tonnage
//

import SwiftData
import SwiftUI

struct SettingsView: View {
  var body: some View {
    NavigationStack {
      Form {
        Section("Training") {
          NavigationLink {
            ExerciseManagementView()
          } label: {
            Label("Exercises", systemImage: "dumbbell")
          }
        }
      }
      .navigationTitle("Settings")
    }
  }
}

#Preview {
  SettingsView()
    .modelContainer(for: TonnageSchema.models, inMemory: true)
}
