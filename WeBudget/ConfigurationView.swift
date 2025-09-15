//
//  ConfigurationView.swift
//  WeBudget
//
//  Created by Pierre-Louis L'ALLORET on 14/09/2025.
//

import SwiftUI

struct ConfigurationView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    @State private var showingSaveAlert = false
    @State private var tempSalaires: Salaires
    @State private var tempBudgets: Budgets
    
    init() {
        _tempSalaires = State(initialValue: Salaires(pilou: 6000, doudou: 10000))
        _tempBudgets = State(initialValue: Budgets())
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("👥 Revenus du couple") {
                    SalaireInputView(
                        label: "💼 Salaire Pilou",
                        value: $tempSalaires.pilou
                    )
                    
                    SalaireInputView(
                        label: "💼 Salaire Doudou",
                        value: $tempSalaires.doudou
                    )
                    
                    ProportionDisplayView(salaires: tempSalaires)
                }
                
                Section("💰 Budgets mensuels") {
                    ForEach(TransactionCategory.allCases, id: \.self) { category in
                        BudgetInputView(
                            category: category,
                            value: Binding(
                                get: { tempBudgets.budgetForCategory(category) },
                                set: { tempBudgets.setBudgetForCategory(category, amount: $0) }
                            )
                        )
                    }
                }
                
                Section("💳 Redistribution mensuelle") {
                    RedistributionView(salaires: tempSalaires, budgets: tempBudgets)
                }
            }
            .navigationTitle("⚙️ Configuration")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("💾 Sauvegarder") {
                        saveConfiguration()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                tempSalaires = budgetManager.salaires
                tempBudgets = budgetManager.budgets
            }
            .alert("Configuration sauvegardée !", isPresented: $showingSaveAlert) {
                Button("OK") { }
            }
        }
    }
    
    private func saveConfiguration() {
        budgetManager.salaires = tempSalaires
        budgetManager.budgets = tempBudgets
        budgetManager.saveSalaires()
        budgetManager.saveBudgets()
        showingSaveAlert = true
    }
}

struct SalaireInputView: View {
    let label: String
    @Binding var value: Double
    
    var body: some View {
        HStack {
            Text(label)
                .fontWeight(.medium)
            
            Spacer()
            
            TextField("Montant", value: $value, format: .currency(code: "EUR"))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .frame(width: 120)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct BudgetInputView: View {
    let category: TransactionCategory
    @Binding var value: Double
    
    var body: some View {
        HStack {
            Text(category.displayName)
                .fontWeight(.medium)
            
            Spacer()
            
            TextField("Budget", value: $value, format: .currency(code: "EUR"))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .frame(width: 120)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct ProportionDisplayView: View {
    let salaires: Salaires
    
    private var totalRevenus: Double {
        salaires.pilou + salaires.doudou
    }
    
    private var pourcentagePilou: Double {
        totalRevenus > 0 ? (salaires.pilou / totalRevenus) * 100 : 0
    }
    
    private var pourcentageDoudou: Double {
        totalRevenus > 0 ? (salaires.doudou / totalRevenus) * 100 : 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Répartition:")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack {
                Text("Pilou: \(pourcentagePilou.formatted(.number.precision(.fractionLength(1))))%")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Text("Doudou: \(pourcentageDoudou.formatted(.number.precision(.fractionLength(1))))%")
                    .font(.subheadline)
                    .foregroundColor(.purple)
            }
            
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: CGFloat(pourcentagePilou) * 2)
                
                Rectangle()
                    .fill(Color.purple)
                    .frame(width: CGFloat(pourcentageDoudou) * 2)
            }
            .frame(height: 8)
            .cornerRadius(4)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct RedistributionView: View {
    let salaires: Salaires
    let budgets: Budgets
    
    private var totalRevenus: Double {
        salaires.pilou + salaires.doudou
    }
    
    private var resteRedistribution: Double {
        totalRevenus - budgets.totalAmount
    }
    
    private var redistribPilou: Double {
        totalRevenus > 0 ? resteRedistribution * (salaires.pilou / totalRevenus) : 0
    }
    
    private var redistribDoudou: Double {
        totalRevenus > 0 ? resteRedistribution * (salaires.doudou / totalRevenus) : 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Compte personnel Pilou:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(redistribPilou.formatted(.currency(code: "EUR")))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Compte personnel Doudou:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(redistribDoudou.formatted(.currency(code: "EUR")))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
            }
            
            Divider()
            
            HStack {
                Text("Revenus totaux:")
                    .foregroundColor(.secondary)
                Spacer()
                Text(totalRevenus.formatted(.currency(code: "EUR")))
                    .fontWeight(.medium)
            }
            
            HStack {
                Text("Total charges communes:")
                    .foregroundColor(.secondary)
                Spacer()
                Text(budgets.totalAmount.formatted(.currency(code: "EUR")))
                    .fontWeight(.medium)
            }
            
            HStack {
                Text("Reste à redistribuer:")
                    .fontWeight(.semibold)
                Spacer()
                Text(resteRedistribution.formatted(.currency(code: "EUR")))
                    .fontWeight(.bold)
                    .foregroundColor(resteRedistribution >= 0 ? .green : .red)
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
}
