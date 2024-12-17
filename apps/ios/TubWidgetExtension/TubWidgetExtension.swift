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
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), balance: 1234.56, priceChange: 2.34)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        // Need to fetch actual data here!
        SimpleEntry(date: Date(), configuration: configuration, balance: 1234.56, priceChange: 2.34)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []
        let currentDate = Date()
        
        let balance = 1234.56  // Replace with real data!!
        let priceChange = 2.34 // Replace with real data!!

        for secondOffset in stride(from: 0, to: 300, by: 10) {
            let entryDate = Calendar.current.date(byAdding: .second, value: secondOffset, to: currentDate)!
            let entry = SimpleEntry(
                date: entryDate,
                configuration: configuration,
                balance: balance,
                priceChange: priceChange
            )
            entries.append(entry)
        }

        return Timeline(entries: entries, policy: .atEnd)
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
