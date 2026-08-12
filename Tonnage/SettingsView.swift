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
            ExerciseManagementView()
          } label: {
            Text("Exercises")
          }

          NavigationLink {
            TemplateManagementView()
          } label: {
            Text("Workout Templates")
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
