//
//  RangeBeaconViewController.swift
//  iOS_iBeaconRoll
//
//  Created by soo on 5/30/25.
//

import UIKit
import CoreLocation

extension Notification.Name {
    static let attendanceUpdateSuccess = Notification.Name("attendanceUpdateSuccess")
}

class RangeBeaconViewController: UIViewController, CLLocationManagerDelegate {

    let defaultUUID = "ADD8CE0A-EF05-4B57-AD8C-7651198EAB2C"
    
    var locationManager = CLLocationManager()
    var beaconConstraints = [CLBeaconIdentityConstraint: [CLBeacon]]()
    var beacons = [CLProximity: [CLBeacon]]()
    
    var hasSentRequest = false

    override func viewDidLoad() {
        super.viewDidLoad()
                
        // ✅ iBeacon 위치 권한 설정 및 delegate 연결
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization() // background 실행하기 위해
        locationManager.allowsBackgroundLocationUpdates = true

        // ✅ SwiftUI에서 안 보이는 문제 방지
        view.backgroundColor = .clear

        // ✅ 앱 실행하자마자 기본 UUID 감지 시작
        if let uuid = UUID(uuidString: defaultUUID) {
            let constraint = CLBeaconIdentityConstraint(uuid: uuid, major: 100, minor: 0)
            self.beaconConstraints[constraint] = []

            let beaconRegion = CLBeaconRegion(beaconIdentityConstraint: constraint, identifier: uuid.uuidString)
            self.locationManager.startMonitoring(for: beaconRegion)

            print("📡 기본 UUID 감지 시작: \(uuid.uuidString)")
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // ✅ 백그라운드에서 탐지 종료
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        for constraint in beaconConstraints.keys {
            locationManager.stopRangingBeacons(satisfying: constraint)
        }
    }

    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("🚀 모니터링 시작됨: \(region.identifier)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ 위치 매니저 에러: \(error.localizedDescription)")
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

    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        print("🛰️ 탐지된 비콘 수: \(beacons.count)")
        beaconConstraints[beaconConstraint] = beacons

        self.beacons.removeAll()
        var allBeacons = [CLBeacon]()
        for regionResult in beaconConstraints.values {
            allBeacons.append(contentsOf: regionResult)
        }

        for range in [CLProximity.unknown, .immediate, .near, .far] {
            let proximityBeacons = allBeacons.filter { $0.proximity == range }
            if !proximityBeacons.isEmpty {
                self.beacons[range] = proximityBeacons
            }
        }

        // ✅ 가까운 비콘이 있으면 한 번만 서버 요청 보내기
        if !hasSentRequest, let nearest = allBeacons.first, nearest.proximity == .immediate {
            hasSentRequest = true
            sendAttendanceUpdate()
        }
    }
    
    func sendAttendanceUpdate() {
        guard let url = URL(string: "http://192.168.4.5:8080/api/attendance") else {
            print("❌ URL이 잘못됨")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"  // ✅ PUT 요청
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // ✅ 보내고자 하는 JSON 바디
        let payload: [String: Any] = [
            "student_id": 1,
            "status": "Present",
            "classroom": "Building 302",
            "attendance_date": "2025-05-13"
        ]

        // JSON 변환
        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else {
            print("❌ JSON 변환 실패")
            return
        }

        request.httpBody = httpBody

        // ✅ 네트워크 요청 실행
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ 요청 실패: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("✅ 요청 완료 - 응답 코드: \(httpResponse.statusCode)")
                
                // 성공적인 응답을 받았을 때 NotificationCenter를 통해 알림
                if httpResponse.statusCode == 200 {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .attendanceUpdateSuccess, object: nil)
                    }
                }
            }

            if let data = data,
               let responseString = String(data: data, encoding: .utf8) {
                print("📦 응답 데이터: \(responseString)")
            }

        }.resume()
    }
}

