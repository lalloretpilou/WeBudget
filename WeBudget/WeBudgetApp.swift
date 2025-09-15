//
//  WeBudgetApp.swift
//  WeBudget
//
//  Created by Pierre-Louis L'ALLORET on 14/09/2025.
//

import SwiftUI
import CloudKit

@main
struct WeBudgetApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    requestCloudKitPermissions()
                }
        }
    }
    
    private func requestCloudKitPermissions() {
        CKContainer.default().requestApplicationPermission(.userDiscoverability) { status, error in
            if let error = error {
                print("Erreur CloudKit: \(error.localizedDescription)")
            }
        }
    }
}
