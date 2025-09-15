// WeatherViews.swift - Toutes les vues météo
import SwiftUI
import WeatherKit

// MARK: - WeatherWidget
struct WeatherWidget: View {
    @EnvironmentObject var weatherManager: WeatherManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: weatherIcon)
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(weatherManager.locationName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let weather = weatherManager.currentWeather {
                            Text("\(Int(weather.temperature.value))°C")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                    }
                }
                
                if let weather = weatherManager.currentWeather {
                    Text(weather.condition.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Indicateur d'impact budget
            if let impact = budgetImpact {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Impact budget")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(impact.text)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(impact.color)
                }
            }
            
            if weatherManager.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else if weatherManager.errorMessage != nil {
                Button("Réessayer") {
                    weatherManager.requestLocationPermission()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.cyan.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .onAppear {
            weatherManager.requestLocationPermission()
        }
    }
    
    private var weatherIcon: String {
        guard let weather = weatherManager.currentWeather else {
            return "cloud.fill"
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
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                if !suggestions.isEmpty {
                    Text("\(suggestions.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            
            if suggestions.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Aucune recommandation météo particulière aujourd'hui")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                ForEach(suggestions.prefix(2)) { suggestion in
                    SuggestionCard(suggestion: suggestion)
                }
                
                if suggestions.count > 2 {
                    Button("Voir \(suggestions.count - 2) suggestion\(suggestions.count > 3 ? "s" : "") de plus") {
                        // Action pour voir plus
                    }
                    .font(.caption)
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
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(suggestion.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Circle()
                    .fill(suggestion.priority.color)
                    .frame(width: 8, height: 8)
                
                Text(suggestion.category.icon)
                    .font(.caption2)
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
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                if !predictions.isEmpty {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }
            
            if predictions.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Aucun impact météo prévu sur vos budgets")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
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
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("≈ +\(prediction.predictedIncrease.formatted(.currency(code: "EUR")))")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(prediction.confidence * 100))%")
                        .font(.caption)
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
                .font(.caption)
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
