//
//  TransactionsView.swift
//  WeBudget
//
//  Created by Pierre-Louis L'ALLORET on 14/09/2025.
//

import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    @State private var showingAddTransaction = false
    @State private var showingEditTransaction = false
    @State private var transactionToEdit: Transaction?
    @State private var selectedCategory: TransactionCategory?
    @State private var searchText = ""
    @Environment(\.colorScheme) private var colorScheme
    
    private var filteredTransactions: [Transaction] {
        var transactions = budgetManager.transactions
        
        if let category = selectedCategory {
            transactions = transactions.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            transactions = transactions.filter {
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return transactions.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Filtres avec fond transparent
                FilterView(selectedCategory: $selectedCategory)
                
                // Liste des transactions
                if filteredTransactions.isEmpty {
                    EmptyTransactionsView()
                } else {
                    List {
                        ForEach(filteredTransactions) { transaction in
                            TransactionDetailRowView(transaction: transaction)
                                .listRowBackground(Color.clear) // Fond transparent pour la cellule de liste
                                .listRowSeparator(.hidden) // Masquer les séparateurs
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button("Supprimer", role: .destructive) {
                                        budgetManager.deleteTransaction(transaction)
                                    }
                                    .font(.buttonText) // Space Grotesk Medium
                                    .tint(Color.softCoral)
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button("Modifier") {
                                        transactionToEdit = transaction
                                        showingEditTransaction = true
                                    }
                                    .font(.buttonText) // Space Grotesk Medium
                                    .tint(Color.skyBlueRetro)
                                }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden) // Masquer le fond par défaut de la liste
                    .searchable(text: $searchText, prompt: "Rechercher une transaction...")
                }
            }
            .background(Color.adaptiveBackground(colorScheme))
            .navigationTitle("Dépenses")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar) // Masquer le fond de la barre de navigation
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddTransaction = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.limeToSky)
                                .frame(width: 32, height: 32)
                                .shadow(color: Color.limeElectric.opacity(0.3), radius: 4, x: 0, y: 2)
                            
                            Image(systemName: "plus")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color.brownDeep)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView()
            }
            .sheet(isPresented: $showingEditTransaction) {
                if let transaction = transactionToEdit {
                    EditTransactionView(transaction: transaction)
                }
            }
        }
    }
}

struct FilterView: View {
    @Binding var selectedCategory: TransactionCategory?
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: "Toutes",
                    isSelected: selectedCategory == nil,
                    accentColor: Color.limeElectric
                ) {
                    selectedCategory = nil
                }
                
                ForEach(TransactionCategory.allCases, id: \.self) { category in
                    FilterChip(
                        title: category.icon,
                        isSelected: selectedCategory == category,
                        accentColor: categoryColor(for: category)
                    ) {
                        selectedCategory = selectedCategory == category ? nil : category
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
        // Suppression du fond blanc/surface - seuls les chips ont un fond
    }
    
    private func categoryColor(for category: TransactionCategory) -> Color {
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
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.appSubheadline) // Space Grotesk Medium
                .fontWeight(.semibold)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? accentColor : Color.adaptiveSurface(colorScheme))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(accentColor.opacity(0.4), lineWidth: isSelected ? 2 : 1)
                        )
                )
                .foregroundColor(isSelected ? Color.brownDeep : Color.adaptiveText(colorScheme))
                .shadow(color: isSelected ? accentColor.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TransactionDetailRowView: View {
    let transaction: Transaction
    @Environment(\.colorScheme) private var colorScheme
    
    private var categoryColor: Color {
        switch transaction.category {
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
        switch transaction.payer {
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
                    
                    Text(transaction.category.icon)
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.description)
                        .font(.appHeadline) // Space Grotesk SemiBold
                        .fontWeight(.semibold)
                        .foregroundColor(Color.adaptiveText(colorScheme))
                    
                    Text(transaction.category.displayName.dropFirst(2))
                        .font(.appSubheadline) // Space Grotesk Medium
                        .foregroundColor(categoryColor)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("-\(transaction.amount.formatted(.currency(code: "EUR")))")
                        .font(.currencyMedium) // Space Grotesk SemiBold
                        .fontWeight(.bold)
                        .foregroundColor(Color.softCoral)
                    
                    Text(transaction.date.formatted(.dateTime.day().month().year()))
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
                    
                    Text(transaction.payer.displayName)
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
                
                // Badge de la date relative
                Text(relativeDate)
                    .font(.appCaption2) // Space Grotesk Light
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.dimGray.opacity(0.1))
                    .foregroundColor(.secondary)
                    .cornerRadius(8)
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
        .padding(.horizontal, 16) // Espacement par rapport aux bords
        .padding(.vertical, 6) // Espacement vertical entre les transactions
    }
    
    private var relativeDate: String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(transaction.date) {
            return "Aujourd'hui"
        } else if calendar.isDateInYesterday(transaction.date) {
            return "Hier"
        } else {
            let days = calendar.dateComponents([.day], from: transaction.date, to: now).day ?? 0
            if days < 7 {
                return "Il y a \(days)j"
            } else if days < 30 {
                let weeks = days / 7
                return "Il y a \(weeks)sem"
            } else {
                return transaction.date.formatted(.dateTime.day().month())
            }
        }
    }
}

struct EmptyTransactionsView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            // Illustration avec style rétro
            ZStack {
                Circle()
                    .fill(Color.limeElectric.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Circle()
                    .stroke(Color.limeElectric.opacity(0.3), lineWidth: 2)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "creditcard.trianglebadge.exclamationmark")
                    .font(.system(size: 50))
                    .foregroundColor(Color.limeElectric)
            }
            
            VStack(spacing: 12) {
                Text("Aucune transaction")
                    .font(.appTitle3) // Space Grotesk SemiBold
                    .fontWeight(.bold)
                    .foregroundColor(Color.adaptiveText(colorScheme))
                
                Text("Ajoutez votre première transaction\nen appuyant sur le bouton +")
                    .font(.appSubheadline) // Space Grotesk Medium
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.adaptiveSurface(colorScheme).opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.limeElectric.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
}
