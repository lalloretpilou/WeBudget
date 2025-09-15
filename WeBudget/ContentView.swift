//
//  ContentView.swift
//  WeBudget
//
//  Created by Pierre-Louis L'ALLORET on 14/09/2025.
//

// ContentView.swift
import SwiftUI

struct ContentView: View {
    @StateObject private var budgetManager = BudgetManager()
    
    var body: some View {
        Group {
            if budgetManager.isAuthenticated {
                TabView {
                    DashboardView()
                        .tabItem {
                            Image(systemName: "house.fill")
                            Text("Dashboard")
                        }
                    
                    ConfigurationView()
                        .tabItem {
                            Image(systemName: "gearshape.fill")
                            Text("Config")
                        }
                    
                    TransactionsView()
                        .tabItem {
                            Image(systemName: "creditcard.fill")
                            Text("Dépenses")
                        }
                    
                    StatisticsView()
                        .tabItem {
                            Image(systemName: "chart.bar.fill")
                            Text("Stats")
                        }
                    
                    SettingsView()
                        .tabItem {
                            Image(systemName: "slider.horizontal.3")
                            Text("Paramètres")
                        }
                }
                .environmentObject(budgetManager)
            } else {
                AuthenticationStatusView()
                    .environmentObject(budgetManager)
            }
        }
    }
}
