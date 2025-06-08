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

    // 현재 수업의 UUID를 가져오는 computed property
    var defaultUUID: String {
        if let currentClass = DailyDataManager.shared.getCurrentClass() {
            print("🚨 UUID to detect :",currentClass.beaconInfo.uuid)
            return currentClass.beaconInfo.uuid
        }else {
            print("no uuid")
            return "NO-UUID"
        }
    }
    
    var locationManager = CLLocationManager()
    var beaconConstraints = [CLBeaconIdentityConstraint: [CLBeacon]]()
    var beacons = [CLProximity: [CLBeacon]]()
    
    var hasSentRequest = false
    var attendanceViewModel: AttendanceViewModel?

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

//        // [테스트 용] 캐시 초기화
//        DailyDataManager.shared.clearCache()

        // ✅ 앱 실행하자마자 기본 UUID 감지 시작
        startBeaconMonitoring()
    }

    private func startBeaconMonitoring() {
        if let uuid = UUID(uuidString: defaultUUID) {
            let constraint = CLBeaconIdentityConstraint(uuid: uuid, major: 100, minor: 0)
            self.beaconConstraints[constraint] = []

            let beaconRegion = CLBeaconRegion(beaconIdentityConstraint: constraint, identifier: uuid.uuidString)
            beaconRegion.notifyEntryStateOnDisplay = true  // 디스플레이가 켜져있을 때도 감지
            beaconRegion.notifyOnEntry = true  // 영역 진입 시 알림
            beaconRegion.notifyOnExit = true   // 영역 이탈 시 알림
            
            self.locationManager.startMonitoring(for: beaconRegion)
            self.locationManager.startRangingBeacons(satisfying: constraint)

            print("📡 기본 UUID 감지 시작: \(uuid.uuidString)")
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
        // 기존 모니터링 중지
        for constraint in beaconConstraints.keys {
            if let region = locationManager.monitoredRegions.first(where: { $0.identifier == constraint.uuid.uuidString }) {
                locationManager.stopMonitoring(for: region)
                locationManager.stopRangingBeacons(satisfying: constraint)
            }
        }
        beaconConstraints.removeAll()
        
        // 현재 수업의 UUID로 새로운 모니터링 시작
        if let currentClass = DailyDataManager.shared.getCurrentClass(),
           let uuid = UUID(uuidString: currentClass.beaconInfo.uuid) {
            let constraint = CLBeaconIdentityConstraint(uuid: uuid, major: 100, minor: 0)
            self.beaconConstraints[constraint] = []

            let beaconRegion = CLBeaconRegion(beaconIdentityConstraint: constraint, identifier: uuid.uuidString)
            self.locationManager.startMonitoring(for: beaconRegion)
            self.locationManager.startRangingBeacons(satisfying: constraint)

            print("📡 현재 수업 비콘 UUID 감지 시작: \(uuid.uuidString)")
            hasSentRequest = false  // 새로운 수업이 시작되면 출석 요청 플래그 초기화
        }
    }

    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        print("🛰️ 탐지된 비콘 수: \(beacons.count)")
        
        // 현재 수업이 있는지 확인
        guard let currentClass = DailyDataManager.shared.getCurrentClass() else {
            print("⚠️ 현재 진행 중인 수업이 없음")
            return
        }
        
        // 현재 감지된 비콘이 현재 수업의 비콘과 일치하는지 확인
        if beaconConstraint.uuid.uuidString != currentClass.beaconInfo.uuid {
            print("⚠️ 현재 수업의 비콘이 아님 - 감지 중지")
            updateBeaconMonitoring()  // 현재 수업의 비콘으로 업데이트
            return
        }
        
        beaconConstraints[beaconConstraint] = beacons

        self.beacons.removeAll()
        var allBeacons = [CLBeacon]()
        for regionResult in beaconConstraints.values {
            allBeacons.append(contentsOf: regionResult)
        }

        // Add logging for beacon proximity
        for beacon in allBeacons {
            print("📡 비콘 proximity: \(beacon.proximity.rawValue)")
        }

        for range in [CLProximity.unknown, .immediate, .near, .far] {
            let proximityBeacons = allBeacons.filter { $0.proximity == range }
            if !proximityBeacons.isEmpty {
                self.beacons[range] = proximityBeacons
            }
        }

        // ✅ 가까운 비콘이 있으면 한 번만 서버 요청 보내기
        print("🔍 Debug - hasSentRequest: \(hasSentRequest)")
        print("🔍 Debug - allBeacons count: \(allBeacons.count)")
//        if let nearest = allBeacons.first {
//            print("🔍 Debug - nearest proximity: \(nearest.proximity.rawValue)")
//            print("🔍 Debug - is near?: \(nearest.proximity == .immediate)")
//        }
        
        if !hasSentRequest, let nearest = allBeacons.first, nearest.proximity == .immediate {
            hasSentRequest = true
            print("🔥출석 요청 api")
            
            // 현재 시간에 해당하는 수업 찾기
            if let currentClass = DailyDataManager.shared.getCurrentClass() {
                // 현재 감지된 비콘의 UUID와 수업의 비콘 UUID 비교
                let detectedBeaconUUID = nearest.uuid.uuidString
                if currentClass.beaconInfo.uuid == detectedBeaconUUID {
                    print("🔥 현재 수업 시간에 해당하는 비콘 감지됨")
                    // 서버에 출석 요청 보내기
                    sendAttendanceUpdate(for: currentClass)
                } else {
                    print("❌ 감지된 비콘이 현재 수업의 비콘과 일치하지 않음")
                }
            } else {
                print("❌ 현재 진행 중인 수업이 없음")
            }
        }
    }
    
    func sendAttendanceUpdate(for classInfo: Class) {
        guard let url = URL(string: "http://192.168.100.125:8080/api/attendance") else {
            print("❌ URL이 잘못됨")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"  // ✅ PUT 요청
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("classInfo.studentId",classInfo.studentId)
        print("classInfo.classroom",classInfo.classroom)
        
        // Format date in YYYY-MM-DD format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = dateFormatter.string(from: Date())

        // ✅ 보내고자 하는 JSON 바디
        let payload: [String: Any] = [
            "student_id": classInfo.studentId,
            "timetable_id": classInfo.id,  // 추가: timetable_id 필드
            "status": "ongoing",           // 대문자 O로 수정
            "classroom": classInfo.classroom,
            "attendance_date": formattedDate
        ]
        print(payload)

        // JSON 변환
        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else {
            print("❌ JSON 변환 실패")
            return
        }

        request.httpBody = httpBody

        // ✅ 네트워크 요청 실행
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("❌ 요청 실패: \(error.localizedDescription)")
                if let urlError = error as? URLError {
                    print("🔍 URL Error Code: \(urlError.code.rawValue)")
                    print("🔍 URL Error Description: \(urlError.localizedDescription)")
                }
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("✅ 요청 완료 - 응답 코드: \(httpResponse.statusCode)")
            }

            // if let data = data,
            //    let responseString = String(data: data, encoding: .utf8) {
            //     print("📦 응답 데이터: \(responseString)")
                
            //     // 응답이 "success"일 때 출석 상태 업데이트
            //     if responseString.contains("success") {
            //         DispatchQueue.main.async {
            //             self?.attendanceViewModel?.updateAttendanceStatusForBeacon(classroom: "Building 302")
            //         }
            //     }
            // }
            if let data = data {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = json["message"] as? String,
                       message == "Attendance updated" {
                        print("✅ 출석 업데이트 성공")
                        // 서버 응답이 성공이면 프론트엔드 상태 업데이트
                        DispatchQueue.main.async {
                            // 캐시 업데이트
                            DailyDataManager.shared.updateClassStatus(classroom: classInfo.classroom, status: .ongoing)
                            // ViewModel 업데이트
                            self?.attendanceViewModel?.fetchDailySchedule()
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

