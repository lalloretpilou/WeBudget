//
//  SavingsGoalDetailView.swift
//  WeBudget
//
//  Created by Pierre-Louis L'ALLORET on 15/09/2025.
//

import SwiftUI
import Charts

struct SavingsGoalDetailView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    let goal: SavingsGoal
    @State private var showingAddContribution = false
    @State private var showingEditGoal = false
    @Environment(\.colorScheme) private var colorScheme
    
    private var contributions: [SavingsContribution] {
        budgetManager.savingsContributions
            .filter { $0.goalId == goal.id }
            .sorted { $0.date > $1.date }
    }
    
    private var monthlyContributions: [(String, Double)] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "fr_FR")
        dateFormatter.dateFormat = "MMM yyyy"
        
        var monthlyTotals: [String: Double] = [:]
        
        for contribution in contributions {
            let monthKey = dateFormatter.string(from: contribution.date)
            monthlyTotals[monthKey, default: 0] += contribution.amount
        }
        
        return monthlyTotals.map { ($0.key, $0.value) }
            .sorted { month1, month2 in
                let date1 = dateFormatter.date(from: month1.0) ?? Date()
                let date2 = dateFormatter.date(from: month2.0) ?? Date()
                return date1 < date2
            }
            .suffix(6)
    }
    
    private var goalCategoryColor: Color {
        switch goal.category {
        case .general: return Color.limeElectric
        case .vacation: return Color.pinkBubblegum
        case .emergency: return Color.softCoral
        case .home: return Color.skyBlueRetro
        case .education: return Color.plumVintage
        case .car: return Color.turquoiseVintage
        case .retirement: return Color.khakiGold
        case .electronics: return Color.peachSunset
        case .wedding: return Color.powderPink
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 25) {
                // En-tête avec informations principales
                GoalHeaderView(goal: goal)
                
                // Graphique de progression
                if !monthlyContributions.isEmpty {
                    MonthlyContributionsChartView(data: monthlyContributions, goalColor: goalCategoryColor)
                }
                
                // Statistiques détaillées
                GoalStatisticsView(goal: goal, contributions: contributions)
                
                // Actions rapides
                QuickActionsView(goal: goal, showingAddContribution: $showingAddContribution)
                
                // Historique des contributions
                ContributionsHistoryView(contributions: contributions)
                
                // Conseils et recommandations
                GoalRecommendationsView(goal: goal)
            }
            .padding()
        }
        .background(Color.adaptiveBackground(colorScheme))
        .navigationTitle(goal.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(goalCategoryColor.opacity(0.1), for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Modifier") {
                    showingEditGoal = true
                }
                .font(.buttonText) // Space Grotesk Medium
                .foregroundColor(goalCategoryColor)
            }
        }
        .sheet(isPresented: $showingAddContribution) {
            AddContributionView(goalId: goal.id, goalName: goal.name)
        }
        .sheet(isPresented: $showingEditGoal) {
            EditSavingsGoalView(goal: goal)
        }
    }
}

// MARK: - Vues pour ajouter une contribution
struct AddContributionView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let goalId: UUID
    let goalName: String
    
    @State private var amount = ""
    @State private var date = Date()
    @State private var note = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.khakiGold.opacity(0.15))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "eurosign.circle.fill")
                                .foregroundColor(Color.khakiGold)
                                .font(.title3)
                        }
                        
                        Text("Montant")
                            .font(.appBody)
                        
                        Spacer()
                        
                        TextField("0,00", text: $amount)
                            .font(.currencyMedium)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.adaptiveSurface(colorScheme))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.khakiGold.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .frame(width: 120)
                        
                        Text("€")
                            .font(.appCallout)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.skyBlueRetro.opacity(0.15))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "calendar")
                                .foregroundColor(Color.skyBlueRetro)
                                .font(.title3)
                        }
                        
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .font(.appBody)
                            .labelsHidden()
                    }
                    
                    HStack(alignment: .top) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.plumVintage.opacity(0.15))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "note.text")
                                .foregroundColor(Color.plumVintage)
                                .font(.title3)
                        }
                        
                        TextField("Note (optionnel)", text: $note, axis: .vertical)
                            .font(.appBody)
                            .lineLimit(3)
                    }
                    
                } header: {
                    HStack {
                        Text("💰 Nouvelle contribution")
                            .font(.appHeadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.adaptiveText(colorScheme))
                        
                        Spacer()
                        
                        Image(systemName: isFormValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundColor(isFormValid ? Color.limeElectric : Color.softCoral)
                            .font(.title3)
                    }
                }
                .listRowBackground(Color.adaptiveSurface(colorScheme))
                
                Section {
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.limeElectric.opacity(0.15))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "target")
                                .foregroundColor(Color.limeElectric)
                                .font(.title3)
                        }
                        
                        Text("Nom de l'objectif:")
                            .font(.appBody)
                        
                        Spacer()
                        
                        Text(goalName)
                            .font(.appBody)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("🎯 Objectif concerné")
                        .font(.appHeadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.adaptiveText(colorScheme))
                }
                .listRowBackground(Color.adaptiveSurface(colorScheme))
            }
            .scrollContentBackground(.hidden)
            .background(Color.adaptiveBackground(colorScheme))
            .navigationTitle("Ajouter contribution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.limeElectric.opacity(0.1), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .font(.buttonText)
                    .foregroundColor(Color.softCoral)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Ajouter") {
                        addContribution()
                    }
                    .font(.buttonText)
                    .fontWeight(.semibold)
                    .foregroundColor(isFormValid ? Color.limeElectric : .secondary)
                    .disabled(!isFormValid)
                }
            }
            .alert("Erreur", isPresented: $showingAlert) {
                Button("OK") {
                    // Action OK
                }
                .font(.buttonText)
            } message: {
                Text(alertMessage)
                    .font(.appCallout)
            }
        }
    }
    
    private var isFormValid: Bool {
        !amount.isEmpty && (Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0) > 0
    }
    
    private func addContribution() {
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) else {
            alertMessage = "Montant invalide"
            showingAlert = true
            return
        }
        
        guard amountValue > 0 else {
            alertMessage = "Le montant doit être supérieur à 0"
            showingAlert = true
            return
        }
        
        let noteText = note.trimmingCharacters(in: .whitespacesAndNewlines)
        budgetManager.addContributionToGoal(
            goalId,
            amount: amountValue,
            note: noteText.isEmpty ? nil : noteText
        )
        
        dismiss()
    }
}

// MARK: - Vue pour éditer un objectif
struct EditSavingsGoalView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let goal: SavingsGoal
    
    @State private var name: String
    @State private var description: String
    @State private var targetAmount: String
    @State private var targetDate: Date
    @State private var selectedCategory: GoalCategory
    @State private var selectedPriority: GoalPriority
    @State private var monthlyContribution: String
    @State private var isActive: Bool
    
    init(goal: SavingsGoal) {
        self.goal = goal
        _name = State(initialValue: goal.name)
        _description = State(initialValue: goal.description)
        _targetAmount = State(initialValue: String(goal.targetAmount))
        _targetDate = State(initialValue: goal.targetDate)
        _selectedCategory = State(initialValue: goal.category)
        _selectedPriority = State(initialValue: goal.priority)
        _monthlyContribution = State(initialValue: String(goal.monthlyContribution))
        _isActive = State(initialValue: goal.isActive)
    }
    
    private var categoryColor: Color {
        switch selectedCategory {
        case .general: return Color.limeElectric
        case .vacation: return Color.pinkBubblegum
        case .emergency: return Color.softCoral
        case .home: return Color.skyBlueRetro
        case .education: return Color.plumVintage
        case .car: return Color.turquoiseVintage
        case .retirement: return Color.khakiGold
        case .electronics: return Color.peachSunset
        case .wedding: return Color.powderPink
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Nom de l'objectif", text: $name)
                        .font(.appBody)
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .font(.appBody)
                        .lineLimit(2...4)
                    
                    Picker("Catégorie", selection: $selectedCategory) {
                        ForEach(GoalCategory.allCases, id: \.self) { category in
                            HStack {
                                Text(category.icon)
                                Text(category.displayName.dropFirst(2))
                            }
                            .font(.appBody)
                            .tag(category)
                        }
                    }
                    .font(.appBody)
                    
                    Picker("Priorité", selection: $selectedPriority) {
                        ForEach(GoalPriority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(priorityColorForSelection(priority))
                                    .frame(width: 12, height: 12)
                                Text(priority.displayName.dropFirst(2))
                            }
                            .font(.appBody)
                            .tag(priority)
                        }
                    }
                    .font(.appBody)
                    
                    Toggle("Objectif actif", isOn: $isActive)
                        .font(.appBody)
                        .tint(Color.limeElectric)
                    
                } header: {
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(categoryColor.opacity(0.15))
                                .frame(width: 24, height: 24)
                            
                            Text(selectedCategory.icon)
                                .font(.title3)
                        }
                        
                        Text("🎯 Informations de l'objectif")
                            .font(.appHeadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.adaptiveText(colorScheme))
                    }
                }
                .listRowBackground(Color.adaptiveSurface(colorScheme))
                
                Section {
                    HStack {
                        Text("Objectif")
                            .font(.appBody)
                        Spacer()
                        TextField("Montant", text: $targetAmount)
                            .font(.currencySmall)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.adaptiveSurface(colorScheme))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.khakiGold.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .frame(width: 120)
                        Text("€")
                            .font(.appCallout)
                    }
                    
                    DatePicker("Date cible", selection: $targetDate, displayedComponents: .date)
                        .font(.appBody)
                    
                    HStack {
                        Text("Contribution mensuelle")
                            .font(.appBody)
                        Spacer()
                        TextField("Montant", text: $monthlyContribution)
                            .font(.currencySmall)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.adaptiveSurface(colorScheme))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.limeElectric.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .frame(width: 120)
                        Text("€")
                            .font(.appCallout)
                    }
                    
                } header: {
                    Text("💰 Montants et échéance")
                        .font(.appHeadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.adaptiveText(colorScheme))
                }
                .listRowBackground(Color.adaptiveSurface(colorScheme))
            }
            .scrollContentBackground(.hidden)
            .background(Color.adaptiveBackground(colorScheme))
            .navigationTitle("Modifier objectif")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(categoryColor.opacity(0.1), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .font(.buttonText)
                    .foregroundColor(Color.softCoral)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sauvegarder") {
                        updateGoal()
                    }
                    .font(.buttonText)
                    .fontWeight(.semibold)
                    .foregroundColor(categoryColor)
                }
            }
        }
    }
    
    private func priorityColorForSelection(_ priority: GoalPriority) -> Color {
        switch priority {
        case .low: return Color.dimGray
        case .medium: return Color.skyBlueRetro
        case .high: return Color.peachSunset
        case .urgent: return Color.softCoral
        }
    }
    
    private func updateGoal() {
        let updatedGoal = SavingsGoal(
            id: goal.id,
            name: name,
            description: description,
            targetAmount: Double(targetAmount.replacingOccurrences(of: ",", with: ".")) ?? goal.targetAmount,
            currentAmount: goal.currentAmount,
            startDate: goal.startDate,
            targetDate: targetDate,
            category: selectedCategory,
            priority: selectedPriority,
            monthlyContribution: Double(monthlyContribution.replacingOccurrences(of: ",", with: ".")) ?? goal.monthlyContribution,
            isActive: isActive
        )
        
        budgetManager.updateSavingsGoal(updatedGoal)
        dismiss()
    }
}

struct GoalHeaderView: View {
    let goal: SavingsGoal
    @Environment(\.colorScheme) private var colorScheme
    
    private var categoryColor: Color {
        switch goal.category {
        case .general: return Color.limeElectric
        case .vacation: return Color.pinkBubblegum
        case .emergency: return Color.softCoral
        case .home: return Color.skyBlueRetro
        case .education: return Color.plumVintage
        case .car: return Color.turquoiseVintage
        case .retirement: return Color.khakiGold
        case .electronics: return Color.peachSunset
        case .wedding: return Color.powderPink
        }
    }
    
    private var priorityColor: Color {
        switch goal.priority {
        case .low: return Color.dimGray
        case .medium: return Color.skyBlueRetro
        case .high: return Color.peachSunset
        case .urgent: return Color.softCoral
        }
    }
    
    private var statusColor: Color {
        switch goal.status {
        case .onTrack: return Color.limeElectric
        case .behindSchedule: return Color.peachSunset
        case .completed: return Color.limeElectric
        case .expired: return Color.softCoral
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Icône et badges de statut
            HStack {
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.15))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .stroke(categoryColor.opacity(0.3), lineWidth: 2)
                        )
                    
                    Text(goal.category.icon)
                        .font(.system(size: 40))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    // Badge de statut
                    HStack(spacing: 6) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        
                        Text(goal.status.displayName.dropFirst(2))
                            .font(.appSubheadline)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(statusColor.opacity(0.15))
                    .foregroundColor(statusColor.darker(by: 0.2))
                    .cornerRadius(15)
                    
                    // Badge de priorité
                    HStack(spacing: 6) {
                        Image(systemName: priorityIcon)
                            .font(.caption)
                        
                        Text(goal.priority.displayName.dropFirst(2))
                            .font(.appCaption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(priorityColor.opacity(0.15))
                    .foregroundColor(priorityColor.darker(by: 0.2))
                    .cornerRadius(12)
                }
            }
            
            // Progression principale avec design rétro
            VStack(spacing: 12) {
                HStack {
                    Text("🎯 Progression")
                        .font(.appTitle3)
                        .fontWeight(.bold)
                        .foregroundColor(Color.adaptiveText(colorScheme))
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(categoryColor.opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        Text("\(Int(goal.progressPercentage * 100))%")
                            .font(.appHeadline)
                            .fontWeight(.bold)
                            .foregroundColor(categoryColor)
                    }
                }
                
                // Barre de progression rétro
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(categoryColor.opacity(0.1))
                        .frame(height: 16)
                    
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [categoryColor, categoryColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, CGFloat(min(goal.progressPercentage, 1.0)) * 300), height: 16)
                    
                    // Effet de surbrillance
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.3))
                        .frame(width: max(0, CGFloat(min(goal.progressPercentage, 1.0)) * 300), height: 8)
                        .offset(y: -2)
                }
                
                HStack {
                    Text(goal.currentAmount.formatted(.currency(code: "EUR")))
                        .font(.currencyLarge)
                        .fontWeight(.bold)
                        .foregroundColor(Color.limeElectric)
                    
                    Spacer()
                    
                    Text(goal.targetAmount.formatted(.currency(code: "EUR")))
                        .font(.currencyMedium)
                        .fontWeight(.bold)
                        .foregroundColor(Color.adaptiveText(colorScheme))
                }
            }
            
            // Informations temporelles avec style rétro
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(Color.skyBlueRetro)
                        Text("Temps restant")
                            .font(.appSubheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color.adaptiveText(colorScheme))
                    }
                    
                    if goal.monthsRemaining > 0 {
                        Text("\(goal.monthsRemaining) mois")
                            .font(.appTitle2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.skyBlueRetro)
                    } else if goal.status == .completed {
                        Text("Terminé!")
                            .font(.appTitle2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.limeElectric)
                    } else {
                        Text("Expiré")
                            .font(.appTitle2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.softCoral)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 6) {
                        Text("Reste à épargner")
                            .font(.appSubheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color.adaptiveText(colorScheme))
                        Image(systemName: "target")
                            .foregroundColor(Color.peachSunset)
                    }
                    
                    Text(goal.remainingAmount.formatted(.currency(code: "EUR")))
                        .font(.appTitle2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.peachSunset)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.adaptiveSurface(colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(categoryColor.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: categoryColor.opacity(0.15), radius: 10, x: 0, y: 5)
    }
    
    private var priorityIcon: String {
        switch goal.priority {
        case .low: return "arrow.down"
        case .medium: return "minus"
        case .high: return "arrow.up"
        case .urgent: return "exclamationmark"
        }
    }
}

struct MonthlyContributionsChartView: View {
    let data: [(String, Double)]
    let goalColor: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(goalColor)
                    .font(.title2)
                
                Text("Contributions mensuelles")
                    .font(.appTitle3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.adaptiveText(colorScheme))
                
                Spacer()
                
                Text("6 derniers mois")
                    .font(.appCaption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(goalColor.opacity(0.15))
                    .foregroundColor(goalColor)
                    .cornerRadius(8)
            }
            
            Chart(data, id: \.0) { month, amount in
                BarMark(
                    x: .value("Mois", month),
                    y: .value("Montant", amount)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [goalColor, goalColor.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(6)
            }
            .frame(height: 220)
            .chartYAxis {
                AxisMarks(format: .currency(code: "EUR"))
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.appCaption)
                        //.foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.adaptiveSurface(colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(goalColor.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: goalColor.opacity(0.1), radius: 6, x: 0, y: 3)
    }
}

struct GoalStatisticsView: View {
    let goal: SavingsGoal
    let contributions: [SavingsContribution]
    @Environment(\.colorScheme) private var colorScheme
    
    private var averageMonthlyContribution: Double {
        guard !contributions.isEmpty else { return 0 }
        let total = contributions.reduce(0) { $0 + $1.amount }
        
        let calendar = Calendar.current
        if let firstContribution = contributions.last {
            let months = calendar.dateComponents([.month], from: firstContribution.date, to: Date()).month ?? 1
            return total / Double(max(months, 1))
        }
        
        return total / Double(contributions.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(Color.turquoiseVintage)
                    .font(.title2)
                
                Text("Statistiques détaillées")
                    .font(.appTitle3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.adaptiveText(colorScheme))
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                RetroStatisticCard(
                    title: "Contribution moyenne",
                    value: averageMonthlyContribution.formatted(.currency(code: "EUR")),
                    subtitle: "par mois",
                    icon: "chart.line.uptrend.xyaxis",
                    color: Color.skyBlueRetro
                )
                
                RetroStatisticCard(
                    title: "Contribution requise",
                    value: goal.requiredMonthlyContribution.formatted(.currency(code: "EUR")),
                    subtitle: "pour atteindre l'objectif",
                    icon: "target",
                    color: Color.peachSunset
                )
                
                RetroStatisticCard(
                    title: "Nombre de versements",
                    value: "\(contributions.count)",
                    subtitle: "contributions effectuées",
                    icon: "number.circle",
                    color: Color.limeElectric
                )
                
                if let projectedDate = goal.projectedCompletionDate {
                    RetroStatisticCard(
                        title: "Fin prévue",
                        value: projectedDate.formatted(.dateTime.month().year()),
                        subtitle: "au rythme actuel",
                        icon: "calendar.badge.clock",
                        color: Color.plumVintage
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.adaptiveSurface(colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.turquoiseVintage.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: Color.turquoiseVintage.opacity(0.1), radius: 6, x: 0, y: 3)
    }
}

struct RetroStatisticCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title3)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(value)
                    .font(.currencyMedium)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.appSubheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.adaptiveText(colorScheme))
                
                Text(subtitle)
                    .font(.appCaption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.adaptiveSurface(colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: color.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct QuickActionsView: View {
    let goal: SavingsGoal
    @Binding var showingAddContribution: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(Color.khakiGold)
                    .font(.title2)
                
                Text("Actions rapides")
                    .font(.appTitle3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.adaptiveText(colorScheme))
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                RetroActionButton(
                    title: "Ajouter contribution",
                    icon: "plus.circle.fill",
                    color: Color.limeElectric
                ) {
                    showingAddContribution = true
                }
                
                RetroActionButton(
                    title: "Contribution mensuelle",
                    icon: "calendar.badge.plus",
                    color: Color.skyBlueRetro
                ) {
                    // TODO: Programmer contribution automatique
                }
                
                RetroActionButton(
                    title: "Partager progression",
                    icon: "square.and.arrow.up",
                    color: Color.pinkBubblegum
                ) {
                    // TODO: Partager
                }
                
                RetroActionButton(
                    title: "Calculer intérêts",
                    icon: "percent",
                    color: Color.peachSunset
                ) {
                    // TODO: Calculateur d'intérêts
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.adaptiveSurface(colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.khakiGold.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: Color.khakiGold.opacity(0.1), radius: 6, x: 0, y: 3)
    }
}

struct RetroActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(color.opacity(0.3), lineWidth: 1)
                        )
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.appSubheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.adaptiveText(colorScheme))
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.adaptiveSurface(colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: color.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ContributionsHistoryView: View {
    let contributions: [SavingsContribution]
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "list.bullet.rectangle.fill")
                    .foregroundColor(Color.plumVintage)
                    .font(.title2)
                
                Text("Historique des contributions")
                    .font(.appTitle3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.adaptiveText(colorScheme))
                
                Spacer()
                
                if contributions.count > 5 {
                    Text("(\(contributions.count) au total)")
                        .font(.appCaption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.plumVintage.opacity(0.15))
                        .cornerRadius(6)
                }
            }
            
            if contributions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundColor(Color.dimGray)
                    
                    Text("Aucune contribution")
                        .font(.appSubheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Commencez par ajouter votre première contribution")
                        .font(.appCaption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(30)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(contributions.prefix(5)) { contribution in
                        RetroContributionRowView(contribution: contribution)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.adaptiveSurface(colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.plumVintage.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: Color.plumVintage.opacity(0.1), radius: 6, x: 0, y: 3)
    }
}

struct RetroContributionRowView: View {
    let contribution: SavingsContribution
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(Color.limeElectric.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(Color.limeElectric)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(contribution.amount.formatted(.currency(code: "EUR")))
                    .font(.currencySmall)
                    .fontWeight(.bold)
                    .foregroundColor(Color.limeElectric)
                
                Text(contribution.date.formatted(.dateTime.day().month().year()))
                    .font(.appCaption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let note = contribution.note, !note.isEmpty {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(note)
                        .font(.appCaption)
                        .foregroundColor(Color.adaptiveText(colorScheme))
                        .multilineTextAlignment(.trailing)
                        .lineLimit(2)
                    
                    Image(systemName: "note.text")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.limeElectric.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.limeElectric.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct GoalRecommendationsView: View {
    let goal: SavingsGoal
    @Environment(\.colorScheme) private var colorScheme
    
    private var recommendations: [String] {
        var recs: [String] = []
        
        switch goal.status {
        case .behindSchedule:
            recs.append("💡 Augmentez votre contribution mensuelle de \((goal.requiredMonthlyContribution - goal.monthlyContribution).formatted(.currency(code: "EUR"))) pour rattraper le retard")
            recs.append("🔄 Révisez votre budget pour identifier des économies possibles")
            
        case .onTrack:
            recs.append("✅ Vous êtes en bonne voie ! Maintenez ce rythme")
            recs.append("📈 Considérez placer vos économies sur un livret rémunéré")
            
        case .completed:
            recs.append("🎉 Félicitations ! Objectif atteint")
            recs.append("🎯 Il est temps de définir un nouvel objectif d'épargne")
            
        case .expired:
            recs.append("⏰ Redéfinissez une nouvelle date cible réaliste")
            recs.append("💪 Analysez ce qui a empêché d'atteindre l'objectif initial")
        }
        
        if goal.priority == .urgent {
            recs.append("🚨 Objectif prioritaire : concentrez-vous sur celui-ci en premier")
        }
        
        return recs
    }
    
    var body: some View {
        if !recommendations.isEmpty {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(Color.khakiGold)
                        .font(.title2)
                    
                    Text("Recommandations")
                        .font(.appTitle3)
                        .fontWeight(.bold)
                        .foregroundColor(Color.adaptiveText(colorScheme))
                }
                
                LazyVStack(alignment: .leading, spacing: 15) {
                    ForEach(recommendations, id: \.self) { recommendation in
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .fill(Color.khakiGold)
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)
                            
                            Text(recommendation)
                                .font(.appSubheadline)
                                .foregroundColor(Color.adaptiveText(colorScheme))
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Spacer()
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.adaptiveSurface(colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.khakiGold.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: Color.khakiGold.opacity(0.1), radius: 6, x: 0, y: 3)
        }
    }
}
