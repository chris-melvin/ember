import SwiftUI
import Combine

struct TranscriptSegment: Identifiable {
    let id: Int
    let startTime: TimeInterval
    var text: String
    let timestampString: String

    static func parse(_ content: String) -> [TranscriptSegment] {
        var segments: [TranscriptSegment] = []
        let lines = content.components(separatedBy: "\n")
        var currentId = 0

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            // Match [MM:SS] or [HH:MM:SS] prefix
            if let match = trimmed.range(of: #"^\[(\d{1,2}:\d{2}(?::\d{2})?)\]"#, options: .regularExpression) {
                let tsString = String(trimmed[match]).dropFirst().dropLast()
                let time = parseTimestamp(String(tsString))
                let text = String(trimmed[match.upperBound...]).trimmingCharacters(in: .whitespaces)

                segments.append(TranscriptSegment(
                    id: currentId,
                    startTime: time,
                    text: text,
                    timestampString: String(tsString)
                ))
                currentId += 1
            }
        }

        return segments
    }

    static func parseTimestamp(_ ts: String) -> TimeInterval {
        let parts = ts.split(separator: ":").compactMap { Int($0) }
        if parts.count == 3 {
            return TimeInterval(parts[0] * 3600 + parts[1] * 60 + parts[2])
        } else if parts.count == 2 {
            return TimeInterval(parts[0] * 60 + parts[1])
        }
        return 0
    }

    static func serialize(_ segments: [TranscriptSegment]) -> String {
        segments.map { "[\($0.timestampString)] \($0.text)\n" }.joined(separator: "\n")
    }
}

struct TranscriptView: View {
    @Binding var text: String
    @ObservedObject var playbackState: PlaybackState
    @State private var segments: [TranscriptSegment] = []
    @State private var editingSegmentId: Int?
    @State private var saveTask: DispatchWorkItem?

    var body: some View {
        ScrollViewReader { proxy in
            VStack(alignment: .leading, spacing: 0) {
                Text("Transcript")
                    .font(.headline)
                    .padding(.bottom, 8)

                ForEach($segments) { $segment in
                    TranscriptSegmentRow(
                        segment: $segment,
                        isActive: isActiveSegment(segment),
                        onTimestampTap: {
                            playbackState.seek(to: segment.startTime)
                            if !playbackState.isPlaying {
                                playbackState.togglePlayPause()
                            }
                        },
                        onTextChange: {
                            debouncedSave()
                        }
                    )
                    .id(segment.id)
                }
            }
            .onChange(of: playbackState.currentTime) { _, newTime in
                if let activeId = activeSegmentId(at: newTime) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(activeId, anchor: .center)
                    }
                }
            }
        }
        .onAppear {
            segments = TranscriptSegment.parse(text)
        }
        .onChange(of: text) { _, newText in
            // Only re-parse if text changed externally (not from our own edits)
            if editingSegmentId == nil {
                segments = TranscriptSegment.parse(newText)
            }
        }
    }

    private func isActiveSegment(_ segment: TranscriptSegment) -> Bool {
        guard playbackState.isPlaying || playbackState.currentTime > 0 else { return false }
        let currentTime = playbackState.currentTime

        // Find the next segment's start time
        if let index = segments.firstIndex(where: { $0.id == segment.id }) {
            let nextStart = index + 1 < segments.count ? segments[index + 1].startTime : .infinity
            return currentTime >= segment.startTime && currentTime < nextStart
        }
        return false
    }

    private func activeSegmentId(at time: TimeInterval) -> Int? {
        var activeId: Int?
        for (i, segment) in segments.enumerated() {
            if time >= segment.startTime {
                activeId = segment.id
            }
            if i + 1 < segments.count && time < segments[i + 1].startTime {
                break
            }
        }
        return activeId
    }

    private func debouncedSave() {
        saveTask?.cancel()
        let task = DispatchWorkItem { [segments] in
            text = TranscriptSegment.serialize(segments)
        }
        saveTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: task)
    }
}

struct TranscriptSegmentRow: View {
    @Binding var segment: TranscriptSegment
    let isActive: Bool
    let onTimestampTap: () -> Void
    let onTextChange: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Clickable timestamp
            Button(action: onTimestampTap) {
                Text("[\(segment.timestampString)]")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(isActive ? .primary : .secondary)
            }
            .buttonStyle(.plain)
            .frame(minWidth: 55, alignment: .leading)

            // Editable text
            TextField("", text: $segment.text, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.body)
                .focused($isFocused)
                .onChange(of: segment.text) { _, _ in
                    onTextChange()
                }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isActive ? Color.accentColor.opacity(0.1) : Color.clear)
        )
    }
}
