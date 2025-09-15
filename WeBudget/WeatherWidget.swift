// WeatherViews.swift - Version complète avec polices Space Grotesk
import SwiftUI
import WeatherKit

// MARK: - WeatherWidget
struct WeatherWidget: View {
    @EnvironmentObject var weatherManager: WeatherManager
    
    var body: some View {
        VStack(spacing: 12) {
            // En-tête avec météo ou statut
            HStack {
                weatherIcon
                
                VStack(alignment: .leading, spacing: 4) {
                    locationSection
                    temperatureSection
                }
                
                Spacer()
                
                rightSection
            }
        }
        .padding()
        .background(weatherBackground)
        .cornerRadius(12)
        .onAppear {
            checkAndRequestLocationIfNeeded()
        }
    }
    
    private func checkAndRequestLocationIfNeeded() {
        let availability = weatherManager.checkLocationAvailability()
        
        switch availability {
        case .needsPermission:
            print("Demande automatique de permission au démarrage du widget")
            weatherManager.requestLocationPermission()
        case .authorized:
            print("Permission déjà accordée, actualisation météo")
            if weatherManager.currentWeather == nil {
                weatherManager.requestLocationPermission()
            }
        default:
            print("ℹ️ Statut localisation: \(availability)")
        }
    }
    
    // MARK: - Composants de l'interface
    
    private var weatherIcon: some View {
        Image(systemName: weatherIconName)
            .font(.title2)
            .foregroundColor(iconColor)
            .symbolEffect(.bounce, value: weatherManager.currentWeather?.temperature.value)
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(weatherManager.locationName)
                .font(.appCaption) // Space Grotesk Regular
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
    
    private var temperatureSection: some View {
        Group {
            if let weather = weatherManager.currentWeather {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(weather.temperature.value))°C")
                        .font(.appTitle2) // Space Grotesk SemiBold
                        .fontWeight(.bold)
                    
                    Text(weather.condition.description)
                        .font(.appCaption) // Space Grotesk Regular
                        .foregroundColor(.secondary)
                }
            } else if weatherManager.isLoading {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Chargement...")
                        .font(.appCaption) // Space Grotesk Regular
                        .foregroundColor(.secondary)
                    
                    ProgressView()
                        .scaleEffect(0.8)
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Non disponible")
                        .font(.appCaption) // Space Grotesk Regular
                        .foregroundColor(.secondary)
                    
                    if let error = weatherManager.errorMessage {
                        Text(locationStatusText)
                            .font(.appCaption2) // Space Grotesk Light
                            .foregroundColor(.orange)
                    }
                }
            }
        }
    }
    
    private var rightSection: some View {
        VStack(alignment: .trailing, spacing: 4) {
            // Indicateur d'impact budget
            if let impact = budgetImpact {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Impact budget")
                        .font(.appCaption2) // Space Grotesk Light
                        .foregroundColor(.secondary)
                    
                    Text(impact.text)
                        .font(.appCaption) // Space Grotesk Regular
                        .fontWeight(.medium)
                        .foregroundColor(impact.color)
                }
            }
        }
    }
    
    private var locationStatusIndicator: some View {
        let availability = weatherManager.checkLocationAvailability()
        
        return HStack(spacing: 4) {
            Circle()
                .fill(statusColor(for: availability))
                .frame(width: 8, height: 8)
            
            Text(statusText(for: availability))
                .font(.appCaption2) // Space Grotesk Light
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Propriétés calculées
    
    private var weatherIconName: String {
        guard let weather = weatherManager.currentWeather else {
            return "location.slash"
        }
        
        switch weather.condition {
        case .clear:
            return "sun.max.fill"
        case .cloudy, .mostlyCloudy:
            return "cloud.fill"
        case .partlyCloudy:
            return "cloud.sun.fill"
        case .rain:
            return "cloud.rain.fill"
        case .snow:
            return "cloud.snow.fill"
        case .thunderstorms:
            return "cloud.bolt.rain.fill"
        default:
            return "cloud.fill"
        }
    }
    
    private var iconColor: Color {
        if weatherManager.currentWeather != nil {
            return .blue
        } else if weatherManager.isLoading {
            return .orange
        } else {
            return .gray
        }
    }
    
    private var weatherBackground: some View {
        Group {
            if weatherManager.currentWeather != nil {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.cyan.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    gradient: Gradient(colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
    
    private var locationStatusText: String {
        let availability = weatherManager.checkLocationAvailability()
        
        switch availability {
        case .needsPermission:
            return "Permission requise"
        case .denied:
            return "Accès refusé"
        case .servicesDisabled:
            return "Service désactivé"
        case .authorized:
            return "Autorisé"
        case .unknown:
            return "Statut inconnu"
        }
    }
    
    private var budgetImpact: (text: String, color: Color)? {
        guard let weather = weatherManager.currentWeather else { return nil }
        
        if weather.temperature.value < 5 {
            return ("Chauffage ↗", .orange)
        } else if weather.temperature.value > 28 {
            return ("Clim ↗", .orange)
        } else if isRainyWeather(weather.condition) {
            return ("Livraisons ↗", .yellow)
        } else if isClearWeather(weather.condition) && isWeekend() {
            return ("Sorties ↗", .green)
        }
        
        return nil
    }
    
    // MARK: - Méthodes d'aide
    
    private func statusColor(for availability: LocationAvailability) -> Color {
        switch availability {
        case .authorized:
            return .green
        case .needsPermission:
            return .orange
        case .denied, .servicesDisabled:
            return .red
        case .unknown:
            return .gray
        }
    }
    
    private func statusText(for availability: LocationAvailability) -> String {
        switch availability {
        case .authorized:
            return "Autorisé"
        case .needsPermission:
            return "Permission"
        case .denied:
            return "Refusé"
        case .servicesDisabled:
            return "Désactivé"
        case .unknown:
            return "Inconnu"
        }
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
        return weekday == 1 || weekday == 7
    }
}

// MARK: - WeatherSuggestionsView
struct WeatherSuggestionsView: View {
    @EnvironmentObject var weatherManager: WeatherManager
    
    private var suggestions: [WeatherSuggestion] {
        weatherManager.getWeatherBasedSuggestions()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("💡 Suggestions météo")
                    .font(.appHeadline) // Space Grotesk SemiBold
                    .fontWeight(.bold)
                
                Spacer()
                
                if !suggestions.isEmpty {
                    Text("\(suggestions.count)")
                        .font(.appCaption) // Space Grotesk Regular
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            
            if suggestions.isEmpty {
                if weatherManager.currentWeather != nil {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Aucune recommandation météo particulière aujourd'hui")
                            .font(.appSubheadline) // Space Grotesk Medium
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    HStack {
                        Image(systemName: "location.slash")
                            .foregroundColor(.orange)
                        Text("Activez la localisation pour recevoir des suggestions personnalisées")
                            .font(.appSubheadline) // Space Grotesk Medium
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            } else {
                ForEach(suggestions.prefix(2)) { suggestion in
                    SuggestionCard(suggestion: suggestion)
                }
                
                if suggestions.count > 2 {
                    Button("Voir \(suggestions.count - 2) suggestion\(suggestions.count > 3 ? "s" : "") de plus") {
                        // Action pour voir plus
                    }
                    .font(.appCaption) // Space Grotesk Regular
                    .foregroundColor(.blue)
                    .padding(.top, 5)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - SuggestionCard
struct SuggestionCard: View {
    let suggestion: WeatherSuggestion
    
    var body: some View {
        HStack(spacing: 12) {
            Text(suggestion.icon)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(suggestion.title)
                    .font(.appSubheadline) // Space Grotesk Medium
                    .fontWeight(.medium)
                
                Text(suggestion.message)
                    .font(.appCaption) // Space Grotesk Regular
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Circle()
                    .fill(suggestion.priority.color)
                    .frame(width: 8, height: 8)
                
                Text(suggestion.category.icon)
                    .font(.appCaption2) // Space Grotesk Light
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(suggestion.category.color.opacity(0.08))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(suggestion.category.color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - ExpensePredictionsView
struct ExpensePredictionsView: View {
    @EnvironmentObject var budgetManager: BudgetManager
    @EnvironmentObject var weatherManager: WeatherManager
    
    private var predictions: [ExpensePrediction] {
        weatherManager.getExpensePredictions(basedOn: budgetManager)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("📊 Prédictions météo")
                    .font(.appHeadline) // Space Grotesk SemiBold
                    .fontWeight(.bold)
                
                Spacer()
                
                if !predictions.isEmpty {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.appCaption) // Space Grotesk Regular
                }
            }
            
            if predictions.isEmpty {
                if weatherManager.currentWeather != nil {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Aucun impact météo prévu sur vos budgets")
                            .font(.appSubheadline) // Space Grotesk Medium
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    HStack {
                        Image(systemName: "location.slash")
                            .foregroundColor(.orange)
                        Text("Données météo requises pour les prédictions budgétaires")
                            .font(.appSubheadline) // Space Grotesk Medium
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            } else {
                ForEach(predictions) { prediction in
                    PredictionCard(prediction: prediction)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.03))
        .cornerRadius(12)
    }
}

// MARK: - PredictionCard
struct PredictionCard: View {
    let prediction: ExpensePrediction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(prediction.category.icon)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(prediction.category.displayName.dropFirst(2)))
                        .font(.appSubheadline) // Space Grotesk Medium
                        .fontWeight(.medium)
                    
                    Text("≈ +\(prediction.predictedIncrease.formatted(.currency(code: "EUR")))")
                        .font(.appCaption) // Space Grotesk Regular
                        .foregroundColor(.orange)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(prediction.confidence * 100))%")
                        .font(.appCaption) // Space Grotesk Regular
                        .fontWeight(.medium)
                        .foregroundColor(confidenceColor)
                    
                    // Mini barre de confiance
                    RoundedRectangle(cornerRadius: 2)
                        .fill(confidenceColor)
                        .frame(width: 30 * prediction.confidence, height: 3)
                        .frame(width: 30, alignment: .leading)
                }
            }
            
            Text(prediction.reason)
                .font(.appCaption) // Space Grotesk Regular
                .foregroundColor(.secondary)
                .padding(.top, 2)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(prediction.category.color.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var confidenceColor: Color {
        if prediction.confidence > 0.7 {
            return .green
        } else if prediction.confidence > 0.5 {
            return .orange
        } else {
            return .red
        }
    }
}
