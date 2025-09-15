// AuthenticationStatusView.swift
import SwiftUI

struct AuthenticationStatusView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: budgetManager.isAuthenticated ? "checkmark.icloud.fill" : "xmark.icloud.fill")
                .font(.system(size: 60))
                .foregroundColor(budgetManager.isAuthenticated ? .green : .red)
            
            Text(budgetManager.isAuthenticated ? "Connecté à iCloud" : "Non connecté à iCloud")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(budgetManager.isAuthenticated ? .green : .red)
            
            Text(budgetManager.authenticationStatus)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            if !budgetManager.isAuthenticated {
                VStack(spacing: 15) {
                    Text("Pour utiliser WeBudget, vous devez :")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "1.circle.fill")
                                .foregroundColor(.blue)
                            Text("Vous connecter à iCloud dans Réglages iOS")
                        }
                        
                        HStack {
                            Image(systemName: "2.circle.fill")
                                .foregroundColor(.blue)
                            Text("Activer iCloud Drive")
                        }
                        
                        HStack {
                            Image(systemName: "3.circle.fill")
                                .foregroundColor(.blue)
                            Text("Redémarrer l'application")
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding()
            }
            
            Button {
                budgetManager.checkAuthentication()
            } label: {
                Label("Vérifier à nouveau", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}
