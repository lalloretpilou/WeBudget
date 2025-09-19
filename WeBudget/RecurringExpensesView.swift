//
//  RecurringExpensesView.swift
//  WeBudget
//
//  Created by Pierre-Louis L'ALLORET on 15/09/2025.
//

import SwiftUI

struct RecurringExpensesView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    @State private var showingAddExpense = false
    @State private var selectedFrequency: Frequency?
    @Environment(\.colorScheme) private var colorScheme
    
    private var filteredExpenses: [RecurringExpense] {
        if let frequency = selectedFrequency {
            return budgetManager.recurringExpenses.filter { $0.frequency == frequency }
        }
        return budgetManager.recurringExpenses
    }
    
    private var groupedExpenses: [(String, [RecurringExpense])] {
        let grouped = Dictionary(grouping: filteredExpenses) { expense in
            expense.frequency.displayName
        }
        return grouped.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Résumé en haut avec style rétro
                    RecurringSummaryCard()
                    
                    // Filtres avec style rétro
                    FrequencyFilterView(selectedFrequency: $selectedFrequency)
                    
                    // Liste des dépenses
                    if filteredExpenses.isEmpty {
                        EmptyRecurringExpensesView()
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(groupedExpenses, id: \.0) { frequencyName, expenses in
                                VStack(alignment: .leading, spacing: 12) {
                                    // Header de section
                                    HStack {
                                        Image(systemName: frequencyIcon(for: frequencyName))
                                            .foregroundColor(Color.turquoiseVintage)
                                            .font(.title3)
                                        
                                        Text(frequencyName)
                                            .font(.appHeadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(Color.adaptiveText(colorScheme))
                                        
                                        Spacer()
                                        
                                        Text("\(expenses.count)")
                                            .font(.appCaption)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.turquoiseVintage.opacity(0.2))
                                            .foregroundColor(Color.turquoiseVintage)
                                            .cornerRadius(8)
                                    }
                                    .padding(.horizontal, 20)
                                    
                                    // Dépenses de cette fréquence
                                    VStack(spacing: 12) {
                                        ForEach(expenses) { expense in
                                            RecurringExpenseRowView(expense: expense)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color.adaptiveBackground(colorScheme))
            .navigationTitle("🔄 Dépenses récurrentes")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddExpense = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.turquoiseVintage)
                                .frame(width: 32, height: 32)
                                .shadow(color: Color.turquoiseVintage.opacity(0.3), radius: 4, x: 0, y: 2)
                            
                            Image(systemName: "plus")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color.brownDeep)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddRecurringExpenseView()
            }
        }
    }
    
    private func frequencyIcon(for frequency: String) -> String {
        switch frequency.lowercased() {
        case let f where f.contains("quotidien"): return "calendar.day.timeline.leading"
        case let f where f.contains("hebdomadaire"): return "calendar"
        case let f where f.contains("mensuel"): return "calendar.circle"
        case let f where f.contains("annuel"): return "calendar.badge.clock"
        default: return "arrow.clockwise"
        }
    }
}

struct RecurringSummaryCard: View {
    @EnvironmentObject var budgetManager: BudgetManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("💰 Total mensuel")
                        .font(.appSubheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.adaptiveText(colorScheme))
                    
                    Text(budgetManager.totalMonthlyRecurring.formatted(.currency(code: "EUR")))
                        .font(.currencyLarge)
                        .fontWeight(.bold)
                        .foregroundColor(Color.khakiGold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    Text("⏰ En attente")
                        .font(.appSubheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.adaptiveText(colorScheme))
                    
                    ZStack {
                        Circle()
                            .fill(budgetManager.dueRecurringExpenses.isEmpty ? Color.limeElectric.opacity(0.2) : Color.peachSunset.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Text("\(budgetManager.dueRecurringExpenses.count)")
                            .font(.appTitle2)
                            .fontWeight(.bold)
                            .foregroundColor(budgetManager.dueRecurringExpenses.isEmpty ? Color.limeElectric : Color.peachSunset)
                    }
                }
            }
            
            if !budgetManager.dueRecurringExpenses.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Color.peachSunset)
                    
                    Text("\(budgetManager.dueRecurringExpenses.count) dépense(s) à traiter")
                        .font(.appSubheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.peachSunset)
                    
                    Spacer()
                    
                    Button("Traiter tout") {
                        // Action pour traiter toutes les dépenses dues
                    }
                    .font(.appCaption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.peachSunset.opacity(0.2))
                    .foregroundColor(Color.peachSunset)
                    .cornerRadius(12)
                }
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.limeElectric)
                    
                    Text("Toutes les dépenses récurrentes sont à jour")
                        .font(.appSubheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.limeElectric)
                    
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.adaptiveSurface(colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.turquoiseVintage.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: Color.turquoiseVintage.opacity(0.15), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 20)
    }
}

struct FrequencyFilterView: View {
    @Binding var selectedFrequency: Frequency?
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: "Toutes",
                    isSelected: selectedFrequency == nil,
                    accentColor: Color.turquoiseVintage
                ) {
                    selectedFrequency = nil
                }
                
                ForEach(Frequency.allCases, id: \.self) { frequency in
                    FilterChip(
                        title: frequency.shortName,
                        isSelected: selectedFrequency == frequency,
                        accentColor: frequencyColor(for: frequency)
                    ) {
                        selectedFrequency = selectedFrequency == frequency ? nil : frequency
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
        // Suppression du fond pour permettre au fond vert d'être visible
    }
    
    private func frequencyColor(for frequency: Frequency) -> Color {
        switch frequency {
        case .weekly: return Color.skyBlueRetro
        case .biweekly: return Color.turquoiseVintage
        case .monthly: return Color.limeElectric
        case .quarterly: return Color.peachSunset
        case .biannual: return Color.plumVintage
        case .annual: return Color.khakiGold
        }
    }
}

struct RecurringExpenseRowView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    let expense: RecurringExpense
    @Environment(\.colorScheme) private var colorScheme
    
    private var categoryColor: Color {
        switch expense.category {
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
    
    private var payerColor: Color {
        switch expense.payer {
        case .pilou: return Color.skyBlueRetro
        case .doudou: return Color.pinkBubblegum
        case .commun: return Color.limeElectric
        }
    }
    
    private var frequencyColor: Color {
        switch expense.frequency {
        case .weekly: return Color.skyBlueRetro
        case .biweekly: return Color.turquoiseVintage
        case .monthly: return Color.limeElectric
        case .quarterly: return Color.peachSunset
        case .biannual: return Color.plumVintage
        case .annual: return Color.khakiGold
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 15) {
                // Icône et statut avec design rétro
                VStack(spacing: 6) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(categoryColor.opacity(0.15))
                            .frame(width: 50, height: 50)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(categoryColor.opacity(0.3), lineWidth: 1)
                            )
                        
                        Text(expense.category.icon)
                            .font(.title2)
                    }
                    
                    // Indicateur de statut
                    if expense.isDue {
                        Circle()
                            .fill(Color.softCoral)
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle()
                                    .stroke(Color.adaptiveSurface(colorScheme), lineWidth: 2)
                            )
                    } else if !expense.isActive {
                        Circle()
                            .fill(Color.dimGray)
                            .frame(width: 10, height: 10)
                    } else {
                        Circle()
                            .fill(Color.limeElectric)
                            .frame(width: 10, height: 10)
                    }
                }
                
                // Informations principales
                VStack(alignment: .leading, spacing: 6) {
                    Text(expense.description)
                        .font(.appHeadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.adaptiveText(colorScheme))
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        // Badge catégorie
                        Text(expense.category.displayName.dropFirst(2))
                            .font(.appCaption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(categoryColor.opacity(0.15))
                            .foregroundColor(categoryColor)
                            .cornerRadius(8)
                        
                        // Badge fréquence
                        Text(expense.frequency.displayName.dropFirst(2))
                            .font(.appCaption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(frequencyColor.opacity(0.15))
                            .foregroundColor(frequencyColor)
                            .cornerRadius(8)
                    }
                    
                    if let endDate = expense.endDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .foregroundColor(Color.peachSunset)
                                .font(.caption)
                            
                            Text("Jusqu'au \(endDate.formatted(.dateTime.day().month().year()))")
                                .font(.appCaption2)
                                .foregroundColor(Color.peachSunset)
                        }
                    }
                }
                
                Spacer()
                
                // Montant et échéance
                VStack(alignment: .trailing, spacing: 6) {
                    Text(expense.amount.formatted(.currency(code: "EUR")))
                        .font(.currencyMedium)
                        .fontWeight(.bold)
                        .foregroundColor(expense.isActive ? Color.adaptiveText(colorScheme) : Color.dimGray)
                    
                    if expense.isDue {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(Color.softCoral)
                                .font(.caption)
                            
                            Text("Due maintenant")
                                .font(.appCaption)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.softCoral)
                        }
                    } else {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Prochaine:")
                                .font(.appCaption2)
                                .foregroundColor(.secondary)
                            
                            Text(expense.nextDueDate.formatted(.dateTime.day().month()))
                                .font(.appCaption)
                                .fontWeight(.medium)
                                .foregroundColor(Color.skyBlueRetro)
                        }
                    }
                }
            }
            
            // Informations supplémentaires avec badges rétro
            HStack(spacing: 12) {
                // Badge payeur
                HStack(spacing: 6) {
                    Circle()
                        .fill(payerColor)
                        .frame(width: 8, height: 8)
                    
                    Text(expense.payer.displayName.dropFirst(2))
                        .font(.appCaption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(payerColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(payerColor.opacity(0.3), lineWidth: 1)
                )
                .foregroundColor(payerColor.darker(by: 0.2))
                .cornerRadius(12)
                
                // Badge auto-génération
                if expense.autoGenerate {
                    HStack(spacing: 4) {
                        Image(systemName: "gear.circle.fill")
                            .font(.caption)
                        Text("Auto")
                            .font(.appCaption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.limeElectric.opacity(0.15))
                    .foregroundColor(Color.limeElectric)
                    .cornerRadius(8)
                }
                
                Spacer()
                
                // Coût annuel
                Text("≈ \(expense.annualCost.formatted(.currency(code: "EUR")))/an")
                    .font(.appCaption2)
                    .foregroundColor(.secondary)
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
        .opacity(expense.isActive ? 1.0 : 0.6)
        .padding(.horizontal, 20)
        .contextMenu {
            Button(action: {
                budgetManager.deleteRecurringExpense(expense)
            }) {
                Label("Supprimer", systemImage: "trash")
            }
            
            if expense.isDue {
                Button(action: {
                    budgetManager.processRecurringExpense(expense)
                }) {
                    Label("Traiter", systemImage: "checkmark.circle")
                }
            }
        }
    }
}

struct AddRecurringExpenseView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var description = ""
    @State private var amount = ""
    @State private var selectedCategory: TransactionCategory = .abonnements
    @State private var selectedPayer: Payer = .pilou
    @State private var selectedFrequency: Frequency = .monthly
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var autoGenerate = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private var categoryColor: Color {
        switch selectedCategory {
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
        NavigationView {
            Form {
                // Section informations générales avec style rétro
                Section {
                    TextField("Description", text: $description)
                        .font(.appBody)
                        .textInputAutocapitalization(.sentences)
                    
                    HStack {
                        Text("💰 Montant")
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
                            .frame(width: 100)
                        
                        Text("€")
                            .font(.appCallout)
                            .foregroundColor(.secondary)
                    }
                    
                    Picker("🏷️ Catégorie", selection: $selectedCategory) {
                        ForEach(TransactionCategory.allCases, id: \.self) { category in
                            HStack {
                                Text(category.icon)
                                Text(category.displayName.dropFirst(2))
                            }
                            .font(.appBody)
                            .tag(category)
                        }
                    }
                    .font(.appBody)
                    
                    Picker("👤 Payeur", selection: $selectedPayer) {
                        ForEach(Payer.allCases, id: \.self) { payer in
                            HStack {
                                Circle()
                                    .fill(payerColorForSelection(payer))
                                    .frame(width: 12, height: 12)
                                Text(payer.displayName.dropFirst(2))
                            }
                            .font(.appBody)
                            .tag(payer)
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
                        
                        Text("📋 Informations générales")
                            .font(.appHeadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.adaptiveText(colorScheme))
                    }
                }
                .listRowBackground(Color.adaptiveSurface(colorScheme))
                
                // Section récurrence
                Section {
                    Picker("📅 Fréquence", selection: $selectedFrequency) {
                        ForEach(Frequency.allCases, id: \.self) { frequency in
                            Text(frequency.displayName)
                                .font(.appBody)
                                .tag(frequency)
                        }
                    }
                    .font(.appBody)
                    
                    DatePicker("📅 Date de début", selection: $startDate, displayedComponents: .date)
                        .font(.appBody)
                    
                    Toggle("📅 Date de fin", isOn: $hasEndDate)
                        .font(.appBody)
                    
                    if hasEndDate {
                        DatePicker("📅 Date de fin", selection: $endDate, displayedComponents: .date)
                            .font(.appBody)
                    }
                    
                    Toggle("🤖 Génération automatique", isOn: $autoGenerate)
                        .font(.appBody)
                        .tint(Color.limeElectric)
                    
                    if autoGenerate {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(Color.skyBlueRetro)
                            
                            Text("Les transactions seront créées automatiquement aux échéances")
                                .font(.appCaption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
                    
                } header: {
                    Text("⏰ Configuration de la récurrence")
                        .font(.appHeadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.adaptiveText(colorScheme))
                }
                .listRowBackground(Color.adaptiveSurface(colorScheme))
                
                // Aperçu avec style rétro
                if !description.isEmpty && !amount.isEmpty {
                    Section {
                        RecurringExpensePreviewView(
                            description: description,
                            amount: Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0,
                            category: selectedCategory,
                            payer: selectedPayer,
                            frequency: selectedFrequency
                        )
                    } header: {
                        Text("👀 Aperçu")
                            .font(.appHeadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.adaptiveText(colorScheme))
                    }
                    .listRowBackground(Color.adaptiveSurface(colorScheme))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.adaptiveBackground(colorScheme))
            .navigationTitle("➕ Nouvelle dépense récurrente")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.turquoiseVintage.opacity(0.1), for: .navigationBar)
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
                        addRecurringExpense()
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
    
    private func payerColorForSelection(_ payer: Payer) -> Color {
        switch payer {
        case .pilou: return Color.skyBlueRetro
        case .doudou: return Color.pinkBubblegum
        case .commun: return Color.limeElectric
        }
    }
    
    private var isFormValid: Bool {
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !amount.isEmpty &&
        (Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0) > 0 &&
        (!hasEndDate || endDate > startDate)
    }
    
    private func addRecurringExpense() {
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
        
        if hasEndDate && endDate <= startDate {
            alertMessage = "La date de fin doit être postérieure à la date de début"
            showingAlert = true
            return
        }
        
        let expense = RecurringExpense(
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: amountValue,
            category: selectedCategory,
            payer: selectedPayer,
            frequency: selectedFrequency,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            autoGenerate: autoGenerate
        )
        
        budgetManager.addRecurringExpense(expense)
        dismiss()
    }
}

struct RecurringExpensePreviewView: View {
    let description: String
    let amount: Double
    let category: TransactionCategory
    let payer: Payer
    let frequency: Frequency
    @Environment(\.colorScheme) private var colorScheme
    
    private var categoryColor: Color {
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
                    Text(description)
                        .font(.appHeadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.adaptiveText(colorScheme))
                    
                    Text(frequency.displayName.dropFirst(2))
                        .font(.appSubheadline)
                        .foregroundColor(categoryColor)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(amount.formatted(.currency(code: "EUR")))
                        .font(.currencyMedium)
                        .fontWeight(.bold)
                        .foregroundColor(Color.adaptiveText(colorScheme))
                    
                    Text("≈ \((frequency.annualMultiplier * amount).formatted(.currency(code: "EUR")))/an")
                        .font(.appCaption2)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(payerColor(payer))
                        .frame(width: 8, height: 8)
                    
                    Text("Payé par \(payer.displayName.dropFirst(2))")
                        .font(.appCaption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(payerColor(payer).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(payerColor(payer).opacity(0.3), lineWidth: 1)
                )
                .foregroundColor(payerColor(payer).darker(by: 0.2))
                .cornerRadius(15)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "eye.fill")
                        .font(.caption2)
                    Text("Aperçu")
                        .font(.appCaption2)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.turquoiseVintage.opacity(0.1))
                .foregroundColor(Color.turquoiseVintage)
                .cornerRadius(8)
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
    
    private func payerColor(_ payer: Payer) -> Color {
        switch payer {
        case .pilou: return Color.skyBlueRetro
        case .doudou: return Color.pinkBubblegum
        case .commun: return Color.limeElectric
        }
    }
}

struct EmptyRecurringExpensesView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            // Illustration avec style rétro
            ZStack {
                Circle()
                    .fill(Color.turquoiseVintage.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Circle()
                    .stroke(Color.turquoiseVintage.opacity(0.3), lineWidth: 2)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "arrow.clockwise.circle")
                    .font(.system(size: 50))
                    .foregroundColor(Color.turquoiseVintage)
            }
            
            VStack(spacing: 12) {
                Text("Aucune dépense récurrente")
                    .font(.appTitle3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.adaptiveText(colorScheme))
                
                Text("Ajoutez vos abonnements et factures\nrécurrentes pour un suivi automatique")
                    .font(.appSubheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // Suggestions avec style rétro
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(Color.khakiGold)
                    Text("Idées : Netflix, Spotify, loyer, assurance...")
                        .font(.appFootnote)
                        .fontWeight(.medium)
                        .foregroundColor(Color.khakiGold)
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(Color.khakiGold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.khakiGold.opacity(0.1))
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
                        .stroke(Color.turquoiseVintage.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
}
