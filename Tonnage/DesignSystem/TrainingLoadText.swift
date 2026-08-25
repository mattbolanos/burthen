//
//  TrainingLoadText.swift
//  Tonnage
//

import SwiftUI

struct TrainingLoadText: View {
  let load: VolumeLoad?

  var body: some View {
    Text(load?.displayText ?? "—")
      .monospacedDigit()
      .foregroundStyle(.pink)
      .lineLimit(1)
      .minimumScaleFactor(0.8)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("Training load")
      .accessibilityValue(load?.accessibilityText ?? "Not available")
  }
}
