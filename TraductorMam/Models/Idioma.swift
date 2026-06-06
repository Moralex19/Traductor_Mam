//
//  Idioma.swift
//  TraductorMam
//
//  Created by Freddy Morales on 27/03/26.
//

import Foundation

enum Idioma: String, CaseIterable, Identifiable {
    case mam = "Mam"
    case espanol = "Español"
    case ingles = "Inglés"

    var id: String { rawValue }

    var code: String {
        switch self {
        case .mam: return "mam"
        case .espanol: return "es"
        case .ingles: return "en"
        }
    }
}
