//
//  FontExtensions.swift
//  WeBudget
//
//  Extension pour utiliser les polices Space Grotesk
//

import SwiftUI

extension Font {
    // MARK: - Space Grotesk Fonts
    
    static func spaceGroteskLight(_ size: CGFloat = 17) -> Font {
        return .custom("SpaceGrotesk-Light", size: size)
    }
    
    static func spaceGroteskRegular(_ size: CGFloat = 17) -> Font {
        return .custom("SpaceGrotesk-Regular", size: size)
    }
    
    static func spaceGroteskMedium(_ size: CGFloat = 17) -> Font {
        return .custom("SpaceGrotesk-Medium", size: size)
    }
    
    static func spaceGroteskSemiBold(_ size: CGFloat = 17) -> Font {
        return .custom("SpaceGrotesk-SemiBold", size: size)
    }
    
    static func spaceGroteskBold(_ size: CGFloat = 17) -> Font {
        return .custom("SpaceGrotesk-Bold", size: size)
    }
    
    // MARK: - Semantic Font Styles
    
    // Titres
    static var appLargeTitle: Font {
        .spaceGroteskBold(34)
    }
    
    static var appTitle: Font {
        .spaceGroteskBold(28)
    }
    
    static var appTitle2: Font {
        .spaceGroteskSemiBold(22)
    }
    
    static var appTitle3: Font {
        .spaceGroteskSemiBold(20)
    }
    
    // Corps de texte
    static var appHeadline: Font {
        .spaceGroteskSemiBold(17)
    }
    
    static var appBody: Font {
        .spaceGroteskRegular(17)
    }
    
    static var appCallout: Font {
        .spaceGroteskRegular(16)
    }
    
    static var appSubheadline: Font {
        .spaceGroteskMedium(15)
    }
    
    static var appFootnote: Font {
        .spaceGroteskRegular(13)
    }
    
    static var appCaption: Font {
        .spaceGroteskRegular(12)
    }
    
    static var appCaption2: Font {
        .spaceGroteskLight(11)
    }
    
    // Spécifiques à l'app
    static var currencyLarge: Font {
        .spaceGroteskBold(28)
    }
    
    static var currencyMedium: Font {
        .spaceGroteskSemiBold(20)
    }
    
    static var currencySmall: Font {
        .spaceGroteskMedium(16)
    }
    
    static var buttonText: Font {
        .spaceGroteskMedium(16)
    }
    
    static var navTitle: Font {
        .spaceGroteskBold(20)
    }
}

// MARK: - View Modifier pour appliquer facilement les polices
extension View {
    func appFont(_ font: Font) -> some View {
        self.font(font)
    }
    
    // Modificateurs de style spécifiques
    func titleStyle() -> some View {
        self.font(.appTitle)
            .foregroundColor(.primary)
    }
    
    func headlineStyle() -> some View {
        self.font(.appHeadline)
            .foregroundColor(.primary)
    }
    
    func bodyStyle() -> some View {
        self.font(.appBody)
            .foregroundColor(.primary)
    }
    
    func captionStyle() -> some View {
        self.font(.appCaption)
            .foregroundColor(.secondary)
    }
    
    func currencyStyle(size: CurrencySize = .medium) -> some View {
        self.font(currencyFont(for: size))
            .foregroundColor(.primary)
    }
    
    private func currencyFont(for size: CurrencySize) -> Font {
        switch size {
        case .large: return .currencyLarge
        case .medium: return .currencyMedium
        case .small: return .currencySmall
        }
    }
}

enum CurrencySize {
    case large, medium, small
}
