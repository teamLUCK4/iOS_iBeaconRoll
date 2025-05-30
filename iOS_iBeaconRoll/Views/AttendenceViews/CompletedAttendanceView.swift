//
//  CompletedAttendanceView.swift
//  iOS_iBeaconRoll
//
//  Created by soo on 5/30/25.
//

import SwiftUI

struct CompletedAttendanceView: View {
    let schedule: Class
    
    var body: some View {
        AttendanceStatusView(
            type: .present,
            title: "출석 완료",
            subtitle: subtitleText
        )
    }
    
    private var subtitleText: String {
        if schedule.attendanceTime.valid == true {
            return "입실: \(String(describing: schedule.attendanceTime.time))"
        }
        return ""
    }
}
