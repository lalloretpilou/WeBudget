//
//  EditTransactionView.swift
//  WeBudget
//
//  Created by Pierre-Louis L'ALLORET on 15/09/2025.
//

import SwiftUI

struct EditTransactionView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    @Environment(\.dismiss) private var dismiss
    
    let transaction: Transaction
    
    @State private var date: Date
    @State private var description: String
    @State private var selectedCategory: TransactionCategory
    @State private var amount: String
    @State private var selectedPayer: Payer
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(transaction: Transaction) {
        self.transaction = transaction
        _date = State(initialValue: transaction.date)
        _description = State(initialValue: transaction.description)
        _selectedCategory = State(initialValue: transaction.category)
        _amount = State(initialValue: String(transaction.amount).replacingOccurrences(of: ".", with: ","))
        _selectedPayer = State(initialValue: transaction.payer)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("📋 Détails de la transaction") {
                    DatePicker("📅 Date", selection: $date, displayedComponents: .date)
                        .font(.appBody) // Space Grotesk Regular
                    
                    TextField("📝 Description", text: $description)
                        .font(.appBody) // Space Grotesk Regular
                        .textInputAutocapitalization(.sentences)
                    
                    Picker("🏷️ Catégorie", selection: $selectedCategory) {
                        ForEach(TransactionCategory.allCases, id: \.self) { category in
                            Text(category.displayName)
                                .font(.appBody) // Space Grotesk Regular
                                .tag(category)
                        }
                    }
                    .font(.appBody) // Space Grotesk Regular
                    
                    HStack {
                        Text("💰 Montant")
                            .font(.appBody) // Space Grotesk Regular
                        
                        Spacer()
                        
                        TextField("0,00", text: $amount)
                            .font(.currencyMedium) // Space Grotesk SemiBold pour les montants
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 100)
                            .multilineTextAlignment(.trailing)
                        
                        Text("€")
                            .font(.appCallout) // Space Grotesk Regular
                            .foregroundColor(.secondary)
                    }
                    
                    Picker("👤 Payeur", selection: $selectedPayer) {
                        ForEach(Payer.allCases, id: \.self) { payer in
                            Text(payer.displayName)
                                .font(.appBody) // Space Grotesk Regular
                                .tag(payer)
                        }
                    }
                    .font(.appBody) // Space Grotesk Regular
                }
                
                if !description.isEmpty && !amount.isEmpty {
                    Section("📋 Aperçu des modifications") {
                        TransactionPreviewViewEdit(
                            date: date,
                            description: description,
                            category: selectedCategory,
                            amount: Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0,
                            payer: selectedPayer
                        )
                    }
                }
                
                if hasChanges {
                    Section("🔄 Modifications") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Changements détectés :")
                                .font(.appSubheadline) // Space Grotesk Medium
                                .fontWeight(.medium)
                            
                            ForEach(changes, id: \.field) { change in
                                HStack {
                                    Text(change.field)
                                        .font(.appCaption) // Space Grotesk Regular
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(change.oldValue)
                                            .font(.appCaption2) // Space Grotesk Light
                                            .strikethrough()
                                            .foregroundColor(.red)
                                        Text(change.newValue)
                                            .font(.appCaption2) // Space Grotesk Light
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("✏️ Modifier transaction")
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
                        updateTransaction()
                    }
                    .font(.buttonText) // Space Grotesk Medium
                    .fontWeight(.semibold)
                    .disabled(!isFormValid || !hasChanges)
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
        (Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0) > 0
    }
    
    private var hasChanges: Bool {
        date != transaction.date ||
        description.trimmingCharacters(in: .whitespacesAndNewlines) != transaction.description ||
        selectedCategory != transaction.category ||
        (Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0) != transaction.amount ||
        selectedPayer != transaction.payer
    }
    
    private var changes: [FieldChange] {
        var changesList: [FieldChange] = []
        
        if date != transaction.date {
            changesList.append(FieldChange(
                field: "Date",
                oldValue: transaction.date.formatted(.dateTime.day().month().year()),
                newValue: date.formatted(.dateTime.day().month().year())
            ))
        }
        
        if description.trimmingCharacters(in: .whitespacesAndNewlines) != transaction.description {
            changesList.append(FieldChange(
                field: "Description",
                oldValue: transaction.description,
                newValue: description.trimmingCharacters(in: .whitespacesAndNewlines)
            ))
        }
        
        if selectedCategory != transaction.category {
            changesList.append(FieldChange(
                field: "Catégorie",
                oldValue: String(transaction.category.displayName.dropFirst(2)),
                newValue: String(selectedCategory.displayName.dropFirst(2))
            ))
        }
        
        let newAmount = Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0
        if newAmount != transaction.amount {
            changesList.append(FieldChange(
                field: "Montant",
                oldValue: transaction.amount.formatted(.currency(code: "EUR")),
                newValue: newAmount.formatted(.currency(code: "EUR"))
            ))
        }
        
        if selectedPayer != transaction.payer {
            changesList.append(FieldChange(
                field: "Payeur",
                oldValue: String(transaction.payer.displayName.dropFirst(2)),
                newValue: String(selectedPayer.displayName.dropFirst(2))
            ))
        }
        
        return changesList
    }
    
    private func updateTransaction() {
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
        
        let updatedTransaction = Transaction(
            id: transaction.id, // Conserver le même ID
            date: date,
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            category: selectedCategory,
            amount: amountValue,
            payer: selectedPayer
        )
        
        budgetManager.updateTransaction(updatedTransaction)
        dismiss()
    }
}

struct FieldChange {
    let field: String
    let oldValue: String
    let newValue: String
}

struct TransactionPreviewViewEdit: View {
    let date: Date
    let description: String
    let category: TransactionCategory
    let amount: Double
    let payer: Payer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category.icon)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(description)
                        .font(.appHeadline) // Space Grotesk SemiBold
                        .fontWeight(.medium)
                    
                    Text(category.displayName.dropFirst(2))
                        .font(.appCaption) // Space Grotesk Regular
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("-\(amount.formatted(.currency(code: "EUR")))")
                        .font(.currencyMedium) // Space Grotesk SemiBold pour les montants
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text(date.formatted(.dateTime.day().month().year()))
                        .font(.appCaption) // Space Grotesk Regular
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
