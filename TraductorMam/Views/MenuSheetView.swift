//
//  MenuSheetView.swift
//  TraductorMam
//
//  Created by Freddy Morales on 27/03/26.
//

import SwiftUI

struct MenuSheetView: View {
    @Binding var mostrarInfo: Bool
    @Binding var mostrarCreditos: Bool

    var body: some View {
        VStack(spacing: 30) {
            Text("Menú")
                .font(.title)
                .padding(.top)

            Button {
                mostrarInfo = true
            } label: {
                Label("Información de la aplicación", systemImage: "info.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.mint.opacity(0.2))
                    .cornerRadius(12)
            }

            Button {
                mostrarCreditos = true
            } label: {
                Label("Créditos", systemImage: "person.3.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(12)
            }

            Spacer()
        }
        .padding()
        .alert("Información", isPresented: $mostrarInfo) {
            Button("Aceptar", role: .cancel) { }
        } message: {
            Text("""
            Traductor Mam es una aplicación educativa
            que permite traducir palabras y frases
            entre Mam, Español e Inglés.

            Incluye autocompletado y audio
            para apoyar el aprendizaje.
            """)
        }
        .alert("Créditos", isPresented: $mostrarCreditos) {
            Button("Aceptar", role: .cancel) { }
        } message: {
            Text("""
            • Dr. Aron De La Cruz Vázquez
            • Dr. Christian Mauricio Castillo Estrada
            • Dra. Vanessa Benvides Garcia
            • Dr. Ángeles Belem Priego Sánchez
            • Dr. Karina Cnacino Villatoro
            • Dr. Gloria Amelia Gutu Moguel
            • Dr. Gabriela Setsuko Nakamura Román
            • Mtro. Rene Servando Rivera Robero
            • Mtro. Luis Antonio Álvarez Oval

            • Natalia Isabel García Faviel
            • Proyecto académico
            • Lengua Mam (Ta Qyol Mam)

            2026
            """)
        }
    }
}
