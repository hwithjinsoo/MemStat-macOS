//
//  SharedTopProcess.swift
//  memory widgetExtension 타겟 전용 (Target Membership: memory widgetExtension만)
//
//  헬퍼 앱이 App Group 공유 저장공간에 적어둔 "톱 프로세스" 정보를 읽어온다.
//

import Foundation

func fetchSharedTopProcess(groupID: String = "group.com.jin.memorywidget") -> (name: String, memoryMB: Double)? {
    guard let defaults = UserDefaults(suiteName: groupID),
          let name = defaults.string(forKey: "topProcessName"),
          !name.isEmpty else {
        return nil
    }
    let memoryMB = defaults.double(forKey: "topProcessMemoryMB")
    return (name, memoryMB)
}

