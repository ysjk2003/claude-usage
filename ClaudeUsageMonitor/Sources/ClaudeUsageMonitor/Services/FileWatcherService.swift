import Foundation

final class FileWatcherService {
    private var fileDescriptor: Int32 = -1
    private var dispatchSource: DispatchSourceFileSystemObject?
    private let filePath: String
    private let onChange: () -> Void

    init(filePath: String, onChange: @escaping () -> Void) {
        self.filePath = filePath
        self.onChange = onChange
    }

    deinit {
        stop()
    }

    func start() {
        startWatching()
    }

    func stop() {
        dispatchSource?.cancel()
        dispatchSource = nil
        if fileDescriptor >= 0 {
            close(fileDescriptor)
            fileDescriptor = -1
        }
    }

    private func startWatching() {
        stop()

        fileDescriptor = open(filePath, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            // File doesn't exist yet, poll for it
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.startWatching()
            }
            return
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .rename, .delete],
            queue: .global()
        )

        source.setEventHandler { [weak self] in
            guard let self else { return }
            let flags = source.data
            if flags.contains(.rename) || flags.contains(.delete) {
                // File was atomically replaced — restart watcher
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.startWatching()
                    self?.onChange()
                }
            } else {
                self.onChange()
            }
        }

        source.setCancelHandler { [weak self] in
            guard let self else { return }
            if self.fileDescriptor >= 0 {
                close(self.fileDescriptor)
                self.fileDescriptor = -1
            }
        }

        dispatchSource = source
        source.resume()
    }
}
