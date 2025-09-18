//
//  SavingsGoalsView.swift
//  WeBudget
//
//  Created by Pierre-Louis L'ALLORET on 15/09/2025.
//

import SwiftUI

struct SavingsGoalsView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    @State private var showingAddGoal = false
    @State private var selectedPriority: GoalPriority?
    @State private var selectedStatus: GoalStatus?
    @Environment(\.colorScheme) private var colorScheme
    
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
            VStack(spacing: 20) {
                // Résumé des objectifs avec style rétro
                SavingsGoalsSummaryCard()
                
                // Filtres redesignés
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
                            .listRowBackground(Color.adaptiveSurface(colorScheme))
                        }
                        .onDelete(perform: deleteGoals)
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                    .background(Color.adaptiveBackground(colorScheme))
                }
            }
            .background(Color.adaptiveBackground(colorScheme))
            .navigationTitle("🎯 Objectifs d'épargne")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.khakiGold.opacity(0.1), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddGoal = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.khakiGold)
                                .frame(width: 32, height: 32)
                                .shadow(color: Color.khakiGold.opacity(0.3), radius: 4, x: 0, y: 2)
                            
                            Image(systemName: "plus")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color.brownDeep)
                        }
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
    @Environment(\.colorScheme) private var colorScheme
    
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
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("💰 Total épargné")
                        .font(.appSubheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.adaptiveText(colorScheme))
                    
                    Text(totalCurrentAmount.formatted(.currency(code: "EUR")))
                        .font(.currencyLarge)
                        .fontWeight(.bold)
                        .foregroundColor(Color.limeElectric)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    Text("🎯 Objectif global")
                        .font(.appSubheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.adaptiveText(colorScheme))
                    
                    Text(totalTargetAmount.formatted(.currency(code: "EUR")))
                        .font(.currencyLarge)
                        .fontWeight(.bold)
                        .foregroundColor(Color.khakiGold)
                }
            }
            
            // Barre de progression globale rétro
            VStack(spacing: 8) {
                HStack {
                    Text("Progression d'ensemble")
                        .font(.appTitle3)
                        .fontWeight(.bold)
                        .foregroundColor(Color.adaptiveText(colorScheme))
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(Color.khakiGold.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Text("\(Int(overallProgress * 100))%")
                            .font(.appHeadline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.khakiGold)
                    }
                }
                
                // Barre de progression rétro
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.khakiGold.opacity(0.15))
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [Color.limeElectric, Color.khakiGold],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, CGFloat(overallProgress) * 300), height: 12)
                }
            }
            
            // Statistiques rapides avec design rétro
            HStack(spacing: 15) {
                RetroStatPill(
                    title: "Actifs",
                    value: "\(budgetManager.savingsGoals.filter { $0.isActive }.count)",
                    color: Color.skyBlueRetro
                )
                
                RetroStatPill(
                    title: "Terminés",
                    value: "\(budgetManager.savingsGoals.filter { $0.status == .completed }.count)",
                    color: Color.limeElectric
                )
                
                RetroStatPill(
                    title: "En retard",
                    value: "\(budgetManager.behindScheduleGoals.count)",
                    color: Color.peachSunset
                )
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.adaptiveSurface(colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.khakiGold.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: Color.khakiGold.opacity(0.15), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
    }
}

struct RetroStatPill: View {
    let title: String
    let value: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.appTitle2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.appCaption)
                .fontWeight(.medium)
                .foregroundColor(Color.adaptiveText(colorScheme))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: color.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

struct SavingsFiltersView: View {
    @Binding var selectedPriority: GoalPriority?
    @Binding var selectedStatus: GoalStatus?
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            // Filtres par priorité
            VStack(alignment: .leading, spacing: 8) {
                Text("🔥 Filtrer par priorité")
                    .font(.appSubheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.adaptiveText(colorScheme))
                    .padding(.leading, 20)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterChip(
                            title: "Toutes",
                            isSelected: selectedPriority == nil,
                            accentColor: Color.peachSunset
                        ) {
                            selectedPriority = nil
                        }
                        
                        ForEach(GoalPriority.allCases, id: \.self) { priority in
                            FilterChip(
                                title: String(priority.displayName.dropFirst(2)),
                                isSelected: selectedPriority == priority,
                                accentColor: priorityColor(for: priority)
                            ) {
                                selectedPriority = selectedPriority == priority ? nil : priority
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            // Filtres par statut
            VStack(alignment: .leading, spacing: 8) {
                Text("📊 Filtrer par statut")
                    .font(.appSubheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.adaptiveText(colorScheme))
                    .padding(.leading, 20)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterChip(
                            title: "Tous",
                            isSelected: selectedStatus == nil,
                            accentColor: Color.turquoiseVintage
                        ) {
                            selectedStatus = nil
                        }
                        
                        ForEach([GoalStatus.onTrack, .behindSchedule, .completed, .expired], id: \.self) { status in
                            FilterChip(
                                title: String(status.displayName.dropFirst(2)),
                                isSelected: selectedStatus == status,
                                accentColor: statusColor(for: status)
                            ) {
                                selectedStatus = selectedStatus == status ? nil : status
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.adaptiveSurface(colorScheme).opacity(0.5))
        )
    }
    
    private func priorityColor(for priority: GoalPriority) -> Color {
        switch priority {
        case .low: return Color.dimGray
        case .medium: return Color.skyBlueRetro
        case .high: return Color.peachSunset
        case .urgent: return Color.softCoral
        }
    }
    
    private func statusColor(for status: GoalStatus) -> Color {
        switch status {
        case .onTrack: return Color.limeElectric
        case .behindSchedule: return Color.peachSunset
        case .completed: return Color.limeElectric
        case .expired: return Color.softCoral
        }
    }
}

struct SavingsGoalRowView: View {
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 15) {
                // Icône et indicateurs
                VStack(spacing: 6) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(categoryColor.opacity(0.15))
                            .frame(width: 50, height: 50)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(categoryColor.opacity(0.3), lineWidth: 1)
                            )
                        
                        Text(goal.category.icon)
                            .font(.title2)
                    }
                    
                    Circle()
                        .fill(priorityColor)
                        .frame(width: 10, height: 10)
                        .overlay(
                            Circle()
                                .stroke(Color.adaptiveSurface(colorScheme), lineWidth: 2)
                        )
                }
                
                // Informations principales
                VStack(alignment: .leading, spacing: 6) {
                    Text(goal.name)
                        .font(.appHeadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.adaptiveText(colorScheme))
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        // Badge catégorie
                        Text(goal.category.displayName.dropFirst(2))
                            .font(.appCaption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(categoryColor.opacity(0.15))
                            .foregroundColor(categoryColor)
                            .cornerRadius(8)
                        
                        // Badge statut
                        Text(goal.status.displayName.dropFirst(2))
                            .font(.appCaption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor.opacity(0.15))
                            .foregroundColor(statusColor)
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                // Montants et progression
                VStack(alignment: .trailing, spacing: 6) {
                    Text(goal.currentAmount.formatted(.currency(code: "EUR")))
                        .font(.currencyMedium)
                        .fontWeight(.bold)
                        .foregroundColor(Color.limeElectric)
                    
                    Text("/ \(goal.targetAmount.formatted(.currency(code: "EUR")))")
                        .font(.appCaption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(goal.progressPercentage * 100))%")
                        .font(.appSubheadline)
                        .fontWeight(.bold)
                        .foregroundColor(categoryColor)
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
                    .frame(width: max(0, CGFloat(goal.progressPercentage) * 300), height: 8)
            }
            
            // Informations temporelles et badges
            HStack(spacing: 12) {
                if goal.monthsRemaining > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(goal.monthsRemaining) mois restant\(goal.monthsRemaining > 1 ? "s" : "")")
                            .font(.appCaption)
                            .foregroundColor(.secondary)
                    }
                } else if goal.status == .completed {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(Color.limeElectric)
                        
                        Text("Objectif atteint!")
                            .font(.appCaption)
                            .foregroundColor(Color.limeElectric)
                            .fontWeight(.medium)
                    }
                }
                
                Spacer()
                
                if goal.monthlyContribution > 0 {
                    Text("\(goal.monthlyContribution.formatted(.currency(code: "EUR")))/mois")
                        .font(.appCaption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.skyBlueRetro.opacity(0.15))
                        .foregroundColor(Color.skyBlueRetro)
                        .cornerRadius(10)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.adaptiveSurface(colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(categoryColor.opacity(0.15), lineWidth: 1)
                )
        )
        .shadow(color: categoryColor.opacity(0.1), radius: 6, x: 0, y: 3)
        .opacity(goal.isActive ? 1.0 : 0.6)
    }
}

struct AddSavingsGoalView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
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
                        .textInputAutocapitalization(.words)
                    
                    TextField("Description (optionnel)", text: $description, axis: .vertical)
                        .font(.appBody)
                        .lineLimit(2...4)
                        .textInputAutocapitalization(.sentences)
                    
                    Picker("🏷️ Catégorie", selection: $selectedCategory) {
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
                    
                    Picker("⚠️ Priorité", selection: $selectedPriority) {
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
                        Text("🎯 Objectif")
                            .font(.appBody)
                        
                        Spacer()
                        
                        TextField("0,00", text: $targetAmount)
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
                        Text("💵 Montant actuel")
                            .font(.appBody)
                        
                        Spacer()
                        
                        TextField("0,00", text: $currentAmount)
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
                                            .stroke(Color.limeElectric.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .frame(width: 120)
                        
                        Text("€")
                            .font(.appCallout)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("📅 Contribution mensuelle")
                            .font(.appBody)
                        
                        Spacer()
                        
                        TextField("\(calculatedMonthlyContribution.formatted(.number.precision(.fractionLength(0))))", text: $monthlyContribution)
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
                                            .stroke(Color.skyBlueRetro.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .frame(width: 120)
                        
                        Text("€")
                            .font(.appCallout)
                            .foregroundColor(.secondary)
                    }
                    
                } header: {
                    Text("💰 Configuration des montants")
                        .font(.appHeadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.adaptiveText(colorScheme))
                }
                .listRowBackground(Color.adaptiveSurface(colorScheme))
                
                Section {
                    DatePicker("🎯 Date cible", selection: $targetDate, in: Date()..., displayedComponents: .date)
                        .font(.appBody)
                    
                    if calculatedMonthlyContribution > 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(Color.khakiGold)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Contribution suggérée:")
                                    .font(.appCaption)
                                    .foregroundColor(.secondary)
                                
                                Text(calculatedMonthlyContribution.formatted(.currency(code: "EUR")))
                                    .font(.currencySmall)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.khakiGold)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color.khakiGold.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                } header: {
                    Text("📅 Planning temporel")
                        .font(.appHeadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.adaptiveText(colorScheme))
                }
                .listRowBackground(Color.adaptiveSurface(colorScheme))
                
                if !name.isEmpty && !targetAmount.isEmpty {
                    Section {
                        SavingsGoalPreviewView(
                            name: name,
                            targetAmount: Double(targetAmount.replacingOccurrences(of: ",", with: ".")) ?? 0,
                            currentAmount: Double(currentAmount.replacingOccurrences(of: ",", with: ".")) ?? 0,
                            category: selectedCategory,
                            priority: selectedPriority,
                            targetDate: targetDate
                        )
                    } header: {
                        Text("👀 Aperçu de l'objectif")
                            .font(.appHeadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.adaptiveText(colorScheme))
                    }
                    .listRowBackground(Color.adaptiveSurface(colorScheme))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.adaptiveBackground(colorScheme))
            .navigationTitle("➕ Nouvel objectif")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.khakiGold.opacity(0.1), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .font(.buttonText)
                    .foregroundColor(Color.softCoral)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Créer") {
                        addSavingsGoal()
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
    
    private func priorityColorForSelection(_ priority: GoalPriority) -> Color {
        switch priority {
        case .low: return Color.dimGray
        case .medium: return Color.skyBlueRetro
        case .high: return Color.peachSunset
        case .urgent: return Color.softCoral
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
    @Environment(\.colorScheme) private var colorScheme
    
    private var progressPercentage: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount, 1.0)
    }
    
    private var categoryColor: Color {
        switch category {
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
        switch priority {
        case .low: return Color.dimGray
        case .medium: return Color.skyBlueRetro
        case .high: return Color.peachSunset
        case .urgent: return Color.softCoral
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 15) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(categoryColor.opacity(0.15))
                        .frame(width: 50, height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(categoryColor.opacity(0.3), lineWidth: 1)
                        )
                    
                    Text(category.icon)
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.appHeadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.adaptiveText(colorScheme))
                    
                    HStack(spacing: 8) {
                        Text(category.displayName.dropFirst(2))
                            .font(.appCaption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(categoryColor.opacity(0.15))
                            .foregroundColor(categoryColor)
                            .cornerRadius(8)
                        
                        Text(priority.displayName.dropFirst(2))
                            .font(.appCaption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(priorityColor.opacity(0.15))
                            .foregroundColor(priorityColor)
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(currentAmount.formatted(.currency(code: "EUR")))
                        .font(.currencyMedium)
                        .fontWeight(.bold)
                        .foregroundColor(Color.limeElectric)
                    
                    Text("/ \(targetAmount.formatted(.currency(code: "EUR")))")
                        .font(.appCaption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Barre de progression
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
                    .frame(width: max(0, CGFloat(progressPercentage) * 300), height: 8)
            }
            
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Échéance: \(targetDate.formatted(.dateTime.day().month().year()))")
                        .font(.appCaption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("\(Int(progressPercentage * 100))%")
                        .font(.appCaption)
                        .fontWeight(.bold)
                        .foregroundColor(categoryColor)
                    
                    Image(systemName: "eye.fill")
                        .font(.caption2)
                        .foregroundColor(Color.turquoiseVintage)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(categoryColor.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(categoryColor.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: categoryColor.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct EmptySavingsGoalsView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            // Illustration avec style rétro
            ZStack {
                Circle()
                    .fill(Color.khakiGold.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Circle()
                    .stroke(Color.khakiGold.opacity(0.3), lineWidth: 2)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "target")
                    .font(.system(size: 50))
                    .foregroundColor(Color.khakiGold)
            }
            
            VStack(spacing: 12) {
                Text("Aucun objectif d'épargne")
                    .font(.appTitle3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.adaptiveText(colorScheme))
                
                Text("Créez vos premiers objectifs\npour économiser efficacement")
                    .font(.appSubheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // Suggestions avec style rétro
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .foregroundColor(Color.pinkBubblegum)
                    Text("Vacances, maison, voiture, urgences...")
                        .font(.appFootnote)
                        .fontWeight(.medium)
                        .foregroundColor(Color.pinkBubblegum)
                    Image(systemName: "star.fill")
                        .foregroundColor(Color.pinkBubblegum)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.pinkBubblegum.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.adaptiveSurface(colorScheme).opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.khakiGold.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
}
