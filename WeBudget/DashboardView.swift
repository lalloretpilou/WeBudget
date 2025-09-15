// DashboardView.swift - Version mise à jour et simplifiée
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
            .navigationTitle("💰 Tableau de bord")
            .refreshable {
                budgetManager.loadData()
                weatherManager.loadWeather()
            }
        }
    }
}

// MARK: - Vues existantes (ne pas changer)
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
                Text(value.formatted(.currency(code: "EUR")))
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
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
            Text("🎯 Suivi des budgets")
                .font(.headline)
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
                Text(category.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(spent.formatted(.currency(code: "EUR"))) / \(budget.formatted(.currency(code: "EUR")))")
                        .font(.caption)
                    
                    Text("Reste: \(remaining.formatted(.currency(code: "EUR")))")
                        .font(.caption2)
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
            Text("🔔 Alertes et notifications")
                .font(.headline)
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
        Text(alert.message)
            .font(.subheadline)
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
                Text("💳 Transactions récentes")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                NavigationLink("Voir tout") {
                    TransactionsView()
                }
                .font(.caption)
            }
            
            if recentTransactions.isEmpty {
                Text("Aucune transaction")
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
                Text(transaction.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text(transaction.category.displayName.dropFirst(2))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(transaction.payer.displayName.dropFirst(2))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("-\(transaction.amount.formatted(.currency(code: "EUR")))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                
                Text(transaction.date.formatted(.dateTime.day().month().year()))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
