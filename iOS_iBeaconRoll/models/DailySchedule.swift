//
//  DailySchedule.swift
//  iOS_iBeaconRoll
//
//  Created by soo on 5/30/25.
//

import Foundation
import SwiftUI

enum AttendanceStatus: String, Codable {
    case waiting // 초기값; 출석 전 상태
    case ongoing // 수업이 진행 중
    case completed // 수업이 끝남
    case absent // 결석 처리
    
    var displayText: String {
        switch self {
        case .waiting: return "대기중"
        case .ongoing: return "진행중"
        case .completed: return "완료"
        case .absent: return "결석"
        }
    }
    
    var color: Color {
        switch self {
        case .waiting: return .orange
        case .ongoing: return .green
        case .completed: return .blue
        case .absent: return .red
        }
    }
}

struct DailySchedule: Codable {
    let date: Date
    let studentId: Int
    let dayOfWeek: String
    let classes: [Class]
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case date
        case studentId = "student_id"
        case dayOfWeek = "day_of_week"
        case classes
        case updatedAt = "updated_at"
    }
}

struct Class: Codable {
    let id: Int
    let studentId: Int
    let semester: Int
    let subjectName: String
    let dayOfWeek: String
    let startTime: String
    let endTime: String
    let classroom: String
    var status: Status                      // 수업 상태 정보
    var attendanceTime: AttendanceTime      // 출석 시간 정보
    var attendanceStatus: AttendanceStatus
    let beaconInfo: BeaconInfo
    
    enum CodingKeys: String, CodingKey {
        case id
        case studentId = "student_id"
        case semester
        case subjectName = "subject_name"
        case dayOfWeek = "day_of_week"
        case startTime = "start_time"
        case endTime = "end_time"
        case classroom
        case status
        case attendanceTime = "attendance_time"
        case attendanceStatus = "attendance_status"
        case beaconInfo = "beacon_info"
    }
    
    // 시작 시간을 Date 객체로 변환
    var startTimeDate: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.date(from: startTime) ?? Date()
    }
    // 종료 시간을 Date 객체로 변환
    var endTimeDate: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.date(from: endTime) ?? Date()
    }
}

// **수업** 상태 정보
struct Status: Codable {
    let string: String
    let valid: Bool
    
    enum CodingKeys: String, CodingKey {
        case string = "String"
        case valid = "Valid"
    }
}

// 출석 시간
struct AttendanceTime: Codable {
    let string: String
    let valid: Bool
    let time: Date?
    
    enum CodingKeys: String, CodingKey {
        case string = "String"
        case valid = "Valid"
        case time
    }
    
    init(string: String = "", valid: Bool = false, time: Date? = nil) {
        self.string = string
        self.valid = valid
        self.time = time
    }
}

// 출석 유형 (present, late, absent)
enum AttendanceType {
    case present, late, absent
    
    var icon: String {
        switch self {
        case .present: return "checkmark.circle.fill"
        case .late: return "clock.fill"
        case .absent: return "xmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .present: return .green
        case .late: return .orange
        case .absent: return .red
        }
    }
}


struct BeaconInfo: Codable {
    let id: String
    let uuid: String
    let classroom: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case classroom
        case createdAt = "created_at"
    }
}
