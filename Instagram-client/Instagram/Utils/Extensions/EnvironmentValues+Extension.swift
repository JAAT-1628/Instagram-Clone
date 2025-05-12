//
//  EnvironmentValues+Extension.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 05/04/25.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var authController = AuthController(httpClient: HTTPClient())
}
