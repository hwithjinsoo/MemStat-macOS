//
//  MemoryInfo.swift
//  MemoryWidget
//
//  host_statistics64로 시스템 메모리 사용량을 읽어온다.
//  Activity Monitor의 "메모리 사용량"과 완전히 동일한 값은 아니고
//  (active + wired + compressed 기준) 근사치임 — Activity Monitor는
//  내부적으로 조금 더 복잡한 계산을 쓰기 때문. 실시간 위젯 용도로는
//  이 정도 근사치면 충분함.
//

import Foundation

struct MemoryInfo {
    let usedGB: Double
    let totalGB: Double
    let usedPercent: Double

    static let placeholder = MemoryInfo(usedGB: 8, totalGB: 16, usedPercent: 50)
}

func fetchMemoryInfo() -> MemoryInfo {
    var stats = vm_statistics64()
    var count = mach_msg_type_number_t(
        MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride
    )

    let result = withUnsafeMutablePointer(to: &stats) { statsPtr -> kern_return_t in
        statsPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { ptr in
            host_statistics64(mach_host_self(), HOST_VM_INFO64, ptr, &count)
        }
    }

    guard result == KERN_SUCCESS else {
        return .placeholder
    }

    let pageSize = UInt64(vm_kernel_page_size)
    let totalBytes = ProcessInfo.processInfo.physicalMemory

    // Activity Monitor의 "사용 중" 항목과 비슷하게: active + wired + compressed
    let activeBytes = UInt64(stats.active_count) * pageSize
    let wiredBytes = UInt64(stats.wire_count) * pageSize
    let compressedBytes = UInt64(stats.compressor_page_count) * pageSize
    let usedBytes = activeBytes + wiredBytes + compressedBytes

    let gb = 1_073_741_824.0
    let usedGB = Double(usedBytes) / gb
    let totalGB = Double(totalBytes) / gb
    let usedPercent = totalBytes > 0 ? (Double(usedBytes) / Double(totalBytes)) * 100 : 0

    return MemoryInfo(usedGB: usedGB, totalGB: totalGB, usedPercent: usedPercent)
}
