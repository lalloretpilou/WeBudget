// ContentView.swift - Version mise à jour avec polices Space Grotesk
import SwiftUI

struct ContentView: View {
    @StateObject var budgetManager = BudgetManager()
    
    var body: some View {
        Group {
            if budgetManager.isAuthenticated {
                TabView {
                    DashboardView()
                        .tabItem {
                            Image(systemName: "house.fill")
                            Text("Dashboard")
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

// Extension pour ajouter les nouvelles sections au DashboardView
extension DashboardView {
    var enhancedBody: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Widget météo en haut
                    WeatherWidget()
                        .environmentObject(weatherManager)
                    
                    // NOUVELLE SECTION: Aperçu des dépenses récurrentes
                    RecurringExpensesOverviewCard()
                    
                    // NOUVELLE SECTION: Aperçu des objectifs d'épargne
                    SavingsGoalsOverviewCard()
                    
                    // Statistiques principales (existant)
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

// NOUVELLES VUES pour le Dashboard
struct RecurringExpensesOverviewCard: View {
    @EnvironmentObject var budgetManager: BudgetManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Dépenses récurrentes")
                    .font(.appHeadline) // Space Grotesk SemiBold
                    .fontWeight(.bold)
                
                Spacer()
                
                NavigationLink("Voir tout") {
                    RecurringExpensesView()
                }
                .font(.appCaption) // Space Grotesk Regular
                .foregroundColor(.blue)
            }
            
            if budgetManager.recurringExpenses.isEmpty {
                HStack {
                    Image(systemName: "arrow.clockwise.circle")
                        .foregroundColor(.gray)
                    
                    Text("Aucune dépense récurrente configurée")
                        .font(.appCallout) // Space Grotesk Regular
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding()
            } else {
                VStack(spacing: 8) {
                    // Résumé financier
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total mensuel")
                                .font(.appCaption) // Space Grotesk Regular
                                .foregroundColor(.secondary)
                            
                            Text(budgetManager.totalMonthlyRecurring.formatted(.currency(code: "EUR")))
                                .font(.currencyMedium) // Space Grotesk SemiBold
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        if !budgetManager.dueRecurringExpenses.isEmpty {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("À traiter")
                                    .font(.appCaption) // Space Grotesk Regular
                                    .foregroundColor(.secondary)
                                
                                Text("\(budgetManager.dueRecurringExpenses.count)")
                                    .font(.appTitle3) // Space Grotesk SemiBold
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    
                    // Alertes si nécessaire
                    if !budgetManager.dueRecurringExpenses.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            
                            Text("\(budgetManager.dueRecurringExpenses.count) dépense(s) récurrente(s) en attente")
                                .font(.appSubheadline) // Space Grotesk Medium
                                .foregroundColor(.orange)
                            
                            Spacer()
                        }
                        .padding(.top, 4)
                    }
                    
                    // Prochaines échéances
                    let nextExpenses = budgetManager.recurringExpenses
                        .filter { $0.isActive }
                        .sorted { $0.nextDueDate < $1.nextDueDate }
                        .prefix(3)
                    
                    if !nextExpenses.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Prochaines échéances:")
                                .font(.appCaption) // Space Grotesk Regular
                                .foregroundColor(.secondary)
                            
                            ForEach(Array(nextExpenses)) { expense in
                                HStack {
                                    Text(expense.category.icon)
                                        .font(.appCaption) // Space Grotesk Regular
                                    
                                    Text(expense.description)
                                        .font(.appCaption) // Space Grotesk Regular
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    Text(expense.nextDueDate.formatted(.dateTime.day().month()))
                                        .font(.appCaption2) // Space Grotesk Light
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
}

struct SavingsGoalsOverviewCard: View {
    @EnvironmentObject var budgetManager: BudgetManager
    
    private var activeGoals: [SavingsGoal] {
        budgetManager.savingsGoals.filter { $0.isActive }
    }
    
    private var totalTargetAmount: Double {
        activeGoals.reduce(0) { $0 + $1.targetAmount }
    }
    
    private var totalCurrentAmount: Double {
        activeGoals.reduce(0) { $0 + $1.currentAmount }
    }
    
    private var overallProgress: Double {
        guard totalTargetAmount > 0 else { return 0 }
        return totalCurrentAmount / totalTargetAmount
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🎯 Objectifs d'épargne")
                    .font(.appHeadline) // Space Grotesk SemiBold
                    .fontWeight(.bold)
                
                Spacer()
                
                NavigationLink("Voir tout") {
                    SavingsGoalsView()
                }
                .font(.appCaption) // Space Grotesk Regular
                .foregroundColor(.blue)
            }
            
            if activeGoals.isEmpty {
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(.gray)
                    
                    Text("Aucun objectif d'épargne configuré")
                        .font(.appCallout) // Space Grotesk Regular
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding()
            } else {
                VStack(spacing: 12) {
                    // Progression globale
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Épargné")
                                .font(.appCaption) // Space Grotesk Regular
                                .foregroundColor(.secondary)
                            
                            Text(totalCurrentAmount.formatted(.currency(code: "EUR")))
                                .font(.currencyMedium) // Space Grotesk SemiBold
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Objectif")
                                .font(.appCaption) // Space Grotesk Regular
                                .foregroundColor(.secondary)
                            
                            Text(totalTargetAmount.formatted(.currency(code: "EUR")))
                                .font(.currencyMedium) // Space Grotesk SemiBold
                                .fontWeight(.bold)
                        }
                    }
                    
                    // Barre de progression
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Progression globale")
                                .font(.appSubheadline) // Space Grotesk Medium
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("\(Int(overallProgress * 100))%")
                                .font(.appSubheadline) // Space Grotesk Medium
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        
                        ProgressView(value: overallProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .scaleEffect(y: 1.5)
                    }
                    
                    // Alertes pour objectifs en retard
                    if !budgetManager.behindScheduleGoals.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            
                            Text("\(budgetManager.behindScheduleGoals.count) objectif(s) en retard")
                                .font(.appSubheadline) // Space Grotesk Medium
                                .foregroundColor(.orange)
                            
                            Spacer()
                        }
                    }
                    
                    // Objectifs prioritaires
                    let priorityGoals = activeGoals
                        .filter { $0.priority == .high || $0.priority == .urgent }
                        .prefix(2)
                    
                    if !priorityGoals.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Objectifs prioritaires:")
                                .font(.appCaption) // Space Grotesk Regular
                                .foregroundColor(.secondary)
                            
                            ForEach(Array(priorityGoals)) { goal in
                                HStack {
                                    Text(goal.category.icon)
                                        .font(.appCaption) // Space Grotesk Regular
                                    
                                    Text(goal.name)
                                        .font(.appCaption) // Space Grotesk Regular
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(goal.progressPercentage * 100))%")
                                        .font(.appCaption2) // Space Grotesk Light
                                        .foregroundColor(goal.status.color)
                                    
                                    Circle()
                                        .fill(goal.priority.color)
                                        .frame(width: 6, height: 6)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(12)
    }
}

// Mise à jour des alertes pour inclure les nouvelles fonctionnalités
extension AlertsView {
    var enhancedAlerts: [AlertItem] {
        var items: [AlertItem] = []
        
        // Alertes budgets existantes
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
        
        // NOUVELLES ALERTES: Dépenses récurrentes
        if !budgetManager.dueRecurringExpenses.isEmpty {
            items.append(AlertItem(
                type: .warning,
                message: "♻️ \(budgetManager.dueRecurringExpenses.count) dépense(s) récurrente(s) à traiter"
            ))
        }
        
        // NOUVELLES ALERTES: Objectifs d'épargne en retard
        if !budgetManager.behindScheduleGoals.isEmpty {
            items.append(AlertItem(
                type: .warning,
                message: "🎯 \(budgetManager.behindScheduleGoals.count) objectif(s) d'épargne en retard sur la planification"
            ))
        }
        
        // Alertes positives
        let completedGoals = budgetManager.savingsGoals.filter { $0.status == .completed }
        if !completedGoals.isEmpty {
            items.append(AlertItem(
                type: .success,
                message: "🎉 \(completedGoals.count) objectif(s) d'épargne atteint(s) ! Félicitations !"
            ))
        }
        
        // Si pas d'alertes négatives, message positif
        if items.filter({ $0.type != .success }).isEmpty {
            items.append(AlertItem(
                type: .success,
                message: "✅ Tous vos budgets et objectifs sont sous contrôle !"
            ))
        }
        
        return items
    }
}

// MISE À JOUR: Modèles mis à jour
extension Budgets {
    // Inclure les dépenses récurrentes dans le calcul du budget total
    func totalAmountWithRecurring(_ budgetManager: BudgetManager) -> Double {
        return totalAmount + budgetManager.totalMonthlyRecurring
    }
}

// Extension pour les statistiques avancées
extension BudgetManager {
    // Nouvelles métriques pour le dashboard
    var totalMonthlySavingsTarget: Double {
        savingsGoals.filter { $0.isActive }.reduce(0) { $0 + $1.monthlyContribution }
    }
    
    var budgetHealthScore: Double {
        let budgetRespected = TransactionCategory.allCases.filter { progressionBudget($0) <= 1.0 }.count
        let totalCategories = TransactionCategory.allCases.count
        let budgetScore = Double(budgetRespected) / Double(totalCategories)
        
        let savingsOnTrack = savingsGoals.filter { $0.status == .onTrack || $0.status == .completed }.count
        let totalSavings = max(savingsGoals.count, 1)
        let savingsScore = Double(savingsOnTrack) / Double(totalSavings)
        
        return (budgetScore + savingsScore) / 2.0
    }
    
    var nextFinancialMilestone: String? {
        // Prochain objectif d'épargne à atteindre
        let nextGoal = savingsGoals
            .filter { $0.isActive && $0.status != .completed }
            .sorted { $0.targetDate < $1.targetDate }
            .first
        
        if let goal = nextGoal {
            return "🎯 \(goal.name) dans \(goal.monthsRemaining) mois"
        }
        
        // Prochaine dépense récurrente importante
        let nextExpense = recurringExpenses
            .filter { $0.isActive && $0.amount > 100 }
            .sorted { $0.nextDueDate < $1.nextDueDate }
            .first
        
        if let expense = nextExpense {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: expense.nextDueDate).day ?? 0
            return "♻️ \(expense.description) dans \(days) jour\(days > 1 ? "s" : "")"
        }
        
        return nil
    }
}

// Widget de santé financière pour le dashboard
struct FinancialHealthWidget: View {
    @EnvironmentObject var budgetManager: BudgetManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("💊 Santé financière")
                    .font(.appHeadline) // Space Grotesk SemiBold
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(Int(budgetManager.budgetHealthScore * 100))%")
                    .font(.appTitle2) // Space Grotesk SemiBold
                    .fontWeight(.bold)
                    .foregroundColor(healthColor)
            }
            
            ProgressView(value: budgetManager.budgetHealthScore)
                .progressViewStyle(LinearProgressViewStyle(tint: healthColor))
                .scaleEffect(y: 1.5)
            
            HStack {
                Text(healthMessage)
                    .font(.appSubheadline) // Space Grotesk Medium
                    .foregroundColor(healthColor)
                
                Spacer()
            }
            
            if let milestone = budgetManager.nextFinancialMilestone {
                HStack {
                    Image(systemName: "flag.fill")
                        .foregroundColor(.blue)
                    
                    Text("Prochain objectif: \(milestone)")
                        .font(.appCaption) // Space Grotesk Regular
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [healthColor.opacity(0.1), healthColor.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }
    
    private var healthColor: Color {
        if budgetManager.budgetHealthScore >= 0.8 {
            return .green
        } else if budgetManager.budgetHealthScore >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var healthMessage: String {
        if budgetManager.budgetHealthScore >= 0.8 {
            return "Excellente gestion financière !"
        } else if budgetManager.budgetHealthScore >= 0.6 {
            return "Bonne gestion, quelques améliorations possibles"
        } else {
            return "Attention requise sur vos finances"
        }
    }
}
