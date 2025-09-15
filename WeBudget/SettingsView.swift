//
//  SettingsView.swift
//  WeBudget
//
//  Created by Pierre-Louis L'ALLORET on 14/09/2025.
//

// SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    @State private var showingExportSheet = false
    @State private var showingClearAlert = false
    @State private var exportData = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("💾 Sauvegarde des données") {
                    Button {
                        exportDataToJSON()
                    } label: {
                        Label("📤 Exporter les données", systemImage: "square.and.arrow.up")
                    }
                    
                    Button {
                        showingClearAlert = true
                    } label: {
                        Label("🗑️ Effacer toutes les données", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
                
                Section("ℹ️ Informations") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Transactions")
                        Spacer()
                        Text("\(budgetManager.transactions.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("CloudKit")
                        Spacer()
                        Text("Activé")
                            .foregroundColor(.green)
                    }
                }
                
                Section("⚙️ Préférences") {
                    HStack {
                        Text("🌙 Mode sombre")
                        Spacer()
                        Text("Automatique")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("🔔 Notifications")
                        Spacer()
                        Text("Activées")
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Text("💱 Devise")
                        Spacer()
                        Text("EUR (€)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("🔧 Paramètres")
            .alert("Effacer toutes les données", isPresented: $showingClearAlert) {
                Button("Annuler", role: .cancel) { }
                Button("Effacer", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("⚠️ Cette action est irréversible. Toutes vos données seront supprimées définitivement.")
            }
            .sheet(isPresented: $showingExportSheet) {
                ShareSheet(activityItems: [exportData])
            }
        }
    }
    
    private func exportDataToJSON() {
        let exportModel = ExportModel(
            salaires: budgetManager.salaires,
            budgets: budgetManager.budgets,
            transactions: budgetManager.transactions
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let jsonData = try encoder.encode(exportModel)
            exportData = String(data: jsonData, encoding: .utf8) ?? ""
            showingExportSheet = true
        } catch {
            print("Erreur lors de l'export: \(error)")
        }
    }
    
    private func clearAllData() {
        budgetManager.transactions.removeAll()
        budgetManager.salaires = Salaires(pilou: 6000, doudou: 10000)
        budgetManager.budgets = Budgets()
        
        // Ici, vous devriez aussi supprimer les données de CloudKit
        // Implementation selon vos besoins
    }
}

struct ExportModel: Codable {
    let salaires: Salaires
    let budgets: Budgets
    let transactions: [Transaction]
    let exportDate: Date = Date()
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
