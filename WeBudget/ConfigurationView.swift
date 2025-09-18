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
    @Environment(\.colorScheme) private var colorScheme
    
    init() {
        _tempSalaires = State(initialValue: Salaires(pilou: 6000, doudou: 10000))
        _tempBudgets = State(initialValue: Budgets())
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    SalaireInputView(
                        label: "👨 Salaire Pilou",
                        value: $tempSalaires.pilou,
                        color: Color.skyBlueRetro
                    )
                    
                    SalaireInputView(
                        label: "👩 Salaire Doudou",
                        value: $tempSalaires.doudou,
                        color: Color.plumVintage
                    )
                    
                    ProportionDisplayView(salaires: tempSalaires)
                } header: {
                    Text("💰 Revenus du couple")
                        .font(.appSubheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.incomeColor)
                }
                
                Section {
                    ForEach(TransactionCategory.allCases, id: \.self) { category in
                        BudgetInputView(
                            category: category,
                            value: Binding(
                                get: { tempBudgets.budgetForCategory(category) },
                                set: { tempBudgets.setBudgetForCategory(category, amount: $0) }
                            )
                        )
                    }
                } header: {
                    Text("📊 Budgets mensuels")
                        .font(.appSubheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.limeElectric)
                }
                
                Section {
                    RedistributionView(salaires: tempSalaires, budgets: tempBudgets)
                } header: {
                    Text("💳 Redistribution mensuelle")
                        .font(.appSubheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.turquoiseVintage)
                }
            }
            .background(Color.adaptiveBackground(colorScheme))
            .scrollContentBackground(.hidden)
            .navigationTitle("⚙️ Configuration")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.earthTone, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("💾 Sauvegarder") {
                        saveConfiguration()
                    }
                    .font(.buttonText)
                    .retroButtonStyle()
                }
            }
            .onAppear {
                tempSalaires = budgetManager.salaires
                tempBudgets = budgetManager.budgets
            }
            .alert("Configuration sauvegardée !", isPresented: $showingSaveAlert) {
                Button("OK") {
                    // Action OK
                }
                .font(.buttonText)
            } message: {
                Text("Vos paramètres ont été enregistrés avec succès.")
                    .font(.appCallout)
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
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "eurosign.circle")
                        .foregroundColor(color)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(label)
                    .font(.appCallout)
                    .fontWeight(.medium)
                    .foregroundColor(Color.adaptiveText(colorScheme))
            }
            
            Spacer()
            
            TextField("Montant", value: $value, format: .currency(code: "EUR"))
                .font(.currencySmall)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.adaptiveSurface(colorScheme))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(color.opacity(0.3), lineWidth: 1)
                        )
                )
                .keyboardType(.decimalPad)
                .frame(width: 130)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
    }
}

struct BudgetInputView: View {
    let category: TransactionCategory
    @Binding var value: Double
    @Environment(\.colorScheme) private var colorScheme
    
    private var categoryColor: Color {
        switch category {
        case .alimentation: return Color.categoryAlimentation
        case .loyer: return Color.categoryLoyer
        case .abonnements: return Color.categoryAbonnements
        case .habitation: return Color.categoryHabitation
        case .sorties: return Color.categorySorties
        case .credits: return Color.categoryCredits
        case .epargne: return Color.categoryEpargne
        case .transports: return Color.categoryTransports
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(categoryColor.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Text(category.icon)
                        .font(.system(size: 16))
                }
                
                Text(category.displayName.dropFirst(2))
                    .font(.appCallout)
                    .fontWeight(.medium)
                    .foregroundColor(Color.adaptiveText(colorScheme))
            }
            
            Spacer()
            
            TextField("Budget", value: $value, format: .currency(code: "EUR"))
                .font(.currencySmall)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.adaptiveSurface(colorScheme))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(categoryColor.opacity(0.3), lineWidth: 1)
                        )
                )
                .keyboardType(.decimalPad)
                .frame(width: 130)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
    }
}

struct ProportionDisplayView: View {
    let salaires: Salaires
    @Environment(\.colorScheme) private var colorScheme
    
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("📊 Répartition:")
                    .font(.appSubheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.adaptiveText(colorScheme))
                
                Spacer()
                
                Text("Total: \(totalRevenus.formatted(.currency(code: "EUR")))")
                    .font(.appCaption)
                    .fontWeight(.medium)
                    .foregroundColor(Color.incomeColor)
            }
            
            // Statistiques individuelles
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.skyBlueRetro)
                            .frame(width: 8, height: 8)
                        
                        Text("Pilou")
                            .font(.appCaption)
                            .fontWeight(.medium)
                            .foregroundColor(Color.adaptiveText(colorScheme))
                    }
                    
                    Text("\(pourcentagePilou.formatted(.number.precision(.fractionLength(1))))%")
                        .font(.appHeadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.skyBlueRetro)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Doudou")
                            .font(.appCaption)
                            .fontWeight(.medium)
                            .foregroundColor(Color.adaptiveText(colorScheme))
                        
                        Circle()
                            .fill(Color.plumVintage)
                            .frame(width: 8, height: 8)
                    }
                    
                    Text("\(pourcentageDoudou.formatted(.number.precision(.fractionLength(1))))%")
                        .font(.appHeadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.plumVintage)
                }
            }
            
            // Barre de progression stylisée
            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.dimGray.opacity(0.2))
                        .frame(height: 12)
                    
                    HStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.skyBlueRetro)
                            .frame(width: CGFloat(pourcentagePilou) * 2.8)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.plumVintage)
                            .frame(width: CGFloat(pourcentageDoudou) * 2.8)
                    }
                    .frame(height: 12)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.adaptiveSurface(colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.incomeColor.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: Color.incomeColor.opacity(0.1), radius: 6, x: 0, y: 3)
    }
}

struct RedistributionView: View {
    let salaires: Salaires
    let budgets: Budgets
    @Environment(\.colorScheme) private var colorScheme
    
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
    
    private var balanceColor: Color {
        resteRedistribution >= 0 ? Color.limeElectric : Color.softCoral
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // En-tête avec indicateur de santé
            HStack {
                Text("💳 Comptes personnels")
                    .font(.appSubheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.adaptiveText(colorScheme))
                
                Spacer()
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(balanceColor)
                        .frame(width: 8, height: 8)
                    
                    Text(resteRedistribution >= 0 ? "Équilibré" : "Déficit")
                        .font(.appCaption)
                        .fontWeight(.medium)
                        .foregroundColor(balanceColor)
                }
            }
            
            // Redistribution par personne
            HStack(spacing: 16) {
                // Pilou
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.skyBlueRetro.opacity(0.2))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "person.fill")
                                .foregroundColor(Color.skyBlueRetro)
                                .font(.system(size: 16, weight: .medium))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pilou")
                                .font(.appCaption)
                                .foregroundColor(.secondary)
                            
                            Text("Personnel")
                                .font(.appCaption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text(redistribPilou.formatted(.currency(code: "EUR")))
                        .font(.currencyMedium)
                        .fontWeight(.bold)
                        .foregroundColor(Color.skyBlueRetro)
                }
                
                Spacer()
                
                // Doudou
                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 8) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Doudou")
                                .font(.appCaption)
                                .foregroundColor(.secondary)
                            
                            Text("Personnel")
                                .font(.appCaption2)
                                .foregroundColor(.secondary)
                        }
                        
                        ZStack {
                            Circle()
                                .fill(Color.plumVintage.opacity(0.2))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "person.fill")
                                .foregroundColor(Color.plumVintage)
                                .font(.system(size: 16, weight: .medium))
                        }
                    }
                    
                    Text(redistribDoudou.formatted(.currency(code: "EUR")))
                        .font(.currencyMedium)
                        .fontWeight(.bold)
                        .foregroundColor(Color.plumVintage)
                }
            }
            
            Divider()
                .background(Color.dimGray.opacity(0.3))
            
            // Détails financiers
            VStack(spacing: 10) {
                RedistributionRow(
                    title: "Revenus totaux:",
                    value: totalRevenus,
                    color: Color.incomeColor
                )
                
                RedistributionRow(
                    title: "Charges communes:",
                    value: budgets.totalAmount,
                    color: Color.dimGray
                )
                
                Divider()
                    .background(Color.dimGray.opacity(0.3))
                
                HStack {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(balanceColor.opacity(0.2))
                                .frame(width: 24, height: 24)
                            
                            Image(systemName: resteRedistribution >= 0 ? "checkmark" : "exclamationmark")
                                .foregroundColor(balanceColor)
                                .font(.system(size: 12, weight: .bold))
                        }
                        
                        Text("Reste à redistribuer:")
                            .font(.appSubheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.adaptiveText(colorScheme))
                    }
                    
                    Spacer()
                    
                    Text(resteRedistribution.formatted(.currency(code: "EUR")))
                        .font(.currencyMedium)
                        .fontWeight(.bold)
                        .foregroundColor(balanceColor)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.adaptiveSurface(colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(balanceColor.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: balanceColor.opacity(0.1), radius: 6, x: 0, y: 3)
    }
}

struct RedistributionRow: View {
    let title: String
    let value: Double
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            Text(title)
                .font(.appFootnote)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value.formatted(.currency(code: "EUR")))
                .font(.currencySmall)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}
