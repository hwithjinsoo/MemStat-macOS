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
}

// MARK: - Timeline Provider

struct MemoryProvider: TimelineProvider {
    func placeholder(in context: Context) -> MemoryEntry {
        MemoryEntry(date: Date(), info: .placeholder, topProcessName: "예시앱", topProcessMemoryMB: 512)
    }

    func getSnapshot(in context: Context, completion: @escaping (MemoryEntry) -> Void) {
        let top = fetchSharedTopProcess()
        completion(MemoryEntry(date: Date(), info: fetchMemoryInfo(), topProcessName: top?.name, topProcessMemoryMB: top?.memoryMB))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MemoryEntry>) -> Void) {
        let now = Date()
        let top = fetchSharedTopProcess()
        let entry = MemoryEntry(date: now, info: fetchMemoryInfo(), topProcessName: top?.name, topProcessMemoryMB: top?.memoryMB)

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

            if let topName = entry.topProcessName {
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
    MemoryEntry(date: .now, info: .placeholder, topProcessName: "예시앱", topProcessMemoryMB: 512)
}
