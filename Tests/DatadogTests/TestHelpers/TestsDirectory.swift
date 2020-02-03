import Foundation
@testable import Datadog

/// Creates `Directory` pointing to unique subfolder in `/var/folders/`.
/// Does not create the subfolder - it must be later created with `.create()`.
func obtainUniqueTemporaryDirectory() -> Directory {
    let subdirectoryName = "com.datadoghq.ios-sdk-tests-\(UUID().uuidString)"
    let osTemporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(subdirectoryName, isDirectory: true)
    print("💡 Obtained temporary directory URL: \(osTemporaryDirectoryURL)")
    return Directory(url: osTemporaryDirectoryURL)
}

/// `Directory` pointing to subfolder in `/var/folders/`.
/// The subfolder does not exist and can be created and deleted by calling `.create()` and `.delete()`.
let temporaryDirectory = obtainUniqueTemporaryDirectory()

/// Extends `Directory` with set of utilities for convenient work with files in tests.
/// Provides handy methods to create / delete files and directires.
extension Directory {
    /// Creates empty directory with given attributes .
    func create(attributes: [FileAttributeKey: Any]? = nil) {
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: attributes)
            let initialFilesCount = try files().count
            precondition(initialFilesCount == 0) // ensure it's empty
        } catch {
            fatalError("🔥 Failed to create `TestsDirectory`: \(error)")
        }
    }

    /// Deletes entire directory with its content.
    func delete() {
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                fatalError("🔥 Failed to delete `TestsDirectory`: \(error)")
            }
        }
    }

    /// Sets directory attributes.
    func set(attributes: [FileAttributeKey: Any]) {
        do {
            try FileManager.default.setAttributes(attributes, ofItemAtPath: url.path)
        } catch {
            fatalError("🔥 Failed to set attributes: \(attributes) for `TestsDirectory`: \(error)")
        }
    }
}
