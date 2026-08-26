//
//  TrainingLoadText.swift
//  Burthen
//

import SwiftUI

struct TrainingLoadText: View {
  enum Emphasis {
    case accent
    case standard
  }

  let load: VolumeLoad?
  let emphasis: Emphasis

  init(load: VolumeLoad?, emphasis: Emphasis = .accent) {
    self.load = load
    self.emphasis = emphasis
  }

  var body: some View {
    Text(load?.displayText ?? "—")
      .monospacedDigit()
      .foregroundStyle(foregroundColor)
      .lineLimit(1)
      .minimumScaleFactor(0.8)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("Training load")
      .accessibilityValue(load?.accessibilityText ?? "Not available")
  }

  private var foregroundColor: Color {
    switch emphasis {
    case .accent: .pink
    case .standard: .primary
    }
  }
}
