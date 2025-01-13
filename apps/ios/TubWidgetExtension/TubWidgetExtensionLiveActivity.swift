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
            var gain: Double {
                let absGain = context.state.currentPriceUsd - context.attributes.initialPriceUsd
                let buyAmountUsdc = context.attributes.buyAmountUsdc
                let buyAmountUsd = Double(context.attributes.buyAmountUsdc) / 1e6
                return buyAmountUsd * absGain / context.attributes.initialPriceUsd
            }
            
            var gainType: String {
                return gain >= 0.01 ? "up" : gain <=  -0.01  ? "down" : "right"
            }
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
                        Text(String(format: "%+.2f%%", abs(gain)))
                            .font(.title)
                            .fontWeight(.medium)
                            .foregroundStyle(gainType == "up" ? .tubSuccess : gainType == "down" ? .tubError : .gray)
                    }
                }
            } compactLeading: {
                Text("$\(context.attributes.symbol)")
                    .font(.system(size: 12))
                    .padding(.leading, 8)
            } compactTrailing: {
                HStack (spacing: 2){
                    Image(
                        systemName: gainType == "up"
                        ? "arrow.up.circle.fill" : gainType == "down"  ? "arrow.down.circle.fill" : "arrow.right.circle.fill"
                    )
                    .resizable()
                    .frame(width: 10, height: 10)
                    .foregroundStyle(gainType == "up" ? .tubSuccess : gainType == "down" ? .tubError : .gray)
                    Text(String(format: "$%.2f", abs(gain)))
                        .font(.caption2)
                        .foregroundStyle(gainType == "up" ? .tubSuccess : gainType == "down" ? .tubError : .gray)
                }
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
    
    var gain: Double {
        let absGain = context.state.currentPriceUsd - context.attributes.initialPriceUsd
        let buyAmountUsdc = context.attributes.buyAmountUsdc
        let buyAmountUsd = Double(context.attributes.buyAmountUsdc) / 1e6
        return buyAmountUsd * absGain / context.attributes.initialPriceUsd
    }
    
    var gainType: String {
        return gain >= 0.01 ? "up" : gain <=  -0.01  ? "down" : "right"
    }
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(context.attributes.name)
                    .font(.headline)
                Text(context.attributes.symbol)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Label {
                Text(String(format: "$%.2f", abs(gain)))
                    .font(.system(.body, design: .rounded))
                    .bold()
            } icon: {
                Image(
                    systemName: gainType == "up"
                    ? "arrow.up.circle.fill" : gainType == "down"  ? "arrow.down.circle.fill" : "arrow.right.circle.fill"
                )
                .foregroundStyle(gainType == "up" ? .tubSuccess : gainType == "down" ? .tubError : .gray)
            }
        }
        .padding(.horizontal, 16)
    }
}

extension TubActivityAttributes {
    fileprivate static var preview: TubActivityAttributes {
        TubActivityAttributes(
            tokenMint: "So11111111111111111111111111111111111111112",
            name: "Solana",
            symbol: "SOL",
            initialPriceUsd: 100.0,
            buyAmountUsdc: 1 * Int(1e6)
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
    
    fileprivate static var third: TubActivityAttributes.ContentState {
        TubActivityAttributes.ContentState(
            currentPriceUsd: 100.0,
            timestamp: Date().addingTimeInterval(3600).timeIntervalSince1970
        )
    }
}

#Preview("Live Activity", as: .content, using: TubActivityAttributes.preview) {
    TubWidgetExtensionLiveActivity()
} contentStates: {
    TubActivityAttributes.ContentState.first
    TubActivityAttributes.ContentState.second
    TubActivityAttributes.ContentState.third
}

#Preview("Lock Screen", as: .content, using: TubActivityAttributes.preview) {
    TubWidgetExtensionLiveActivity()
} contentStates: {
    TubActivityAttributes.ContentState.first
    TubActivityAttributes.ContentState.second
    TubActivityAttributes.ContentState.third
}

#Preview(
    "Dynamic Island (compact)", as: .dynamicIsland(.compact), using: TubActivityAttributes.preview
) {
    TubWidgetExtensionLiveActivity()
} contentStates: {
    TubActivityAttributes.ContentState.first
    TubActivityAttributes.ContentState.second
    TubActivityAttributes.ContentState.third
}

#Preview(
    "Dynamic Island (expanded)", as: .dynamicIsland(.expanded), using: TubActivityAttributes.preview
) {
    TubWidgetExtensionLiveActivity()
} contentStates: {
    TubActivityAttributes.ContentState.first
    TubActivityAttributes.ContentState.second
    TubActivityAttributes.ContentState.third
}

#Preview(
    "Dynamic Island (minimal)", as: .dynamicIsland(.minimal), using: TubActivityAttributes.preview
) {
    TubWidgetExtensionLiveActivity()
} contentStates: {
    TubActivityAttributes.ContentState.first
    TubActivityAttributes.ContentState.second
    TubActivityAttributes.ContentState.third
}
