//
//  GlassTextField.swift
//  GlassCast
//
//  Created by Claude on 20/01/26.
//

import SwiftUI

struct GlassTextField: View {
    let label: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))

            if isSecure {
                SecureField("", text: $text)
                    .textFieldStyle(GlassTextFieldStyle())
            } else {
                TextField("", text: $text)
                    .textFieldStyle(GlassTextFieldStyle())
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
    }
}

struct GlassTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 16))
            .foregroundStyle(.primary)
            .padding()
            .background {
                GlassEffectContainer {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.9))
                }
            }
    }
}
