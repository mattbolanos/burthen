//
//  BurthenApp.swift
//  Burthen
//
//  Created by Matt Bolaños on 7/25/26.
//

import SwiftData
import SwiftUI

@main
struct BurthenApp: App {
  private let modelContainer: ModelContainer = {
    let configuration = ModelConfiguration(
      schema: BurthenSchema.schema,
      isStoredInMemoryOnly: false
    )

    do {
      return try ModelContainer(
        for: BurthenSchema.schema,
        configurations: [configuration]
      )
    } catch {
      fatalError("Unable to create the Burthen model container: \(error)")
    }
  }()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .preferredColorScheme(.dark)
    }
    .modelContainer(modelContainer)
  }
}
