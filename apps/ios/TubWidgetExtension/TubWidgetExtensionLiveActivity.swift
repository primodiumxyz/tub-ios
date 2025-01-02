//
//  TubWidgetExtensionLiveActivity.swift
//  TubWidgetExtension
//
//  Created by yixintan on 12/16/24.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct TubWidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration<TubActivityAttributes>(for: TubActivityAttributes.self) { context in
            // Lock screen/banner UI
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading, priority: 1) {
                    HStack(spacing: 8) {
                        AsyncImage(url: URL(string: context.attributes.imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50)
                        } placeholder: {
                            Image(systemName: "circle.fill")
                                .foregroundStyle(.accent)
                                .frame(width: 50, height: 50)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.attributes.symbol)
                                .font(.system(size: 15))
                                .foregroundStyle(.secondary)
                            Text(String(format: "$%.6f", context.state.currentPrice))
                                .font(.title2)
                                .fontWeight(.medium)
                        }
                    }
                    .dynamicIsland(verticalPlacement: .belowIfTooWide)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack {
                        Spacer()
                        Text(String(format: "%+.2f%%", context.state.value))
                            .font(.title)
                            .fontWeight(.medium)
                            .foregroundStyle(context.state.trend == "up" ? .tubSuccess : .tubError)
                    }
                }
            } compactLeading: {
                AsyncImage(url: URL(string: context.attributes.imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())
                } placeholder: {
                    Image(systemName: "circle.fill")
                        .foregroundStyle(.accent)
                }
            } compactTrailing: {
                Text(String(format: "%+.1f%%", context.state.value))
                    .font(.caption2)
                    .foregroundStyle(context.state.trend == "up" ? .tubSuccess : .tubError)
            } minimal: {
                AsyncImage(url: URL(string: context.attributes.imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .clipShape(Circle())
                } placeholder: {
                    Image(systemName: "circle.fill")
                        .foregroundStyle(.accent)
                }
            }
        }
    }
}

// Lock Screen Live Activity View
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<TubActivityAttributes>
    
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
                Text(String(format: "$%.2f", context.state.value))
                    .font(.system(.body, design: .rounded))
                    .bold()
            } icon: {
                Image(systemName: context.state.trend == "up" ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .foregroundStyle(context.state.trend == "up" ? .tubSuccess : .tubError)
            }
        }
        .padding()
    }
}
