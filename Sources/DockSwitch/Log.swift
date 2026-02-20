import Foundation

private let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return f
}()

func log(_ message: String) {
    let timestamp = dateFormatter.string(from: Date())
    let line = "[\(timestamp)] \(message)"
    print(line)
    fflush(stdout)
}
