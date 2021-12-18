//
//  BlurError.swift
//  Blurrable
//
//  Created by Mariya Pankova on 18.12.2021.
//

enum BlurError: Error {
    case unsupportedType

    var description: String {
        switch self {
        case .unsupportedType:
            return "Unsupported data type"
        }
    }
}
