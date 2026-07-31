//
//  SettingsView.swift
//  Tonnage
//

import SwiftUI

struct SettingsView: View {
  var body: some View {
    NavigationStack {
      ContentUnavailableView {
        Label("Settings", systemImage: "gearshape")
      } description: {
        Text("App preferences will appear here.")
      }
      .navigationTitle("Settings")
    }
  }
}

#Preview {
  SettingsView()
}
