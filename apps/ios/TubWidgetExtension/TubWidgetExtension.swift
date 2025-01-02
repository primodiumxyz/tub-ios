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
            imageUrl: "",
            currentPrice: 0,
            priceChange: 0
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        guard let activity = Activity<TubActivityAttributes>.activities.first else {
            return SimpleEntry(
                date: Date(),
                configuration: configuration,
                symbol: "No Data",
                imageUrl: "",
                currentPrice: 0,
                priceChange: 0
            )
        }
        
        return SimpleEntry(
            date: Date(),
            configuration: configuration,
            symbol: activity.attributes.symbol,
            imageUrl: activity.attributes.imageUrl,
            currentPrice: activity.content.state.currentPrice,
            priceChange: activity.content.state.value
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
                    imageUrl: "",
                    currentPrice: 0,
                    priceChange: 0
                )
            ], policy: .after(currentDate.addingTimeInterval(60)))
        }
        
        let entry = SimpleEntry(
            date: currentDate,
            configuration: configuration,
            symbol: activity.attributes.symbol,
            imageUrl: activity.attributes.imageUrl,
            currentPrice: activity.content.state.currentPrice,
            priceChange: activity.content.state.value
        )
        entries.append(entry)
        
        return Timeline(entries: entries, policy: .after(currentDate.addingTimeInterval(10)))
    }
    
    private func calculatePriceChange(initialValue: Double, currentValue: Double) -> Double {
        guard initialValue != 0 else { return 0 }
        return ((currentValue - initialValue) / initialValue) * 100
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let symbol: String
    let imageUrl: String
    let currentPrice: Double
    let priceChange: Double
}

struct TubWidgetExtensionEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                AsyncImage(url: URL(string: entry.imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                } placeholder: {
                    Image(systemName: "circle.fill")
                        .foregroundStyle(.accent)
                        .frame(width: 32, height: 32)
                        .padding(.horizontal, -6)
                }
                
                Text(entry.symbol)
                    .font(.system(.body, design: .rounded))
                    .bold()
                    .foregroundStyle(.white)
            }
            
            Text(String(format: "$%.6f", entry.currentPrice))
                .font(.system(.title3, design: .rounded))
                .bold()
                .foregroundStyle(.white)
                .minimumScaleFactor(0.8)
            
            HStack(spacing: 4) {
                Image(systemName: entry.priceChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption2)
                    .foregroundStyle(entry.priceChange >= 0 ? .tubSuccess : .tubError)
                
                Text("\(abs(entry.priceChange), specifier: "%.2f")%")
                    .font(.caption2)
                    .foregroundStyle(entry.priceChange >= 0 ? .tubSuccess : .tubError)
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
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), symbol: "", imageUrl: "", currentPrice: 0.5612, priceChange: 2.34)
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), symbol: "", imageUrl: "", currentPrice: 0.5612, priceChange: -1.23)
}
