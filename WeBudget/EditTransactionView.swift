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
    @Environment(\.colorScheme) private var colorScheme
    
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
                Section {
                    // Date avec style rétro
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
                            .font(.appBody) // Space Grotesk Regular
                            .labelsHidden()
                        
                        Spacer()
                    }
                    
                    // Description avec icône
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.peachSunset.opacity(0.15))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "text.cursor")
                                .foregroundColor(Color.peachSunset)
                                .font(.title3)
                        }
                        
                        TextField("Description", text: $description)
                            .font(.appBody) // Space Grotesk Regular
                            .textInputAutocapitalization(.sentences)
                    }
                    
                    // Catégorie avec preview coloré
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(categoryColor.opacity(0.15))
                                .frame(width: 32, height: 32)
                            
                            Text(selectedCategory.icon)
                                .font(.title3)
                        }
                        
                        Picker("Catégorie", selection: $selectedCategory) {
                            ForEach(TransactionCategory.allCases, id: \.self) { category in
                                HStack {
                                    Text(category.icon)
                                    Text(category.displayName.dropFirst(2))
                                }
                                .font(.appBody) // Space Grotesk Regular
                                .tag(category)
                            }
                        }
                        .font(.appBody) // Space Grotesk Regular
                        .labelsHidden()
                        
                        Spacer()
                    }
                    
                    // Montant avec style monétaire
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
                            .font(.appBody) // Space Grotesk Regular
                        
                        Spacer()
                        
                        TextField("0,00", text: $amount)
                            .font(.currencyMedium) // Space Grotesk SemiBold pour les montants
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
                            .font(.appCallout) // Space Grotesk Regular
                            .foregroundColor(.secondary)
                    }
                    
                    // Payeur avec couleurs distinctes
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(payerColor(selectedPayer).opacity(0.15))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(payerColor(selectedPayer))
                                .font(.title3)
                        }
                        
                        Picker("Payeur", selection: $selectedPayer) {
                            ForEach(Payer.allCases, id: \.self) { payer in
                                HStack {
                                    Circle()
                                        .fill(payerColor(payer))
                                        .frame(width: 12, height: 12)
                                    Text(payer.displayName.dropFirst(2))
                                }
                                .font(.appBody) // Space Grotesk Regular
                                .tag(payer)
                            }
                        }
                        .font(.appBody) // Space Grotesk Regular
                        .labelsHidden()
                        
                        Spacer()
                    }
                } header: {
                    HStack {
                        Text("✏️ Détails de la transaction")
                            .font(.appHeadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.adaptiveText(colorScheme))
                        
                        Spacer()
                        
                        // Indicateur de validité
                        Image(systemName: isFormValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundColor(isFormValid ? Color.limeElectric : Color.softCoral)
                            .font(.title3)
                    }
                }
                .listRowBackground(Color.adaptiveSurface(colorScheme))
                
                // Aperçu des modifications avec style rétro
                if !description.isEmpty && !amount.isEmpty {
                    Section {
                        TransactionPreviewViewEdit(
                            date: date,
                            description: description,
                            category: selectedCategory,
                            amount: Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0,
                            payer: selectedPayer
                        )
                    } header: {
                        Text("👀 Aperçu des modifications")
                            .font(.appHeadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.adaptiveText(colorScheme))
                    }
                    .listRowBackground(Color.adaptiveSurface(colorScheme))
                }
                
                // Section des changements avec diff coloré
                if hasChanges {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .foregroundColor(Color.turquoiseVintage)
                                
                                Text("Changements détectés")
                                    .font(.appSubheadline) // Space Grotesk Medium
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.adaptiveText(colorScheme))
                                
                                Spacer()
                                
                                Text("\(changes.count)")
                                    .font(.appCaption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.turquoiseVintage.opacity(0.2))
                                    .foregroundColor(Color.turquoiseVintage)
                                    .cornerRadius(8)
                            }
                            
                            ForEach(changes, id: \.field) { change in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(change.field)
                                        .font(.appCaption)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color.adaptiveText(colorScheme))
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        // Ancienne valeur
                                        HStack {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(Color.softCoral)
                                                .font(.caption)
                                            
                                            Text(change.oldValue)
                                                .font(.appCaption2) // Space Grotesk Light
                                                .strikethrough()
                                                .foregroundColor(Color.softCoral)
                                        }
                                        
                                        // Nouvelle valeur
                                        HStack {
                                            Image(systemName: "plus.circle.fill")
                                                .foregroundColor(Color.limeElectric)
                                                .font(.caption)
                                            
                                            Text(change.newValue)
                                                .font(.appCaption2) // Space Grotesk Light
                                                .foregroundColor(Color.limeElectric)
                                                .fontWeight(.medium)
                                        }
                                    }
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.turquoiseVintage.opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.turquoiseVintage.opacity(0.2), lineWidth: 1)
                                        )
                                )
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("🔄 Résumé des modifications")
                            .font(.appHeadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.adaptiveText(colorScheme))
                    }
                    .listRowBackground(Color.adaptiveSurface(colorScheme))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.adaptiveBackground(colorScheme))
            .navigationTitle("✏️ Modifier transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.turquoiseVintage.opacity(0.1), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .font(.buttonText) // Space Grotesk Medium
                    .foregroundColor(Color.softCoral)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sauvegarder") {
                        updateTransaction()
                    }
                    .font(.buttonText) // Space Grotesk Medium
                    .fontWeight(.semibold)
                    .foregroundColor(isFormValid && hasChanges ? Color.limeElectric : .secondary)
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
    
    private func payerColor(_ payer: Payer) -> Color {
        switch payer {
        case .pilou: return Color.skyBlueRetro
        case .doudou: return Color.pinkBubblegum
        case .commun: return Color.limeElectric
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
    
    private var payerColor: Color {
        switch payer {
        case .pilou: return Color.skyBlueRetro
        case .doudou: return Color.pinkBubblegum
        case .commun: return Color.limeElectric
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 15) {
                // Icône de catégorie avec design rétro
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
                        .font(.appHeadline) // Space Grotesk SemiBold
                        .fontWeight(.semibold)
                        .foregroundColor(Color.adaptiveText(colorScheme))
                    
                    Text(category.displayName.dropFirst(2))
                        .font(.appSubheadline) // Space Grotesk Medium
                        .foregroundColor(categoryColor)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("-\(amount.formatted(.currency(code: "EUR")))")
                        .font(.currencyMedium) // Space Grotesk SemiBold pour les montants
                        .fontWeight(.bold)
                        .foregroundColor(Color.softCoral)
                    
                    Text(date.formatted(.dateTime.day().month().year()))
                        .font(.appCaption) // Space Grotesk Regular
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 12) {
                // Badge du payeur avec couleur spécifique
                HStack(spacing: 6) {
                    Circle()
                        .fill(payerColor)
                        .frame(width: 8, height: 8)
                    
                    Text("Payé par \(payer.displayName.dropFirst(2))")
                        .font(.appCaption) // Space Grotesk Regular
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(payerColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(payerColor.opacity(0.3), lineWidth: 1)
                )
                .foregroundColor(payerColor.darker(by: 0.2))
                .cornerRadius(15)
                
                Spacer()
                
                // Badge "Aperçu"
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
}
