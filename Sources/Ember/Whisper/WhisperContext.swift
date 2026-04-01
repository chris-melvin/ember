import Foundation

enum WhisperError: Error {
    case couldNotInitializeContext
    case transcriptionFailed
    case noModelAvailable
}

actor WhisperContext {
    private var context: OpaquePointer

    init(context: OpaquePointer) {
        self.context = context
    }

    deinit {
        whisper_free(context)
    }

    func fullTranscribe(samples: [Float], onProgress: (@Sendable (Int) -> Void)? = nil) throws {
        let maxThreads = max(1, min(8, ProcessInfo.processInfo.processorCount - 2))
        var params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)

        "en".withCString { en in
            params.print_realtime = false
            params.print_progress = false
            params.print_timestamps = true
            params.print_special = false
            params.translate = false
            params.language = en
            params.n_threads = Int32(maxThreads)
            params.offset_ms = 0
            params.no_context = true
            params.single_segment = false
        }

        whisper_reset_timings(context)

        let result = samples.withUnsafeBufferPointer { samplesPtr in
            whisper_full(context, params, samplesPtr.baseAddress, Int32(samplesPtr.count))
        }

        if result != 0 {
            throw WhisperError.transcriptionFailed
        }

        whisper_print_timings(context)
    }

    struct Segment {
        let startMs: Int64
        let endMs: Int64
        let text: String
    }

    func getSegments() -> [Segment] {
        var segments: [Segment] = []
        let n = whisper_full_n_segments(context)
        for i in 0..<n {
            let text = String(cString: whisper_full_get_segment_text(context, i))
            let t0 = whisper_full_get_segment_t0(context, i)
            let t1 = whisper_full_get_segment_t1(context, i)
            segments.append(Segment(startMs: t0 * 10, endMs: t1 * 10, text: text))
        }
        return segments
    }

    func getFullTranscription() -> String {
        var text = ""
        let n = whisper_full_n_segments(context)
        for i in 0..<n {
            text += String(cString: whisper_full_get_segment_text(context, i))
        }
        return text
    }

    static func createContext(path: String) throws -> WhisperContext {
        var params = whisper_context_default_params()
        params.flash_attn = true
        guard let ctx = whisper_init_from_file_with_params(path, params) else {
            throw WhisperError.couldNotInitializeContext
        }
        return WhisperContext(context: ctx)
    }
}
