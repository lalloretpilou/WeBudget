// BudgetManager.swift - Version avec gestion d'authentification
import Foundation
import CloudKit
import Combine

class BudgetManager: ObservableObject {
    @Published var salaires = Salaires(pilou: 6000, doudou: 10000)
    @Published var budgets = Budgets()
    @Published var transactions: [Transaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    @Published var authenticationStatus = "Vérification..."
    
    // ✅ Container personnalisé
    private let container = CKContainer(identifier: "iCloud.com.budget.nous")
    private var database: CKDatabase {
        container.privateCloudDatabase
    }
    
    init() {
        checkAuthentication()
    }
    
    // MARK: - Computed Properties
    var totalRevenus: Double {
        salaires.pilou + salaires.doudou
    }
    
    var pourcentagePilou: Double {
        totalRevenus > 0 ? (salaires.pilou / totalRevenus) * 100 : 0
    }
    
    var pourcentageDoudou: Double {
        totalRevenus > 0 ? (salaires.doudou / totalRevenus) * 100 : 0
    }
    
    var totalBudgets: Double {
        budgets.totalAmount
    }
    
    var resteRedistribution: Double {
        totalRevenus - totalBudgets
    }
    
    var redistribPilou: Double {
        totalRevenus > 0 ? resteRedistribution * (salaires.pilou / totalRevenus) : 0
    }
    
    var redistribDoudou: Double {
        totalRevenus > 0 ? resteRedistribution * (salaires.doudou / totalRevenus) : 0
    }
    
    // Dépenses du mois en cours
    var depensesMoisCourant: Double {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        return transactions
            .filter { transaction in
                let transactionMonth = calendar.component(.month, from: transaction.date)
                let transactionYear = calendar.component(.year, from: transaction.date)
                return transactionMonth == currentMonth && transactionYear == currentYear
            }
            .reduce(0) { $0 + $1.amount }
    }
    
    var resteDisponible: Double {
        totalRevenus - depensesMoisCourant
    }
    
    // MARK: - Authentication
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
    
    // MARK: - CloudKit Methods
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
    }
    
    func saveTransaction(_ transaction: Transaction) {
        guard isAuthenticated else {
            print("⚠️ Tentative de sauvegarde sans authentification")
            errorMessage = "Non authentifié - connectez-vous à iCloud"
            return
        }
        
        print("💾 Sauvegarde de la transaction: \(transaction.description)")
        
        // Ajouter d'abord à la liste locale pour une mise à jour immédiate
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
                    
                    // Retirer de la liste locale en cas d'erreur
                    self?.transactions.removeAll { $0.id == transaction.id }
                    
                    // Si erreur d'authentification, revérifier
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
        
        // Supprimer de la liste locale d'abord
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
                        // Remettre la transaction dans la liste en cas d'erreur
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
    
    // MARK: - Helper Methods
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
}
