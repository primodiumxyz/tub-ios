//
//  TubWidgetExtension.swift
//  TubWidgetExtension
//
//  Created by yixintan on 12/16/24.
//

import WidgetKit
import SwiftUI
import ActivityKit

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            configuration: ConfigurationAppIntent(),
            symbol: "Loading...",
            currentPriceUsd: 0,
            initialPriceUsd: 0
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        guard let activity = Activity<TubActivityAttributes>.activities.first else {
            return SimpleEntry(
                date: Date(),
                configuration: configuration,
                symbol: "No Data",
                currentPriceUsd: 0,
                initialPriceUsd: 0
            )
        }
        
        return SimpleEntry(
            date: Date(),
            configuration: configuration,
            symbol: activity.attributes.symbol,
            currentPriceUsd: activity.content.state.currentPriceUsd,
            initialPriceUsd: activity.attributes.initialPriceUsd
        )
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []
        let currentDate = Date()
        
        guard let activity = Activity<TubActivityAttributes>.activities.first else {
            return Timeline(entries: [
                SimpleEntry(
                    date: currentDate,
                    configuration: configuration,
                    symbol: "No Data",
                    currentPriceUsd: 0,
                    initialPriceUsd: 0
                )
            ], policy: .after(currentDate.addingTimeInterval(60)))
        }
        
        let entry = SimpleEntry(
            date: currentDate,
            configuration: configuration,
            symbol: activity.attributes.symbol,
            currentPriceUsd: activity.content.state.currentPriceUsd,
            initialPriceUsd: activity.attributes.initialPriceUsd
        )
        entries.append(entry)
        
        return Timeline(entries: entries, policy: .after(currentDate.addingTimeInterval(10)))
    }
    
    private func calculatePriceChange(initialPrice: Double, currentPrice: Double) -> Double {
        guard initialPrice != 0 else { return 0 }
        return ((currentPrice - initialPrice) / initialPrice) * 100
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let symbol: String
    let currentPriceUsd: Double
    let initialPriceUsd: Double
}

struct TubWidgetExtensionEntryView : View {
    var entry: Provider.Entry
    
    var pctGain : Double {
        let absGain = entry.currentPriceUsd - entry.initialPriceUsd
        return absGain / entry.initialPriceUsd
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(entry.symbol)
                    .font(.system(.body, design: .rounded))
                    .bold()
                    .foregroundStyle(.white)
            }
            
            Text(String(format: "$%.6f", entry.currentPriceUsd))
                .font(.system(.title3, design: .rounded))
                .bold()
                .foregroundStyle(.white)
                .minimumScaleFactor(0.8)
            
            HStack(spacing: 4) {
                Image(systemName: pctGain >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption2)
                    .foregroundStyle(pctGain >= 0 ? .tubSuccess : .tubError)
                
                Text("\(abs(pctGain), specifier: "%.2f")%")
                    .font(.caption2)
                    .foregroundStyle(pctGain >= 0 ? .tubSuccess : .tubError)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(12)
    }
}

struct TubWidgetExtension: Widget {
    let kind: String = "TubWidgetExtension"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            TubWidgetExtensionEntryView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    TubWidgetExtension()
} timeline: {
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), symbol: "MONK", currentPriceUsd: 0.5612, initialPriceUsd: 1)
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), symbol: "MONK", currentPriceUsd: 0.5612, initialPriceUsd: 0.25)
}
