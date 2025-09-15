// BudgetManager.swift - Version étendue
import Foundation
import CloudKit
import Combine

class BudgetManager: ObservableObject {
    // Propriétés existantes
    @Published var salaires = Salaires(pilou: 6000, doudou: 10000)
    @Published var budgets = Budgets()
    @Published var transactions: [Transaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    @Published var authenticationStatus = "Vérification..."
    
    // NOUVELLES PROPRIÉTÉS
    @Published var recurringExpenses: [RecurringExpense] = []
    @Published var savingsGoals: [SavingsGoal] = []
    @Published var savingsContributions: [SavingsContribution] = []
    
    private let container = CKContainer(identifier: "iCloud.com.budget.nous")
    private var database: CKDatabase {
        container.privateCloudDatabase
    }
    
    init() {
        checkAuthentication()
        // Démarrer la vérification des dépenses récurrentes
        startRecurringExpenseMonitoring()
    }
    
    // MARK: - Computed Properties existantes (inchangées)
    var totalRevenus: Double {
        salaires.pilou + salaires.doudou
    }
    
    var totalBudgets: Double {
        budgets.totalAmount
    }
    
    var depensesMoisCourant: Double {
        let calendar = Calendar.current
        let now = Date()
        return transactions
            .filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }
    
    var resteDisponible: Double {
        totalRevenus - depensesMoisCourant - totalMonthlyRecurring - totalMonthlySavingsGoals
    }
    
    // NOUVELLES COMPUTED PROPERTIES
    
    // Total des dépenses récurrentes mensuelles
    var totalMonthlyRecurring: Double {
        return recurringExpenses
            .filter { $0.isActive }
            .reduce(0) { total, expense in
                total + (expense.amount / expense.frequency.annualMultiplier * 12)
            }
    }
    
    // Total des contributions d'épargne mensuelles
    var totalMonthlySavingsGoals: Double {
        return savingsGoals
            .filter { $0.isActive }
            .reduce(0) { $0 + $1.monthlyContribution }
    }
    
    // Dépenses récurrentes dues
    var dueRecurringExpenses: [RecurringExpense] {
        return recurringExpenses.filter { $0.isDue }
    }
    
    // Objectifs d'épargne en retard
    var behindScheduleGoals: [SavingsGoal] {
        return savingsGoals.filter { $0.status == .behindSchedule }
    }
    
    // Total épargné cette année
    var totalSavedThisYear: Double {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        
        return savingsContributions
            .filter { calendar.component(.year, from: $0.date) == currentYear }
            .reduce(0) { $0 + $1.amount }
    }
    
    // MARK: - Gestion des Dépenses Récurrentes
    
    func addRecurringExpense(_ expense: RecurringExpense) {
        recurringExpenses.append(expense)
        saveRecurringExpense(expense)
    }
    
    func updateRecurringExpense(_ expense: RecurringExpense) {
        if let index = recurringExpenses.firstIndex(where: { $0.id == expense.id }) {
            recurringExpenses[index] = expense
            saveRecurringExpense(expense)
        }
    }
    
    func deleteRecurringExpense(_ expense: RecurringExpense) {
        recurringExpenses.removeAll { $0.id == expense.id }
        deleteRecurringExpenseFromCloudKit(expense)
    }
    
    func processRecurringExpense(_ expense: RecurringExpense) {
        // Créer une transaction pour cette dépense récurrente
        let transaction = Transaction(
            date: expense.nextDueDate,
            description: "♻️ \(expense.description)",
            category: expense.category,
            amount: expense.amount,
            payer: expense.payer
        )
        
        saveTransaction(transaction)
        
        // Mettre à jour la prochaine échéance
        var updatedExpense = expense
        let newExpense = RecurringExpense(
            id: expense.id,
            description: expense.description,
            amount: expense.amount,
            category: expense.category,
            payer: expense.payer,
            frequency: expense.frequency,
            startDate: expense.startDate,
            isActive: expense.isActive,
            endDate: expense.endDate,
            autoGenerate: expense.autoGenerate
        )
        
        updateRecurringExpense(newExpense)
    }
    
    private func startRecurringExpenseMonitoring() {
        // Vérifier toutes les heures s'il y a des dépenses récurrentes à traiter
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.checkAndProcessRecurringExpenses()
        }
        
        // Vérification immédiate au démarrage
        checkAndProcessRecurringExpenses()
    }
    
    private func checkAndProcessRecurringExpenses() {
        for expense in dueRecurringExpenses {
            if expense.autoGenerate {
                processRecurringExpense(expense)
            }
        }
    }
    
    // MARK: - Gestion des Objectifs d'Épargne
    
    func addSavingsGoal(_ goal: SavingsGoal) {
        savingsGoals.append(goal)
        saveSavingsGoal(goal)
    }
    
    func updateSavingsGoal(_ goal: SavingsGoal) {
        if let index = savingsGoals.firstIndex(where: { $0.id == goal.id }) {
            savingsGoals[index] = goal
            saveSavingsGoal(goal)
        }
    }
    
    func deleteSavingsGoal(_ goal: SavingsGoal) {
        savingsGoals.removeAll { $0.id == goal.id }
        // Supprimer aussi les contributions associées
        savingsContributions.removeAll { $0.goalId == goal.id }
        deleteSavingsGoalFromCloudKit(goal)
    }
    
    func addContributionToGoal(_ goalId: UUID, amount: Double, note: String? = nil) {
        let contribution = SavingsContribution(goalId: goalId, amount: amount, note: note)
        savingsContributions.append(contribution)
        
        // Mettre à jour le montant de l'objectif
        if let index = savingsGoals.firstIndex(where: { $0.id == goalId }) {
            let goal = savingsGoals[index]
            let updatedGoal = SavingsGoal(
                id: goal.id,
                name: goal.name,
                description: goal.description,
                targetAmount: goal.targetAmount,
                currentAmount: goal.currentAmount + amount,
                startDate: goal.startDate,
                targetDate: goal.targetDate,
                category: goal.category,
                priority: goal.priority,
                monthlyContribution: goal.monthlyContribution,
                isActive: goal.isActive
            )
            savingsGoals[index] = updatedGoal
            saveSavingsGoal(updatedGoal)
        }
        
        saveSavingsContribution(contribution)
    }
    
    // MARK: - CloudKit - Nouvelles méthodes de sauvegarde
    
    private func saveRecurringExpense(_ expense: RecurringExpense) {
        guard isAuthenticated else { return }
        
        let record = CKRecord(recordType: "RecurringExpense")
        record["id"] = expense.id.uuidString
        record["description"] = expense.description
        record["amount"] = expense.amount
        record["category"] = expense.category.rawValue
        record["payer"] = expense.payer.rawValue
        record["frequency"] = expense.frequency.rawValue
        record["startDate"] = expense.startDate
        record["nextDueDate"] = expense.nextDueDate
        record["isActive"] = expense.isActive
        record["autoGenerate"] = expense.autoGenerate
        if let endDate = expense.endDate {
            record["endDate"] = endDate
        }
        
        database.save(record) { _, error in
            if let error = error {
                print("❌ Erreur sauvegarde dépense récurrente: \(error)")
            } else {
                print("✅ Dépense récurrente sauvegardée")
            }
        }
    }
    
    private func saveSavingsGoal(_ goal: SavingsGoal) {
        guard isAuthenticated else { return }
        
        let record = CKRecord(recordType: "SavingsGoal")
        record["id"] = goal.id.uuidString
        record["name"] = goal.name
        record["description"] = goal.description
        record["targetAmount"] = goal.targetAmount
        record["currentAmount"] = goal.currentAmount
        record["startDate"] = goal.startDate
        record["targetDate"] = goal.targetDate
        record["category"] = goal.category.rawValue
        record["priority"] = goal.priority.rawValue
        record["monthlyContribution"] = goal.monthlyContribution
        record["isActive"] = goal.isActive
        
        database.save(record) { _, error in
            if let error = error {
                print("❌ Erreur sauvegarde objectif épargne: \(error)")
            } else {
                print("✅ Objectif épargne sauvegardé")
            }
        }
    }
    
    private func saveSavingsContribution(_ contribution: SavingsContribution) {
        guard isAuthenticated else { return }
        
        let record = CKRecord(recordType: "SavingsContribution")
        record["id"] = contribution.id.uuidString
        record["goalId"] = contribution.goalId.uuidString
        record["amount"] = contribution.amount
        record["date"] = contribution.date
        if let note = contribution.note {
            record["note"] = note
        }
        
        database.save(record) { _, error in
            if let error = error {
                print("❌ Erreur sauvegarde contribution: \(error)")
            } else {
                print("✅ Contribution sauvegardée")
            }
        }
    }
    
    // MARK: - CloudKit - Suppression
    
    private func deleteRecurringExpenseFromCloudKit(_ expense: RecurringExpense) {
        let predicate = NSPredicate(format: "id == %@", expense.id.uuidString)
        let query = CKQuery(recordType: "RecurringExpense", predicate: predicate)
        
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            guard let records = records, !records.isEmpty else { return }
            
            let deleteOperation = CKModifyRecordsOperation(
                recordsToSave: nil,
                recordIDsToDelete: records.map { $0.recordID }
            )
            
            self?.database.add(deleteOperation)
        }
    }
    
    private func deleteSavingsGoalFromCloudKit(_ goal: SavingsGoal) {
        let predicate = NSPredicate(format: "id == %@", goal.id.uuidString)
        let query = CKQuery(recordType: "SavingsGoal", predicate: predicate)
        
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            guard let records = records, !records.isEmpty else { return }
            
            let deleteOperation = CKModifyRecordsOperation(
                recordsToSave: nil,
                recordIDsToDelete: records.map { $0.recordID }
            )
            
            self?.database.add(deleteOperation)
        }
    }
    
    // MARK: - CloudKit - Chargement (à ajouter à loadData())
    
    func loadData() {
        guard isAuthenticated else {
            print("⚠️ Tentative de chargement sans authentification")
            authenticationStatus = "Non authentifié - impossible de charger les données"
            return
        }
        
        print("🔄 Chargement des données depuis CloudKit...")
        isLoading = true
        errorMessage = nil
        
        loadSalaires()
        loadBudgets()
        loadTransactions()
        loadRecurringExpenses()
        loadSavingsGoals()
        loadSavingsContributions()
    }
    
    private func loadRecurringExpenses() {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "RecurringExpense", predicate: predicate)
        
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Erreur chargement dépenses récurrentes: \(error)")
                    return
                }
                
                if let records = records {
                    let expenses = records.compactMap { record -> RecurringExpense? in
                        guard let idString = record["id"] as? String,
                              let id = UUID(uuidString: idString),
                              let description = record["description"] as? String,
                              let amount = record["amount"] as? Double,
                              let categoryString = record["category"] as? String,
                              let category = TransactionCategory(rawValue: categoryString),
                              let payerString = record["payer"] as? String,
                              let payer = Payer(rawValue: payerString),
                              let frequencyString = record["frequency"] as? String,
                              let frequency = Frequency(rawValue: frequencyString),
                              let startDate = record["startDate"] as? Date,
                              let nextDueDate = record["nextDueDate"] as? Date,
                              let isActive = record["isActive"] as? Bool,
                              let autoGenerate = record["autoGenerate"] as? Bool else {
                            return nil
                        }
                        
                        let endDate = record["endDate"] as? Date
                        
                        return RecurringExpense(
                            id: id,
                            description: description,
                            amount: amount,
                            category: category,
                            payer: payer,
                            frequency: frequency,
                            startDate: startDate,
                            isActive: isActive,
                            endDate: endDate,
                            autoGenerate: autoGenerate
                        )
                    }
                    
                    self?.recurringExpenses = expenses
                    print("✅ \(expenses.count) dépenses récurrentes chargées")
                }
            }
        }
    }
    
    private func loadSavingsGoals() {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "SavingsGoal", predicate: predicate)
        
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Erreur chargement objectifs épargne: \(error)")
                    return
                }
                
                if let records = records {
                    let goals = records.compactMap { record -> SavingsGoal? in
                        guard let idString = record["id"] as? String,
                              let id = UUID(uuidString: idString),
                              let name = record["name"] as? String,
                              let description = record["description"] as? String,
                              let targetAmount = record["targetAmount"] as? Double,
                              let currentAmount = record["currentAmount"] as? Double,
                              let startDate = record["startDate"] as? Date,
                              let targetDate = record["targetDate"] as? Date,
                              let categoryString = record["category"] as? String,
                              let category = GoalCategory(rawValue: categoryString),
                              let priorityString = record["priority"] as? String,
                              let priority = GoalPriority(rawValue: priorityString),
                              let monthlyContribution = record["monthlyContribution"] as? Double,
                              let isActive = record["isActive"] as? Bool else {
                            return nil
                        }
                        
                        return SavingsGoal(
                            id: id,
                            name: name,
                            description: description,
                            targetAmount: targetAmount,
                            currentAmount: currentAmount,
                            startDate: startDate,
                            targetDate: targetDate,
                            category: category,
                            priority: priority,
                            monthlyContribution: monthlyContribution,
                            isActive: isActive
                        )
                    }
                    
                    self?.savingsGoals = goals
                    print("✅ \(goals.count) objectifs épargne chargés")
                }
            }
        }
    }
    
    private func loadSavingsContributions() {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "SavingsContribution", predicate: predicate)
        
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Erreur chargement contributions: \(error)")
                    return
                }
                
                if let records = records {
                    let contributions = records.compactMap { record -> SavingsContribution? in
                        guard let idString = record["id"] as? String,
                              let id = UUID(uuidString: idString),
                              let goalIdString = record["goalId"] as? String,
                              let goalId = UUID(uuidString: goalIdString),
                              let amount = record["amount"] as? Double,
                              let date = record["date"] as? Date else {
                            return nil
                        }
                        
                        let note = record["note"] as? String
                        
                        return SavingsContribution(
                            id: id,
                            goalId: goalId,
                            amount: amount,
                            date: date,
                            note: note
                        )
                    }
                    
                    self?.savingsContributions = contributions
                    print("✅ \(contributions.count) contributions chargées")
                }
            }
        }
    }
    
    // MARK: - Méthodes utilitaires existantes (inchangées)
    
    func checkAuthentication() {
        print("🔐 Vérification de l'authentification iCloud...")
        
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Erreur lors de la vérification du compte: \(error)")
                    self?.authenticationStatus = "Erreur: \(error.localizedDescription)"
                    self?.isAuthenticated = false
                    return
                }
                
                switch status {
                case .available:
                    print("✅ Compte iCloud disponible")
                    self?.authenticationStatus = "Connecté à iCloud"
                    self?.isAuthenticated = true
                    self?.requestPermissions()
                    
                case .noAccount:
                    print("❌ Aucun compte iCloud configuré")
                    self?.authenticationStatus = "Aucun compte iCloud configuré. Allez dans Réglages > iCloud"
                    self?.isAuthenticated = false
                    
                case .restricted:
                    print("❌ Compte iCloud restreint")
                    self?.authenticationStatus = "Compte iCloud restreint"
                    self?.isAuthenticated = false
                    
                case .couldNotDetermine:
                    print("❌ Impossible de déterminer le statut du compte")
                    self?.authenticationStatus = "Impossible de déterminer le statut iCloud"
                    self?.isAuthenticated = false
                    
                case .temporarilyUnavailable:
                    print("⏳ iCloud temporairement indisponible")
                    self?.authenticationStatus = "iCloud temporairement indisponible"
                    self?.isAuthenticated = false
                    
                @unknown default:
                    print("❓ Statut iCloud inconnu")
                    self?.authenticationStatus = "Statut iCloud inconnu"
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    private func requestPermissions() {
        print("🔑 Demande des permissions CloudKit...")
        
        container.requestApplicationPermission(.userDiscoverability) { [weak self] status, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Erreur permissions: \(error)")
                } else {
                    print("✅ Permissions accordées")
                    self?.loadData()
                }
            }
        }
    }
    
    func saveTransaction(_ transaction: Transaction) {
        guard isAuthenticated else {
            print("⚠️ Tentative de sauvegarde sans authentification")
            errorMessage = "Non authentifié - connectez-vous à iCloud"
            return
        }
        
        print("💾 Sauvegarde de la transaction: \(transaction.description)")
        
        if !transactions.contains(where: { $0.id == transaction.id }) {
            transactions.insert(transaction, at: 0)
            print("📱 Transaction ajoutée à la liste locale")
        }
        
        let record = CKRecord(recordType: "Transaction")
        record["id"] = transaction.id.uuidString
        record["date"] = transaction.date
        record["description"] = transaction.description
        record["category"] = transaction.category.rawValue
        record["amount"] = transaction.amount
        record["payer"] = transaction.payer.rawValue
        
        database.save(record) { [weak self] record, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Erreur sauvegarde transaction: \(error)")
                    self?.errorMessage = "Erreur sauvegarde: \(error.localizedDescription)"
                    self?.transactions.removeAll { $0.id == transaction.id }
                    
                    if let ckError = error as? CKError, ckError.code == .notAuthenticated {
                        self?.checkAuthentication()
                    }
                } else {
                    print("✅ Transaction sauvegardée avec succès dans CloudKit")
                }
            }
        }
    }
    
    func saveSalaires() {
        guard isAuthenticated else {
            print("⚠️ Tentative de sauvegarde salaires sans authentification")
            errorMessage = "Non authentifié - connectez-vous à iCloud"
            return
        }
        
        print("💾 Sauvegarde des salaires...")
        
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Salaires", predicate: predicate)
        
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            DispatchQueue.main.async {
                let record: CKRecord
                
                if let existingRecord = records?.first {
                    record = existingRecord
                    print("📝 Modification de l'enregistrement Salaires existant")
                } else {
                    record = CKRecord(recordType: "Salaires")
                    print("🆕 Création d'un nouvel enregistrement Salaires")
                }
                
                record["pilou"] = self?.salaires.pilou
                record["doudou"] = self?.salaires.doudou
                record["lastUpdated"] = Date()
                
                self?.database.save(record) { savedRecord, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            print("❌ Erreur sauvegarde salaires: \(error)")
                            self?.errorMessage = "Erreur sauvegarde salaires: \(error.localizedDescription)"
                        } else {
                            print("✅ Salaires sauvegardés avec succès")
                        }
                    }
                }
            }
        }
    }
    
    func saveBudgets() {
        guard isAuthenticated else {
            print("⚠️ Tentative de sauvegarde budgets sans authentification")
            errorMessage = "Non authentifié - connectez-vous à iCloud"
            return
        }
        
        print("💾 Sauvegarde des budgets...")
        
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Budgets", predicate: predicate)
        
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            DispatchQueue.main.async {
                let record: CKRecord
                
                if let existingRecord = records?.first {
                    record = existingRecord
                    print("📝 Modification de l'enregistrement Budgets existant")
                } else {
                    record = CKRecord(recordType: "Budgets")
                    print("🆕 Création d'un nouvel enregistrement Budgets")
                }
                
                record["alimentation"] = self?.budgets.alimentation
                record["loyer"] = self?.budgets.loyer
                record["abonnements"] = self?.budgets.abonnements
                record["habitation"] = self?.budgets.habitation
                record["sorties"] = self?.budgets.sorties
                record["credits"] = self?.budgets.credits
                record["epargne"] = self?.budgets.epargne
                record["transports"] = self?.budgets.transports
                record["lastUpdated"] = Date()
                
                self?.database.save(record) { savedRecord, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            print("❌ Erreur sauvegarde budgets: \(error)")
                            self?.errorMessage = "Erreur sauvegarde budgets: \(error.localizedDescription)"
                        } else {
                            print("✅ Budgets sauvegardés avec succès")
                        }
                    }
                }
            }
        }
    }
    
    func deleteTransaction(_ transaction: Transaction) {
        guard isAuthenticated else {
            print("⚠️ Tentative de suppression sans authentification")
            return
        }
        
        print("🗑️ Suppression de la transaction: \(transaction.description)")
        
        transactions.removeAll { $0.id == transaction.id }
        
        let predicate = NSPredicate(format: "id == %@", transaction.id.uuidString)
        let query = CKQuery(recordType: "Transaction", predicate: predicate)
        
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            guard let records = records, !records.isEmpty else {
                print("⚠️ Aucun enregistrement trouvé pour suppression")
                return
            }
            
            let deleteOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: records.map { $0.recordID })
            
            deleteOperation.modifyRecordsCompletionBlock = { _, deletedRecordIDs, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Erreur suppression CloudKit: \(error)")
                        self?.transactions.append(transaction)
                    } else {
                        print("✅ Transaction supprimée de CloudKit")
                    }
                }
            }
            
            self?.database.add(deleteOperation)
        }
    }
    
    private func loadSalaires() {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Salaires", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "lastUpdated", ascending: false)]
        
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Erreur chargement salaires: \(error)")
                    self?.errorMessage = "Erreur chargement salaires: \(error.localizedDescription)"
                } else if let record = records?.first {
                    self?.salaires.pilou = record["pilou"] as? Double ?? 6000
                    self?.salaires.doudou = record["doudou"] as? Double ?? 10000
                    print("✅ Salaires chargés: Pilou=\(self?.salaires.pilou ?? 0), Doudou=\(self?.salaires.doudou ?? 0)")
                } else {
                    print("ℹ️ Aucun salaire trouvé, utilisation des valeurs par défaut")
                }
                self?.isLoading = false
            }
        }
    }
    
    private func loadBudgets() {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Budgets", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "lastUpdated", ascending: false)]
        
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Erreur chargement budgets: \(error)")
                    self?.errorMessage = "Erreur chargement budgets: \(error.localizedDescription)"
                } else if let record = records?.first {
                    self?.budgets.alimentation = record["alimentation"] as? Double ?? 500
                    self?.budgets.loyer = record["loyer"] as? Double ?? 1200
                    self?.budgets.abonnements = record["abonnements"] as? Double ?? 200
                    self?.budgets.habitation = record["habitation"] as? Double ?? 300
                    self?.budgets.sorties = record["sorties"] as? Double ?? 400
                    self?.budgets.credits = record["credits"] as? Double ?? 800
                    self?.budgets.epargne = record["epargne"] as? Double ?? 1000
                    self?.budgets.transports = record["transports"] as? Double ?? 300
                    print("✅ Budgets chargés depuis CloudKit")
                } else {
                    print("ℹ️ Aucun budget trouvé, utilisation des valeurs par défaut")
                }
            }
        }
    }
    
    private func loadTransactions() {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Transaction", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Erreur chargement transactions: \(error)")
                    self?.errorMessage = "Erreur chargement transactions: \(error.localizedDescription)"
                    return
                }
                
                if let records = records {
                    let loadedTransactions = records.compactMap { record -> Transaction? in
                        guard let idString = record["id"] as? String,
                              let id = UUID(uuidString: idString),
                              let date = record["date"] as? Date,
                              let description = record["description"] as? String,
                              let categoryString = record["category"] as? String,
                              let category = TransactionCategory(rawValue: categoryString),
                              let amount = record["amount"] as? Double,
                              let payerString = record["payer"] as? String,
                              let payer = Payer(rawValue: payerString) else {
                            print("⚠️ Transaction invalide trouvée dans CloudKit")
                            return nil
                        }
                        
                        return Transaction(
                            id: id,
                            date: date,
                            description: description,
                            category: category,
                            amount: amount,
                            payer: payer
                        )
                    }
                    
                    self?.transactions = loadedTransactions
                    print("✅ \(loadedTransactions.count) transactions chargées depuis CloudKit")
                } else {
                    print("ℹ️ Aucune transaction trouvée dans CloudKit")
                }
            }
        }
    }
    
    func depensesParCategorie(_ category: TransactionCategory) -> Double {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        return transactions
            .filter { transaction in
                let transactionMonth = calendar.component(.month, from: transaction.date)
                let transactionYear = calendar.component(.year, from: transaction.date)
                return transaction.category == category &&
                transactionMonth == currentMonth &&
                transactionYear == currentYear
            }
            .reduce(0) { $0 + $1.amount }
    }
    
    func progressionBudget(_ category: TransactionCategory) -> Double {
        let budget = budgets.budgetForCategory(category)
        let depenses = depensesParCategorie(category)
        return budget > 0 ? min(depenses / budget, 1.0) : 0
    }
    
    // Correction : Déplacez cette fonction DANS la classe BudgetManager

    // MARK: - Mise à jour des transactions (à ajouter dans BudgetManager)
    func updateTransaction(_ updatedTransaction: Transaction) {
        guard isAuthenticated else {
            print("⚠️ Tentative de mise à jour sans authentification")
            errorMessage = "Non authentifié - connectez-vous à iCloud"
            return
        }
        
        print("✏️ Mise à jour de la transaction: \(updatedTransaction.description)")
        
        // Mettre à jour la liste locale d'abord
        if let index = transactions.firstIndex(where: { $0.id == updatedTransaction.id }) {
            transactions[index] = updatedTransaction
            print("📱 Transaction mise à jour dans la liste locale")
        }
        
        // Rechercher l'enregistrement existant dans CloudKit
        let predicate = NSPredicate(format: "id == %@", updatedTransaction.id.uuidString)
        let query = CKQuery(recordType: "Transaction", predicate: predicate)
        
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Erreur recherche transaction pour mise à jour: \(error)")
                    self?.errorMessage = "Erreur recherche transaction: \(error.localizedDescription)"
                    
                    // Si erreur d'authentification, revérifier
                    if let ckError = error as? CKError, ckError.code == .notAuthenticated {
                        self?.checkAuthentication()
                    }
                    return
                }
                
                guard let record = records?.first else {
                    print("❌ Transaction non trouvée dans CloudKit pour mise à jour")
                    self?.errorMessage = "Transaction non trouvée dans CloudKit"
                    return
                }
                
                // Mettre à jour les champs du record
                record["date"] = updatedTransaction.date
                record["description"] = updatedTransaction.description
                record["category"] = updatedTransaction.category.rawValue
                record["amount"] = updatedTransaction.amount
                record["payer"] = updatedTransaction.payer.rawValue
                record["lastUpdated"] = Date()
                
                // Sauvegarder les modifications dans CloudKit
                self?.database.save(record) { [weak self] savedRecord, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            print("❌ Erreur mise à jour CloudKit: \(error)")
                            self?.errorMessage = "Erreur mise à jour: \(error.localizedDescription)"
                            
                            // Restaurer l'ancienne version en cas d'erreur
                            if let originalIndex = self?.transactions.firstIndex(where: { $0.id == updatedTransaction.id }) {
                                // Pour restaurer, on devrait garder une copie de l'original,
                                // mais ici on recharge simplement les données
                                self?.loadTransactions()
                            }
                            
                            // Si erreur d'authentification, revérifier
                            if let ckError = error as? CKError, ckError.code == .notAuthenticated {
                                self?.checkAuthentication()
                            }
                        } else {
                            print("✅ Transaction mise à jour avec succès dans CloudKit")
                            // Optionnel : afficher un message de succès ou faire une action
                        }
                    }
                }
            }
        }
    }
}
