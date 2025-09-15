// DashboardView.swift - Version avec polices Space Grotesk
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    @StateObject var weatherManager = WeatherManager()
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Widget météo en haut
                    WeatherWidget()
                        .environmentObject(weatherManager)
                    
                    // Statistiques principales
                    StatsCardsView()
                    
                    // Suggestions météo intelligentes
                    WeatherSuggestionsView()
                        .environmentObject(weatherManager)
                    
                    // Progression des budgets
                    BudgetProgressView()
                    
                    // Prédictions de dépenses basées sur la météo
                    ExpensePredictionsView()
                        .environmentObject(weatherManager)
                    
                    // Alertes
                    AlertsView()
                    
                    // Transactions récentes
                    RecentTransactionsView()
                }
                .padding()
            }
            .navigationTitle("Tableau de bord")
            .refreshable {
                budgetManager.loadData()
                weatherManager.loadWeather()
            }
        }
    }
}

// MARK: - StatsCardsView avec polices Space Grotesk
struct StatsCardsView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
            StatCard(
                title: "Revenus totaux",
                value: budgetManager.totalRevenus,
                icon: "banknote.fill",
                color: .blue
            )
            
            StatCard(
                title: "Dépenses ce mois",
                value: budgetManager.depensesMoisCourant,
                icon: "creditcard.fill",
                color: .red
            )
            
            StatCard(
                title: "Budget alloué",
                value: budgetManager.totalBudgets,
                icon: "chart.pie.fill",
                color: .orange
            )
            
            StatCard(
                title: "Reste disponible",
                value: budgetManager.resteDisponible,
                icon: "dollarsign.circle.fill",
                color: budgetManager.resteDisponible >= 0 ? .green : .red
            )
        }
    }
}

struct StatCard: View {
    let title: String
    let value: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // ✅ Police Space Grotesk Bold pour les montants
                Text(value.formatted(.currency(code: "EUR")))
                    .font(.currencyMedium) // Space Grotesk SemiBold 20pt
                    .fontWeight(.bold)
                
                // ✅ Police Space Grotesk Regular pour les titres
                Text(title)
                    .font(.appFootnote) // Space Grotesk Regular 13pt
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct BudgetProgressView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // ✅ Police Space Grotesk Bold pour les titres de section
            Text("🎯 Suivi des budgets")
                .font(.appTitle3) // Space Grotesk SemiBold 20pt
                .fontWeight(.bold)
            
            ForEach(TransactionCategory.allCases, id: \.self) { category in
                BudgetProgressRow(category: category)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct BudgetProgressRow: View {
    @EnvironmentObject var budgetManager: BudgetManager
    let category: TransactionCategory
    
    var budget: Double {
        budgetManager.budgets.budgetForCategory(category)
    }
    
    var spent: Double {
        budgetManager.depensesParCategorie(category)
    }
    
    var progress: Double {
        budgetManager.progressionBudget(category)
    }
    
    var remaining: Double {
        max(budget - spent, 0)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // ✅ Police Space Grotesk Medium pour les noms de catégorie
                Text(category.displayName)
                    .font(.appSubheadline) // Space Grotesk Medium 15pt
                    .fontWeight(.medium)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    // ✅ Police Space Grotesk Medium pour les montants de budget
                    Text("\(spent.formatted(.currency(code: "EUR"))) / \(budget.formatted(.currency(code: "EUR")))")
                        .font(.currencySmall) // Space Grotesk Medium 16pt
                    
                    // ✅ Police Space Grotesk Regular pour les détails
                    Text("Reste: \(remaining.formatted(.currency(code: "EUR")))")
                        .font(.appCaption2) // Space Grotesk Light 11pt
                        .foregroundColor(.secondary)
                }
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
        }
    }
    
    var progressColor: Color {
        if progress > 1.0 { return .red }
        if progress > 0.9 { return .orange }
        return category.color
    }
}

struct AlertsView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    
    var alerts: [AlertItem] {
        var items: [AlertItem] = []
        
        for category in TransactionCategory.allCases {
            let progress = budgetManager.progressionBudget(category)
            
            if progress > 1.0 {
                items.append(AlertItem(
                    type: .danger,
                    message: "⚠️ Budget dépassé pour \(category.displayName.dropFirst(2)) : \(((progress - 1.0) * 100).formatted(.number.precision(.fractionLength(1))))% de dépassement"
                ))
            } else if progress > 0.9 {
                items.append(AlertItem(
                    type: .warning,
                    message: "🔶 Attention : \(category.displayName.dropFirst(2)) à \((progress * 100).formatted(.number.precision(.fractionLength(1))))% du budget"
                ))
            }
        }
        
        if items.isEmpty {
            items.append(AlertItem(
                type: .success,
                message: "✅ Tous vos budgets sont sous contrôle !"
            ))
        }
        
        return items
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // ✅ Police Space Grotesk Bold pour les titres de section
            Text("🔔 Alertes et notifications")
                .font(.appTitle3) // Space Grotesk SemiBold 20pt
                .fontWeight(.bold)
            
            ForEach(alerts) { alert in
                AlertCard(alert: alert)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct AlertItem: Identifiable {
    let id = UUID()
    let type: AlertType
    let message: String
}

enum AlertType {
    case success, warning, danger
    
    var color: Color {
        switch self {
        case .success: return .green
        case .warning: return .orange
        case .danger: return .red
        }
    }
}

struct AlertCard: View {
    let alert: AlertItem
    
    var body: some View {
        // ✅ Police Space Grotesk Regular pour les messages d'alerte
        Text(alert.message)
            .font(.appCallout) // Space Grotesk Regular 16pt
            .padding()
            .background(alert.type.color.opacity(0.1))
            .foregroundColor(alert.type.color)
            .cornerRadius(8)
    }
}

struct RecentTransactionsView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    
    var recentTransactions: [Transaction] {
        Array(budgetManager.transactions.prefix(5))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                // ✅ Police Space Grotesk Bold pour les titres de section
                Text("💳 Transactions récentes")
                    .font(.appTitle3) // Space Grotesk SemiBold 20pt
                    .fontWeight(.bold)
                
                Spacer()
                
                NavigationLink("Voir tout") {
                    TransactionsView()
                }
                .font(.appCaption) // Space Grotesk Regular 12pt
            }
            
            if recentTransactions.isEmpty {
                // ✅ Police Space Grotesk Regular pour le texte d'état vide
                Text("Aucune transaction")
                    .font(.appBody) // Space Grotesk Regular 17pt
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(recentTransactions) { transaction in
                    TransactionRowView(transaction: transaction)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct TransactionRowView: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            Text(transaction.category.icon)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                // ✅ Police Space Grotesk Medium pour les descriptions de transaction
                Text(transaction.description)
                    .font(.appSubheadline) // Space Grotesk Medium 15pt
                    .fontWeight(.medium)
                
                HStack {
                    // ✅ Police Space Grotesk Regular pour les détails secondaires
                    Text(transaction.category.displayName.dropFirst(2))
                        .font(.appCaption) // Space Grotesk Regular 12pt
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.appCaption)
                        .foregroundColor(.secondary)
                    
                    Text(transaction.payer.displayName.dropFirst(2))
                        .font(.appCaption) // Space Grotesk Regular 12pt
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                // ✅ Police Space Grotesk SemiBold pour les montants
                Text("-\(transaction.amount.formatted(.currency(code: "EUR")))")
                    .font(.currencySmall) // Space Grotesk Medium 16pt
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                
                // ✅ Police Space Grotesk Light pour les dates
                Text(transaction.date.formatted(.dateTime.day().month().year()))
                    .font(.appCaption2) // Space Grotesk Light 11pt
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
