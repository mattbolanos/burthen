//
//  ContentUnavailableLogoLabel.swift
//  Burthen
//

import SwiftUI

struct ContentUnavailableLogoLabel: View {
  let title: LocalizedStringKey

  @ScaledMetric(relativeTo: .title)
  private var logoWidth = LayoutMetrics.Size.contentUnavailableLogoWidth

  var body: some View {
    Label {
      Text(title)
    } icon: {
      Image("BurthenLogo")
        .resizable()
        .scaledToFit()
        .frame(width: logoWidth)
        .accessibilityHidden(true)
    }
  }
}

