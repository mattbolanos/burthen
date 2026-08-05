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
        Section {
          NavigationLink {
            TemplateManagementView()
          } label: {
            Text("Workout Templates")
          }

          NavigationLink {
            ExerciseManagementView()
          } label: {
            Text("Exercises")
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
