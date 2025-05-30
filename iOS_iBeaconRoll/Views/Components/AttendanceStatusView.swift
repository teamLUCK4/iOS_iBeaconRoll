//
//  AttendanceStatusView.swift
//  iOS_iBeaconRoll
//
//  Created by soo on 5/30/25.
//

import SwiftUI

struct AttendanceStatusView: View {
    let type: AttendanceType
    let title: String
    let subtitle: String
    let backgroundColor: Color?
    
    init(type: AttendanceType, title: String, subtitle: String, backgroundColor: Color? = nil) {
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background((backgroundColor ?? Color.gray).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
