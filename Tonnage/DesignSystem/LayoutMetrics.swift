//
//  LayoutMetrics.swift
//  Tonnage
//

import SwiftUI

/// Shared layout values for deliberate overrides of SwiftUI's native spacing.
///
/// Prefer the defaults supplied by containers such as `Form`, `List`, and
/// `Section`. Use these metrics when a custom composition needs an explicit
/// relationship between elements.
enum LayoutMetrics {
  enum Spacing {
    static let extraSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let extraLarge: CGFloat = 24
    static let doubleExtraLarge: CGFloat = 32
  }

  enum Padding {
    static let card = Spacing.large
    static let horizontalContent = Spacing.large
  }

  enum CornerRadius {
    static let card: CGFloat = 22
  }

  enum Size {
    static let setNumberColumn = Spacing.extraLarge
    static let workoutRowContentHeight: CGFloat = 44
    static let resumeWorkoutButton = workoutRowContentHeight
  }

  enum Insets {
    static let cardRow = EdgeInsets(
      top: Spacing.small,
      leading: Spacing.large,
      bottom: Spacing.small,
      trailing: Spacing.large
    )

    static let finalActionRow = EdgeInsets(
      top: Spacing.large,
      leading: Spacing.large,
      bottom: Spacing.extraLarge,
      trailing: Spacing.large
    )
  }
}
