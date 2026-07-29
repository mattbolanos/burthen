//
//  WorkoutTemplatePickerView.swift
//  Tonnage
//

import SwiftUI

struct WorkoutTemplatePickerView: View {
  var body: some View {
    ContentUnavailableView(
      "No Templates Yet",
      systemImage: "rectangle.stack",
      description: Text("Saved workout templates will appear here.")
    )
    .navigationTitle("Choose a Template")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  NavigationStack {
    WorkoutTemplatePickerView()
  }
}
