//
//  SharedTopProcess.swift
//  memory widgetExtension 타겟 전용 (Target Membership: memory widgetExtension만)
//
//  헬퍼 앱이 App Group 공유 저장공간에 적어둔 "톱 프로세스" 정보를 읽어온다.
//

import Foundation

/// 헬퍼는 5초마다 값을 쓰므로, 이보다 오래된 값이면 헬퍼가 멈춘 것으로 본다.
let sharedTopProcessStaleInterval: TimeInterval = 60

func fetchSharedTopProcess(groupID: String = "group.com.jin.memorywidget") -> (name: String, memoryMB: Double, updatedAt: Date?)? {
    guard let defaults = UserDefaults(suiteName: groupID),
          let name = defaults.string(forKey: "topProcessName"),
          !name.isEmpty else {
        return nil
    }
    let memoryMB = defaults.double(forKey: "topProcessMemoryMB")
    // 예전 버전 헬퍼가 쓴 값에는 시각이 없음 -> nil (오래된 값으로 취급)
    let timestamp = defaults.double(forKey: "topProcessUpdatedAt")
    let updatedAt = timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
    return (name, memoryMB, updatedAt)
}
