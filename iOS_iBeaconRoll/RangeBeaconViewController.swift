//
//  RangeBeaconViewController.swift
//  iOS_iBeaconRoll
//
//  Created by soo on 5/30/25.
//

import UIKit
import CoreLocation
import CoreBluetooth


class RangeBeaconViewController: UIViewController, CLLocationManagerDelegate, CBCentralManagerDelegate {

    // 오늘의 모든 수업 UUID를 가져오는 computed property
    var todayUUIDs: [String] {
        if let dailySchedule = DailyDataManager.shared.getCachedData() {
            let uuids = dailySchedule.classes.map { $0.beaconInfo.uuid }
            print("🚨 UUIDs to detect:", uuids)
            return uuids
        }
        print("no uuids")
        return []
    }
    
    var locationManager = CLLocationManager()
    var beaconConstraints = [CLBeaconIdentityConstraint: [CLBeacon]]()
    var beacons = [CLProximity: [CLBeacon]]()
    
    var hasSentRequest = false
    var attendanceViewModel: AttendanceViewModel?
    var lastBeaconDetectionTime: Date? // 마지막 비콘 감지 시간
    var absenceCheckTimer: Timer? // 부재 체크 타이머

    var bluetoothManager: CBCentralManager?  // ✅ 블루투스 매니저 선언
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // ✅ Bluetooth 권한 요청 트리거
        bluetoothManager = CBCentralManager(delegate: self, queue: nil)
                
        // ✅ iBeacon 위치 권한 설정 및 delegate 연결
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization() // background 실행하기 위해
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false  // 자동 일시 중지 방지

        // ✅ SwiftUI에서 안 보이는 문제 방지
        view.backgroundColor = .clear

        // 초기 마지막 비콘 감지 시간 설정
        lastBeaconDetectionTime = Date()
        
        // 부재 체크 타이머 시작
        startAbsenceCheckTimer()
        
//        // [테스트 용] 캐시 초기화Add commentMore actions
//        DailyDataManager.shared.clearCache()

        // ✅ 앱 실행하자마자 기본 UUID 감지 시작
        startBeaconMonitoring()
    }

    func startAbsenceCheckTimer() {
        // 기존 타이머가 있다면 중지
        absenceCheckTimer?.invalidate()
        
        // 10초마다 부재 체크
        absenceCheckTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.checkForAbsence()
        }
    }

    func checkForAbsence() {
        print("🕒 부재 체크 실행됨")
        guard let lastDetection = lastBeaconDetectionTime else {
            print("⚠️ 마지막 감지 시간 없음")
            return
        }
        
        guard let currentClass = DailyDataManager.shared.getCurrentClass() else {
            print("⚠️ 현재 수업 정보 없음")
            return
        }

        print("📊 현재 수업 상태: \(currentClass.attendanceStatus)")
        
        // 마지막 비콘 감지로부터 10초가 지났는지 확인
        let timeSinceLastDetection = Date().timeIntervalSince(lastDetection)
        print("⏱️ 마지막 비콘 감지로부터 경과 시간: \(timeSinceLastDetection)초")
        
        if timeSinceLastDetection >= 10 { // 10초
            print("❗️비콘 감지 안됨 - \(timeSinceLastDetection)초 경과")
            // 현재 수업이 completed 상태일 때만 absent 처리하도록 수정
            if currentClass.attendanceStatus == .completed {
                print("🔄 결석 처리 시작...")
                DispatchQueue.main.async { [weak self] in
                    self?.sendAbsenceUpdate(for: currentClass)
                }
            } else {
                print("ℹ️ 현재 상태가 completed가 아니라서 결석 처리하지 않음")
            }
        } else {
            print("✅ 비콘 정상 감지 중 - \(timeSinceLastDetection)초")
        }
    }

    func sendAbsenceUpdate(for classInfo: Class) {
        sendAttendanceStatusUpdate(for: classInfo, newStatus: "absent")
    }

    func startBeaconMonitoring() {
        // 기존 모니터링 중지
        for constraint in beaconConstraints.keys {
            if let region = locationManager.monitoredRegions.first(where: { $0.identifier == constraint.uuid.uuidString }) {
                locationManager.stopMonitoring(for: region)
                locationManager.stopRangingBeacons(satisfying: constraint)
            }
        }
        beaconConstraints.removeAll()
        
        // 오늘의 모든 수업 UUID에 대해 모니터링 시작
        for uuidString in todayUUIDs {
            if let uuid = UUID(uuidString: uuidString) {
                print("🔍 비콘 모니터링 시작 - UUID: \(uuid.uuidString)")
                let constraint = CLBeaconIdentityConstraint(uuid: uuid, major: 100, minor: 0)
                self.beaconConstraints[constraint] = []

                let beaconRegion = CLBeaconRegion(beaconIdentityConstraint: constraint, identifier: uuid.uuidString)
                beaconRegion.notifyEntryStateOnDisplay = true  // 디스플레이가 켜져있을 때도 감지
                beaconRegion.notifyOnEntry = true  // 영역 진입 시 알림
                beaconRegion.notifyOnExit = true   // 영역 이탈 시 알림
                
                self.locationManager.startMonitoring(for: beaconRegion)
                self.locationManager.startRangingBeacons(satisfying: constraint)

                print("📡 기본 UUID 감지 시작: \(uuid.uuidString)")
//            print("📱 Location Authorization Status: \(locationManager.authorizationStatus.rawValue)")
//            print("🔵 Bluetooth State: \(bluetoothManager?.state.rawValue ?? -1)")
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("🚀 모니터링 시작됨: \(region.identifier)")
        // 모니터링 시작 즉시 ranging 시작
        if let beaconRegion = region as? CLBeaconRegion {
            manager.startRangingBeacons(satisfying: beaconRegion.beaconIdentityConstraint)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ 위치 매니저 에러: \(error.localizedDescription)")
        // 에러 발생 시 모니터링 재시작
        startBeaconMonitoring()
    }

    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        print("📍 didDetermineState 호출됨 — state: \(state.rawValue), region: \(region.identifier)")

        guard let beaconRegion = region as? CLBeaconRegion else { return }

        if state == .inside {
            print("📍 Region 안에 있음 → Ranging 시작")
            manager.startRangingBeacons(satisfying: beaconRegion.beaconIdentityConstraint)
        } else {
            print("📤 Region 밖에 있음 → Ranging 중단")
            manager.stopRangingBeacons(satisfying: beaconRegion.beaconIdentityConstraint)
        }
    }

    // MARK: - Beacon Monitoring Methods
    func updateBeaconMonitoring() {
        startBeaconMonitoring()  // 모든 UUID 다시 시작
    }

    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        print("🛰️ 탐지된 비콘 수: \(beacons.count)")
        
        // 비콘이 감지될 때마다 마지막 감지 시간 업데이트
        if !beacons.isEmpty {
            lastBeaconDetectionTime = Date()
            print("⏰ 마지막 비콘 감지 시간 업데이트: \(lastBeaconDetectionTime?.description ?? "nil")")
        }
        
        // 현재 수업이 있는지 확인
        guard let currentClass = DailyDataManager.shared.getCurrentClass() else {
            print("⚠️ 현재 진행 중인 수업이 없음")
            return
        }
        
        print("📚 현재 수업: \(currentClass.classroom), 상태: \(currentClass.attendanceStatus)")
        
        beaconConstraints[beaconConstraint] = beacons

        self.beacons.removeAll()
        var allBeacons = [CLBeacon]()
        for regionResult in beaconConstraints.values {
            allBeacons.append(contentsOf: regionResult)
        }

        // Add logging for beacon proximity
        for beacon in allBeacons {
            print("📡 비콘 \(beacon.uuid.uuidString) proximity: \(beacon.proximity.rawValue)")
        }

        for range in [CLProximity.unknown, .immediate, .near, .far] {
            let proximityBeacons = allBeacons.filter { $0.proximity == range }
            if !proximityBeacons.isEmpty {
                self.beacons[range] = proximityBeacons
            }
        }

        if let nearest = allBeacons.first, nearest.proximity == .immediate || nearest.proximity == .near  {
            // 현재 감지된 비콘의 UUID와 수업의 비콘 UUID 비교
            let detectedBeaconUUID = nearest.uuid.uuidString
            let proximityText = nearest.proximity == .immediate ? "immediate" : "near"
            print("🎯 가장 가까운 비콘 UUID: \(detectedBeaconUUID) (proximity: \(proximityText))")
            print("📍 현재 수업 비콘 UUID: \(currentClass.beaconInfo.uuid)")
            
            if currentClass.beaconInfo.uuid == detectedBeaconUUID {
                print("🔥 현재 수업 시간에 해당하는 비콘 감지됨 (proximity: \(proximityText))")
                
                if currentClass.attendanceStatus == .absent {
                    // 결석 상태였다면 다시 출석 상태로 변경
                    print("🔄 결석 → 출석 상태로 복구")
                    DispatchQueue.main.async { [weak self] in
                        self?.sendAttendanceStatusUpdate(for: currentClass, newStatus: "completed")
                    }
                } else if !hasSentRequest {
                    // 첫 출석 요청
                    hasSentRequest = true
                    print("🔥 첫 출석 요청 api")
                    DispatchQueue.main.async { [weak self] in
                        self?.sendAttendanceStatusUpdate(for: currentClass, newStatus: "completed")
                    }
                }
            } else {
                print("❌ 감지된 비콘이 현재 수업의 비콘과 일치하지 않음")
            }
        } else {
            print("📡 immediate 상태의 비콘이 없음")
        }
    }

    // 통합된 출석 상태 업데이트 함수
    func sendAttendanceStatusUpdate(for classInfo: Class, newStatus: String) {
        guard let url = URL(string: "http://43.203.147.170:8080/api/attendance") else {
            print("❌ URL이 잘못됨")
            return
        }

        print("📤 상태 업데이트 시작 - \(classInfo.classroom): \(newStatus)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = dateFormatter.string(from: Date())

        let payload: [String: Any] = [
            "student_id": classInfo.studentId,
            "timetable_id": classInfo.id,
            "status": newStatus,
            "classroom": classInfo.classroom,
            "attendance_date": formattedDate
        ]
        print("📤 전송할 데이터:", payload)

        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else {
            print("❌ JSON 변환 실패")
            return
        }

        request.httpBody = httpBody

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("❌ 요청 실패: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("✅ 요청 완료 - 응답 코드: \(httpResponse.statusCode)")
            }

            if let data = data {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = json["message"] as? String,
                       message == "Attendance updated" {
                        print("😍😍 출석 상태 업데이트 성공")
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            print("📱 ViewModel 업데이트 시작")
                            // 캐시 업데이트
                            let newAttendanceStatus: AttendanceStatus = newStatus == "completed" ? .completed : .absent
                            DailyDataManager.shared.updateClassStatus(classroom: classInfo.classroom, status: newAttendanceStatus)
                            
                            // ViewModel이 nil이 아닌지 확인
                            if let viewModel = self.attendanceViewModel {
                                print("✅ ViewModel 존재함")
                                viewModel.fetchDailySchedule()
                            } else {
                                print("❌ ViewModel이 nil입니다")
                            }
                            
                            // 비콘 모니터링 재시작
                            self.startBeaconMonitoring()
                        }
                    }
                } catch {
                    print("❌ JSON 파싱 실패: \(error.localizedDescription)")
                }
            }
        }.resume()
    }

    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("✅ Bluetooth is ON")
        case .poweredOff:
            print("❌ Bluetooth is OFF")
        default:
            print("⚠️ Bluetooth 상태: \(central.state.rawValue)")
        }
    }
}

