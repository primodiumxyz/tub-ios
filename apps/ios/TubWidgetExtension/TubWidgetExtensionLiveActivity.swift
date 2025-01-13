//
//  TubWidgetExtensionLiveActivity.swift
//  TubWidgetExtension
//
//  Created by yixintan on 12/16/24.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct TubWidgetExtensionLiveActivity: Widget {

  var body: some WidgetConfiguration {

    ActivityConfiguration<TubActivityAttributes>(for: TubActivityAttributes.self) { context in
      // Lock screen/banner UI
      LockScreenLiveActivityView(context: context)
    } dynamicIsland: { context in
      let absGain = context.state.currentPriceUsd - context.attributes.initialPriceUsd
      let pctGain = absGain / context.attributes.initialPriceUsd
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading, priority: 1) {
          HStack(spacing: 8) {
            Text(context.attributes.name)
              .font(.system(size: 15))
            VStack(alignment: .leading, spacing: 2) {
              Text(context.attributes.symbol)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
              Text(String(format: "$%.6f", context.state.currentPriceUsd))
                .font(.title2)
                .fontWeight(.medium)
            }
          }
          .dynamicIsland(verticalPlacement: .belowIfTooWide)
        }

        DynamicIslandExpandedRegion(.trailing) {
          VStack {
            Spacer()
            Text(String(format: "%+.2f%%", abs(pctGain)))
              .font(.title)
              .fontWeight(.medium)
              .foregroundStyle(pctGain > 0 ? .tubSuccess : .tubError)
          }
        }
      } compactLeading: {
        Text("$\(context.attributes.symbol)")
          .font(.system(size: 15))
      } compactTrailing: {
        Text(String(format: "%+.1f%%", abs(pctGain)))
          .font(.caption2)
          .foregroundStyle(pctGain > 0 ? .tubSuccess : .tubError)
      } minimal: {
        Text(context.attributes.symbol)
          .font(.system(size: 15))

      }
    }
  }
}

// Lock Screen Live Activity View
struct LockScreenLiveActivityView: View {
  let context: ActivityViewContext<TubActivityAttributes>

  var pctGain: Double {
    let absGain = context.state.currentPriceUsd - context.attributes.initialPriceUsd
    return absGain / context.attributes.initialPriceUsd
  }

  var body: some View {
    HStack {
      Image(systemName: "dollarsign.circle.fill")
        .foregroundStyle(.tubSuccess)

      VStack(alignment: .leading) {
        Text(context.attributes.name)
          .font(.headline)
        Text(context.attributes.symbol)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()

      Label {
        Text(String(format: "$%.2f", abs(pctGain)))
          .font(.system(.body, design: .rounded))
          .bold()
      } icon: {
        Image(
          systemName: pctGain > 0
            ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
        )
        .foregroundStyle(pctGain > 0 ? .tubSuccess : .tubError)
      }
    }
    .padding()

  }
}

extension TubActivityAttributes {
  fileprivate static var preview: TubActivityAttributes {
    TubActivityAttributes(
      tokenMint: "So11111111111111111111111111111111111111112",
      name: "Solana",
      symbol: "SOL",
      initialPriceUsd: 100.0
    )
  }
}

extension TubActivityAttributes.ContentState {
  fileprivate static var first: TubActivityAttributes.ContentState {
    TubActivityAttributes.ContentState(
      currentPriceUsd: 99.0,
      timestamp: Date().timeIntervalSince1970
    )
  }

  fileprivate static var second: TubActivityAttributes.ContentState {
    TubActivityAttributes.ContentState(
      currentPriceUsd: 105.42,
      timestamp: Date().addingTimeInterval(3600).timeIntervalSince1970
    )
  }
}

#Preview("Live Activity", as: .content, using: TubActivityAttributes.preview) {
  TubWidgetExtensionLiveActivity()
} contentStates: {
  TubActivityAttributes.ContentState.first
  TubActivityAttributes.ContentState.second
}

#Preview("Lock Screen", as: .content, using: TubActivityAttributes.preview) {
  TubWidgetExtensionLiveActivity()
} contentStates: {
  TubActivityAttributes.ContentState.first
  TubActivityAttributes.ContentState.second
}

#Preview(
  "Dynamic Island (compact)", as: .dynamicIsland(.compact), using: TubActivityAttributes.preview
) {
  TubWidgetExtensionLiveActivity()
} contentStates: {
  TubActivityAttributes.ContentState.first
  TubActivityAttributes.ContentState.second
}

#Preview(
  "Dynamic Island (expanded)", as: .dynamicIsland(.expanded), using: TubActivityAttributes.preview
) {
  TubWidgetExtensionLiveActivity()
} contentStates: {
  TubActivityAttributes.ContentState.first
  TubActivityAttributes.ContentState.second
}

#Preview(
  "Dynamic Island (minimal)", as: .dynamicIsland(.minimal), using: TubActivityAttributes.preview
) {
  TubWidgetExtensionLiveActivity()
} contentStates: {
  TubActivityAttributes.ContentState.first
  TubActivityAttributes.ContentState.second
}
