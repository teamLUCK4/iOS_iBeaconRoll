//
//  ScheduleCardView.swift
//  iOS_iBeaconRoll
//
//  Created by soo on 5/30/25.
//

import SwiftUI

struct ScheduleCardView: View {
    let schedule: Class
    let index: Int
    let viewModel: AttendanceViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 카드 헤더
            CardHeaderView(schedule: schedule)
            
            Divider()
            
            // 출석 섹션
            attendanceSection
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
    
    @ViewBuilder
    private var attendanceSection: some View {
        switch schedule.attendanceStatus {
        case .waiting:
            WaitingAttendanceView(index: index, viewModel: viewModel)
        case .ongoing:
            OngoingAttendanceView(schedule: schedule, index: index, viewModel: viewModel)
        case .completed:
            CompletedAttendanceView(schedule: schedule)
        case .absent:
            AbsentAttendanceView()
        }
    }
}
