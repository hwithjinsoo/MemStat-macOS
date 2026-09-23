//
//  MemoryInfo.swift
//  MemoryWidget
//
//  host_statistics64로 시스템 메모리 사용량을 읽어온다.
//  Activity Monitor의 "메모리 사용량"과 동일한 방식으로 계산:
//  (internal_page_count - purgeable_count) + wire_count + compressor_page_count
//
//  internal_page_count - purgeable_count = "App Memory" (앱이 실제로 물고 있는
//  익명 페이지에서, 커널이 언제든 즉시 회수 가능한 purgeable 페이지는 제외).
//  단순히 active_count를 쓰면 재사용 가능한 파일 캐시(external page)까지
//  "사용 중"으로 잡혀서 Activity Monitor보다 높게 나오는 문제가 있었음.
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

    // Activity Monitor 방식: App Memory(internal - purgeable) + Wired + Compressed
    let internalBytes = UInt64(stats.internal_page_count) * pageSize
    let purgeableBytes = UInt64(stats.purgeable_count) * pageSize
    let appBytes = internalBytes > purgeableBytes ? internalBytes - purgeableBytes : 0

    let wiredBytes = UInt64(stats.wire_count) * pageSize
    let compressedBytes = UInt64(stats.compressor_page_count) * pageSize
    let usedBytes = appBytes + wiredBytes + compressedBytes

    let gb = 1_073_741_824.0
    let usedGB = Double(usedBytes) / gb
    let totalGB = Double(totalBytes) / gb
    let usedPercent = totalBytes > 0 ? (Double(usedBytes) / Double(totalBytes)) * 100 : 0

    return MemoryInfo(usedGB: usedGB, totalGB: totalGB, usedPercent: usedPercent)
}
