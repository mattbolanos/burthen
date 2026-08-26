//
//  StartingWorkingWeightSection.swift
//  Burthen
//

import Foundation
import SwiftUI

struct StartingWorkingWeightSection: View {
  @Binding var weightText: String
  @Binding var weightUnit: WeightUnit

  var body: some View {
    Section {
      TextField("Starting Working Weight (Optional)", text: $weightText)
        .keyboardType(.decimalPad)

      Picker("Weight Unit", selection: $weightUnit) {
        ForEach(WeightUnit.allCases, id: \.self) { unit in
          Text(unit.displayAbbreviation)
            .tag(unit)
        }
      }
      .pickerStyle(.segmented)
    } header: {
      SectionHeader("Starting Weight")
    } footer: {
      Text("Used until this exercise has a completed working set.")
    }
  }
}

enum StartingWorkingWeightInput {
  static func value(from text: String) -> Decimal? {
    let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedText.isEmpty else { return nil }
    return Decimal(string: trimmedText, locale: .current)
  }

  static func text(for weight: Decimal?) -> String {
    weight?.formatted(
      .number.precision(.fractionLength(0...1))
    ) ?? ""
  }

  static func isValid(_ text: String) -> Bool {
    let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedText.isEmpty else { return true }
    guard let weight = value(from: trimmedText) else { return false }
    return (try? Exercise.validateStartingWorkingWeight(weight)) != nil
  }
}
