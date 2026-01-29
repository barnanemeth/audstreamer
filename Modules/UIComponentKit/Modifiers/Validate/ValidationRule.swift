//
//  ValidationRule.swift
//  UIComponentKit
//
//  Created by Barna Nemeth on 2024. 12. 16..
//

public protocol ValidationRule: AnyObject {
    var errorMessage: String? { get set }
    func validate(_ text: String) -> Bool
    var isValid: Bool { get }
}
