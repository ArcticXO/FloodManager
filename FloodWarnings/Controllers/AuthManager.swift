//
//  AuthManager.swift
//  FloodWarnings
//
//  Created by Ali on 20/03/2025.
//


import Foundation
import SwiftUI

class AuthManager: ObservableObject {
    @Published var isAuthenticated: Bool = false

    func login() {
        isAuthenticated = true
    }

    func logout() {
        isAuthenticated = false
    }
}