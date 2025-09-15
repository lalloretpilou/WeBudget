//
//  SavingsGoalsView.swift
//  WeBudget
//
//  Created by Pierre-Louis L'ALLORET on 15/09/2025.
//

// SavingsGoalsView.swift
import SwiftUI

struct SavingsGoalsView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    @State private var showingAddGoal = false
    @State private var selectedPriority: GoalPriority?
    @State private var selectedStatus: GoalStatus?
    
    private var filteredGoals: [SavingsGoal] {
        var goals = budgetManager.savingsGoals
        
        if let priority = selectedPriority {
            goals = goals.filter { $0.priority == priority }
        }
        
        if let status = selectedStatus {
            goals = goals.filter { $0.status == status }
        }
        
        return goals.sorted { goal1, goal2 in
            // Trier par priorité d'abord, puis par date cible
            if goal1.priority != goal2.priority {
                return goal1.priority.rawValue > goal2.priority.rawValue
            }
            return goal1.targetDate < goal2.targetDate
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Résumé des objectifs
                SavingsGoalsSummaryCard()
                
                // Filtres
                SavingsFiltersView(
                    selectedPriority: $selectedPriority,
                    selectedStatus: $selectedStatus
                )
                
                // Liste des objectifs
                if filteredGoals.isEmpty {
                    EmptySavingsGoalsView()
                } else {
                    List {
                        ForEach(filteredGoals) { goal in
                            NavigationLink(destination: SavingsGoalDetailView(goal: goal)) {
                                SavingsGoalRowView(goal: goal)
                            }
                        }
                        .onDelete(perform: deleteGoals)
                    }
                }
            }
            .navigationTitle("🎯 Objectifs d'épargne")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddGoal = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddGoal) {
                AddSavingsGoalView()
            }
        }
    }
    
    private func deleteGoals(at offsets: IndexSet) {
        for index in offsets {
            let goal = filteredGoals[index]
            budgetManager.deleteSavingsGoal(goal)
        }
    }
}

struct SavingsGoalsSummaryCard: View {
    @EnvironmentObject var budgetManager: BudgetManager
    
    private var totalTargetAmount: Double {
        budgetManager.savingsGoals.filter { $0.isActive }.reduce(0) { $0 + $1.targetAmount }
    }
    
    private var totalCurrentAmount: Double {
        budgetManager.savingsGoals.filter { $0.isActive }.reduce(0) { $0 + $1.currentAmount }
    }
    
    private var overallProgress: Double {
        guard totalTargetAmount > 0 else { return 0 }
        return totalCurrentAmount / totalTargetAmount
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("💰 Épargné")
                        .font(.appCaption) // Space Grotesk Regular
                        .foregroundColor(.secondary)
                    
                    Text(totalCurrentAmount.formatted(.currency(code: "EUR")))
                        .font(.currencyMedium) // Space Grotesk SemiBold
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("🎯 Objectif total")
                        .font(.appCaption) // Space Grotesk Regular
                        .foregroundColor(.secondary)
                    
                    Text(totalTargetAmount.formatted(.currency(code: "EUR")))
                        .font(.currencyMedium) // Space Grotesk SemiBold
                        .fontWeight(.bold)
                }
            }
            
            // Barre de progression globale
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
            
            // Statistiques rapides
            HStack {
                StatPill(
                    title: "Actifs",
                    value: "\(budgetManager.savingsGoals.filter { $0.isActive }.count)",
                    color: .blue
                )
                
                StatPill(
                    title: "Terminés",
                    value: "\(budgetManager.savingsGoals.filter { $0.status == .completed }.count)",
                    color: .green
                )
                
                StatPill(
                    title: "En retard",
                    value: "\(budgetManager.behindScheduleGoals.count)",
                    color: .orange
                )
                
                Spacer()
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.green.opacity(0.1), Color.blue.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct StatPill: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.appHeadline) // Space Grotesk SemiBold
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.appCaption2) // Space Grotesk Light
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct SavingsFiltersView: View {
    @Binding var selectedPriority: GoalPriority?
    @Binding var selectedStatus: GoalStatus?
    
    var body: some View {
        VStack(spacing: 8) {
            // Filtres par priorité
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Text("Priorité:")
                        .font(.appCaption) // Space Grotesk Regular
                        .foregroundColor(.secondary)
                    
                    FilterChip(
                        title: "Toutes",
                        isSelected: selectedPriority == nil
                    ) {
                        selectedPriority = nil
                    }
                    
                    ForEach(GoalPriority.allCases, id: \.self) { priority in
                        FilterChip(
                            title: String(priority.displayName.dropFirst(2)),
                            isSelected: selectedPriority == priority
                        ) {
                            selectedPriority = selectedPriority == priority ? nil : priority
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Filtres par statut
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Text("Statut:")
                        .font(.appCaption) // Space Grotesk Regular
                        .foregroundColor(.secondary)
                    
                    FilterChip(
                        title: "Tous",
                        isSelected: selectedStatus == nil
                    ) {
                        selectedStatus = nil
                    }
                    
                    ForEach([GoalStatus.onTrack, .behindSchedule, .completed, .expired], id: \.self) { status in
                        FilterChip(
                            title: String(status.displayName.dropFirst(2)),
                            isSelected: selectedStatus == status
                        ) {
                            selectedStatus = selectedStatus == status ? nil : status
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
}

struct SavingsGoalRowView: View {
    let goal: SavingsGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                // Icône et priorité
                VStack {
                    Text(goal.category.icon)
                        .font(.title2)
                    
                    Circle()
                        .fill(goal.priority.color)
                        .frame(width: 8, height: 8)
                }
                
                // Informations principales
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.name)
                        .font(.appHeadline) // Space Grotesk SemiBold
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    HStack {
                        Text(goal.category.displayName.dropFirst(2))
                            .font(.appCaption) // Space Grotesk Regular
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.appCaption) // Space Grotesk Regular
                            .foregroundColor(.secondary)
                        
                        Text(goal.status.displayName)
                            .font(.appCaption) // Space Grotesk Regular
                            .foregroundColor(goal.status.color)
                    }
                }
                
                Spacer()
                
                // Montants et progression
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(goal.currentAmount.formatted(.currency(code: "EUR")))")
                        .font(.currencyMedium) // Space Grotesk SemiBold
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("/ \(goal.targetAmount.formatted(.currency(code: "EUR")))")
                        .font(.appCaption) // Space Grotesk Regular
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(goal.progressPercentage * 100))%")
                        .font(.appCaption) // Space Grotesk Regular
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
            
            // Barre de progression
            ProgressView(value: goal.progressPercentage)
                .progressViewStyle(LinearProgressViewStyle(tint: progressColor(for: goal)))
                .scaleEffect(y: 1.2)
            
            // Informations temporelles
            HStack {
                if goal.monthsRemaining > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.appCaption2) // Space Grotesk Light
                            .foregroundColor(.secondary)
                        
                        Text("\(goal.monthsRemaining) mois restant\(goal.monthsRemaining > 1 ? "s" : "")")
                            .font(.appCaption) // Space Grotesk Regular
                            .foregroundColor(.secondary)
                    }
                } else if goal.status == .completed {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.appCaption2) // Space Grotesk Light
                            .foregroundColor(.green)
                        
                        Text("Objectif atteint!")
                            .font(.appCaption) // Space Grotesk Regular
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                if goal.monthlyContribution > 0 {
                    Text("\(goal.monthlyContribution.formatted(.currency(code: "EUR")))/mois")
                        .font(.appCaption) // Space Grotesk Regular
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 8)
        .opacity(goal.isActive ? 1.0 : 0.6)
    }
    
    private func progressColor(for goal: SavingsGoal) -> Color {
        switch goal.status {
        case .completed:
            return .green
        case .onTrack:
            return .blue
        case .behindSchedule:
            return .orange
        case .expired:
            return .red
        }
    }
}

struct AddSavingsGoalView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var targetAmount = ""
    @State private var currentAmount = ""
    @State private var targetDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var selectedCategory: GoalCategory = .general
    @State private var selectedPriority: GoalPriority = .medium
    @State private var monthlyContribution = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private var calculatedMonthlyContribution: Double {
        guard let target = Double(targetAmount.replacingOccurrences(of: ",", with: ".")),
              let current = Double(currentAmount.replacingOccurrences(of: ",", with: ".")) else {
            return 0
        }
        
        let remaining = max(target - current, 0)
        let calendar = Calendar.current
        let months = calendar.dateComponents([.month], from: Date(), to: targetDate).month ?? 1
        
        return remaining / Double(max(months, 1))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("🎯 Informations de l'objectif") {
                    TextField("Nom de l'objectif", text: $name)
                        .font(.appBody) // Space Grotesk Regular
                        .textInputAutocapitalization(.words)
                    
                    TextField("Description (optionnel)", text: $description, axis: .vertical)
                        .font(.appBody) // Space Grotesk Regular
                        .lineLimit(2...4)
                        .textInputAutocapitalization(.sentences)
                    
                    Picker("🏷️ Catégorie", selection: $selectedCategory) {
                        ForEach(GoalCategory.allCases, id: \.self) { category in
                            Text(category.displayName)
                                .font(.appBody) // Space Grotesk Regular
                                .tag(category)
                        }
                    }
                    .font(.appBody) // Space Grotesk Regular
                    
                    Picker("⚠️ Priorité", selection: $selectedPriority) {
                        ForEach(GoalPriority.allCases, id: \.self) { priority in
                            Text(priority.displayName)
                                .font(.appBody) // Space Grotesk Regular
                                .tag(priority)
                        }
                    }
                    .font(.appBody) // Space Grotesk Regular
                }
                
                Section("💰 Montants") {
                    HStack {
                        Text("🎯 Objectif")
                            .font(.appBody) // Space Grotesk Regular
                        
                        Spacer()
                        
                        TextField("0,00", text: $targetAmount)
                            .font(.currencyMedium) // Space Grotesk SemiBold
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 120)
                            .multilineTextAlignment(.trailing)
                        
                        Text("€")
                            .font(.appCallout) // Space Grotesk Regular
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("💵 Montant actuel")
                            .font(.appBody) // Space Grotesk Regular
                        
                        Spacer()
                        
                        TextField("0,00", text: $currentAmount)
                            .font(.currencyMedium) // Space Grotesk SemiBold
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 120)
                            .multilineTextAlignment(.trailing)
                        
                        Text("€")
                            .font(.appCallout) // Space Grotesk Regular
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("📅 Contribution mensuelle")
                            .font(.appBody) // Space Grotesk Regular
                        
                        Spacer()
                        
                        TextField("\(calculatedMonthlyContribution.formatted(.number.precision(.fractionLength(0))))", text: $monthlyContribution)
                            .font(.currencyMedium) // Space Grotesk SemiBold
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 120)
                            .multilineTextAlignment(.trailing)
                        
                        Text("€")
                            .font(.appCallout) // Space Grotesk Regular
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("📅 Échéance") {
                    DatePicker("🎯 Date cible", selection: $targetDate, in: Date()..., displayedComponents: .date)
                        .font(.appBody) // Space Grotesk Regular
                    
                    if calculatedMonthlyContribution > 0 {
                        HStack {
                            Text("💡 Contribution suggérée:")
                                .font(.appCaption) // Space Grotesk Regular
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(calculatedMonthlyContribution.formatted(.currency(code: "EUR")))
                                .font(.appCaption) // Space Grotesk Regular
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                if !name.isEmpty && !targetAmount.isEmpty {
                    Section("📊 Aperçu") {
                        SavingsGoalPreviewView(
                            name: name,
                            targetAmount: Double(targetAmount.replacingOccurrences(of: ",", with: ".")) ?? 0,
                            currentAmount: Double(currentAmount.replacingOccurrences(of: ",", with: ".")) ?? 0,
                            category: selectedCategory,
                            priority: selectedPriority,
                            targetDate: targetDate
                        )
                    }
                }
            }
            .navigationTitle("➕ Nouvel objectif")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .font(.buttonText) // Space Grotesk Medium
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Créer") {
                        addSavingsGoal()
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
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !targetAmount.isEmpty &&
        (Double(targetAmount.replacingOccurrences(of: ",", with: ".")) ?? 0) > 0 &&
        targetDate > Date()
    }
    
    private func addSavingsGoal() {
        guard let targetAmountValue = Double(targetAmount.replacingOccurrences(of: ",", with: ".")) else {
            alertMessage = "Montant objectif invalide"
            showingAlert = true
            return
        }
        
        guard targetAmountValue > 0 else {
            alertMessage = "L'objectif doit être supérieur à 0"
            showingAlert = true
            return
        }
        
        let currentAmountValue = Double(currentAmount.replacingOccurrences(of: ",", with: ".")) ?? 0
        let monthlyContributionValue = Double(monthlyContribution.replacingOccurrences(of: ",", with: ".")) ?? calculatedMonthlyContribution
        
        let goal = SavingsGoal(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            targetAmount: targetAmountValue,
            currentAmount: currentAmountValue,
            targetDate: targetDate,
            category: selectedCategory,
            priority: selectedPriority,
            monthlyContribution: monthlyContributionValue
        )
        
        budgetManager.addSavingsGoal(goal)
        dismiss()
    }
}

struct SavingsGoalPreviewView: View {
    let name: String
    let targetAmount: Double
    let currentAmount: Double
    let category: GoalCategory
    let priority: GoalPriority
    let targetDate: Date
    
    private var progressPercentage: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category.icon)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.appHeadline) // Space Grotesk SemiBold
                        .fontWeight(.medium)
                    
                    HStack {
                        Text(category.displayName.dropFirst(2))
                            .font(.appCaption) // Space Grotesk Regular
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.appCaption) // Space Grotesk Regular
                            .foregroundColor(.secondary)
                        
                        Text(priority.displayName)
                            .font(.appCaption) // Space Grotesk Regular
                            .foregroundColor(priority.color)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(currentAmount.formatted(.currency(code: "EUR")))
                        .font(.currencyMedium) // Space Grotesk SemiBold
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("/ \(targetAmount.formatted(.currency(code: "EUR")))")
                        .font(.appCaption) // Space Grotesk Regular
                        .foregroundColor(.secondary)
                }
            }
            
            ProgressView(value: progressPercentage)
                .progressViewStyle(LinearProgressViewStyle(tint: category.color))
            
            HStack {
                Text("Échéance: \(targetDate.formatted(.dateTime.day().month().year()))")
                    .font(.appCaption) // Space Grotesk Regular
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(progressPercentage * 100))%")
                    .font(.appCaption) // Space Grotesk Regular
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct EmptySavingsGoalsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Aucun objectif d'épargne")
                .font(.appHeadline) // Space Grotesk SemiBold
                .foregroundColor(.secondary)
            
            Text("Créez vos premiers objectifs\npour économiser efficacement")
                .font(.appSubheadline) // Space Grotesk Medium
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
