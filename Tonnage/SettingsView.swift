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
            Label("Workout Templates", systemImage: "rectangle.stack")
          }

          NavigationLink {
            ExerciseManagementView()
          } label: {
            Label("Exercises", systemImage: "dumbbell")
          }
        } header: {
          SectionHeader("Training")
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
