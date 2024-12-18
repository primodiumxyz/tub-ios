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
        // Use 0 as placeholder values
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), balance: 0, priceChange: 0)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        guard let activity = Activity<TubActivityAttributes>.activities.first else {
            return SimpleEntry(date: Date(), configuration: configuration, balance: 0, priceChange: 0)
        }
        
        let balance = activity.content.state.value
        
        return SimpleEntry(date: Date(), configuration: configuration, balance: balance, priceChange: 0)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []
        let currentDate = Date()
        
        // Debug: Print all activities
        print("All activities: \(Activity<TubActivityAttributes>.activities)")
        
        guard let activity = Activity<TubActivityAttributes>.activities.first else {
            print("No activity found")
            return Timeline(entries: [
                SimpleEntry(date: currentDate, configuration: configuration, balance: 0, priceChange: 0)
            ], policy: .atEnd)
        }
        
        let balance = activity.content.state.value
        print("Found activity with balance: \(balance)")

        // Create timeline entries
        for secondOffset in stride(from: 0, to: 300, by: 10) {
            let entryDate = Calendar.current.date(byAdding: .second, value: secondOffset, to: currentDate)!
            let entry = SimpleEntry(
                date: entryDate,
                configuration: configuration,
                balance: balance,
                priceChange: 0 // need to fetch actual data!!
            )
            entries.append(entry)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }
    
    private func calculatePriceChange(initialValue: Double, currentValue: Double) -> Double {
        guard initialValue != 0 else { return 0 }
        return ((currentValue - initialValue) / initialValue) * 100
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let balance: Double
    let priceChange: Double
}

struct TubWidgetExtensionEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Balance")
                .font(.caption2)
                .foregroundStyle(.gray)
            
            Text("$\(entry.balance, specifier: "%.2f")")
                .font(.system(.body, design: .rounded))
                .bold()
                .foregroundStyle(.white)
                .minimumScaleFactor(0.8)
            
            Spacer(minLength: 2)
            
            HStack(spacing: 4) {
                Image(systemName: entry.priceChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption2)
                    .foregroundStyle(entry.priceChange >= 0 ? .green : .red)
                
                Text("\(abs(entry.priceChange), specifier: "%.2f")%")
                    .font(.caption2)
                    .foregroundStyle(entry.priceChange >= 0 ? .green : .red)
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
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), balance: 1234.56, priceChange: 2.34)
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), balance: 1234.56, priceChange: -1.23)
}
