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
    private let apiURL = URL(string: "http://43.203.147.170:8080/api/students/1/schedule/today")!
    
    private init() {}
    
    func getDailyData(completion: @escaping (Result<DailySchedule, Error>) -> Void) {
        let today = formattedDate(Date())
        let lastFetched = UserDefaults.standard.string(forKey: dateKey)
        
        if lastFetched == today, let cached = UserDefaults.standard.data(forKey: cacheKey) {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    
                    // Try to decode as string first
                    if let dateString = try? container.decode(String.self) {
                        let dateFormatter = ISO8601DateFormatter()
                        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                        if let date = dateFormatter.date(from: dateString) {
                            return date
                        }
                    }
                    
                    // If string decoding fails, try to decode as number (timestamp)
                    if let timestamp = try? container.decode(Double.self) {
                        return Date(timeIntervalSince1970: timestamp)
                    }
                    
                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Cannot decode date value"
                    )
                }
                let schedule = try decoder.decode(DailySchedule.self, from: cached)
                completion(.success(schedule))
            } catch {
                print("❌ [CACHE DECODING ERROR] \(error)")
                // 캐시 디코딩 실패 시 캐시를 지우고 API에서 새로 가져오기
                UserDefaults.standard.removeObject(forKey: cacheKey)
                UserDefaults.standard.removeObject(forKey: dateKey)
                fetchFromAPI(completion: completion)
            }
        } else {
            fetchFromAPI(completion: completion)
        }
    }
    
    private func fetchFromAPI(completion: @escaping (Result<DailySchedule, Error>) -> Void) {
        print("🌐 [API REQUEST] Fetching from URL: \(apiURL)")
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ [API ERROR] \(error)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 [HTTP STATUS] \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    print("❌ [HTTP ERROR] Unexpected status code: \(httpResponse.statusCode)")
                    completion(.failure(NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Unexpected status code: \(httpResponse.statusCode)"])))
                    return
                }
            }
            
            guard let data = data else {
                print("❌ [API ERROR] No data received")
                completion(.failure(NSError(domain: "DataError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            // Print raw JSON response
//            if let jsonString = String(data: data, encoding: .utf8) {
//                // print("📦 [API RAW JSON] \(jsonString)")
//            }
            
            do {
                let decoder = JSONDecoder()
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateString = try container.decode(String.self)
                    print("📅 [DATE PARSING] Attempting to parse date: \(dateString)")
                    
                    if let date = dateFormatter.date(from: dateString) {
                        print("✅ [DATE PARSING] Successfully parsed date")
                        return date
                    }
                    
                    print("❌ [DATE PARSING] Failed to parse date")
                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Cannot decode date string \(dateString)"
                    )
                }
                
                let schedule = try decoder.decode(DailySchedule.self, from: data)
                print("✅ [DECODING SUCCESS] Successfully decoded schedule")
                
                // 캐시에 저장할 때는 타임스탬프로 변환
                if let encodedData = try? JSONEncoder().encode(schedule) {
                    let json = try JSONSerialization.jsonObject(with: encodedData) as? [String: Any]
                    var modifiedJson = json ?? [:]
                    
                    // date와 updatedAt을 타임스탬프로 변환
                    modifiedJson["date"] = schedule.date.timeIntervalSince1970
                    modifiedJson["updated_at"] = schedule.updatedAt.timeIntervalSince1970
                    
                    if let modifiedData = try? JSONSerialization.data(withJSONObject: modifiedJson) {
                        UserDefaults.standard.set(modifiedData, forKey: self.cacheKey)
                        UserDefaults.standard.set(self.formattedDate(Date()), forKey: self.dateKey)
                    }
                }
                
                completion(.success(schedule))
            } catch {
                print("❌ [DECODING ERROR] \(error)")
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .typeMismatch(let type, let context):
                        print("Type '\(type)' mismatch:", context.debugDescription)
                        print("codingPath:", context.codingPath)
                        if let data = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            print("📄 [JSON STRUCTURE]", data)
                        }
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
        
        // Fetch new data from API
        fetchFromAPI { result in
            switch result {
            case .success(let schedule):
                if let data = try? JSONEncoder().encode(schedule) {
                    UserDefaults.standard.set(data, forKey: self.cacheKey)
                    UserDefaults.standard.set(self.formattedDate(Date()), forKey: self.dateKey)
                }
            case .failure(let error):
                print("❌ Failed to fetch new data after cache clear: \(error)")
            }
        }
    }
    
    // MARK: - Cached Data Access
    
    /// Returns the cached DailySchedule if available, nil otherwise
    func getCachedData() -> DailySchedule? {
        guard let cached = UserDefaults.standard.data(forKey: cacheKey) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                
                // Try to decode as string first
                if let dateString = try? container.decode(String.self) {
                    let dateFormatter = ISO8601DateFormatter()
                    dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    if let date = dateFormatter.date(from: dateString) {
                        return date
                    }
                }
                
                // If string decoding fails, try to decode as number (timestamp)
                if let timestamp = try? container.decode(Double.self) {
                    return Date(timeIntervalSince1970: timestamp)
                }
                
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Cannot decode date value"
                )
            }
            return try decoder.decode(DailySchedule.self, from: cached)
        } catch {
            print("❌ [CACHE DECODING ERROR] \(error)")
            return nil
        }
    }
    
    /// Returns true if there is valid cached data for today
    var hasValidCache: Bool {
        let today = formattedDate(Date())
        let lastFetched = UserDefaults.standard.string(forKey: dateKey)
        return lastFetched == today && UserDefaults.standard.data(forKey: cacheKey) != nil
    }
    
    // MARK: - Attendance Management
    
    /// 현재 시간에 해당하는 수업을 찾아 반환합니다.
    func getCurrentClass() -> Class? {
        guard let schedule = getCachedData() else { return nil }
        
        let now = Date()
        let calendar = Calendar.current
        
        // 현재 시간의 시/분만 추출
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTimeInMinutes = currentHour * 60 + currentMinute
        
        print("🕒 현재 시간: \(currentHour):\(currentMinute)")
        
        if let foundClass = schedule.classes.first(where: { classInfo in
            // 시작 시간 파싱
            let startComponents = classInfo.startTime.split(separator: ":")
            guard startComponents.count == 3,
                  let startHour = Int(startComponents[0]),
                  let startMinute = Int(startComponents[1]) else {
                return false
            }
            let startTimeInMinutes = startHour * 60 + startMinute
            
            // 종료 시간 파싱
            let endComponents = classInfo.endTime.split(separator: ":")
            guard endComponents.count == 3,
                  let endHour = Int(endComponents[0]),
                  let endMinute = Int(endComponents[1]) else {
                return false
            }
            let endTimeInMinutes = endHour * 60 + endMinute
            
            // print("📚 수업 시간: \(startHour):\(startMinute) ~ \(endHour):\(endMinute)")
            
            // 수업 시작 5분 전부터 종료 20분 후까지를 수업 시간으로 간주
            let bufferTime = 5 // 5분 버퍼
            return currentTimeInMinutes >= (startTimeInMinutes - bufferTime) &&
                   currentTimeInMinutes <= (endTimeInMinutes)
        }) {
            print("✅ 찾은 수업: \(foundClass.subjectName) (\(foundClass.classroom))")
            print("📡 수업 비콘 UUID: \(foundClass.beaconInfo.uuid)")
            return foundClass
        }
        
        return nil
    }
    
    /// 특정 교실의 수업 정보를 찾아 반환합니다.
    func getClassForClassroom(_ classroom: String) -> Class? {
        guard let schedule = getCachedData() else { return nil }
        return schedule.classes.first { $0.classroom == classroom }
    }
    
    /// 캐시된 수업 정보를 업데이트합니다.
    func updateClassStatus(classroom: String, status: AttendanceStatus) {
        guard let schedule = getCachedData() else { return }
        
        // 새로운 classes 배열 생성
        var updatedClasses = schedule.classes
        if let index = updatedClasses.firstIndex(where: { $0.classroom == classroom }) {
            // 새로운 Class 객체 생성
            var updatedClass = updatedClasses[index]
            updatedClass.attendanceStatus = status
            updatedClasses[index] = updatedClass
            
            // 새로운 DailySchedule 객체 생성
            let updatedSchedule = DailySchedule(
                date: schedule.date,
                studentId: schedule.studentId,
                dayOfWeek: schedule.dayOfWeek,
                classes: updatedClasses,
                updatedAt: Date()
            )
            
            // 캐시 업데이트
            if let encodedData = try? JSONEncoder().encode(updatedSchedule) {
                UserDefaults.standard.set(encodedData, forKey: cacheKey)
            }
        }
    }
}
