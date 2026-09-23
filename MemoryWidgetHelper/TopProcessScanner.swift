//
//  TopProcessScanner.swift
//  MemoryWidgetHelper 타겟
//
//  개별 프로세스가 아니라 "앱 단위"로 메모리를 합산해서 1등을 뽑는다.
//  예: "Google Chrome Helper (Renderer)" x4개, "Google Chrome Helper" 1개,
//      "Google Chrome" 1개 -> 전부 "Google Chrome"으로 묶어서 합산.
//

import Foundation

struct TopProcessInfo {
    let name: String
    let memoryMB: Double
}

/// "Google Chrome Helper (Renderer)" -> "Google Chrome" 처럼
/// " Helper" 이후 부분을 잘라내서 앱 기본 이름을 뽑아낸다.
private func baseAppName(from processName: String) -> String {
    if let range = processName.range(of: " Helper") {
        return String(processName[..<range.lowerBound])
    }
    return processName
}

func fetchTopMemoryProcess() -> TopProcessInfo? {
    let sizeNeeded = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
    guard sizeNeeded > 0 else { return nil }

    let pidCount = Int(sizeNeeded) / MemoryLayout<pid_t>.size
    var pids = [pid_t](repeating: 0, count: pidCount)
    let actualSize = proc_listpids(UInt32(PROC_ALL_PIDS), 0, &pids, sizeNeeded)
    guard actualSize > 0 else { return nil }

    // 앱 이름 -> 합산된 레지던트 메모리(바이트)
    var appMemory: [String: UInt64] = [:]

    for pid in pids where pid > 0 {
        var info = proc_taskinfo()
        let result = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &info, Int32(MemoryLayout<proc_taskinfo>.size))
        guard result == Int32(MemoryLayout<proc_taskinfo>.size) else { continue }

        var nameBuffer = [CChar](repeating: 0, count: Int(MAXPATHLEN))
        let nameLength = proc_name(pid, &nameBuffer, UInt32(MAXPATHLEN))
        guard nameLength > 0 else { continue }

        let rawName = String(cString: nameBuffer)
        let appName = baseAppName(from: rawName)

        appMemory[appName, default: 0] += info.pti_resident_size
    }

    guard let top = appMemory.max(by: { $0.value < $1.value }) else { return nil }
    return TopProcessInfo(name: top.key, memoryMB: Double(top.value) / 1_048_576.0)
}
