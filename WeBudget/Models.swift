// Models.swift - Version corrigée
import Foundation
import SwiftUI

struct Salaires: Codable {
    var pilou: Double
    var doudou: Double
}

struct Budgets: Codable {
    var alimentation: Double = 500
    var loyer: Double = 1200
    var abonnements: Double = 200
    var habitation: Double = 300
    var sorties: Double = 400
    var credits: Double = 800
    var epargne: Double = 1000
    var transports: Double = 300
    
    var totalAmount: Double {
        alimentation + loyer + abonnements + habitation + sorties + credits + epargne + transports
    }
    
    func budgetForCategory(_ category: TransactionCategory) -> Double {
        switch category {
        case .alimentation: return alimentation
        case .loyer: return loyer
        case .abonnements: return abonnements
        case .habitation: return habitation
        case .sorties: return sorties
        case .credits: return credits
        case .epargne: return epargne
        case .transports: return transports
        }
    }
    
    mutating func setBudgetForCategory(_ category: TransactionCategory, amount: Double) {
        switch category {
        case .alimentation: alimentation = amount
        case .loyer: loyer = amount
        case .abonnements: abonnements = amount
        case .habitation: habitation = amount
        case .sorties: sorties = amount
        case .credits: credits = amount
        case .epargne: epargne = amount
        case .transports: transports = amount
        }
    }
}

// ✅ CORRECTION: Transaction avec id paramétrable
struct Transaction: Identifiable, Codable {
    let id: UUID
    let date: Date
    let description: String
    let category: TransactionCategory
    let amount: Double
    let payer: Payer
    
    // Initializer principal avec tous les paramètres
    init(id: UUID = UUID(), date: Date, description: String, category: TransactionCategory, amount: Double, payer: Payer) {
        self.id = id
        self.date = date
        self.description = description
        self.category = category
        self.amount = amount
        self.payer = payer
    }
}

enum TransactionCategory: String, CaseIterable, Codable {
    case alimentation = "alimentation"
    case loyer = "loyer"
    case abonnements = "abonnements"
    case habitation = "habitation"
    case sorties = "sorties"
    case credits = "credits"
    case epargne = "epargne"
    case transports = "transports"
    
    var displayName: String {
        switch self {
        case .alimentation: return "🥗 Alimentation"
        case .loyer: return "🏠 Loyer"
        case .abonnements: return "📱 Abonnements"
        case .habitation: return "🔨 Habitation"
        case .sorties: return "🍽️ Sorties/Restaurants"
        case .credits: return "💳 Crédits"
        case .epargne: return "💰 Épargne"
        case .transports: return "🚗 Transports"
        }
    }
    
    var icon: String {
        switch self {
        case .alimentation: return "🥗"
        case .loyer: return "🏠"
        case .abonnements: return "📱"
        case .habitation: return "🔨"
        case .sorties: return "🍽️"
        case .credits: return "💳"
        case .epargne: return "💰"
        case .transports: return "🚗"
        }
    }
    
    var color: Color {
        switch self {
        case .alimentation: return .green
        case .loyer: return .blue
        case .abonnements: return .orange
        case .habitation: return .purple
        case .sorties: return .red
        case .credits: return .teal
        case .epargne: return .indigo
        case .transports: return .yellow
        }
    }
}

enum Payer: String, CaseIterable, Codable {
    case pilou = "pilou"
    case doudou = "doudou"
    case commun = "commun"
    
    var displayName: String {
        switch self {
        case .pilou: return "👨 Pilou"
        case .doudou: return "👩 Doudou"
        case .commun: return "👫 Compte commun"
        }
    }
}
