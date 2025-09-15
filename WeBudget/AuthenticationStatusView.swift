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
                .font(.appTitle2) // Space Grotesk SemiBold
                .fontWeight(.bold)
                .foregroundColor(budgetManager.isAuthenticated ? .green : .red)
            
            Text(budgetManager.authenticationStatus)
                .font(.appBody) // Space Grotesk Regular
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            if !budgetManager.isAuthenticated {
                VStack(spacing: 15) {
                    Text("Pour utiliser WeBudget, vous devez :")
                        .font(.appHeadline) // Space Grotesk SemiBold
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "1.circle.fill")
                                .foregroundColor(.blue)
                            Text("Vous connecter à iCloud dans Réglages iOS")
                                .font(.appCallout) // Space Grotesk Regular
                        }
                        
                        HStack {
                            Image(systemName: "2.circle.fill")
                                .foregroundColor(.blue)
                            Text("Activer iCloud Drive")
                                .font(.appCallout) // Space Grotesk Regular
                        }
                        
                        HStack {
                            Image(systemName: "3.circle.fill")
                                .foregroundColor(.blue)
                            Text("Redémarrer l'application")
                                .font(.appCallout) // Space Grotesk Regular
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
                    .font(.buttonText) // Space Grotesk Medium
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}
