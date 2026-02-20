import Foundation

private let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return f
}()

private let logFileHandle: FileHandle? = {
    let home = FileManager.default.homeDirectoryForCurrentUser.path
    let logPath = "\(home)/Library/Logs/DockSwitch.log"
    if !FileManager.default.fileExists(atPath: logPath) {
        FileManager.default.createFile(atPath: logPath, contents: nil)
    }
    return FileHandle(forWritingAtPath: logPath)
}()

func log(_ message: String) {
    let timestamp = dateFormatter.string(from: Date())
    let line = "[\(timestamp)] \(message)"
    print(line)
    fflush(stdout)

    if let handle = logFileHandle, let data = (line + "\n").data(using: .utf8) {
        handle.seekToEndOfFile()
        handle.write(data)
    }
}
