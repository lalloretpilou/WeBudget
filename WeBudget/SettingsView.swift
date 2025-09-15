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
    @State private var showingSeuil = false
    @State private var exportData = ""
    
    var body: some View {
        NavigationView {
            Form {
                // NOUVELLE SECTION: Navigation vers les fonctionnalités
                Section("Fonctionnalités") {
                    NavigationLink {
                        ConfigurationView()
                            .navigationBarBackButtonHidden(false)
                    } label: {
                        Label("Configuration budgets", systemImage: "gearshape.fill")
                            .font(.appCallout) // Space Grotesk Regular
                    }
                    
                    NavigationLink {
                        RecurringExpensesView()
                            .navigationBarBackButtonHidden(false)
                    } label: {
                        Label("Dépenses récurrentes", systemImage: "arrow.clockwise")
                            .font(.appCallout) // Space Grotesk Regular
                            .badge(budgetManager.dueRecurringExpenses.count)
                    }
                    
                    NavigationLink {
                        SavingsGoalsView()
                            .navigationBarBackButtonHidden(false)
                    } label: {
                        Label("Objectifs d'épargne", systemImage: "target")
                            .font(.appCallout) // Space Grotesk Regular
                            .badge(budgetManager.behindScheduleGoals.count)
                    }
                }
                
                Section("Sauvegarde des données") {
                    Button {
                        exportDataToJSON()
                    } label: {
                        Label("Exporter les données", systemImage: "square.and.arrow.up")
                            .font(.appCallout) // Space Grotesk Regular
                    }
                    
                    Button {
                        showingClearAlert = true
                    } label: {
                        Label("Effacer toutes les données", systemImage: "trash")
                            .font(.appCallout) // Space Grotesk Regular
                            .foregroundColor(.red)
                    }
                }
                
                Section("Personnalisation") {
                    
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label("Notifications", systemImage: "bell.fill")
                            .font(.appCallout) // Space Grotesk Regular
                    }
                    
                    NavigationLink {
                        ThemeSettingsView()
                    } label: {
                        Label("Apparence", systemImage: "paintbrush.fill")
                            .font(.appCallout) // Space Grotesk Regular
                    }
                }
                
                Section("Informations") {
                    HStack {
                        Text("Version")
                            .font(.appCallout) // Space Grotesk Regular
                        Spacer()
                        Text("1.0.0")
                            .font(.appCallout) // Space Grotesk Regular
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Transactions")
                            .font(.appCallout) // Space Grotesk Regular
                        Spacer()
                        Text("\(budgetManager.transactions.count)")
                            .font(.appCallout) // Space Grotesk Regular
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Dépenses récurrentes")
                            .font(.appCallout) // Space Grotesk Regular
                        Spacer()
                        Text("\(budgetManager.recurringExpenses.count)")
                            .font(.appCallout) // Space Grotesk Regular
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Objectifs d'épargne")
                            .font(.appCallout) // Space Grotesk Regular
                        Spacer()
                        Text("\(budgetManager.savingsGoals.count)")
                            .font(.appCallout) // Space Grotesk Regular
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("CloudKit")
                            .font(.appCallout) // Space Grotesk Regular
                        Spacer()
                        Text(budgetManager.isAuthenticated ? "Connecté" : "Déconnecté")
                            .font(.appCallout) // Space Grotesk Regular
                            .foregroundColor(budgetManager.isAuthenticated ? .green : .red)
                    }
                }
                
                Section("Préférences système") {
                    HStack {
                        Text("Mode sombre")
                            .font(.appCallout) // Space Grotesk Regular
                        Spacer()
                        Text("Automatique")
                            .font(.appCallout) // Space Grotesk Regular
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Notifications")
                            .font(.appCallout) // Space Grotesk Regular
                        Spacer()
                        Text("Activées")
                            .font(.appCallout) // Space Grotesk Regular
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Text("Devise")
                            .font(.appCallout) // Space Grotesk Regular
                        Spacer()
                        Text("EUR (€)")
                            .font(.appCallout) // Space Grotesk Regular
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Paramètres")
            .alert("Effacer toutes les données", isPresented: $showingClearAlert) {
                Button("Annuler", role: .cancel) {
                    // Action Annuler
                }
                .font(.buttonText) // Space Grotesk Medium
                Button("Effacer", role: .destructive) {
                    clearAllData()
                }
                .font(.buttonText) // Space Grotesk Medium
            } message: {
                Text("Cette action est irréversible. Toutes vos données seront supprimées définitivement.")
                    .font(.appCallout) // Space Grotesk Regular
            }
            .sheet(isPresented: $showingExportSheet) {
                ShareSheet(activityItems: [exportData])
            }
            .sheet(isPresented: $showingSeuil) {
                ConfigurationView()
            }
        }
    }
    
    private func exportDataToJSON() {
        let exportModel = ExportModel(
            salaires: budgetManager.salaires,
            budgets: budgetManager.budgets,
            transactions: budgetManager.transactions,
            recurringExpenses: budgetManager.recurringExpenses,
            savingsGoals: budgetManager.savingsGoals
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
        budgetManager.recurringExpenses.removeAll()
        budgetManager.savingsGoals.removeAll()
        budgetManager.salaires = Salaires(pilou: 6000, doudou: 10000)
        budgetManager.budgets = Budgets()
        
        // Sauvegarder les changements
        budgetManager.saveSalaires()
        budgetManager.saveBudgets()
        // TODO: Ajouter la suppression CloudKit pour les nouvelles entités
    }
    
    private func contactSupport() {
        if let url = URL(string: "mailto:support@webudget.app?subject=Support%20WeBudget") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Nouvelles vues de navigation

struct NotificationSettingsView: View {
    @State private var expenseAlerts = true
    @State private var budgetWarnings = true
    @State private var recurringReminders = true
    @State private var savingsGoalUpdates = true
    @State private var weatherSuggestions = false
    
    var body: some View {
        Form {
            Section("📱 Types de notifications") {
                Toggle("🚨 Alertes de dépassement", isOn: $expenseAlerts)
                    .font(.appCallout) // Space Grotesk Regular
                Toggle("⚠️ Alertes budget (90%)", isOn: $budgetWarnings)
                    .font(.appCallout) // Space Grotesk Regular
                Toggle("🔄 Rappels récurrents", isOn: $recurringReminders)
                    .font(.appCallout) // Space Grotesk Regular
                Toggle("🎯 Objectifs d'épargne", isOn: $savingsGoalUpdates)
                    .font(.appCallout) // Space Grotesk Regular
                Toggle("🌤️ Suggestions météo", isOn: $weatherSuggestions)
                    .font(.appCallout) // Space Grotesk Regular
            }
            
            Section("⏰ Fréquence") {
                HStack {
                    Text("Rappels récurrents")
                        .font(.appCallout) // Space Grotesk Regular
                    Spacer()
                    Text("2 jours avant")
                        .font(.appCallout) // Space Grotesk Regular
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Vérification budget")
                        .font(.appCallout) // Space Grotesk Regular
                    Spacer()
                    Text("Quotidienne")
                        .font(.appCallout) // Space Grotesk Regular
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("🔔 Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ThemeSettingsView: View {
    @State private var selectedTheme: AppTheme = .system
    @State private var accentColor: Color = .blue
    
    var body: some View {
        Form {
            Section("🎨 Thème général") {
                Picker("Mode d'affichage", selection: $selectedTheme) {
                    Text("🌍 Automatique")
                        .font(.appCallout) // Space Grotesk Regular
                        .tag(AppTheme.system)
                    Text("☀️ Clair")
                        .font(.appCallout) // Space Grotesk Regular
                        .tag(AppTheme.light)
                    Text("🌙 Sombre")
                        .font(.appCallout) // Space Grotesk Regular
                        .tag(AppTheme.dark)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            Section("🌈 Couleur d'accentuation") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 15) {
                    ForEach([Color.blue, Color.green, Color.orange, Color.red, Color.purple, Color.teal], id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary, lineWidth: accentColor == color ? 2 : 0)
                            )
                            .onTapGesture {
                                accentColor = color
                            }
                    }
                }
            }
            
            Section("📊 Graphiques") {
                Toggle("🎨 Graphiques colorés", isOn: .constant(true))
                    .font(.appCallout) // Space Grotesk Regular
                Toggle("📈 Animations", isOn: .constant(true))
                    .font(.appCallout) // Space Grotesk Regular
            }
        }
        .navigationTitle("🎨 Apparence")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpView: View {
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                HelpSection(
                    icon: "💰",
                    title: "Gestion des budgets",
                    content: "Configurez vos revenus et budgets mensuels dans l'onglet Configuration. L'application calcule automatiquement vos proportions et votre reste disponible."
                )
                
                HelpSection(
                    icon: "💳",
                    title: "Ajout de transactions",
                    content: "Appuyez sur + dans l'onglet Dépenses pour ajouter une nouvelle transaction. Sélectionnez la catégorie, le montant et qui a payé."
                )
                
                HelpSection(
                    icon: "🔄",
                    title: "Dépenses récurrentes",
                    content: "Créez des dépenses qui se répètent automatiquement (loyer, abonnements, etc.). L'application vous rappellera quand elles sont dues."
                )
                
                HelpSection(
                    icon: "🎯",
                    title: "Objectifs d'épargne",
                    content: "Fixez-vous des objectifs d'épargne avec des dates limites. Suivez votre progression et recevez des encouragements."
                )
                
                HelpSection(
                    icon: "🌤️",
                    title: "Suggestions météo",
                    content: "L'application analyse la météo pour vous suggérer des économies (cuisiner par temps de pluie, activités gratuites au soleil, etc.)."
                )
                
                HelpSection(
                    icon: "☁️",
                    title: "Synchronisation",
                    content: "Vos données sont automatiquement synchronisées via iCloud entre tous vos appareils Apple connectés au même compte."
                )
            }
            .padding()
        }
        .navigationTitle("📖 Guide")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpSection: View {
    let icon: String
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(icon)
                    .font(.title2)
                Text(title)
                    .font(.appHeadline) // Space Grotesk SemiBold
                    .fontWeight(.semibold)
            }
            
            Text(content)
                .font(.appSubheadline) // Space Grotesk Medium
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Logo et nom de l'app
                VStack(spacing: 10) {
                    Image(systemName: "wallet.pass.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("WeBudget")
                        .font(.appTitle) // Space Grotesk SemiBold
                        .fontWeight(.bold)
                    
                    Text("Version 1.0.0")
                        .font(.appSubheadline) // Space Grotesk Medium
                        .foregroundColor(.secondary)
                }
                
                // Description
                VStack(alignment: .leading, spacing: 15) {
                    Text("À propos")
                        .font(.appHeadline) // Space Grotesk SemiBold
                        .fontWeight(.bold)
                    
                    Text("WeBudget est une application de gestion budgétaire conçue spécialement pour les couples. Elle vous aide à gérer vos finances communes tout en respectant vos contributions proportionnelles.")
                        .font(.appSubheadline) // Space Grotesk Medium
                        .foregroundColor(.secondary)
                }
                
                // Fonctionnalités
                VStack(alignment: .leading, spacing: 15) {
                    Text("Fonctionnalités principales")
                        .font(.appHeadline) // Space Grotesk SemiBold
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        FeatureRow(icon: "💰", text: "Gestion proportionnelle des revenus")
                        FeatureRow(icon: "📊", text: "Suivi des budgets par catégorie")
                        FeatureRow(icon: "🔄", text: "Dépenses récurrentes automatiques")
                        FeatureRow(icon: "🎯", text: "Objectifs d'épargne personnalisés")
                        FeatureRow(icon: "🌤️", text: "Suggestions basées sur la météo")
                        FeatureRow(icon: "☁️", text: "Synchronisation iCloud")
                    }
                }
                
                // Crédits
                VStack(alignment: .leading, spacing: 15) {
                    Text("Crédits")
                        .font(.appHeadline) // Space Grotesk SemiBold
                        .fontWeight(.bold)
                    
                    Text("Développé avec ❤️ par Pierre-Louis L'ALLORET")
                        .font(.appSubheadline) // Space Grotesk Medium
                        .foregroundColor(.secondary)
                    
                    Text("Utilise WeatherKit d'Apple pour les données météorologiques")
                        .font(.appCaption) // Space Grotesk Regular
                        .foregroundColor(.secondary)
                }
                
                // Contact
                VStack(spacing: 10) {
                    Button("📧 Contact") {
                        if let url = URL(string: "mailto:contact@webudget.app") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.buttonText) // Space Grotesk Medium
                    .buttonStyle(.borderedProminent)
                    
                    Button("⭐ Noter l'app") {
                        // Action pour noter l'app
                    }
                    .font(.buttonText) // Space Grotesk Medium
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .navigationTitle("À propos")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Text(icon)
            Text(text)
                .font(.appSubheadline) // Space Grotesk Medium
            Spacer()
        }
    }
}

// MARK: - Types d'aide

enum AppTheme: CaseIterable {
    case system, light, dark
}

// MARK: - ExportModel mis à jour

struct ExportModel: Codable {
    let salaires: Salaires
    let budgets: Budgets
    let transactions: [Transaction]
    let recurringExpenses: [RecurringExpense]
    let savingsGoals: [SavingsGoal]
    let exportDate: Date = Date()
}

// MARK: - ShareSheet (inchangé)

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
