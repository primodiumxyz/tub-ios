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
        ActivityConfiguration(for: TubActivityAttributes.self) { context in
            // Lock screen/banner UI
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.attributes.name)
                            .font(.caption)
                    } icon: {
                        AsyncImage(url: URL(string: context.attributes.imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                                .clipShape(Circle())
                        } placeholder: {
                            Image(systemName: "circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Label {
                        Text(String(format: "%.2f%%", context.state.value))
                            .font(.caption)
                    } icon: {
                        Image(systemName: context.state.trend == "up" ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .foregroundStyle(context.state.trend == "up" ? .green : .red)
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.symbol)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Label {
                    Text(String(format: "%.1f%%", context.state.value))
                } icon: {
                    AsyncImage(url: URL(string: context.attributes.imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 18, height: 18)
                            .clipShape(Circle())
                    } placeholder: {
                        Image(systemName: "circle.fill")
                            .foregroundStyle(.blue)
                    }
                }
                .font(.caption2)
            } compactTrailing: {
                Image(systemName: context.state.trend == "up" ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .foregroundStyle(context.state.trend == "up" ? .green : .red)
            } minimal: {
                AsyncImage(url: URL(string: context.attributes.imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .clipShape(Circle())
                } placeholder: {
                    Image(systemName: "circle.fill")
                        .foregroundStyle(.blue)
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
                .foregroundStyle(.green)
            
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
                    .foregroundStyle(context.state.trend == "up" ? .green : .red)
            }
        }
        .padding()
    }
}
