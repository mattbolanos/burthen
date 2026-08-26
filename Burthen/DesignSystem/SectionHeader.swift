//
//  SectionHeader.swift
//  Burthen
//

import SwiftUI

struct SectionHeader: View {
  let title: LocalizedStringKey

  init(_ title: LocalizedStringKey) {
    self.title = title
  }

  var body: some View {
    Text(title)
      .font(.headline)
      .foregroundStyle(.secondary)
      .textCase(nil)
  }
}
