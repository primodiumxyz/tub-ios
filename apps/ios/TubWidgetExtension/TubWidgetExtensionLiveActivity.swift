//
//  TubWidgetExtensionLiveActivity.swift
//  TubWidgetExtension
//
//  Created by yixintan on 12/16/24.
//

import ActivityKit
import SwiftUI
import WidgetKit

enum GainType {
    case up
    case down
    case right
}

struct TubWidgetExtensionLiveActivity: Widget {
    
    var body: some WidgetConfiguration {
        
        ActivityConfiguration<TubActivityAttributes>(for: TubActivityAttributes.self) { context in
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            
            var gain: (absGain: Double, pctGain: Double) {
                let buyAmountUsd = Double(context.attributes.buyAmountUsdc) / 1e6
                let pctGain = context.state.currentPriceUsd / context.attributes.initialPriceUsd
                let absGain = (pctGain * buyAmountUsd) - buyAmountUsd
                return (absGain, pctGain * 100 - 100)
            }
            
            var gainType: GainType {
                return gain.absGain >= 0.01 ? .up : gain.absGain <= -0.01 ? .down : .right
            }

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading, priority: 1) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.name)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .opacity(0.7)
                        
                        Text(
                            formatPriceUsd(usd: context.state.currentPriceUsd)
                        )
                        .font(.title2)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    }.padding(12)
                        .frame(height: 60)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(
                            "\(gainType == .up ? "+" : gainType == .down ? "-" : "")\(String(format: gain.absGain >= 100 ? "$%.0f" : "$%.2f", abs(gain.absGain)))"
                        )
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(
                            gainType == .up ? .tubSuccess : gainType == .down ? .tubError : .gray
                        )
                        Text(
                            "\(gainType == .up ? "+" : gainType == .down ? "-" : "")\(String(format: "%.1f%%", abs(gain.pctGain)))"
                        )
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(
                            gainType == .up ? .tubSuccess : gainType == .down ? .tubError : .gray
                        )
                            .opacity(0.7)
                    }.padding(12)
                    .frame(height: 60)
                    
                }
                
            } compactLeading: {
                Text("$\(context.attributes.symbol)")
                    .font(.system(size: 12))
                    .fontWeight(.semibold)
                    .padding(.leading, 8)
            } compactTrailing: {
                Text(
                    "\(gainType == .up ? "+" : gainType == .down ? "-" : "")\(String(format: gain.absGain >= 100 ? "$%.0f" : "$%.2f", abs(gain.absGain)))"
                )
                .font(.caption2)
                .foregroundStyle(
                    gainType == .up ? .tubSuccess : gainType == .down ? .tubError : .gray)
            } minimal: {
                Image(
                    systemName: gainType == .up
                    ? "arrow.up" : gainType == .down ? "arrow.down" : "arrow.right"
                )
                .font(.caption2)
                .foregroundStyle(
                    gainType == .up ? .tubSuccess : gainType == .down ? .tubError : .gray)
            }
        }
    }
}

// Lock Screen Live Activity View
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<TubActivityAttributes>
    
    var gain: Double {
        let buyAmountUsd = Double(context.attributes.buyAmountUsdc) / 1e6
        let pctGain = context.state.currentPriceUsd / context.attributes.initialPriceUsd
        return (pctGain * buyAmountUsd) - buyAmountUsd
    }
    
    var gainType: GainType {
        return gain >= 0.01 ? .up : gain <= -0.01 ? .down : .right
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
                    systemName: gainType == .up
                    ? "arrow.up.circle.fill"
                    : gainType == .down ? "arrow.down.circle.fill" : "arrow.right.circle.fill"
                )
                .foregroundStyle(gainType == .up ? .tubSuccess : gainType == .down ? .tubError : .gray)
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
            initialPriceUsd: 50,
            buyAmountUsdc: 10 * Int(1e6)
        )
    }
}

extension TubActivityAttributes.ContentState {
    fileprivate static var first: TubActivityAttributes.ContentState {
        TubActivityAttributes.ContentState(
            currentPriceUsd: 45,
            timestamp: Date().timeIntervalSince1970
        )
    }
    
    fileprivate static var second: TubActivityAttributes.ContentState {
        TubActivityAttributes.ContentState(
            currentPriceUsd: 3050.42,
            timestamp: Date().addingTimeInterval(3600).timeIntervalSince1970
        )
    }
    
    fileprivate static var third: TubActivityAttributes.ContentState {
        TubActivityAttributes.ContentState(
            currentPriceUsd: 50.001,
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
