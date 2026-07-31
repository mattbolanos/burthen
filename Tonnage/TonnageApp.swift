//
//  TonnageApp.swift
//  Tonnage
//
//  Created by Matt Bolaños on 7/25/26.
//

import SwiftUI
import SwiftData

@main
struct TonnageApp: App {
  private let modelContainer: ModelContainer = {
    let configuration = ModelConfiguration(
      schema: TonnageSchema.schema,
      isStoredInMemoryOnly: false
    )

    do {
      return try ModelContainer(
        for: TonnageSchema.schema,
        configurations: [configuration]
      )
    } catch {
      fatalError("Unable to create the Tonnage model container: \(error)")
    }
  }()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .tint(.mint)
        .preferredColorScheme(.dark)
    }
    .modelContainer(modelContainer)
  }
}
