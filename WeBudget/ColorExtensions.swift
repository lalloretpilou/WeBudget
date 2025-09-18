//
//  ColorExtensions.swift
//  WeBudget
//
//  Created by Pierre-Louis L'ALLORET on 16/09/2025.
//  Palette de couleurs rétro pour WeBudget
//

import SwiftUI

extension Color {
    
    // MARK: - Couleurs Principales Rétro
    
    /// Couleur d'accent principale - Vert lime électrique (version lisible)
    /// Usage: Boutons principaux, call-to-action, succès, éléments positifs
    static let limeElectric = Color(hex: "#A8E026")
    
    /// Couleur secondaire - Rose bubblegum
    /// Usage: Éléments ludiques, notifications, highlights féminins
    static let pinkBubblegum = Color(hex: "#FFADD8")
    
    /// Couleur tertiaire - Pêche sunset
    /// Usage: Avertissements, transitions, éléments chaleureux
    static let peachSunset = Color(hex: "#FDB687")
    
    /// Rose poudré délicat
    /// Usage: Fond de cartes délicates, éléments subtils
    static let powderPink = Color(hex: "#FFDEEF")
    
    /// Marron riche
    /// Usage: Texte sur fond clair, éléments de contraste
    static let richBrown = Color(hex: "#9C4A0C")
    
    // MARK: - Couleurs Complémentaires Rétro (version améliorée)
    
    /// Vert lime alternatif plus doux
    /// Usage: Éléments secondaires verts, fonds subtils
    static let limeSoft = Color(hex: "#D8FE67")
    
    /// Bleu ciel rétro
    /// Usage: Informations, liens, éléments informatifs et apaisants
    static let skyBlueRetro = Color(hex: "#87CEEB")
    
    /// Violet prune vintage
    /// Usage: Éléments premium, bordures délicates, touches sophistiquées
    static let plumVintage = Color(hex: "#DDA0DD")
    
    /// Or kaki
    /// Usage: Highlights, éléments importants, accents dorés
    static let khakiGold = Color(hex: "#F0E68C")
    
    /// Turquoise vintage
    /// Usage: Éléments aquatiques, fraîcheur, contraste avec les tons chauds
    static let turquoiseVintage = Color(hex: "#40E0D0")
    
    /// Corail doux
    /// Usage: Éléments intermédiaires, transitions douces
    static let softCoral = Color(hex: "#FF7F7F")
    
    // MARK: - Couleurs Sombres (Mode Sombre)
    
    /// Brun profond - Fond principal mode sombre
    /// Usage: Arrière-plan principal en mode sombre, contraste élevé
    static let brownDeep = Color(hex: "#2C1810")
    
    /// Grain de café - Éléments secondaires sombres
    /// Usage: Cartes, éléments secondaires, ombres subtiles
    static let coffeeBean = Color(hex: "#4A3728")
    
    /// Bleu minuit - Alternative sombre élégante
    /// Usage: Mode sombre alternatif, fond d'écran, navigation
    static let midnightBlue = Color(hex: "#1A1A2E")
    
    /// Aubergine profonde
    /// Usage: Éléments sombres avec une touche de couleur
    static let deepEggplant = Color(hex: "#614051")
    
    /// Vert forêt sombre
    /// Usage: Éléments de nature, contraste avec les tons chauds
    static let darkForest = Color(hex: "#355E3B")
    
    // MARK: - Neutres Modernes
    
    /// Crème papier - Fond principal clair
    /// Usage: Arrière-plan principal, fond de cartes, surfaces neutres
    static let creamPaper = Color(hex: "#F5F5DC")
    
    /// Brume lavande - Fond alternatif doux
    /// Usage: Sections délicates, fond alternatif, zones de repos visuel
    static let lavenderMist = Color(hex: "#E6E6FA")
    
    /// Gris mat - Texte secondaire
    /// Usage: Texte secondaire, bordures subtiles, éléments discrets
    static let dimGray = Color(hex: "#696969")
    
    /// Blanc cassé chaleureux
    /// Usage: Zones de contenu, cards en mode clair
    static let warmWhite = Color(hex: "#FEFCF3")
    
    /// Beige moderne
    /// Usage: Éléments neutres sophistiqués
    static let modernBeige = Color(hex: "#E8E2D4")
    
    // MARK: - Gradients Rétro Signature
    
    /// Gradient principal - Lime vers Ciel (version améliorée)
    /// Usage: Boutons principaux, headers importants, éléments de navigation
    static let limeToSky = LinearGradient(
        colors: [Color(hex: "#A8E026"), Color(hex: "#6BB8E8")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Gradient lime doux - pour les fonds
    /// Usage: Fonds subtils, éléments délicats
    static let limeSoftGradient = LinearGradient(
        colors: [Color(hex: "#D8FE67"), Color(hex: "#B8F567")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Gradient doux - Rêves roses
    /// Usage: Cartes spéciales, notifications douces, éléments féminins
    static let pinkDreams = LinearGradient(
        colors: [.pinkBubblegum, .plumVintage],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Gradient chaleureux - Lueur du sunset
    /// Usage: Éléments de navigation, highlights, zones d'action
    static let sunsetGlow = LinearGradient(
        colors: [.peachSunset, .khakiGold],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// Gradient océan - Turquoise vers rose
    /// Usage: Sections météo, éléments aquatiques
    static let oceanBreeze = LinearGradient(
        colors: [.turquoiseVintage, .powderPink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Gradient terre - Brun vers pêche
    /// Usage: Éléments naturels, sections de configuration
    static let earthTone = LinearGradient(
        colors: [.richBrown, .peachSunset],
        startPoint: .bottom,
        endPoint: .top
    )
    
    // MARK: - Couleurs Fonctionnelles WeBudget
    
    /// Succès financier - Vert lime avec meilleur contraste
    static let budgetSuccess = Color(hex: "#7DB928")
    
    /// Succès financier fond - Version plus douce pour les fonds
    static let budgetSuccessBackground = Color(hex: "#D8FE67").opacity(0.3)
    
    /// Attention budget - Orange pêche
    static let budgetWarning = Color.peachSunset
    
    /// Dépassement budget - Rouge corail
    static let budgetDanger = Color.softCoral
    
    /// Informations - Bleu ciel
    static let budgetInfo = Color.skyBlueRetro
    
    /// Épargne - Violet premium
    static let savingsColor = Color.plumVintage
    
    /// Revenus - Or kaki
    static let incomeColor = Color.khakiGold
    
    // MARK: - Couleurs par Catégorie de Transaction (Rétro Theme)
    
    /// Alimentation - Vert lime (nature, fraîcheur)
    static let categoryAlimentation = Color.limeElectric
    
    /// Loyer - Bleu ciel (stabilité, confiance)
    static let categoryLoyer = Color.skyBlueRetro
    
    /// Abonnements - Violet prune (premium, régularité)
    static let categoryAbonnements = Color.plumVintage
    
    /// Habitation - Pêche sunset (chaleur du foyer)
    static let categoryHabitation = Color.peachSunset
    
    /// Sorties - Rose bubblegum (plaisir, détente)
    static let categorySorties = Color.pinkBubblegum
    
    /// Crédits - Brun riche (sérieux, engagement)
    static let categoryCredits = Color.richBrown
    
    /// Épargne - Or kaki (valeur, accumulation)
    static let categoryEpargne = Color.khakiGold
    
    /// Transports - Turquoise (mouvement, déplacement)
    static let categoryTransports = Color.turquoiseVintage
    
    // MARK: - Helper pour conversion Hex vers Color
    
    /// Initialise une Color à partir d'une chaîne hexadécimale
    /// - Parameter hex: Chaîne hexadécimale (avec ou sans #, 3, 6 ou 8 caractères)
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // MARK: - Méthodes Utilitaires
    
    /// Retourne une version plus claire de la couleur
    /// - Parameter factor: Facteur de clarté (0.0 à 1.0)
    func lighter(by factor: Double = 0.2) -> Color {
        return self.opacity(1.0 - factor)
    }
    
    /// Retourne une version plus sombre de la couleur
    /// - Parameter factor: Facteur d'assombrissement (0.0 à 1.0)
    func darker(by factor: Double = 0.2) -> Color {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return Color(
            red: max(red - factor, 0),
            green: max(green - factor, 0),
            blue: max(blue - factor, 0),
            opacity: alpha
        )
    }
}

// MARK: - View Extensions pour Application Facile

extension View {
    
    /// Applique le style de carte rétro standard
    func retroCardStyle() -> some View {
        self
            .padding()
            .background(Color.warmWhite)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.limeElectric.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(12)
            .shadow(color: Color.limeElectric.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    /// Applique le style de bouton principal rétro
    func retroButtonStyle() -> some View {
        self
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.limeToSky)
            .foregroundColor(Color.brownDeep)
            .fontWeight(.semibold)
            .cornerRadius(25)
            .shadow(color: Color.limeElectric.opacity(0.3), radius: 4, x: 0, y: 2)
    }
    
    /// Applique le style de bouton secondaire rétro
    func retroSecondaryButtonStyle() -> some View {
        self
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.pinkDreams)
            .foregroundColor(Color.brownDeep)
            .fontWeight(.medium)
            .cornerRadius(20)
            .shadow(color: Color.pinkBubblegum.opacity(0.2), radius: 3, x: 0, y: 1)
    }
    
    /// Applique le style d'alerte rétro
    /// - Parameter type: Type d'alerte (success, warning, danger, info)
    func retroAlertStyle(_ type: RetroAlertType) -> some View {
        self
            .padding()
            .background(type.backgroundColor)
            .overlay(
                Rectangle()
                    .frame(width: 4)
                    .foregroundColor(type.accentColor),
                alignment: .leading
            )
            .cornerRadius(8)
    }
}

// MARK: - Enum pour Types d'Alertes

enum RetroAlertType {
    case success, warning, danger, info
    
    var backgroundColor: Color {
        switch self {
        case .success: return Color.limeElectric.opacity(0.1)
        case .warning: return Color.peachSunset.opacity(0.1)
        case .danger: return Color.softCoral.opacity(0.1)
        case .info: return Color.skyBlueRetro.opacity(0.1)
        }
    }
    
    var accentColor: Color {
        switch self {
        case .success: return Color.limeElectric
        case .warning: return Color.peachSunset
        case .danger: return Color.softCoral
        case .info: return Color.skyBlueRetro
        }
    }
}

// MARK: - Couleurs Adaptatives (Mode Sombre/Clair)

extension Color {
    
    /// Couleur de fond adaptative selon le mode d'affichage
    static func adaptiveBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.midnightBlue : Color.creamPaper
    }
    
    /// Couleur de texte adaptative selon le mode d'affichage
    static func adaptiveText(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.creamPaper : Color.brownDeep
    }
    
    /// Couleur de surface adaptative (cartes, etc.)
    static func adaptiveSurface(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.coffeeBean : Color.warmWhite
    }
}
