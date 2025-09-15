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
            VStack {
                // Résumé en haut
                RecurringSummaryCard()
                
                // Filtres
                FrequencyFilterView(selectedFrequency: $selectedFrequency)
                
                // Liste des dépenses
                if filteredExpenses.isEmpty {
                    EmptyRecurringExpensesView()
                } else {
                    List {
                        ForEach(groupedExpenses, id: \.0) { frequencyName, expenses in
                            Section(frequencyName) {
                                ForEach(expenses) { expense in
                                    RecurringExpenseRowView(expense: expense)
                                        .swipeActions(edge: .trailing) {
                                            Button("Supprimer", role: .destructive) {
                                                budgetManager.deleteRecurringExpense(expense)
                                            }
                                            
                                            if expense.isDue {
                                                Button("Traiter") {
                                                    budgetManager.processRecurringExpense(expense)
                                                }
                                                .tint(.blue)
                                            }
                                        }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Dépenses récurrentes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddExpense = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddRecurringExpenseView()
            }
        }
    }
}

struct RecurringSummaryCard: View {
    @EnvironmentObject var budgetManager: BudgetManager
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total mensuel")
                        .font(.appCaption) // Space Grotesk Regular
                        .foregroundColor(.secondary)
                    
                    Text(budgetManager.totalMonthlyRecurring.formatted(.currency(code: "EUR")))
                        .font(.currencyMedium) // Space Grotesk SemiBold
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("⏰ En attente")
                        .font(.appCaption) // Space Grotesk Regular
                        .foregroundColor(.secondary)
                    
                    Text("\(budgetManager.dueRecurringExpenses.count)")
                        .font(.appTitle2) // Space Grotesk SemiBold
                        .fontWeight(.bold)
                        .foregroundColor(budgetManager.dueRecurringExpenses.isEmpty ? .green : .orange)
                }
            }
            
            if !budgetManager.dueRecurringExpenses.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text("\(budgetManager.dueRecurringExpenses.count) dépense(s) à traiter")
                        .font(.appSubheadline) // Space Grotesk Medium
                        .foregroundColor(.orange)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct FrequencyFilterView: View {
    @Binding var selectedFrequency: Frequency?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: "Toutes",
                    isSelected: selectedFrequency == nil
                ) {
                    selectedFrequency = nil
                }
                
                ForEach(Frequency.allCases, id: \.self) { frequency in
                    FilterChip(
                        title: frequency.shortName,
                        isSelected: selectedFrequency == frequency
                    ) {
                        selectedFrequency = selectedFrequency == frequency ? nil : frequency
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

struct RecurringExpenseRowView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    let expense: RecurringExpense
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Icône et statut
                VStack {
                    Text(expense.category.icon)
                        .font(.title2)
                    
                    if expense.isDue {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                    } else if !expense.isActive {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 8, height: 8)
                    }
                }
                
                // Informations principales
                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.description)
                        .font(.appHeadline) // Space Grotesk SemiBold
                        .fontWeight(.medium)
                    
                    HStack {
                        Text(expense.category.displayName.dropFirst(2))
                            .font(.appCaption) // Space Grotesk Regular
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.appCaption) // Space Grotesk Regular
                            .foregroundColor(.secondary)
                        
                        Text(expense.frequency.displayName.dropFirst(2))
                            .font(.appCaption) // Space Grotesk Regular
                            .foregroundColor(expense.frequency.color)
                    }
                    
                    if let endDate = expense.endDate {
                        Text("Jusqu'au \(endDate.formatted(.dateTime.day().month().year()))")
                            .font(.appCaption2) // Space Grotesk Light
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                // Montant et échéance
                VStack(alignment: .trailing, spacing: 4) {
                    Text(expense.amount.formatted(.currency(code: "EUR")))
                        .font(.currencyMedium) // Space Grotesk SemiBold
                        .fontWeight(.bold)
                        .foregroundColor(expense.isActive ? .primary : .gray)
                    
                    if expense.isDue {
                        Text("Due maintenant")
                            .font(.appCaption) // Space Grotesk Regular
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    } else {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Prochaine:")
                                .font(.appCaption2) // Space Grotesk Light
                                .foregroundColor(.secondary)
                            
                            Text(expense.nextDueDate.formatted(.dateTime.day().month()))
                                .font(.appCaption) // Space Grotesk Regular
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            // Informations supplémentaires
            HStack {
                Text("Payé par: \(expense.payer.displayName)")
                    .font(.appCaption) // Space Grotesk Regular
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(expense.category.color.opacity(0.2))
                    .foregroundColor(expense.category.color)
                    .cornerRadius(6)
                
                if expense.autoGenerate {
                    Text("Auto")
                        .font(.appCaption) // Space Grotesk Regular
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(6)
                }
                
                Spacer()
                
                Text("≈ \(expense.annualCost.formatted(.currency(code: "EUR")))/an")
                    .font(.appCaption2) // Space Grotesk Light
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .opacity(expense.isActive ? 1.0 : 0.6)
    }
}

struct AddRecurringExpenseView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    @Environment(\.dismiss) private var dismiss
    
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
    
    var body: some View {
        NavigationView {
            Form {
                Section("📋 Informations générales") {
                    TextField("Description", text: $description)
                        .font(.appBody) // Space Grotesk Regular
                        .textInputAutocapitalization(.sentences)
                    
                    HStack {
                        Text("💰 Montant")
                            .font(.appBody) // Space Grotesk Regular
                        
                        Spacer()
                        
                        TextField("0,00", text: $amount)
                            .font(.currencyMedium) // Space Grotesk SemiBold
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 100)
                            .multilineTextAlignment(.trailing)
                        
                        Text("€")
                            .font(.appCallout) // Space Grotesk Regular
                            .foregroundColor(.secondary)
                    }
                    
                    Picker("🏷️ Catégorie", selection: $selectedCategory) {
                        ForEach(TransactionCategory.allCases, id: \.self) { category in
                            Text(category.displayName)
                                .font(.appBody) // Space Grotesk Regular
                                .tag(category)
                        }
                    }
                    .font(.appBody) // Space Grotesk Regular
                    
                    Picker("👤 Payeur", selection: $selectedPayer) {
                        ForEach(Payer.allCases, id: \.self) { payer in
                            Text(payer.displayName)
                                .font(.appBody) // Space Grotesk Regular
                                .tag(payer)
                        }
                    }
                    .font(.appBody) // Space Grotesk Regular
                }
                
                Section("⏰ Récurrence") {
                    Picker("📅 Fréquence", selection: $selectedFrequency) {
                        ForEach(Frequency.allCases, id: \.self) { frequency in
                            Text(frequency.displayName)
                                .font(.appBody) // Space Grotesk Regular
                                .tag(frequency)
                        }
                    }
                    .font(.appBody) // Space Grotesk Regular
                    
                    DatePicker("📅 Date de début", selection: $startDate, displayedComponents: .date)
                        .font(.appBody) // Space Grotesk Regular
                    
                    Toggle("📅 Date de fin", isOn: $hasEndDate)
                        .font(.appBody) // Space Grotesk Regular
                    
                    if hasEndDate {
                        DatePicker("📅 Date de fin", selection: $endDate, displayedComponents: .date)
                            .font(.appBody) // Space Grotesk Regular
                    }
                    
                    Toggle("🤖 Génération automatique", isOn: $autoGenerate)
                        .font(.appBody) // Space Grotesk Regular
                    
                    if autoGenerate {
                        Text("Les transactions seront créées automatiquement aux échéances")
                            .font(.appCaption) // Space Grotesk Regular
                            .foregroundColor(.secondary)
                    }
                }
                
                if !description.isEmpty && !amount.isEmpty {
                    Section("📊 Aperçu") {
                        RecurringExpensePreviewView(
                            description: description,
                            amount: Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0,
                            category: selectedCategory,
                            payer: selectedPayer,
                            frequency: selectedFrequency
                        )
                    }
                }
            }
            .navigationTitle("➕ Nouvelle dépense récurrente")
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
                        addRecurringExpense()
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category.icon)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(description)
                        .font(.appHeadline) // Space Grotesk SemiBold
                        .fontWeight(.medium)
                    
                    Text(frequency.displayName.dropFirst(2))
                        .font(.appCaption) // Space Grotesk Regular
                        .foregroundColor(frequency.color)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(amount.formatted(.currency(code: "EUR")))
                        .font(.currencyMedium) // Space Grotesk SemiBold
                        .fontWeight(.bold)
                    
                    Text("≈ \((frequency.annualMultiplier * amount).formatted(.currency(code: "EUR")))/an")
                        .font(.appCaption2) // Space Grotesk Light
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Text("Payé par: \(payer.displayName)")
                    .font(.appCaption) // Space Grotesk Regular
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(category.color.opacity(0.2))
                    .foregroundColor(category.color)
                    .cornerRadius(6)
                
                Spacer()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct EmptyRecurringExpensesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.clockwise.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Aucune dépense récurrente")
                .font(.appHeadline) // Space Grotesk SemiBold
                .foregroundColor(.secondary)
            
            Text("Ajoutez vos abonnements et factures\nrécurrentes pour un suivi automatique")
                .font(.appSubheadline) // Space Grotesk Medium
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
