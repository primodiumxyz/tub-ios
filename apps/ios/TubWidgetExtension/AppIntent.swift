//
//  AppIntent.swift
//  TubWidgetExtension
//
//  Created by yixintan on 12/16/24.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configuration"
    static var description = IntentDescription("Widget Configuration")

    func perform() async throws -> some IntentResult {
        return .result()
    }
}
