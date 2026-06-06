//
//  TraductorViewModel.swift
//  TraductorMam
//
//  Created by Freddy Morales on 27/03/26.
//
import Foundation
import SwiftUI
import AVFoundation
import UIKit
#if canImport(Translation)
import Translation
import AVFAudio
#endif

final class TraductorViewModel: ObservableObject {

    @Published var textoDeEntrada: String = ""
    @Published var textoTraducido: String = ""
    @Published var sugerencias: [String] = []

    @Published var idiomaDeEntradaSeleccionado: Idioma = .espanol
    @Published var idiomaDestinoSeleccionado: Idioma = .ingles

    @Published var mostrarMenu = false
    @Published var mostrarInfo = false
    @Published var mostrarCreditos = false

    private let mamProvider = MamDictionaryProvider(jsonFileName: "mam_dictionary")

    private var reproductorDeAudio: AVAudioPlayer?
    private let sintetizador = AVSpeechSynthesizer()

    #if canImport(Translation)
    @Published var appleConfig: TranslationSession.Configuration?
    var applePendingText: String = ""
    var appleSourceName: String = ""
    var appleTargetName: String = ""
    #endif

    var idiomasDeEntrada: [Idioma] {
        [.mam, .espanol, .ingles]
    }

    var idiomasDestino: [Idioma] {
        [.espanol, .ingles, .mam]
    }

    func traducirSegunSeleccion() {
        let origen = idiomaDeEntradaSeleccionado.rawValue
        let destino = idiomaDestinoSeleccionado.rawValue
        let trimmed = textoDeEntrada.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            textoTraducido = "(sin traducción)"
            return
        }

        guard origen != destino else {
            textoTraducido = trimmed
            return
        }

        if origen == "Mam" || destino == "Mam" {
            textoTraducido = mamProvider.translate(trimmed, from: origen, to: destino)
            return
        }

        #if canImport(Translation)
        if #available(iOS 18.0, *) {
            let source = Locale.Language(identifier: idiomaDeEntradaSeleccionado.code)
            let target = Locale.Language(identifier: idiomaDestinoSeleccionado.code)

            Task {
                let availability = LanguageAvailability()
                let status = await availability.status(from: source, to: target)

                if status == .unsupported {
                    await MainActor.run {
                        self.textoTraducido = self.mamProvider.translate(trimmed, from: origen, to: destino)
                    }
                    return
                }

                await MainActor.run {
                    self.applePendingText = trimmed
                    self.appleSourceName = origen
                    self.appleTargetName = destino
                    self.appleConfig = .init(source: source, target: target)
                }
            }
        } else {
            textoTraducido = mamProvider.translate(trimmed, from: origen, to: destino)
        }
        #else
        textoTraducido = mamProvider.translate(trimmed, from: origen, to: destino)
        #endif
    }

    func actualizarSugerencias() {
        let q = normalizar(textoDeEntrada)
        guard !q.isEmpty else {
            sugerencias = []
            return
        }

        sugerencias = mamProvider.suggestions(
            prefix: q,
            inputLanguage: idiomaDeEntradaSeleccionado.rawValue,
            limit: 30
        )
    }

    func seleccionarSugerencia(_ sugerencia: String) {
        textoDeEntrada = sugerencia
        sugerencias = []
    }

    func copiarTextoTraducido() {
        let t = textoTraducido.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        UIPasteboard.general.string = t
    }

    func reproducirSegunIdiomaDestino() {
        let pudoReproducirAudio = reproducirAudioDesdeCarpetaAudio(
            fraseTraducida: textoTraducido,
            fallbackOriginal: textoDeEntrada
        )

        if !pudoReproducirAudio {
            hablarTextoTraducido()
        }
    }

    #if canImport(Translation)
    @MainActor
    func aplicarResultadoAppleTranslation(_ texto: String) {
        textoTraducido = texto
        appleConfig = nil
    }

    @MainActor
    func aplicarFallbackAppleTranslation() {
        let fallback = mamProvider.translate(applePendingText, from: appleSourceName, to: appleTargetName)
        textoTraducido = fallback == "(sin traducción offline)"
            ? "(error Apple Translation / sin traducción offline)"
            : fallback
        appleConfig = nil
    }
    #endif

    private func normalizar(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func limpiarTextoParaAudio(_ frase: String) -> String {
        let trimmed = frase.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.folding(options: .diacriticInsensitive, locale: .current)
    }

    private func normalizarSeparadoresAudio(_ texto: String, separator: String, lowercased: Bool) -> String {
        let base = lowercased ? texto.lowercased() : texto
        let allowed = CharacterSet.alphanumerics.union(.whitespaces)
        let cleanedScalars = base.unicodeScalars.map { allowed.contains($0) ? Character($0) : " " }
        let cleaned = String(cleanedScalars)
        let parts = cleaned.split(whereSeparator: { $0.isWhitespace })
        return parts.joined(separator: separator)
    }

    private func nombresCandidatosParaAudio(_ frase: String) -> [String] {
        let limpio = limpiarTextoParaAudio(frase)
        let trimmed = limpio.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let candidatos = [
            trimmed,
            normalizarSeparadoresAudio(trimmed, separator: "_", lowercased: false),
            normalizarSeparadoresAudio(trimmed, separator: "_", lowercased: true),
            normalizarSeparadoresAudio(trimmed, separator: "", lowercased: false),
            normalizarSeparadoresAudio(trimmed, separator: "", lowercased: true)
        ]

        var unicos: [String] = []
        for nombre in candidatos where !nombre.isEmpty {
            if !unicos.contains(nombre) {
                unicos.append(nombre)
            }
        }
        return unicos
    }

    private func reproducirAudioDesdeCarpetaAudio(fraseTraducida: String, fallbackOriginal: String) -> Bool {
        let frase = fraseTraducida.trimmingCharacters(in: .whitespacesAndNewlines)
        let original = fallbackOriginal.trimmingCharacters(in: .whitespacesAndNewlines)

        reproductorDeAudio?.stop()
        reproductorDeAudio = nil

        guard !frase.isEmpty else { return false }

        let translatedCandidates = nombresCandidatosParaAudio(frase)
        let originalCandidates = nombresCandidatosParaAudio(original)
        let candidates = translatedCandidates + originalCandidates
        let exts = ["wav", "mp3", "m4a"]

        var foundURL: URL? = nil

        for name in candidates {
            for ext in exts {
                if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Audios") {
                    foundURL = url
                    break
                }

                if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                    foundURL = url
                    break
                }
            }
            if foundURL != nil { break }
        }

        guard let url = foundURL else {
            print("No se encontró audio.")
            print("Traducción:", frase)
            print("Original:", original)
            print("Probé nombres:", candidates)
            return false
        }

        do {
            reproductorDeAudio?.stop()
            reproductorDeAudio = try AVAudioPlayer(contentsOf: url)
            reproductorDeAudio?.prepareToPlay()
            reproductorDeAudio?.play()
            return true
        } catch {
            print("Error reproduciendo audio:", error.localizedDescription)
            return false
        }
    }

    private func hablarTextoTraducido() {
        let t = textoTraducido.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }

        reproductorDeAudio?.stop()
        reproductorDeAudio = nil

        if sintetizador.isSpeaking {
            sintetizador.stopSpeaking(at: .immediate)
        }

        let u = AVSpeechUtterance(string: t)

        switch idiomaDestinoSeleccionado {
        case .espanol:
            u.voice = AVSpeechSynthesisVoice(language: "es-MX")
        case .ingles:
            u.voice = AVSpeechSynthesisVoice(language: "en-US")
        case .mam:
            u.voice = AVSpeechSynthesisVoice(language: "es-MX")
        }

        u.rate = AVSpeechUtteranceDefaultSpeechRate
        sintetizador.speak(u)
    }
}
