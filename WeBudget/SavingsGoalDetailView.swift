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
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // En-tête avec informations principales
                GoalHeaderView(goal: goal)
                
                // Graphique de progression
                if !monthlyContributions.isEmpty {
                    MonthlyContributionsChartView(data: monthlyContributions)
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
        .navigationTitle(goal.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Modifier") {
                    showingEditGoal = true
                }
                .font(.buttonText) // Space Grotesk Medium
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

struct GoalHeaderView: View {
    let goal: SavingsGoal
    
    var body: some View {
        VStack(spacing: 16) {
            // Icône et statut
            HStack {
                Text(goal.category.icon)
                    .font(.system(size: 50))
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(goal.status.displayName)
                        .font(.appHeadline) // Space Grotesk SemiBold
                        .fontWeight(.semibold)
                        .foregroundColor(goal.status.color)
                    
                    Text(goal.priority.displayName)
                        .font(.appSubheadline) // Space Grotesk Medium
                        .foregroundColor(goal.priority.color)
                }
            }
            
            // Progression principale
            VStack(spacing: 8) {
                HStack {
                    Text("Progression")
                        .font(.appHeadline) // Space Grotesk SemiBold
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(Int(goal.progressPercentage * 100))%")
                        .font(.appTitle2) // Space Grotesk SemiBold
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                ProgressView(value: goal.progressPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(y: 2)
                
                HStack {
                    Text(goal.currentAmount.formatted(.currency(code: "EUR")))
                        .font(.currencyMedium) // Space Grotesk SemiBold
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    Text(goal.targetAmount.formatted(.currency(code: "EUR")))
                        .font(.currencyMedium) // Space Grotesk SemiBold
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            
            // Informations temporelles
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("⏰ Temps restant")
                        .font(.appCaption) // Space Grotesk Regular
                        .foregroundColor(.secondary)
                    
                    if goal.monthsRemaining > 0 {
                        Text("\(goal.monthsRemaining) mois")
                            .font(.appHeadline) // Space Grotesk SemiBold
                            .fontWeight(.medium)
                    } else if goal.status == .completed {
                        Text("Terminé!")
                            .font(.appHeadline) // Space Grotesk SemiBold
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    } else {
                        Text("Expiré")
                            .font(.appHeadline) // Space Grotesk SemiBold
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("💰 Reste à épargner")
                        .font(.appCaption) // Space Grotesk Regular
                        .foregroundColor(.secondary)
                    
                    Text(goal.remainingAmount.formatted(.currency(code: "EUR")))
                        .font(.appHeadline) // Space Grotesk SemiBold
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [goal.category.color.opacity(0.1), goal.category.color.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }
}

struct MonthlyContributionsChartView: View {
    let data: [(String, Double)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("📊 Contributions mensuelles")
                .font(.appHeadline) // Space Grotesk SemiBold
                .fontWeight(.bold)
            
            Chart(data, id: \.0) { month, amount in
                BarMark(
                    x: .value("Mois", month),
                    y: .value("Montant", amount)
                )
                .foregroundStyle(.blue)
                .cornerRadius(4)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(format: .currency(code: "EUR"))
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.appCaption) // Space Grotesk Regular
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct GoalStatisticsView: View {
    let goal: SavingsGoal
    let contributions: [SavingsContribution]
    
    private var averageMonthlyContribution: Double {
        guard !contributions.isEmpty else { return 0 }
        let total = contributions.reduce(0) { $0 + $1.amount }
        
        // Calculer le nombre de mois depuis la première contribution
        let calendar = Calendar.current
        if let firstContribution = contributions.last {
            let months = calendar.dateComponents([.month], from: firstContribution.date, to: Date()).month ?? 1
            return total / Double(max(months, 1))
        }
        
        return total / Double(contributions.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("📈 Statistiques détaillées")
                .font(.appHeadline) // Space Grotesk SemiBold
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                StatisticCard(
                    title: "Contribution moyenne",
                    value: averageMonthlyContribution.formatted(.currency(code: "EUR")),
                    subtitle: "par mois",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue
                )
                
                StatisticCard(
                    title: "Contribution requise",
                    value: goal.requiredMonthlyContribution.formatted(.currency(code: "EUR")),
                    subtitle: "pour atteindre l'objectif",
                    icon: "target",
                    color: .orange
                )
                
                StatisticCard(
                    title: "Nombre de versements",
                    value: "\(contributions.count)",
                    subtitle: "contributions effectuées",
                    icon: "number.circle",
                    color: .green
                )
                
                if let projectedDate = goal.projectedCompletionDate {
                    StatisticCard(
                        title: "Fin prévue",
                        value: projectedDate.formatted(.dateTime.month().year()),
                        subtitle: "au rythme actuel",
                        icon: "calendar.badge.clock",
                        color: .purple
                    )
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct StatisticCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.appHeadline) // Space Grotesk SemiBold
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.appCaption) // Space Grotesk Regular
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.appCaption2) // Space Grotesk Light
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct QuickActionsView: View {
    let goal: SavingsGoal
    @Binding var showingAddContribution: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("⚡ Actions rapides")
                .font(.appHeadline) // Space Grotesk SemiBold
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                ActionButton(
                    title: "Ajouter contribution",
                    icon: "plus.circle.fill",
                    color: .green
                ) {
                    showingAddContribution = true
                }
                
                ActionButton(
                    title: "Contribution mensuelle",
                    icon: "calendar.badge.plus",
                    color: .blue
                ) {
                    // TODO: Programmer contribution automatique
                }
                
                ActionButton(
                    title: "Partager progression",
                    icon: "square.and.arrow.up",
                    color: .purple
                ) {
                    // TODO: Partager
                }
                
                ActionButton(
                    title: "Calculer intérêts",
                    icon: "percent",
                    color: .orange
                ) {
                    // TODO: Calculateur d'intérêts
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.appCaption) // Space Grotesk Regular
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ContributionsHistoryView: View {
    let contributions: [SavingsContribution]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("📋 Historique des contributions")
                    .font(.appHeadline) // Space Grotesk SemiBold
                    .fontWeight(.bold)
                
                Spacer()
                
                if contributions.count > 5 {
                    Text("(\(contributions.count) au total)")
                        .font(.appCaption) // Space Grotesk Regular
                        .foregroundColor(.secondary)
                }
            }
            
            if contributions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.title)
                        .foregroundColor(.gray)
                    
                    Text("Aucune contribution")
                        .font(.appSubheadline) // Space Grotesk Medium
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ForEach(contributions.prefix(5)) { contribution in
                    ContributionRowView(contribution: contribution)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct ContributionRowView: View {
    let contribution: SavingsContribution
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(contribution.amount.formatted(.currency(code: "EUR")))
                    .font(.currencySmall) // Space Grotesk Medium
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                
                Text(contribution.date.formatted(.dateTime.day().month().year()))
                    .font(.appCaption) // Space Grotesk Regular
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let note = contribution.note, !note.isEmpty {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(note)
                        .font(.appCaption) // Space Grotesk Regular
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(2)
                    
                    Image(systemName: "note.text")
                        .font(.appCaption2) // Space Grotesk Light
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(8)
    }
}

struct GoalRecommendationsView: View {
    let goal: SavingsGoal
    
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
        
        // Recommendations basées sur la priorité
        if goal.priority == .urgent {
            recs.append("🚨 Objectif prioritaire : concentrez-vous sur celui-ci en premier")
        }
        
        return recs
    }
    
    var body: some View {
        if !recommendations.isEmpty {
            VStack(alignment: .leading, spacing: 15) {
                Text("💡 Recommandations")
                    .font(.appHeadline) // Space Grotesk SemiBold
                    .fontWeight(.bold)
                
                ForEach(recommendations, id: \.self) { recommendation in
                    HStack(alignment: .top, spacing: 12) {
                        Text("•")
                            .foregroundColor(.blue)
                            .fontWeight(.bold)
                        
                        Text(recommendation)
                            .font(.appSubheadline) // Space Grotesk Medium
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .cornerRadius(12)
        }
    }
}

// MARK: - Vues pour ajouter une contribution
struct AddContributionView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    @Environment(\.dismiss) private var dismiss
    
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
                Section("💰 Contribution") {
                    HStack {
                        Text("Montant")
                            .font(.appBody) // Space Grotesk Regular
                        
                        Spacer()
                        
                        TextField("0,00", text: $amount)
                            .font(.currencyMedium) // Space Grotesk SemiBold
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 120)
                            .multilineTextAlignment(.trailing)
                        
                        Text("€")
                            .font(.appCallout) // Space Grotesk Regular
                            .foregroundColor(.secondary)
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .font(.appBody) // Space Grotesk Regular
                    
                    TextField("Note (optionnel)", text: $note, axis: .vertical)
                        .font(.appBody) // Space Grotesk Regular
                        .lineLimit(3)
                }
                
                Section("🎯 Objectif") {
                    HStack {
                        Text("Nom:")
                            .font(.appBody) // Space Grotesk Regular
                        Spacer()
                        Text(goalName)
                            .font(.appBody) // Space Grotesk Regular
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Ajouter contribution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .font(.buttonText) // Space Grotesk Medium
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Ajouter") {
                        addContribution()
                    }
                    .font(.buttonText) // Space Grotesk Medium
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
            .alert("Erreur", isPresented: $showingAlert) {
                Button("OK") {
                    // Action OK
                }
                .font(.buttonText) // Space Grotesk Medium
            } message: {
                Text(alertMessage)
                    .font(.appCallout) // Space Grotesk Regular
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
    
    var body: some View {
        NavigationView {
            Form {
                Section("🎯 Informations de l'objectif") {
                    TextField("Nom de l'objectif", text: $name)
                        .font(.appBody) // Space Grotesk Regular
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .font(.appBody) // Space Grotesk Regular
                        .lineLimit(2...4)
                    
                    Picker("Catégorie", selection: $selectedCategory) {
                        ForEach(GoalCategory.allCases, id: \.self) { category in
                            Text(category.displayName)
                                .font(.appBody) // Space Grotesk Regular
                        }
                    }
                    .font(.appBody) // Space Grotesk Regular
                    
                    Picker("Priorité", selection: $selectedPriority) {
                        ForEach(GoalPriority.allCases, id: \.self) { priority in
                            Text(priority.displayName)
                                .font(.appBody) // Space Grotesk Regular
                        }
                    }
                    .font(.appBody) // Space Grotesk Regular
                    
                    Toggle("Objectif actif", isOn: $isActive)
                        .font(.appBody) // Space Grotesk Regular
                }
                
                Section("💰 Montants et échéance") {
                    HStack {
                        Text("Objectif")
                            .font(.appBody) // Space Grotesk Regular
                        Spacer()
                        TextField("Montant", text: $targetAmount)
                            .font(.currencySmall) // Space Grotesk Medium
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 120)
                        Text("€")
                            .font(.appCallout) // Space Grotesk Regular
                    }
                    
                    DatePicker("Date cible", selection: $targetDate, displayedComponents: .date)
                        .font(.appBody) // Space Grotesk Regular
                    
                    HStack {
                        Text("Contribution mensuelle")
                            .font(.appBody) // Space Grotesk Regular
                        Spacer()
                        TextField("Montant", text: $monthlyContribution)
                            .font(.currencySmall) // Space Grotesk Medium
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 120)
                        Text("€")
                            .font(.appCallout) // Space Grotesk Regular
                    }
                }
            }
            .navigationTitle("Modifier objectif")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .font(.buttonText) // Space Grotesk Medium
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sauvegarder") {
                        updateGoal()
                    }
                    .font(.buttonText) // Space Grotesk Medium
                    .fontWeight(.semibold)
                }
            }
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
