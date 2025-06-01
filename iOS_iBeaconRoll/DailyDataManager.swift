//
//  DailyDataManager.swift
//  iOS_iBeaconRoll
//
//  Created by soo on 5/30/25.
//

import Foundation

class DailyDataManager {
    static let shared = DailyDataManager()
    
    private let cacheKey = "cachedData"
    private let dateKey = "lastFetchDate"
    private let apiURL = URL(string: "http://192.168.4.12:8080/api/students/1/schedule/today")!
    
    private init() {}
    
    func getDailyData(completion: @escaping (Result<DailySchedule, Error>) -> Void) {
        let today = formattedDate(Date())
        let lastFetched = UserDefaults.standard.string(forKey: dateKey)
        
        if lastFetched == today, let cached = UserDefaults.standard.data(forKey: cacheKey) {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let schedule = try decoder.decode(DailySchedule.self, from: cached)
                completion(.success(schedule))
            } catch {
                completion(.failure(error))
            }
        } else {
            fetchFromAPI { result in
                switch result {
                case .success(let schedule):
                    if let data = try? JSONEncoder().encode(schedule) {
                        UserDefaults.standard.set(data, forKey: self.cacheKey)
                        UserDefaults.standard.set(today, forKey: self.dateKey)
                    }
                    completion(.success(schedule))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func fetchFromAPI(completion: @escaping (Result<DailySchedule, Error>) -> Void) {
        URLSession.shared.dataTask(with: apiURL) { data, response, error in
            if let error = error {
                print("❌ [API ERROR] \(error)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                print("❌ [API ERROR] No data received")
                completion(.failure(NSError(domain: "DataError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 [API RAW JSON] \(jsonString)")
            }
            
            do {
                let decoder = JSONDecoder()
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    if container.decodeNil() {
                        throw DecodingError.valueNotFound(Date.self, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Date value is null"))
                    }
                    let dateString = try container.decode(String.self)
                    guard let date = dateFormatter.date(from: dateString) else {
                        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
                    }
                    return date
                }
                let schedule = try decoder.decode(DailySchedule.self, from: data)
                completion(.success(schedule))
            } catch {
                print("❌ [DECODING ERROR] \(error)")
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .typeMismatch(let type, let context):
                        print("Type '\(type)' mismatch:", context.debugDescription)
                        print("codingPath:", context.codingPath)
                    case .valueNotFound(let type, let context):
                        print("Value '\(type)' not found:", context.debugDescription)
                        print("codingPath:", context.codingPath)
                    case .keyNotFound(let key, let context):
                        print("Key '\(key)' not found:", context.debugDescription)
                        print("codingPath:", context.codingPath)
                    case .dataCorrupted(let context):
                        print("Data corrupted:", context.debugDescription)
                        print("codingPath:", context.codingPath)
                    @unknown default:
                        print("Unknown decoding error")
                    }
                }
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: dateKey)
        print("🗑️ Cache cleared")
    }
}
