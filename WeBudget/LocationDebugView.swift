// LocationDebugView.swift - Vue de debug pour les permissions
import SwiftUI
import CoreLocation
import WeatherKit

struct LocationDebugView: View {
    @EnvironmentObject var weatherManager: WeatherManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("🐛 Debug Localisation")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Statut:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(statusText)
                        .foregroundColor(statusColor)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Localisation:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(weatherManager.locationName)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Météo:")
                        .fontWeight(.medium)
                    Spacer()
                    if let weather = weatherManager.currentWeather {
                        Text("\(Int(weather.temperature.value))°C")
                            .foregroundColor(.blue)
                    } else {
                        Text("Non disponible")
                            .foregroundColor(.red)
                    }
                }
                
                if let error = weatherManager.errorMessage {
                    Text("Erreur: \(error)")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 5)
                }
            }
            
            VStack(spacing: 10) {
                Button("🔄 Demander permission") {
                    weatherManager.requestLocationPermission()
                }
                .buttonStyle(.borderedProminent)
                
                Button("📍 Actualiser localisation") {
                    weatherManager.requestLocationPermission()
                }
                .buttonStyle(.bordered)
                
                Button("⚙️ Ouvrir Réglages") {
                    openSettings()
                }
                .buttonStyle(.bordered)
            }
            
            Text("ℹ️ Instructions:")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.top)
            
            Text("1. La permission doit être 'Autorisé en utilisation'\n2. Redémarrez l'app si nécessaire\n3. Testez sur un vrai device (pas simulateur)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var statusText: String {
        switch weatherManager.locationStatus {
        case .notDetermined: return "Non déterminé"
        case .restricted: return "Restreint"
        case .denied: return "Refusé"
        case .authorizedAlways: return "Autorisé toujours"
        case .authorizedWhenInUse: return "Autorisé en utilisation"
        @unknown default: return "Inconnu"
        }
    }
    
    private var statusColor: Color {
        switch weatherManager.locationStatus {
        case .authorizedWhenInUse, .authorizedAlways: return .green
        case .denied, .restricted: return .red
        case .notDetermined: return .orange
        @unknown default: return .gray
        }
    }
    
    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// Ajoutez cette vue temporairement à votre DashboardView pour debug
extension DashboardView {
    var debugSection: some View {
        LocationDebugView()
            .environmentObject(weatherManager)
    }
}
