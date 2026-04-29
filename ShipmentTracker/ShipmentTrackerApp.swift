//
//  ShipmentTrackerApp.swift
//  ShipmentTracker
//
//  Created by nitinAgnihotri on 29/04/26.
//

import SwiftUI

@main
struct ShipmentTrackerApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}
