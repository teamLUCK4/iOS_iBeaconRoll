//
//  WaitingAttendanceView.swift
//  iOS_iBeaconRoll
//
//  Created by soo on 5/30/25.
//

import SwiftUI

struct WaitingAttendanceView: View {
    let index: Int
    let viewModel: AttendanceViewModel
    
    var body: some View {
        AttendanceStatusView(
            type: .present,
            title: "출석 대기 중",
            subtitle: ""
        )
    }
    
}
