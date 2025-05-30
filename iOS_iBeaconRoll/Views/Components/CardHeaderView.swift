//
//  CardHeaderView.swift
//  iOS_iBeaconRoll
//
//  Created by soo on 5/30/25.
//

import SwiftUI

struct CardHeaderView: View {
    let schedule: Class
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(timeRangeString)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(schedule.subjectName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(schedule.classroom)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 상태 배지
            StatusBadgeView(status: schedule.attendanceStatus)
        }
    }
    
    private var timeRangeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ko_KR")
        return "\(formatter.string(from: schedule.startTimeDate)) - \(formatter.string(from: schedule.endTimeDate))"
    }
}
