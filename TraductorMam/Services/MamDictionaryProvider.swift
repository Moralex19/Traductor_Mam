import Foundation

struct MamEntry: Codable {
    let mam: String
    let es: [String]
    let en: [String]
}

final class MamDictionaryProvider {

    private(set) var entries: [MamEntry] = []

    private(set) var mamToES: [String: [String]] = [:]
    private(set) var mamToEN: [String: [String]] = [:]
    private(set) var esToMam: [String: String] = [:]
    private(set) var enToMam: [String: String] = [:]

    private(set) var allMam: [String] = []
    private(set) var allES: [String] = []
    private(set) var allEN: [String] = []

    init(jsonFileName: String = "mam_dictionary") {
        loadFromBundle(jsonFileName: jsonFileName)
        buildIndexes()
        print("Entradas cargadas:", entries.count)
    }

    func translate(_ text: String, from: String, to: String) -> String {
        let t = norm(text)
        guard !t.isEmpty else { return "(sin traducción)" }
        guard from != to else { return text }

        if from == "Mam" && to == "Español" {
            return mamToES[t]?.joined(separator: ", ") ?? "(sin traducción)"
        }
        if from == "Mam" && to == "Inglés" {
            return mamToEN[t]?.joined(separator: ", ") ?? "(sin traducción)"
        }

        if to == "Mam" && from == "Español" {
            return esToMam[t] ?? "(sin traducción)"
        }
        if to == "Mam" && from == "Inglés" {
            return enToMam[t] ?? "(sin traducción)"
        }

        // ES <-> EN offline por “puente” Mam si existe
        if from == "Español" && to == "Inglés" {
            if let mam = esToMam[t] {
                return mamToEN[norm(mam)]?.joined(separator: ", ") ?? "(sin traducción)"
            }
            return "(sin traducción offline)"
        }
        if from == "Inglés" && to == "Español" {
            if let mam = enToMam[t] {
                return mamToES[norm(mam)]?.joined(separator: ", ") ?? "(sin traducción)"
            }
            return "(sin traducción offline)"
        }

        return "(sin traducción)"
    }

    func suggestions(prefix: String, inputLanguage: String, limit: Int = 30) -> [String] {
        let p = norm(prefix)
        guard !p.isEmpty else { return [] }

        let source: [String]
        switch inputLanguage {
        case "Mam": source = allMam
        case "Español": source = allES
        case "Inglés": source = allEN
        default: source = allMam + allES + allEN
        }

        let matches = source.filter { norm($0).hasPrefix(p) }
        let unique = Array(Set(matches)).sorted()
        return Array(unique.prefix(limit))
    }

    private func loadFromBundle(jsonFileName: String) {
        guard let url = Bundle.main.url(forResource: jsonFileName, withExtension: "json") else {
            print("No se encontró \(jsonFileName).json en el bundle")
            entries = []
            return
        }

        do {
            let data = try Data(contentsOf: url)
            entries = try JSONDecoder().decode([MamEntry].self, from: data)
        } catch {
            print("Error leyendo/decodificando JSON:", error)
            entries = []
        }
    }

    private func buildIndexes() {
        mamToES.removeAll(); mamToEN.removeAll()
        esToMam.removeAll(); enToMam.removeAll()

        allMam = entries.map { $0.mam }

        var tmpES: [String] = []
        var tmpEN: [String] = []

        for e in entries {
            let mk = norm(e.mam)
            if !e.es.isEmpty { mamToES[mk] = e.es }
            if !e.en.isEmpty { mamToEN[mk] = e.en }

            tmpES.append(contentsOf: e.es)
            tmpEN.append(contentsOf: e.en)

            for s in e.es { esToMam[norm(s)] = e.mam }
            for s in e.en { enToMam[norm(s)] = e.mam }
        }

        allES = Array(Set(tmpES)).sorted()
        allEN = Array(Set(tmpEN)).sorted()
        allMam = Array(Set(allMam)).sorted()
    }

    private func norm(_ s: String) -> String {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let apostrophesFixed = trimmed
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "‘", with: "'")
            .replacingOccurrences(of: "´", with: "'")
        return apostrophesFixed.folding(options: [.diacriticInsensitive], locale: .current)
    }
}
