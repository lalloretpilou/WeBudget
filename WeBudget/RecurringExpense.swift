//
//  RecurringExpense.swift
//  WeBudget
//
//  Created by Pierre-Louis L'ALLORET on 15/09/2025.
//

import Foundation
import SwiftUI

// MARK: - Dépenses Récurrentes
struct RecurringExpense: Identifiable, Codable {
    let id: UUID
    let description: String
    let amount: Double
    let category: TransactionCategory
    let payer: Payer
    let frequency: Frequency
    let startDate: Date
    let nextDueDate: Date
    let isActive: Bool
    let endDate: Date? // Pour les abonnements temporaires
    let lastProcessedDate: Date?
    let autoGenerate: Bool // Génère automatiquement la transaction
    
    init(
        id: UUID = UUID(),
        description: String,
        amount: Double,
        category: TransactionCategory,
        payer: Payer,
        frequency: Frequency,
        startDate: Date,
        isActive: Bool = true,
        endDate: Date? = nil,
        autoGenerate: Bool = false
    ) {
        self.id = id
        self.description = description
        self.amount = amount
        self.category = category
        self.payer = payer
        self.frequency = frequency
        self.startDate = startDate
        self.nextDueDate = frequency.nextDueDate(from: startDate)
        self.isActive = isActive
        self.endDate = endDate
        self.lastProcessedDate = nil
        self.autoGenerate = autoGenerate
    }
    
    // Calculer la prochaine échéance
    func calculateNextDueDate() -> Date {
        let baseDate = lastProcessedDate ?? startDate
        return frequency.nextDueDate(from: baseDate)
    }
    
    // Vérifier si la dépense est due
    var isDue: Bool {
        return Date() >= nextDueDate && isActive
    }
    
    // Jours restants avant échéance
    var daysUntilDue: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: nextDueDate).day ?? 0
        return max(0, days)
    }
    
    // Coût annuel estimé
    var annualCost: Double {
        return frequency.annualMultiplier * amount
    }
}

enum Frequency: String, CaseIterable, Codable {
    case weekly = "weekly"
    case biweekly = "biweekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case biannual = "biannual"
    case annual = "annual"
    
    var displayName: String {
        switch self {
        case .weekly: return "📅 Hebdomadaire"
        case .biweekly: return "📅 Bi-mensuel"
        case .monthly: return "📅 Mensuel"
        case .quarterly: return "📅 Trimestriel"
        case .biannual: return "📅 Semestriel"
        case .annual: return "📅 Annuel"
        }
    }
    
    var shortName: String {
        switch self {
        case .weekly: return "sem."
        case .biweekly: return "2 sem."
        case .monthly: return "mois"
        case .quarterly: return "trim."
        case .biannual: return "6 mois"
        case .annual: return "an"
        }
    }
    
    var annualMultiplier: Double {
        switch self {
        case .weekly: return 52
        case .biweekly: return 26
        case .monthly: return 12
        case .quarterly: return 4
        case .biannual: return 2
        case .annual: return 1
        }
    }
    
    func nextDueDate(from date: Date) -> Date {
        let calendar = Calendar.current
        
        switch self {
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: date) ?? date
        case .biannual:
            return calendar.date(byAdding: .month, value: 6, to: date) ?? date
        case .annual:
            return calendar.date(byAdding: .year, value: 1, to: date) ?? date
        }
    }
    
    var color: Color {
        switch self {
        case .weekly, .biweekly: return .red
        case .monthly: return .blue
        case .quarterly: return .orange
        case .biannual: return .purple
        case .annual: return .green
        }
    }
}

// MARK: - Objectifs d'Épargne
struct SavingsGoal: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let targetAmount: Double
    let currentAmount: Double
    let startDate: Date
    let targetDate: Date
    let category: GoalCategory
    let priority: GoalPriority
    let isActive: Bool
    let monthlyContribution: Double
    let contributions: [SavingsContribution]
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        targetAmount: Double,
        currentAmount: Double = 0,
        startDate: Date = Date(),
        targetDate: Date,
        category: GoalCategory = .general,
        priority: GoalPriority = .medium,
        monthlyContribution: Double = 0,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.startDate = startDate
        self.targetDate = targetDate
        self.category = category
        self.priority = priority
        self.isActive = isActive
        self.monthlyContribution = monthlyContribution
        self.contributions = []
    }
    
    // Progression en pourcentage
    var progressPercentage: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount, 1.0)
    }
    
    // Montant restant à épargner
    var remainingAmount: Double {
        return max(targetAmount - currentAmount, 0)
    }
    
    // Mois restants
    var monthsRemaining: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: Date(), to: targetDate)
        return max(components.month ?? 0, 0)
    }
    
    // Contribution mensuelle nécessaire
    var requiredMonthlyContribution: Double {
        guard monthsRemaining > 0 else { return remainingAmount }
        return remainingAmount / Double(monthsRemaining)
    }
    
    // Statut de l'objectif
    var status: GoalStatus {
        if currentAmount >= targetAmount {
            return .completed
        } else if Date() > targetDate {
            return .expired
        } else if monthlyContribution >= requiredMonthlyContribution {
            return .onTrack
        } else {
            return .behindSchedule
        }
    }
    
    // Date d'achèvement prévue selon le rythme actuel
    var projectedCompletionDate: Date? {
        guard monthlyContribution > 0 && remainingAmount > 0 else { return nil }
        let monthsNeeded = ceil(remainingAmount / monthlyContribution)
        return Calendar.current.date(byAdding: .month, value: Int(monthsNeeded), to: Date())
    }
}

struct SavingsContribution: Identifiable, Codable {
    let id: UUID
    let goalId: UUID
    let amount: Double
    let date: Date
    let note: String?
    
    init(id: UUID = UUID(), goalId: UUID, amount: Double, date: Date = Date(), note: String? = nil) {
        self.id = id
        self.goalId = goalId
        self.amount = amount
        self.date = date
        self.note = note
    }
}

enum GoalCategory: String, CaseIterable, Codable {
    case vacation = "vacation"
    case emergency = "emergency"
    case home = "home"
    case car = "car"
    case education = "education"
    case retirement = "retirement"
    case general = "general"
    case electronics = "electronics"
    case wedding = "wedding"
    
    var displayName: String {
        switch self {
        case .vacation: return "🏖️ Vacances"
        case .emergency: return "🚨 Fonds d'urgence"
        case .home: return "🏠 Maison/Logement"
        case .car: return "🚗 Véhicule"
        case .education: return "🎓 Éducation"
        case .retirement: return "👴 Retraite"
        case .general: return "💰 Général"
        case .electronics: return "📱 Électronique"
        case .wedding: return "💒 Mariage"
        }
    }
    
    var icon: String {
        switch self {
        case .vacation: return "🏖️"
        case .emergency: return "🚨"
        case .home: return "🏠"
        case .car: return "🚗"
        case .education: return "🎓"
        case .retirement: return "👴"
        case .general: return "💰"
        case .electronics: return "📱"
        case .wedding: return "💒"
        }
    }
    
    var color: Color {
        switch self {
        case .vacation: return .cyan
        case .emergency: return .red
        case .home: return .brown
        case .car: return .blue
        case .education: return .purple
        case .retirement: return .gray
        case .general: return .green
        case .electronics: return .orange
        case .wedding: return .pink
        }
    }
}

enum GoalPriority: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
    
    var displayName: String {
        switch self {
        case .low: return "🔵 Faible"
        case .medium: return "🟡 Moyenne"
        case .high: return "🟠 Élevée"
        case .urgent: return "🔴 Urgente"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

enum GoalStatus {
    case onTrack
    case behindSchedule
    case completed
    case expired
    
    var displayName: String {
        switch self {
        case .onTrack: return "✅ En bonne voie"
        case .behindSchedule: return "⚠️ En retard"
        case .completed: return "🎉 Terminé"
        case .expired: return "⏰ Expiré"
        }
    }
    
    var color: Color {
        switch self {
        case .onTrack: return .green
        case .behindSchedule: return .orange
        case .completed: return .blue
        case .expired: return .red
        }
    }
}
