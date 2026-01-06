//
//  FileWatcherService.swift
//  scode
//
//  File system watcher for configuration sync
//

import Foundation
import Combine

/// Service for watching configuration file changes
@MainActor
class FileWatcherService: ObservableObject {
    static let shared = FileWatcherService()

    @Published var hasExternalChanges = false
    @Published var changedFiles: Set<URL> = []

    private var watchedPaths: [URL: DispatchSourceFileSystemObject] = [:]
    private var lastModificationDates: [URL: Date] = [:]

    /// Files that are being written by scode itself (should be ignored)
    private var internalWriteFiles: Set<URL> = []

    // MARK: - Watch Management

    func startWatching(_ url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else { return }

        // Record initial modification date
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let modDate = attrs[.modificationDate] as? Date {
            lastModificationDates[url] = modDate
        }

        let fileDescriptor = open(url.path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .delete, .rename],
            queue: .main
        )

        source.setEventHandler { [weak self] in
            Task { @MainActor in
                self?.handleFileChange(at: url)
            }
        }

        source.setCancelHandler {
            close(fileDescriptor)
        }

        source.resume()
        watchedPaths[url] = source
    }

    func stopWatching(_ url: URL) {
        watchedPaths[url]?.cancel()
        watchedPaths.removeValue(forKey: url)
        lastModificationDates.removeValue(forKey: url)
    }

    func stopAll() {
        for (_, source) in watchedPaths {
            source.cancel()
        }
        watchedPaths.removeAll()
        lastModificationDates.removeAll()
    }

    // MARK: - Internal Write Tracking

    /// Mark a file as being written internally (by scode itself)
    /// Call this BEFORE writing to a file to prevent false external change detection
    func markAsInternalWrite(_ url: URL) {
        internalWriteFiles.insert(url)
    }

    /// Mark multiple files as being written internally
    func markAsInternalWrite(_ urls: [URL]) {
        for url in urls {
            internalWriteFiles.insert(url)
        }
    }

    // MARK: - Change Detection

    private func handleFileChange(at url: URL) {
        // Check if this is an internal write (by scode itself)
        if internalWriteFiles.contains(url) {
            internalWriteFiles.remove(url)
            // Update the modification date but don't trigger external change
            if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
               let newModDate = attrs[.modificationDate] as? Date {
                lastModificationDates[url] = newModDate
            }
            return
        }

        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let newModDate = attrs[.modificationDate] as? Date else { return }

        if let lastDate = lastModificationDates[url], newModDate > lastDate {
            changedFiles.insert(url)
            hasExternalChanges = true
        }

        lastModificationDates[url] = newModDate
    }

    func acknowledgeChanges() {
        changedFiles.removeAll()
        hasExternalChanges = false
    }

    func acknowledgeChange(for url: URL) {
        changedFiles.remove(url)
        if changedFiles.isEmpty {
            hasExternalChanges = false
        }
    }
}
