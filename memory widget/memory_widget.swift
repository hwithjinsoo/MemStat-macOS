//
//  MemoryWidget.swift
//  memory widgetExtension 타겟 — 기존 memory_widget.swift 파일을
//  이 내용으로 통째로 교체할 것 (memory_widgetBundle.swift, MemoryInfo.swift는 그대로 둠).
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct MemoryEntry: TimelineEntry {
    let date: Date
    let info: MemoryInfo
    let topProcessName: String?
    let topProcessMemoryMB: Double?
    let topProcessUpdatedAt: Date?

    /// 헬퍼가 꺼졌거나(서명 만료로 실행 실패 등) 멈춰서 톱 프로세스 값이 오래된 상태
    var isTopProcessStale: Bool {
        guard let updatedAt = topProcessUpdatedAt else { return true }
        return date.timeIntervalSince(updatedAt) > sharedTopProcessStaleInterval
    }
}

// MARK: - Timeline Provider

struct MemoryProvider: TimelineProvider {
    func placeholder(in context: Context) -> MemoryEntry {
        MemoryEntry(date: Date(), info: .placeholder, topProcessName: "예시앱", topProcessMemoryMB: 512, topProcessUpdatedAt: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (MemoryEntry) -> Void) {
        completion(makeEntry(at: Date()))
    }

    private func makeEntry(at date: Date) -> MemoryEntry {
        let top = fetchSharedTopProcess()
        return MemoryEntry(date: date, info: fetchMemoryInfo(), topProcessName: top?.name,
                           topProcessMemoryMB: top?.memoryMB, topProcessUpdatedAt: top?.updatedAt)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MemoryEntry>) -> Void) {
        let now = Date()
        let entry = makeEntry(at: now)

        // 30초마다 갱신 (헬퍼는 5초마다 값 갱신, 위젯은 30초마다 그 값을 읽어감)
        let nextRefresh = Calendar.current.date(byAdding: .second, value: 30, to: now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
        completion(timeline)
    }
}

// MARK: - View

struct MemoryWidgetEntryView: View {
    var entry: MemoryProvider.Entry

    private var barColor: Color {
        switch entry.info.usedPercent {
        case ..<70: return .green
        case 70..<85: return .orange
        default: return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "memorychip")
                    .foregroundStyle(.secondary)
                Text("메모리")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                // 위젯이 마지막으로 값을 읽은 시각 (WidgetKit이 갱신을 미루면 여기서 티가 남)
                Text(entry.date, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Text(String(format: "%.1f GB", entry.info.usedGB))
                .font(.title2.bold())

            Text(String(format: "/ %.0f GB 중 사용", entry.info.totalGB))
                .font(.caption2)
                .foregroundStyle(.secondary)

            ProgressView(value: min(entry.info.usedPercent, 100), total: 100)
                .tint(barColor)

            Text(String(format: "%.0f%%", entry.info.usedPercent))
                .font(.caption2.bold())
                .foregroundStyle(barColor)

            if entry.topProcessName != nil && entry.isTopProcessStale {
                Divider()
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text("헬퍼 응답 없음")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            } else if let topName = entry.topProcessName {
                Divider()
                HStack(spacing: 4) {
                    Image(systemName: "arrowtriangle.up.fill")
                        .font(.caption2)
                        .foregroundStyle(.red)
                    Text(topName)
                        .font(.caption2)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .layoutPriority(0)
                    Spacer(minLength: 2)
                    if let mb = entry.topProcessMemoryMB {
                        Text(String(format: "%.0f MB", mb))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .layoutPriority(1)
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Widget

struct MemoryWidget: Widget {
    let kind: String = "MemoryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MemoryProvider()) { entry in
            MemoryWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("메모리 사용량")
        .description("맥 메모리 사용량과 가장 많이 사용 중인 프로세스를 보여줍니다.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    MemoryWidget()
} timeline: {
    MemoryEntry(date: .now, info: .placeholder, topProcessName: "예시앱", topProcessMemoryMB: 512, topProcessUpdatedAt: .now)
}
