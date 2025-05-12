//
//  HTTPClient+Extension.swift
//  Instagram
//
//  Created by Riptik Jhajhria on 06/04/25.
//

import Foundation

extension HTTPClient {
    // Creates a configured JSONDecoder that handles various date formats
    static func configuredJSONDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        
        // Configure date decoding strategy
        decoder.dateDecodingStrategy = .custom({ decoder -> Date in
            let container = try decoder.singleValueContainer()
            
            // Try to decode as double (timestamp)
            if let timestamp = try? container.decode(Double.self) {
                return Date(timeIntervalSince1970: timestamp / 1000) // Convert from milliseconds
            }
            
            // Try to decode as string (ISO date)
            if let dateString = try? container.decode(String.self) {
                // Try ISO 8601 format
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                
                if let date = formatter.date(from: dateString) {
                    return date
                }
                
                // Try other common formats
                let fallbackFormatter = DateFormatter()
                fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                
                if let date = fallbackFormatter.date(from: dateString) {
                    return date
                }
                
                // Try default date format
                fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                if let date = fallbackFormatter.date(from: dateString) {
                    return date
                }
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date"
            )
        })
        
        return decoder
    }
}
