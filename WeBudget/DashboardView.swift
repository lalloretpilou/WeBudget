// DashboardView.swift - Version Rétro avec ColorExtensions
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    @StateObject var weatherManager = WeatherManager()
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 25) {
                    // Widget météo en haut avec style rétro
                    WeatherWidget()
                        .environmentObject(weatherManager)
                    
                    // NOUVEAU: Widget de santé financière
                    FinancialHealthWidget()
                    
                    // Statistiques principales avec nouveau design
                    StatsCardsView()
                    
                    // Suggestions météo intelligentes
                    WeatherSuggestionsView()
                        .environmentObject(weatherManager)
                    
                    // Progression des budgets avec style rétro
                    BudgetProgressView()
                    
                    // Prédictions de dépenses basées sur la météo
                    ExpensePredictionsView()
                        .environmentObject(weatherManager)
                    
                    // Alertes avec style rétro
                    AlertsView()
                    
                    // Transactions récentes avec nouveau style
                    RecentTransactionsView()
                }
                .padding()
            }
            .background(Color.adaptiveBackground(colorScheme))
            .navigationTitle("Tableau de bord")
            .toolbarBackground(Color.limeToSky, for: .navigationBar)
            .refreshable {
                budgetManager.loadData()
                weatherManager.loadWeather()
            }
        }
    }
}

// MARK: - Widget de Santé Financière Rétro
struct FinancialHealthWidget: View {
    @EnvironmentObject var budgetManager: BudgetManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("💊 Santé Financière")
                        .font(.appHeadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.adaptiveText(colorScheme))
                    
                    Text(budgetManager.santeBudgetaire.message)
                        .font(.appSubheadline)
                        .foregroundColor(budgetManager.santeBudgetaire.color)
                }
                
                Spacer()
                
                // Score circulaire basé sur la santé budgétaire
                ZStack {
                    Circle()
                        .stroke(budgetManager.santeBudgetaire.color.opacity(0.2), lineWidth: 8)
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .trim(from: 0, to: healthScorePercentage)
                        .stroke(
                            AngularGradient(
                                colors: [budgetManager.santeBudgetaire.color, budgetManager.santeBudgetaire.color.opacity(0.6)],
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                    
                    Image(systemName: budgetManager.santeBudgetaire.icon)
                        .font(.title2)
                        .foregroundColor(budgetManager.santeBudgetaire.color)
                }
            }
            
            // Détail des calculs
            VStack(spacing: 8) {
                HStack {
                    Text("💰 Revenus totaux:")
                        .font(.appCaption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(budgetManager.totalRevenus.formatted(.currency(code: "EUR")))
                        .font(.appCaption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("📊 Charges communes:")
                        .font(.appCaption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(budgetManager.totalBudgets.formatted(.currency(code: "EUR")))
                        .font(.appCaption)
                        .fontWeight(.medium)
                }
                
                if budgetManager.totalMonthlyRecurring > 0 {
                    HStack {
                        Text("🔄 Dépenses récurrentes:")
                            .font(.appCaption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(budgetManager.totalMonthlyRecurring.formatted(.currency(code: "EUR")))
                            .font(.appCaption)
                            .fontWeight(.medium)
                    }
                }
                
                if budgetManager.totalMonthlySavingsGoals > 0 {
                    HStack {
                        Text("🎯 Épargne mensuelle:")
                            .font(.appCaption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(budgetManager.totalMonthlySavingsGoals.formatted(.currency(code: "EUR")))
                            .font(.appCaption)
                            .fontWeight(.medium)
                    }
                }
                
                Divider()
                
                HStack {
                    Text("💳 Redistribution Pilou:")
                        .font(.appSubheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text(budgetManager.redistributionPilou.formatted(.currency(code: "EUR")))
                        .font(.currencySmall)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Text("💳 Redistribution Doudou:")
                        .font(.appSubheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.purple)
                    
                    Spacer()
                    
                    Text(budgetManager.redistributionDoudou.formatted(.currency(code: "EUR")))
                        .font(.currencySmall)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(budgetManager.santeBudgetaire.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(budgetManager.santeBudgetaire.color.opacity(0.4), lineWidth: 1.5)
                )
        )
        .shadow(color: budgetManager.santeBudgetaire.color.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    private var healthScorePercentage: Double {
        switch budgetManager.santeBudgetaire {
        case .excellent: return 1.0
        case .bonne: return 0.8
        case .attention: return 0.6
        case .danger: return 0.3
        }
    }
}

// MARK: - StatsCardsView avec design rétro
struct StatsCardsView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 20) {
            RetroStatCard(
                title: "Revenus totaux",
                value: budgetManager.totalRevenus,
                icon: "banknote.fill",
                gradient: Color.limeToSky,
                accentColor: Color.limeElectric
            )
            
            RetroStatCard(
                title: "Dépenses réelles",
                value: budgetManager.depensesMoisCourant,
                icon: "creditcard.fill",
                gradient: Color.pinkDreams,
                accentColor: Color.pinkBubblegum
            )
            
            RetroStatCard(
                title: "Charges communes",
                value: budgetManager.totalBudgets,
                icon: "house.fill",
                gradient: Color.sunsetGlow,
                accentColor: Color.peachSunset
            )
            
            // Nouvelle carte pour la redistribution
            RetroStatCard(
                title: "À redistribuer",
                value: budgetManager.resteDisponible,
                icon: "arrow.branch",
                gradient: budgetManager.resteDisponible >= 0 ? Color.limeToSky : Color.pinkDreams,
                accentColor: budgetManager.resteDisponible >= 0 ? Color.limeElectric : Color.softCoral
            )
        }
    }
}

struct RetroStatCard: View {
    let title: String
    let value: Double
    let icon: String
    let gradient: LinearGradient
    let accentColor: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // Icône avec fond rétro
                ZStack {
                    Circle()
                        .fill(gradient)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .foregroundColor(Color.brownDeep)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                // Indicateur de tendance
                Image(systemName: value >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .foregroundColor(accentColor)
                    .font(.caption)
                    .fontWeight(.bold)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(value.formatted(.currency(code: "EUR")))
                    .font(.currencyMedium)
                    .fontWeight(.bold)
                    .foregroundColor(Color.adaptiveText(colorScheme))
                
                Text(title)
                    .font(.appFootnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.adaptiveSurface(colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(accentColor.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: accentColor.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

// MARK: - BudgetProgressView avec style rétro
struct BudgetProgressView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("🎯 Suivi des budgets")
                    .font(.appTitle3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.adaptiveText(colorScheme))
                
                Spacer()
                
                // Badge du mois courant
                Text(Date().formatted(.dateTime.month(.wide)))
                    .font(.appCaption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.skyBlueRetro.opacity(0.2))
                    .foregroundColor(Color.skyBlueRetro)
                    .cornerRadius(12)
            }
            
            ForEach(TransactionCategory.allCases, id: \.self) { category in
                RetroBudgetProgressRow(category: category)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.adaptiveSurface(colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.plumVintage.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: Color.plumVintage.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct RetroBudgetProgressRow: View {
    @EnvironmentObject var budgetManager: BudgetManager
    let category: TransactionCategory
    @Environment(\.colorScheme) private var colorScheme
    
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
    
    var categoryColor: Color {
        switch category {
        case .alimentation: return Color.limeElectric
        case .loyer: return Color.skyBlueRetro
        case .abonnements: return Color.plumVintage
        case .habitation: return Color.peachSunset
        case .sorties: return Color.pinkBubblegum
        case .credits: return Color.richBrown
        case .epargne: return Color.khakiGold
        case .transports: return Color.turquoiseVintage
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // Icône de catégorie avec style rétro
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(categoryColor.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Text(category.icon)
                        .font(.title3)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.displayName.dropFirst(2))
                        .font(.appSubheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.adaptiveText(colorScheme))
                    
                    Text("Reste: \(remaining.formatted(.currency(code: "EUR")))")
                        .font(.appCaption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(spent.formatted(.currency(code: "EUR")))")
                        .font(.currencySmall)
                        .fontWeight(.bold)
                        .foregroundColor(progressColor)
                    
                    Text("/ \(budget.formatted(.currency(code: "EUR")))")
                        .font(.appCaption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Barre de progression rétro
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(categoryColor.opacity(0.15))
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [categoryColor, categoryColor.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, CGFloat(min(progress, 1.0)) * 300), height: 8)
                
                // Effet de surbrillance
                if progress > 1.0 {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.softCoral)
                        .frame(width: 300, height: 8)
                        .opacity(0.8)
                }
            }
            
            // Pourcentage avec style rétro
            HStack {
                Text("\(Int(progress * 100))%")
                    .font(.appCaption)
                    .fontWeight(.bold)
                    .foregroundColor(progressColor)
                
                Spacer()
                
                if progress > 1.0 {
                    Text("DÉPASSÉ")
                        .font(.appCaption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.softCoral.opacity(0.2))
                        .foregroundColor(Color.softCoral)
                        .cornerRadius(6)
                } else if progress > 0.9 {
                    Text("ATTENTION")
                        .font(.appCaption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.peachSunset.opacity(0.2))
                        .foregroundColor(Color.peachSunset)
                        .cornerRadius(6)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(categoryColor.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(categoryColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    var progressColor: Color {
        if progress > 1.0 { return Color.softCoral }
        if progress > 0.9 { return Color.peachSunset }
        return categoryColor
    }
}

// MARK: - AlertsView avec style rétro
struct AlertsView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    @Environment(\.colorScheme) private var colorScheme
    
    var alerts: [RetroAlertItem] {
        var items: [RetroAlertItem] = []
        
        for category in TransactionCategory.allCases {
            let progress = budgetManager.progressionBudget(category)
            
            if progress > 1.0 {
                items.append(RetroAlertItem(
                    type: .danger,
                    title: "Budget dépassé",
                    message: "\(category.displayName.dropFirst(2)) : +\(((progress - 1.0) * 100).formatted(.number.precision(.fractionLength(1))))%",
                    icon: "exclamationmark.triangle.fill"
                ))
            } else if progress > 0.9 {
                items.append(RetroAlertItem(
                    type: .warning,
                    title: "Attention budget",
                    message: "\(category.displayName.dropFirst(2)) à \((progress * 100).formatted(.number.precision(.fractionLength(1))))%",
                    icon: "eye.fill"
                ))
            }
        }
        
        if items.isEmpty {
            items.append(RetroAlertItem(
                type: .success,
                title: "Tout va bien !",
                message: "Tous vos budgets sont sous contrôle",
                icon: "checkmark.circle.fill"
            ))
        }
        
        return items
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("🔔 Alertes")
                    .font(.appTitle3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.adaptiveText(colorScheme))
                
                Spacer()
                
                Text("\(alerts.count)")
                    .font(.appCaption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.limeElectric.opacity(0.2))
                    .foregroundColor(Color.limeElectric)
                    .cornerRadius(8)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(alerts) { alert in
                    RetroAlertCard(alert: alert)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.adaptiveSurface(colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.limeElectric.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: Color.limeElectric.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct RetroAlertItem: Identifiable {
    let id = UUID()
    let type: RetroAlertType
    let title: String
    let message: String
    let icon: String
}

struct RetroAlertCard: View {
    let alert: RetroAlertItem
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Icône avec fond coloré
            ZStack {
                Circle()
                    .fill(alert.type.accentColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: alert.icon)
                    .foregroundColor(alert.type.accentColor)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.title)
                    .font(.appSubheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.adaptiveText(colorScheme))
                
                Text(alert.message)
                    .font(.appCaption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(alert.type.backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(alert.type.accentColor.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

// MARK: - RecentTransactionsView avec style rétro
struct RecentTransactionsView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    @Environment(\.colorScheme) private var colorScheme
    
    var recentTransactions: [Transaction] {
        Array(budgetManager.transactions.prefix(5))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("💳 Transactions récentes")
                    .font(.appTitle3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.adaptiveText(colorScheme))
                
                Spacer()
                
                NavigationLink("Voir tout") {
                    TransactionsView()
                }
                .font(.appCaption)
                .fontWeight(.semibold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.turquoiseVintage.opacity(0.2))
                .foregroundColor(Color.turquoiseVintage)
                .cornerRadius(12)
            }
            
            if recentTransactions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "creditcard.trianglebadge.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundColor(Color.dimGray)
                    
                    Text("Aucune transaction")
                        .font(.appBody)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(30)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(recentTransactions) { transaction in
                        RetroTransactionRowView(transaction: transaction)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.adaptiveSurface(colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.turquoiseVintage.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: Color.turquoiseVintage.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct RetroTransactionRowView: View {
    let transaction: Transaction
    @Environment(\.colorScheme) private var colorScheme
    
    private var categoryColor: Color {
        switch transaction.category {
        case .alimentation: return Color.limeElectric
        case .loyer: return Color.skyBlueRetro
        case .abonnements: return Color.plumVintage
        case .habitation: return Color.peachSunset
        case .sorties: return Color.pinkBubblegum
        case .credits: return Color.richBrown
        case .epargne: return Color.khakiGold
        case .transports: return Color.turquoiseVintage
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icône de catégorie stylée
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(categoryColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Text(transaction.category.icon)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.appSubheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.adaptiveText(colorScheme))
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(transaction.category.displayName.dropFirst(2))
                        .font(.appCaption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(categoryColor.opacity(0.15))
                        .foregroundColor(categoryColor)
                        .cornerRadius(6)
                    
                    Text(transaction.payer.displayName.dropFirst(2))
                        .font(.appCaption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("-\(transaction.amount.formatted(.currency(code: "EUR")))")
                    .font(.currencySmall)
                    .fontWeight(.bold)
                    .foregroundColor(Color.softCoral)
                
                Text(transaction.date.formatted(.dateTime.day().month().year()))
                    .font(.appCaption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(categoryColor.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(categoryColor.opacity(0.1), lineWidth: 1)
                )
        )
    }
}
