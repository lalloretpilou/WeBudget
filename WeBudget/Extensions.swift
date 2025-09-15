//
//  Extensions.swift
//  WeBudget
//
//  Created by Pierre-Louis L'ALLORET on 14/09/2025.
//

import SwiftUI
import Foundation

// MARK: - Date Extensions
extension Date {
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
    
    var endOfMonth: Date {
        let calendar = Calendar.current
        let startOfMonth = self.startOfMonth
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) ?? self
        return calendar.date(byAdding: .day, value: -1, to: nextMonth) ?? self
    }
    
    func isSameMonth(as date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(self, equalTo: date, toGranularity: .month)
    }
    
    func monthName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: self)
    }
}

// MARK: - Double Extensions
extension Double {
    func toCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: NSNumber(value: self)) ?? "0,00 €"
    }
    
    func toPercentage() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: self / 100)) ?? "0%"
    }
}

// MARK: - Color Extensions
extension Color {
    static let customGreen = Color(red: 0.2, green: 0.8, blue: 0.2)
    static let customRed = Color(red: 0.9, green: 0.2, blue: 0.2)
    static let customBlue = Color(red: 0.2, green: 0.4, blue: 0.9)
    static let customOrange = Color(red: 1.0, green: 0.6, blue: 0.0)
    
    // Couleurs pour les graphiques
    static let chartColors: [Color] = [
        .blue, .green, .orange, .purple, .red, .teal, .indigo, .yellow
    ]
    
    // Couleur basée sur un pourcentage de budget
    static func budgetColor(for percentage: Double) -> Color {
        if percentage > 1.0 {
            return .red
        } else if percentage > 0.9 {
            return .orange
        } else if percentage > 0.75 {
            return .yellow
        } else {
            return .green
        }
    }
}

// MARK: - View Extensions
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    func alertCardStyle(color: Color) -> some View {
        self
            .padding()
            .background(color.opacity(0.1))
            .overlay(
                Rectangle()
                    .frame(width: 4)
                    .foregroundColor(color),
                alignment: .leading
            )
            .cornerRadius(8)
    }
}

// MARK: - Custom Shapes
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Array Extensions
extension Array where Element == Transaction {
    func groupedByMonth() -> [String: [Transaction]] {
        return Dictionary(grouping: self) { transaction in
            transaction.date.monthName()
        }
    }
    
    func groupedByCategory() -> [TransactionCategory: [Transaction]] {
        return Dictionary(grouping: self) { transaction in
            transaction.category
        }
    }
    
    func totalAmount() -> Double {
        return self.reduce(0) { $0 + $1.amount }
    }
    
    func filterByCurrentMonth() -> [Transaction] {
        let now = Date()
        return self.filter { $0.date.isSameMonth(as: now) }
    }
    
    func filterByCategory(_ category: TransactionCategory) -> [Transaction] {
        return self.filter { $0.category == category }
    }
    
    func sortedByDate(ascending: Bool = false) -> [Transaction] {
        return self.sorted { ascending ? $0.date < $1.date : $0.date > $1.date }
    }
}

// MARK: - UserDefaults Extensions
extension UserDefaults {
    private enum Keys {
        static let hasLaunchedBefore = "hasLaunchedBefore"
        static let lastSyncDate = "lastSyncDate"
        static let notificationsEnabled = "notificationsEnabled"
    }
    
    var isFirstLaunch: Bool {
        get { !bool(forKey: Keys.hasLaunchedBefore) }
        set { set(!newValue, forKey: Keys.hasLaunchedBefore) }
    }
    
    var lastSyncDate: Date? {
        get { object(forKey: Keys.lastSyncDate) as? Date }
        set { set(newValue, forKey: Keys.lastSyncDate) }
    }
    
    var notificationsEnabled: Bool {
        get { bool(forKey: Keys.notificationsEnabled) }
        set { set(newValue, forKey: Keys.notificationsEnabled) }
    }
}

// MARK: - String Extensions
extension String {
    var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
    
    func toDouble() -> Double? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.number(from: self)?.doubleValue
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let budgetExceeded = Notification.Name("budgetExceeded")
    static let transactionAdded = Notification.Name("transactionAdded")
    static let dataSync = Notification.Name("dataSync")
}

// MARK: - Error Handling
enum BudgetError: LocalizedError {
    case invalidAmount
    case cloudKitError(String)
    case dataCorruption
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Le montant saisi n'est pas valide"
        case .cloudKitError(let message):
            return "Erreur CloudKit: \(message)"
        case .dataCorruption:
            return "Les données sont corrompues"
        case .networkError:
            return "Erreur de connexion réseau"
        }
    }
}

// MARK: - Haptic Feedback
struct HapticFeedback {
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    static func impact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}
