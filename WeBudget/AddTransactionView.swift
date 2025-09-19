//
//  AddTransactionView.swift
//  WeBudget
//
//  Created by Pierre-Louis L'ALLORET on 14/09/2025.
//

// AddTransactionView.swift
import SwiftUI

struct AddTransactionView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var date = Date()
    @State private var description = ""
    @State private var selectedCategory: TransactionCategory = .alimentation
    @State private var amount = ""
    @State private var selectedPayer: Payer = .pilou
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Détails de la transaction") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .font(.appBody) // Space Grotesk Regular
                    
                    TextField("Description", text: $description)
                        .font(.appBody) // Space Grotesk Regular
                        .textInputAutocapitalization(.sentences)
                    
                    Picker("Catégorie", selection: $selectedCategory) {
                        ForEach(TransactionCategory.allCases, id: \.self) { category in
                            Text(category.displayName)
                                .font(.appBody) // Space Grotesk Regular
                                .tag(category)
                        }
                    }
                    .font(.appBody) // Space Grotesk Regular
                    
                    HStack {
                        Text("Montant")
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
                    
                    Picker("Payeur", selection: $selectedPayer) {
                        ForEach(Payer.allCases, id: \.self) { payer in
                            Text(payer.displayName)
                                .font(.appBody) // Space Grotesk Regular
                                .tag(payer)
                        }
                    }
                    .font(.appBody) // Space Grotesk Regular
                }
                
                if !description.isEmpty && !amount.isEmpty {
                    Section("Résumé") {
                        TransactionPreviewView(
                            date: date,
                            description: description,
                            category: selectedCategory,
                            amount: Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0,
                            payer: selectedPayer
                        )
                    }
                }
            }
            .navigationTitle("Nouvelle transaction")
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
                        addTransaction()
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
        (Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0) > 0
    }
    
    private func addTransaction() {
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
        
        let transaction = Transaction(
            date: date,
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            category: selectedCategory,
            amount: amountValue,
            payer: selectedPayer
        )
        
        budgetManager.saveTransaction(transaction)
        dismiss()
    }
}

struct TransactionPreviewView: View {
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
