// StatisticsView.swift - Version corrigée
import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Graphique par catégorie
                    CategoryExpensesChartView()
                    
                    // Graphique des contributions
                    PayerContributionChartView()
                    
                    // Évolution mensuelle
                    MonthlyTrendsChartView()
                    
                    // Rapport mensuel
                    MonthlyReportView()
                }
                .padding()
            }
            .navigationTitle("📊 Statistiques")
            .refreshable {
                budgetManager.loadData()
            }
        }
    }
}

struct CategoryExpensesChartView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    
    private var categoryData: [CategoryExpense] {
        TransactionCategory.allCases.compactMap { category in
            let amount = budgetManager.depensesParCategorie(category)
            return amount > 0 ? CategoryExpense(category: category, amount: amount) : nil
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("📊 Dépenses par catégorie")
                .font(.headline)
                .fontWeight(.bold)
            
            if categoryData.isEmpty {
                Text("Aucune donnée disponible")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            } else {
                Chart(categoryData, id: \.category) { item in
                    BarMark(
                        x: .value("Montant", item.amount),
                        y: .value("Catégorie", String(item.category.displayName.dropFirst(2)))  // ← CORRECTION: String()
                    )
                    .foregroundStyle(item.category.color)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(format: .currency(code: "EUR"))
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct PayerContributionChartView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    
    private var payerData: [PayerContribution] {
        var contributions: [Payer: Double] = [:]
        
        for transaction in budgetManager.transactions {
            contributions[transaction.payer, default: 0] += transaction.amount
        }
        
        return contributions.compactMap { payer, amount in
            amount > 0 ? PayerContribution(payer: payer, amount: amount) : nil
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("💰 Répartition des contributions")
                .font(.headline)
                .fontWeight(.bold)
            
            if payerData.isEmpty {
                Text("Aucune donnée disponible")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            } else {
                Chart(payerData, id: \.payer) { item in
                    SectorMark(
                        angle: .value("Montant", item.amount),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(payerColor(item.payer))
                    .opacity(0.8)
                }
                .frame(height: 200)
                .chartLegend(position: .bottom)
                // ← SUPPRESSION: .chartAngleSelection(value: .constant(nil))
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func payerColor(_ payer: Payer) -> Color {
        switch payer {
        case .pilou: return .blue
        case .doudou: return .purple
        case .commun: return .green
        }
    }
}

struct MonthlyTrendsChartView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    
    private var monthlyData: [MonthlyExpense] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "fr_FR")
        dateFormatter.dateFormat = "MMMM yyyy"
        
        var monthlyTotals: [String: Double] = [:]
        
        for transaction in budgetManager.transactions {
            let monthKey = dateFormatter.string(from: transaction.date)
            monthlyTotals[monthKey, default: 0] += transaction.amount
        }
        
        return monthlyTotals.map { month, amount in
            MonthlyExpense(month: month, amount: amount)
        }.sorted { month1, month2 in
            // Tri par date pour avoir un ordre chronologique correct
            let date1 = dateFormatter.date(from: month1.month) ?? Date()
            let date2 = dateFormatter.date(from: month2.month) ?? Date()
            return date1 < date2
        }.suffix(6)  // Garder les 6 derniers mois
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("📈 Évolution des dépenses sur 6 mois")
                .font(.headline)
                .fontWeight(.bold)
            
            if monthlyData.isEmpty {
                Text("Aucune donnée disponible")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            } else {
                Chart(monthlyData, id: \.month) { item in
                    LineMark(
                        x: .value("Mois", item.month),
                        y: .value("Montant", item.amount)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    AreaMark(
                        x: .value("Mois", item.month),
                        y: .value("Montant", item.amount)
                    )
                    .foregroundStyle(.blue.opacity(0.1))
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(format: .currency(code: "EUR"))
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct MonthlyReportView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    
    private var currentMonthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }
    
    private var monthlyTransactions: [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        return budgetManager.transactions.filter { transaction in
            calendar.isDate(transaction.date, equalTo: now, toGranularity: .month)
        }
    }
    
    private var totalDepenses: Double {
        monthlyTransactions.reduce(0) { $0 + $1.amount }
    }
    
    private var economie: Double {
        budgetManager.totalBudgets - totalDepenses
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("📋 Rapport pour \(currentMonthName)")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                HStack {
                    Text("💰 Budget total alloué:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(budgetManager.totalBudgets.formatted(.currency(code: "EUR")))
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text("💸 Dépenses réelles:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(totalDepenses.formatted(.currency(code: "EUR")))
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                
                Divider()
                
                HStack {
                    Text(economie >= 0 ? "💚 Économie:" : "🔴 Dépassement:")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(abs(economie).formatted(.currency(code: "EUR")))
                        .fontWeight(.bold)
                        .foregroundColor(economie >= 0 ? .green : .red)
                }
                
                HStack {
                    Text("📊 Nombre de transactions:")
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(monthlyTransactions.count)")
                        .fontWeight(.bold)
                }
                
                if !monthlyTransactions.isEmpty {
                    HStack {
                        Text("💳 Dépense moyenne:")
                            .fontWeight(.medium)
                        Spacer()
                        Text((totalDepenses / Double(monthlyTransactions.count)).formatted(.currency(code: "EUR")))
                            .fontWeight(.bold)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// Structures pour les graphiques - Ajout de conformité à Hashable pour éviter les problèmes
struct CategoryExpense: Hashable {
    let category: TransactionCategory
    let amount: Double
}

struct PayerContribution: Hashable {
    let payer: Payer
    let amount: Double
}

struct MonthlyExpense: Hashable {
    let month: String
    let amount: Double
}
