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
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationView {
            Form {
                // NOUVELLE SECTION: Navigation vers les fonctionnalités
                Section {
                    NavigationLink {
                        ConfigurationView()
                            .navigationBarBackButtonHidden(false)
                    } label: {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.limeElectric.opacity(0.2))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "gearshape.fill")
                                    .foregroundColor(Color.limeElectric)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            
                            Text("Configuration budgets")
                                .font(.appCallout)
                                .foregroundColor(Color.adaptiveText(colorScheme))
                        }
                    }
                    
                    NavigationLink {
                        RecurringExpensesView()
                            .navigationBarBackButtonHidden(false)
                    } label: {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.skyBlueRetro.opacity(0.2))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(Color.skyBlueRetro)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            
                            Text("Dépenses récurrentes")
                                .font(.appCallout)
                                .foregroundColor(Color.adaptiveText(colorScheme))
                            
                            Spacer()
                            
                            if budgetManager.dueRecurringExpenses.count > 0 {
                                Text("\(budgetManager.dueRecurringExpenses.count)")
                                    .font(.appCaption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.peachSunset)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    
//                    NavigationLink {
//                        SavingsGoalsView()
//                            .navigationBarBackButtonHidden(false)
//                    } label: {
//                        HStack {
//                            ZStack {
//                                RoundedRectangle(cornerRadius: 8)
//                                    .fill(Color.plumVintage.opacity(0.2))
//                                    .frame(width: 32, height: 32)
//                                Image(systemName: "target")
//                                    .foregroundColor(Color.plumVintage)
//                                    .font(.system(size: 16, weight: .semibold))
//                            }
//                            
//                            Text("Objectifs d'épargne")
//                                .font(.appCallout)
//                                .foregroundColor(Color.adaptiveText(colorScheme))
//                            
//                            Spacer()
//                            
//                            if budgetManager.behindScheduleGoals.count > 0 {
//                                Text("\(budgetManager.behindScheduleGoals.count)")
//                                    .font(.appCaption)
//                                    .fontWeight(.bold)
//                                    .foregroundColor(.white)
//                                    .padding(.horizontal, 8)
//                                    .padding(.vertical, 4)
//                                    .background(Color.softCoral)
//                                    .cornerRadius(12)
//                            }
//                        }
//                    }
                } header: {
                    Text("Fonctionnalités")
                        .font(.appSubheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.limeElectric)
                }
                
                Section {
                    Button {
                        exportDataToJSON()
                    } label: {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.turquoiseVintage.opacity(0.2))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(Color.turquoiseVintage)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            
                            Text("Exporter les données")
                                .font(.appCallout)
                                .foregroundColor(Color.adaptiveText(colorScheme))
                        }
                    }
                    
                    Button {
                        showingClearAlert = true
                    } label: {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.softCoral.opacity(0.2))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "trash")
                                    .foregroundColor(Color.softCoral)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            
                            Text("Effacer toutes les données")
                                .font(.appCallout)
                                .foregroundColor(Color.softCoral)
                        }
                    }
                } header: {
                    Text("Sauvegarde des données")
                        .font(.appSubheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.turquoiseVintage)
                }
                
                                
                Section {
                    SettingsInfoRow(title: "Version", value: "1.0.0", color: Color.dimGray)
                    SettingsInfoRow(title: "Transactions", value: "\(budgetManager.transactions.count)", color: Color.limeElectric)
                    SettingsInfoRow(title: "Dépenses récurrentes", value: "\(budgetManager.recurringExpenses.count)", color: Color.skyBlueRetro)
                    SettingsInfoRow(title: "Objectifs d'épargne", value: "\(budgetManager.savingsGoals.count)", color: Color.plumVintage)
                    
                    HStack {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(budgetManager.isAuthenticated ? Color.limeElectric : Color.softCoral)
                                .frame(width: 8, height: 8)
                            
                            Text("CloudKit")
                                .font(.appCallout)
                                .foregroundColor(Color.adaptiveText(colorScheme))
                        }
                        
                        Spacer()
                        
                        Text(budgetManager.isAuthenticated ? "Connecté" : "Déconnecté")
                            .font(.appCallout)
                            .fontWeight(.medium)
                            .foregroundColor(budgetManager.isAuthenticated ? Color.limeElectric : Color.softCoral)
                    }
                } header: {
                    Text("Informations")
                        .font(.appSubheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.dimGray)
                }
                
                Section {
                    SettingsInfoRow(title: "Mode sombre", value: "Automatique", color: Color.dimGray)
                    SettingsInfoRow(title: "Notifications", value: "Activées", color: Color.limeElectric)
                    SettingsInfoRow(title: "Devise", value: "EUR (€)", color: Color.khakiGold)
                } header: {
                    Text("Préférences système")
                        .font(.appSubheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.dimGray)
                }
            }
            .background(Color.adaptiveBackground(colorScheme))
            .scrollContentBackground(.hidden)
            .navigationTitle("Paramètres")
            .navigationBarTitleDisplayMode(.large)
            .alert("Effacer toutes les données", isPresented: $showingClearAlert) {
                
                Button("Effacer", role: .destructive) {
                    clearAllData()
                }
                .font(.buttonText)
            } message: {
                Text("Cette action est irréversible. Toutes vos données seront supprimées définitivement.")
                    .font(.appCallout)
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

// MARK: - Composant réutilisable pour les lignes d'informations
struct SettingsInfoRow: View {
    let title: String
    let value: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            Text(title)
                .font(.appCallout)
                .foregroundColor(Color.adaptiveText(colorScheme))
            
            Spacer()
            
            Text(value)
                .font(.appCallout)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

struct RetroToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            Text(title)
                .font(.appCallout)
                .foregroundColor(Color.adaptiveText(colorScheme))
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(RetroToggleStyle(color: color))
        }
    }
}

struct RetroToggleStyle: ToggleStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            RoundedRectangle(cornerRadius: 15)
                .fill(configuration.isOn ? color : Color.gray.opacity(0.3))
                .frame(width: 50, height: 30)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 26, height: 26)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}

struct HelpView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                HelpSection(
                    icon: "💰",
                    title: "Gestion des budgets",
                    content: "Configurez vos revenus et budgets mensuels dans l'onglet Configuration. L'application calcule automatiquement vos proportions et votre reste disponible.",
                    color: Color.limeElectric
                )
                
                HelpSection(
                    icon: "💳",
                    title: "Ajout de transactions",
                    content: "Appuyez sur + dans l'onglet Dépenses pour ajouter une nouvelle transaction. Sélectionnez la catégorie, le montant et qui a payé.",
                    color: Color.skyBlueRetro
                )
                
                HelpSection(
                    icon: "🔄",
                    title: "Dépenses récurrentes",
                    content: "Créez des dépenses qui se répètent automatiquement (loyer, abonnements, etc.). L'application vous rappellera quand elles sont dues.",
                    color: Color.peachSunset
                )
                
                HelpSection(
                    icon: "🎯",
                    title: "Objectifs d'épargne",
                    content: "Fixez-vous des objectifs d'épargne avec des dates limites. Suivez votre progression et recevez des encouragements.",
                    color: Color.plumVintage
                )
                
                HelpSection(
                    icon: "🌤️",
                    title: "Suggestions météo",
                    content: "L'application analyse la météo pour vous suggérer des économies (cuisiner par temps de pluie, activités gratuites au soleil, etc.).",
                    color: Color.turquoiseVintage
                )
                
                HelpSection(
                    icon: "☁️",
                    title: "Synchronisation",
                    content: "Vos données sont automatiquement synchronisées via iCloud entre tous vos appareils Apple connectés au même compte.",
                    color: Color.pinkBubblegum
                )
            }
            .padding()
        }
        .background(Color.adaptiveBackground(colorScheme))
        .navigationTitle("📖 Guide")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.oceanBreeze, for: .navigationBar)
    }
}

struct HelpSection: View {
    let icon: String
    let title: String
    let content: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Text(icon)
                        .font(.title2)
                }
                
                Text(title)
                    .font(.appHeadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.adaptiveText(colorScheme))
            }
            
            Text(content)
                .font(.appSubheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.adaptiveSurface(colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: color.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct AboutView: View {
    @Environment(\.colorScheme) private var colorScheme
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Logo et nom de l'app avec style rétro
                VStack(spacing: 15) {
                    ZStack {
                        Circle()
                            .fill(Color.limeToSky)
                            .frame(width: 100, height: 100)
                            .shadow(color: Color.limeElectric.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: "wallet.pass.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Color.brownDeep)
                    }
                    
                    Text("WeBudget")
                        .font(.appTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color.adaptiveText(colorScheme))
                    
                    Text("Version \(appVersion)")
                        .font(.appSubheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.khakiGold.opacity(0.2))
                        .cornerRadius(12)
                }
                
                // Description avec carte rétro
                VStack(alignment: .leading, spacing: 15) {
                    Text("À propos")
                        .font(.appHeadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.adaptiveText(colorScheme))
                    
                    Text("WeBudget est une application de gestion budgétaire conçue spécialement pour les couples. Elle vous aide à gérer vos finances communes tout en respectant vos contributions proportionnelles.")
                        .font(.appSubheadline)
                        .foregroundColor(.secondary)
                        .lineSpacing(2)
                }
                .retroCardStyle()
                
                // Fonctionnalités avec style coloré
                VStack(alignment: .leading, spacing: 15) {
                    Text("Fonctionnalités principales")
                        .font(.appHeadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.adaptiveText(colorScheme))
                    
                    LazyVStack(alignment: .leading, spacing: 12) {
                        FeatureRow(icon: "💰", text: "Gestion proportionnelle des revenus", color: Color.limeElectric)
                        FeatureRow(icon: "📊", text: "Suivi des budgets par catégorie", color: Color.skyBlueRetro)
                        FeatureRow(icon: "🔄", text: "Dépenses récurrentes automatiques", color: Color.peachSunset)
                        FeatureRow(icon: "🎯", text: "Objectifs d'épargne personnalisés", color: Color.plumVintage)
                        FeatureRow(icon: "🌤️", text: "Suggestions basées sur la météo", color: Color.turquoiseVintage)
                        FeatureRow(icon: "☁️", text: "Synchronisation iCloud", color: Color.pinkBubblegum)
                    }
                }
                .retroCardStyle()
                
                // Crédits
                VStack(alignment: .leading, spacing: 15) {
                    Text("Crédits")
                        .font(.appHeadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.adaptiveText(colorScheme))
                    
                    Text("Développé avec ❤️ par Pierre-Louis L'ALLORET")
                        .font(.appSubheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Utilise WeatherKit d'Apple pour les données météorologiques")
                        .font(.appCaption)
                        .foregroundColor(.secondary)
                }
                .retroCardStyle()
            }
            .padding(20)
        }
        .background(Color.adaptiveBackground(colorScheme))
        .navigationTitle("À propos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.limeToSky, for: .navigationBar)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Text(icon)
                    .font(.system(size: 16))
            }
            
            Text(text)
                .font(.appSubheadline)
                .foregroundColor(Color.adaptiveText(colorScheme))
            
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
