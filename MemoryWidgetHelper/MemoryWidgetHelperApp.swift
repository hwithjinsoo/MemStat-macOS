//
//  MemoryWidgetHelperApp.swift
//  MemoryWidgetHelper 타겟 — @main이 있는 파일을 통째로 이 내용으로 교체할 것.
//  (파일 이름이 다르면 @main 붙어있는 파일을 찾아서 여기 내용으로 바꾸면 됨)
//
//  화면에 보이는 창 없이 백그라운드로 5초마다 프로세스를 스캔해서
//  App Group 공유 저장공간에 "제일 메모리 많이 먹는 프로세스" 정보를 적어둔다.
//

import SwiftUI
import ServiceManagement

@main
struct MemoryWidgetHelperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // 창을 띄우지 않기 위해 Settings 씬만 둠 (자동으로 열리지 않음)
        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    // Signing & Capabilities에서 세 타겟에 똑같이 넣은 App Group 문자열과
    // 정확히 같아야 함.
    let groupID = "group.com.jin.memorywidget"
    var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory) // Dock 아이콘 안 뜨게

        registerLoginItemIfNeeded()
        startScanning()
    }

    func registerLoginItemIfNeeded() {
        do {
            if SMAppService.mainApp.status != .enabled {
                try SMAppService.mainApp.register()
            }
        } catch {
            print("로그인 항목 등록 실패 (무시하고 계속 진행): \(error)")
        }
    }

    func startScanning() {
        updateTopProcess()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateTopProcess()
        }
    }

    func updateTopProcess() {
        guard let info = fetchTopMemoryProcess() else {
            print("스캔 실패")
            return
        }
        print("톱 프로세스: \(info.name) - \(info.memoryMB) MB")
        let defaults = UserDefaults(suiteName: groupID)
        defaults?.set(info.name, forKey: "topProcessName")
        defaults?.set(info.memoryMB, forKey: "topProcessMemoryMB")
        // 위젯이 헬퍼가 멈췄는지(값이 오래됐는지) 알 수 있게 기록 시각도 남긴다.
        defaults?.set(Date().timeIntervalSince1970, forKey: "topProcessUpdatedAt")
    }
}
