//
//  TrainingLoadMetric.swift
//  Tonnage
//

import SwiftUI

struct TrainingLoadMetricCard: View {
  let load: VolumeLoad?

  var body: some View {
    HStack(alignment: .top, spacing: LayoutMetrics.Spacing.medium) {
      Image(systemName: "scalemass.fill")
        .font(.title3.weight(.semibold))
        .foregroundStyle(.pink)
        .padding(LayoutMetrics.Spacing.small)
        .background {
          Circle()
            .fill(Color.pink.opacity(0.14))
        }
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: LayoutMetrics.Spacing.extraSmall) {
        Text("Training Load")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.pink)
          .textCase(.uppercase)

        HStack(alignment: .firstTextBaseline, spacing: LayoutMetrics.Spacing.small) {
          Text(load?.formattedValue ?? "—")
            .font(.title.weight(.bold))
            .monospacedDigit()

          if let load {
            Text(load.unit.displayAbbreviation)
              .font(.headline)
              .foregroundStyle(.secondary)
          }
        }

      }

      Spacer(minLength: LayoutMetrics.Spacing.small)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(LayoutMetrics.Padding.card)
    .glassEffect(
      .regular,
      in: .rect(cornerRadius: LayoutMetrics.CornerRadius.card)
    )
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Training load")
    .accessibilityValue(
      "\(load?.accessibilityText ?? "Not available")"
    )
  }
}

struct TrainingLoadCompactMetric: View {
  let load: VolumeLoad?

  var body: some View {
    VStack(alignment: .trailing, spacing: LayoutMetrics.Spacing.extraSmall) {
      Text("Load")
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.pink)
        .textCase(.uppercase)

      Text(load?.displayText ?? "—")
        .font(.subheadline.weight(.semibold))
        .monospacedDigit()
        .foregroundStyle(load == nil ? Color.secondary : Color.primary)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Training load")
    .accessibilityValue(load?.accessibilityText ?? "Not available")
  }
}

struct TrainingLoadInlineMetric: View {
  let load: VolumeLoad?

  var body: some View {
    Label {
      Text(load?.displayText ?? "No training load")
        .monospacedDigit()
    } icon: {
      Image(systemName: "scalemass.fill")
    }
    .font(.caption.weight(.semibold))
    .foregroundStyle(load == nil ? Color.secondary : Color.pink)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Training load")
    .accessibilityValue(load?.accessibilityText ?? "Not available")
  }
}
