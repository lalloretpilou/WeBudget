// WeatherManager.swift - Version corrigée pour demande de localisation
import Foundation
import WeatherKit
import CoreLocation
import Combine
import SwiftUI

@MainActor
class WeatherManager: NSObject, ObservableObject {
    @Published var currentWeather: CurrentWeather?
    @Published var forecast: Forecast<DayWeather>?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var locationName = "Localisation inconnue"
    @Published var locationStatus: CLAuthorizationStatus = .notDetermined
    
    private let weatherService = WeatherService()
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    
    override init() {
        super.init()
        print("🌍 Initialisation du WeatherManager")
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        print("📍 Configuration du LocationManager")
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        
        // ✅ CORRECTION: Mettre à jour le statut initial
        locationStatus = locationManager.authorizationStatus
        print("📱 Statut de localisation initial: \(locationStatus.description)")
        
        // ✅ CORRECTION: Demander les permissions immédiatement
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.requestLocationPermission()
        }
    }
    
    func requestLocationPermission() {
        print("🔐 Demande de permission de localisation...")
        print("📱 Statut actuel: \(locationManager.authorizationStatus.description)")
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            print("🆕 Première demande de permission")
            locationManager.requestWhenInUseAuthorization()
            
        case .denied:
            print("❌ Permission refusée")
            errorMessage = "Accès à la localisation refusé. Activez-la dans Réglages > Confidentialité > Service de localisation > WeBudget"
            
        case .restricted:
            print("❌ Permission restreinte")
            errorMessage = "Accès à la localisation restreint par les réglages de l'appareil"
            
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ Permission accordée, demande de localisation...")
            getCurrentLocation()
            
        @unknown default:
            print("❓ Statut de permission inconnu")
            errorMessage = "Statut de localisation inconnu"
        }
        
        locationStatus = locationManager.authorizationStatus
    }
    
    private func getCurrentLocation() {
        print("📍 Demande de localisation actuelle...")
        
        guard locationManager.authorizationStatus == .authorizedWhenInUse ||
              locationManager.authorizationStatus == .authorizedAlways else {
            print("⚠️ Pas d'autorisation pour obtenir la localisation")
            return
        }
        
        isLoading = true
        errorMessage = nil
        locationManager.requestLocation()
    }
    
    func loadWeather() {
        guard let location = currentLocation else {
            print("❌ Pas de localisation disponible pour charger la météo")
            errorMessage = "Localisation non disponible"
            return
        }
        
        print("🌤️ Chargement de la météo pour: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                print("☁️ Requête données météo...")
                async let current = weatherService.weather(for: location)
                async let dailyForecast = weatherService.weather(for: location, including: .daily)
                
                let currentResult = try await current
                let forecastResult = try await dailyForecast
                
                await MainActor.run {
                    self.currentWeather = currentResult.currentWeather
                    self.forecast = forecastResult
                    print("✅ Données météo reçues: \(currentResult.currentWeather.temperature.value)°C")
                }
                
                // Obtenir le nom de la ville
                await updateLocationName(for: location)
                
                await MainActor.run {
                    self.isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur météo: \(error.localizedDescription)"
                    self.isLoading = false
                    print("❌ Erreur météo: \(error)")
                }
            }
        }
    }
    
    private func updateLocationName(for location: CLLocation) async {
        print("🏙️ Recherche du nom de la ville...")
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                let city = placemark.locality ?? "Ville inconnue"
                let country = placemark.country ?? ""
                await MainActor.run {
                    self.locationName = "\(city), \(country)"
                    print("📍 Localisation trouvée: \(self.locationName)")
                }
            }
        } catch {
            print("❌ Erreur géocodage: \(error)")
        }
    }
    
    // MARK: - Suggestions intelligentes basées sur la météo
    func getWeatherBasedSuggestions() -> [WeatherSuggestion] {
        guard let weather = currentWeather else {
            print("⚠️ Pas de données météo pour les suggestions")
            return []
        }
        
        var suggestions: [WeatherSuggestion] = []
        
        // Suggestions basées sur la température
        if weather.temperature.value < 5 {
            suggestions.append(WeatherSuggestion(
                icon: "❄️",
                title: "Temps froid",
                message: "Pensez aux frais de chauffage supplémentaires",
                category: .habitation,
                priority: .high
            ))
        } else if weather.temperature.value > 25 {
            suggestions.append(WeatherSuggestion(
                icon: "🌡️",
                title: "Temps chaud",
                message: "Période favorable pour les activités extérieures gratuites",
                category: .sorties,
                priority: .medium
            ))
        }
        
        // Suggestions basées sur les précipitations
        if isRainyWeather(weather.condition) {
            suggestions.append(WeatherSuggestion(
                icon: "☔",
                title: "Temps pluvieux",
                message: "Journée idéale pour cuisiner à la maison plutôt que sortir",
                category: .alimentation,
                priority: .medium
            ))
            
            suggestions.append(WeatherSuggestion(
                icon: "🚗",
                title: "Transport",
                message: "Pensez aux frais de transport supplémentaires (taxi/Uber)",
                category: .transports,
                priority: .low
            ))
        }
        
        // Suggestions pour le week-end ensoleillé
        if isWeekend() && isClearWeather(weather.condition) {
            suggestions.append(WeatherSuggestion(
                icon: "☀️",
                title: "Week-end ensoleillé",
                message: "Parfait pour un pique-nique économique au parc",
                category: .sorties,
                priority: .high
            ))
        }
        
        return suggestions
    }
    
    private func isRainyWeather(_ condition: WeatherCondition) -> Bool {
        switch condition {
        case .rain, .heavyRain, .isolatedThunderstorms, .strongStorms,
             .thunderstorms, .frigid, .hail, .sleet, .freezingRain:
            return true
        default:
            return false
        }
    }
    
    private func isClearWeather(_ condition: WeatherCondition) -> Bool {
        switch condition {
        case .clear, .mostlyClear:
            return true
        default:
            return false
        }
    }
    
    private func isWeekend() -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        return weekday == 1 || weekday == 7 // Dimanche ou Samedi
    }
    
    // MARK: - Prédictions de dépenses basées sur la météo
    func getExpensePredictions(basedOn budgetManager: BudgetManager) -> [ExpensePrediction] {
        guard let weather = currentWeather,
              let forecast = forecast else {
            print("⚠️ Pas de données météo pour les prédictions")
            return []
        }
        
        var predictions: [ExpensePrediction] = []
        
        // Prédiction chauffage/climatisation
        let avgTemp = forecast.forecast.prefix(7).map { $0.highTemperature.value }.reduce(0, +) / 7
        
        if avgTemp < 10 {
            let heatingIncrease = budgetManager.budgets.habitation * 0.2 // +20%
            predictions.append(ExpensePrediction(
                category: .habitation,
                predictedIncrease: heatingIncrease,
                reason: "Températures froides prévues cette semaine",
                confidence: 0.8
            ))
        } else if avgTemp > 28 {
            let coolingIncrease = budgetManager.budgets.habitation * 0.15 // +15%
            predictions.append(ExpensePrediction(
                category: .habitation,
                predictedIncrease: coolingIncrease,
                reason: "Fortes chaleurs prévues - climatisation",
                confidence: 0.7
            ))
        }
        
        // Prédiction pluie
        let rainyDays = forecast.forecast.prefix(7).filter { day in
            isRainyWeather(day.condition)
        }.count
        
        if rainyDays >= 4 {
            let deliveryIncrease = budgetManager.budgets.alimentation * 0.1
            predictions.append(ExpensePrediction(
                category: .alimentation,
                predictedIncrease: deliveryIncrease,
                reason: "Plusieurs jours de pluie - livraisons possibles",
                confidence: 0.6
            ))
        }
        
        return predictions
    }
}

// MARK: - CLLocationManagerDelegate
extension WeatherManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("📍 Localisation reçue: \(locations)")
        if let location = locations.first {
            currentLocation = location
            print("✅ Nouvelle localisation: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            loadWeather()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Erreur localisation: \(error)")
        isLoading = false
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                errorMessage = "Accès à la localisation refusé"
            case .locationUnknown:
                errorMessage = "Localisation introuvable"
            case .network:
                errorMessage = "Erreur réseau pour la localisation"
            default:
                errorMessage = "Erreur localisation: \(error.localizedDescription)"
            }
        } else {
            errorMessage = "Erreur localisation: \(error.localizedDescription)"
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("🔄 Changement d'autorisation de localisation: \(status.description)")
        locationStatus = status
        
        switch status {
        case .notDetermined:
            print("🤔 Permission pas encore déterminée")
            
        case .denied, .restricted:
            print("❌ Permission refusée ou restreinte")
            isLoading = false
            errorMessage = status == .denied ?
                "Accès à la localisation refusé. Activez-la dans Réglages" :
                "Accès à la localisation restreint"
            
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ Permission accordée, obtention de la localisation...")
            getCurrentLocation()
            
        @unknown default:
            print("❓ Statut d'autorisation inconnu")
        }
    }
}

// MARK: - Extensions pour debug
extension CLAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined: return "Non déterminé"
        case .restricted: return "Restreint"
        case .denied: return "Refusé"
        case .authorizedAlways: return "Autorisé toujours"
        case .authorizedWhenInUse: return "Autorisé en utilisation"
        @unknown default: return "Inconnu"
        }
    }
}

// MARK: - Models (inchangés)
struct WeatherSuggestion: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let message: String
    let category: TransactionCategory
    let priority: Priority
    
    enum Priority {
        case low, medium, high
        
        var color: Color {
            switch self {
            case .low: return .gray
            case .medium: return .orange
            case .high: return .red
            }
        }
    }
}

struct ExpensePrediction: Identifiable {
    let id = UUID()
    let category: TransactionCategory
    let predictedIncrease: Double
    let reason: String
    let confidence: Double // 0.0 à 1.0
}
