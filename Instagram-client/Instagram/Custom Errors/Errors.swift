//
//  Errors.swift
//  Amazon
//
//  Created by Riptik Jhajhria on 24/03/25.
//

import Foundation

enum ProductError: Error {
    case missingUserId
    case invalidPrice
    case opreationFailed(String)
    case missingImage
    case uploadFailed(String)
    case productNotFound
}

enum UserError: Error {
    case missingId
    case operationFailed(String)
}

enum CartError: Error {
    case operationFailed(String)
}

enum PaymentServiceError: Error {
    case missingPaymentDetails
}

enum OrderError: Error {
    case saveFailed(String)
}
