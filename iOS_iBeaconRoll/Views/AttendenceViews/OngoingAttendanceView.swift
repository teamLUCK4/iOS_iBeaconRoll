//
//  OngoingAttendanceView.swift
//  iOS_iBeaconRoll
//
//  Created by soo on 5/30/25.
//

import SwiftUI

struct OngoingAttendanceView: View {
    let schedule: Class
    let index: Int
    let viewModel: AttendanceViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            // 현재 출석 상태
            AttendanceStatusView(
                type: .present,
                title: "수업 진행중",
                subtitle: subtitleText
            )
        }
    }
    
    private var subtitleText: String {
        guard schedule.attendanceTime.valid == true,
              let time = schedule.attendanceTime.time else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ko_KR")
        return "입실: \(formatter.string(from: time)) | 경과시간: \(viewModel.getElapsedTime(for: schedule))"
    }
}


