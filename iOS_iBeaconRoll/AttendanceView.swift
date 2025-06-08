//
//  AttendanceView.swift
//  iOS_iBeaconRoll
//
//  Created by soo on 5/30/25.
//


import SwiftUI

struct AttendanceView: View {
    @ObservedObject var viewModel: AttendanceViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                // 비콘 모니터링 뷰
                RangeBeaconView(attendanceViewModel: viewModel)
                    .edgesIgnoringSafeArea(.all)
                
                // 배경 그라데이션
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
                
                VStack(spacing: 0) {
                    // 헤더
                    HeaderView(scheduleCount: viewModel.schedules.count)
                    
                    // 컨텐츠
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(Array(viewModel.schedules.enumerated()), id: \.element.id) { index, schedule in
                                ScheduleCardView(
                                    schedule: schedule,
                                    index: index,
                                    viewModel: viewModel
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
            }
        }
        .alert("수업 중 퇴실 확인", isPresented: $viewModel.showPreventionAlert) {
            Button("계속 수업", role: .cancel) {
                viewModel.showPreventionAlert = false
            }
        } message: {
            Text("수업이 아직 진행 중입니다.\n정말로 퇴실하시겠습니까?")
        }
    }
}

struct AttendanceView_Previews: PreviewProvider {
    static var previews: some View {
        AttendanceView(viewModel: AttendanceViewModel())
    }
}
