//
//  AttendanceViewModel.swift
//  iOS_iBeaconRoll
//
//  Created by soo on 5/30/25.
//

import Foundation
import SwiftUI
import UIKit

// MARK: - 출석 관리 ViewModel
/**
 * 출석 관리 기능을 담당하는 ViewModel 클래스
 * - ObservableObject 프로토콜을 통해 SwiftUI View와 데이터 바인딩
 * - 출석 체크인/체크아웃, 스케줄 관리, 타이머 기반 자동 업데이트 등을 처리
 */
class AttendanceViewModel: ObservableObject {
    @Published var schedules: [Class] = []
    @Published var showPreventionAlert = false
    @Published var selectedScheduleIndex: Int?
    @Published var isLoading = false
    @Published var error: Error?
    
    private var timer: Timer?
    weak var beaconViewController: RangeBeaconViewController?
    
    init() {
        loadTodaySchedule()
    }
    
    deinit {
    }
    
    private func loadTodaySchedule() {
        fetchDailySchedule()
    }
    
    
    private func updateScheduleStatus() {
        let now = Date()
        for index in 0..<schedules.count {
            let schedule = schedules[index]
            if schedule.attendanceTime.valid && schedule.attendanceStatus != AttendanceStatus.completed {
                if now >= schedule.endTimeDate {
                    schedules[index].attendanceStatus = AttendanceStatus.completed
                }
            }
        }
    }
    
    /**
     * 서버에서 일일 스케줄 데이터를 가져오는 메서드
     * - 네트워크 요청을 통해 최신 스케줄 정보 동기화
     * - 로딩 상태와 에러 처리 포함
     */
    func fetchDailySchedule() {
        print("📅 Fetching daily schedule...")
        if let dailySchedule = DailyDataManager.shared.getCachedData() {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                print("🔄 이전 상태:", self.schedules.map { "\($0.classroom): \($0.attendanceStatus)" })
                self.schedules = dailySchedule.classes
                print("✅ 새로운 상태:", self.schedules.map { "\($0.classroom): \($0.attendanceStatus)" })
                self.objectWillChange.send()
            }
        } else {
            print("❌ 캐시된 데이터가 없습니다")
        }
    }
    
    func checkIn(at index: Int) {
        schedules[index].attendanceTime = AttendanceTime(string: "", valid: true, time: Date())
        schedules[index].attendanceStatus = AttendanceStatus.completed
    }
    
    //    func requestCheckOut(at index: Int) {
    //        selectedScheduleIndex = index
    //        let schedule = schedules[index]
    //        let now = Date()
    //
    //        // 수업 시간이 끝나지 않았으면 경고 표시
    //        if now < schedule.endTime {
    //            showPreventionAlert = true
    //        } else {
    //            performCheckOut(at: index)
    //        }
    //    }
    
    //    func performCheckOut(at index: Int) {
    //        // 출석 시간만 관리한다면, attendanceTime만 갱신
    //        schedules[index].checkOutTime = AttendanceTime(string: "", valid: true, time: Date())
    //        schedules[index].attendanceStatus = .completed
    //        showPreventionAlert = false
    //        selectedScheduleIndex = nil
    //    }
    
    //    func emergencyCheckOut() {
    //        guard let index = selectedScheduleIndex else { return }
    //        performCheckOut(at: index)
    //    }
    
    func getElapsedTime(for schedule: Class) -> String {
        guard schedule.attendanceTime.valid,
              let checkInTime = schedule.attendanceTime.time else { return "" }
        
        let elapsed = Date().timeIntervalSince(checkInTime)
        let hours = Int(elapsed) / 3600
        let minutes = (Int(elapsed) % 3600) / 60
        return "\(hours)시간 \(minutes)분"
    }
}
