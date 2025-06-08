//
//  ContentView.swift
//  iOS_iBeaconRoll
//
//  Created by soo on 5/30/25.
//

import SwiftUI

struct ContentView: View {
    @State private var isDataLoaded = false
    @State private var showAttendanceView = false
    @State private var dataLoadingError: String?
    @StateObject private var viewModel = AttendanceViewModel()
    
    
    var body: some View {
        
        
        
        if showAttendanceView {
            AttendanceView(viewModel: viewModel)
        } else {
            ZStack {
                // RangeBeaconView를 맨 위로 이동하고 opacity 제거
                RangeBeaconView(attendanceViewModel: viewModel)
                    .edgesIgnoringSafeArea(.all)
                
                // 배경 그라데이션
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)  // 터치 이벤트가 뒤로 전달되도록
                
                VStack(spacing: 20) {
                    // 로딩 텍스트
                    Text("🧭 iBeacon View 연결 중...")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding()
                    
                    // 로딩 상태 표시
                    if !isDataLoaded {
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            
                            Text("스케줄 데이터 로딩 중...")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    } else {
                        // 로딩 완료 상태
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.green)
                            
                            Text("데이터 로딩 완료!")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            if let error = dataLoadingError {
                                Text("⚠️ \(error)")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    
                    // 수동 진입 버튼
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showAttendanceView = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                            Text(isDataLoaded ? "출석 관리 시작하기" : "출석 관리 화면으로 이동")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.white.opacity(0.2))
                                .stroke(Color.white, lineWidth: 1)
                        )
                    }
                    .padding(.top, 20)
                    
                    // 개발자 옵션 (디버그용)
                    if !isDataLoaded {
                        Button("캐시 클리어 & 재시도") {
                            DailyDataManager.shared.clearCache()
                            loadDailyData()
                        }
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, 10)
                    }
                }
            }
            .onAppear {
                loadDailyData()
            }
        }
        
    }
    
    
    private func loadDailyData() {
        print("🚀 Starting daily data load...")
        dataLoadingError = nil
        
        
        DailyDataManager.shared.getDailyData { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                     print("✅ Fetched data: \(data)")
                    self.isDataLoaded = true
                    
                    // 데이터 로드 완료 후 2초 뒤 자동으로 출석 화면으로 전환
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            self.showAttendanceView = true
                        }
                    }
                    
                case .failure(let error):
                    print("❌ Error: \(error.localizedDescription)")
                    self.isDataLoaded = true
                    self.dataLoadingError = error.localizedDescription
                    
                    // 에러 발생 시에도 출석 화면으로 전환 (오프라인 모드)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            self.showAttendanceView = true
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
