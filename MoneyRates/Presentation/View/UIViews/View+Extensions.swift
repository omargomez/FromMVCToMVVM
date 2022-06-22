//
//  View+Extensions.swift
//  MoneyRates
//
//  Created by Omar Gomez on 21/6/22.
//

import SwiftUI

fileprivate struct AppButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(height: 64.0)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(UIColor.systemGray5))
            )
        
    }
}

fileprivate struct AppTextFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(height: 64.0)
            .multilineTextAlignment(.center)
            .textFieldStyle(.plain)
            .font(.system(size: 32, weight: .regular, design: .default))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color(UIColor.systemGray5))
            )
    }
}

extension View {
    func appButtonStyle() -> some View {
        self.modifier(AppButtonModifier())
    }
    
    func appTextFieldStyle() -> some View {
        self.modifier(AppTextFieldModifier())
    }
}
