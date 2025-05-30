//
//  HeaderView.swift
//  iOS_iBeaconRoll
//
//  Created by soo on 5/30/25.
//

import SwiftUI

struct HeaderView: View {
    let scheduleCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(Date().formatted(date: .complete, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
            }
            
            HStack {
                Text("오늘의 시간표")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
            }
            
            HStack {
                Text("총 \(scheduleCount)개 수업 예정")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        HeaderView(scheduleCount: 5)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

