//
//  RangeBeaconView.swift
//  iOS_iBeaconRoll
//
//  Created by soo on 5/30/25.
//

import SwiftUI
import UIKit

struct RangeBeaconView: UIViewControllerRepresentable {
    var attendanceViewModel: AttendanceViewModel
    
    func makeUIViewController(context: Context) -> RangeBeaconViewController {
        let viewController = RangeBeaconViewController()
        viewController.attendanceViewModel = attendanceViewModel
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: RangeBeaconViewController, context: Context) {
        uiViewController.attendanceViewModel = attendanceViewModel
    }
}
