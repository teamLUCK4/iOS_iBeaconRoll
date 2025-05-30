//
//  RangeBeaconView.swift
//  iOS_iBeaconRoll
//
//  Created by soo on 5/30/25.
//

import SwiftUI
import UIKit

struct RangeBeaconView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> RangeBeaconViewController {
        return RangeBeaconViewController()
    }

    func updateUIViewController(_ uiViewController: RangeBeaconViewController, context: Context) {
        // 업데이트 필요 없음
    }
}
