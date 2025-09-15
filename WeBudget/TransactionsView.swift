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
                // Filtres
                FilterView(selectedCategory: $selectedCategory)
                
                // Liste des transactions
                if filteredTransactions.isEmpty {
                    EmptyTransactionsView()
                } else {
                    List {
                        ForEach(filteredTransactions) { transaction in
                            TransactionDetailRowView(transaction: transaction)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button("Supprimer", role: .destructive) {
                                        budgetManager.deleteTransaction(transaction)
                                    }
                                    .font(.buttonText) // Space Grotesk Medium
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button("Modifier") {
                                        transactionToEdit = transaction
                                        showingEditTransaction = true
                                    }
                                    .font(.buttonText) // Space Grotesk Medium
                                    .tint(.blue)
                                }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Rechercher une transaction...")
                }
            }
            .navigationTitle("Dépenses")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddTransaction = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
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
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: "Toutes",
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }
                
                ForEach(TransactionCategory.allCases, id: \.self) { category in
                    FilterChip(
                        title: category.icon,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = selectedCategory == category ? nil : category
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.appSubheadline) // Space Grotesk Medium
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct TransactionDetailRowView: View {
    let transaction: Transaction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(transaction.category.icon)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(transaction.description)
                        .font(.appHeadline) // Space Grotesk SemiBold
                        .fontWeight(.medium)
                    
                    Text(transaction.category.displayName.dropFirst(2))
                        .font(.appCaption) // Space Grotesk Regular
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("-\(transaction.amount.formatted(.currency(code: "EUR")))")
                        .font(.currencyMedium) // Space Grotesk SemiBold
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text(transaction.date.formatted(.dateTime.day().month().year()))
                        .font(.appCaption) // Space Grotesk Regular
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Text("Payé par: \(transaction.payer.displayName)")
                    .font(.appCaption) // Space Grotesk Regular
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(transaction.category.color.opacity(0.2))
                    .foregroundColor(transaction.category.color)
                    .cornerRadius(6)
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

struct EmptyTransactionsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard.trianglebadge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Aucune transaction")
                .font(.appHeadline) // Space Grotesk SemiBold
                .foregroundColor(.secondary)
            
            Text("Ajoutez votre première transaction\nen appuyant sur le bouton +")
                .font(.appSubheadline) // Space Grotesk Medium
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
