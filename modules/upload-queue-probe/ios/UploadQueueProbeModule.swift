import ExpoModulesCore

public final class UploadQueueProbeModule: Module {
  public func definition() -> ModuleDefinition {
    Name("UploadQueueProbe")

    AsyncFunction("post") { (urlString: String, promise: Promise) in
      guard let url = URL(string: urlString) else {
        promise.reject("ERR_INVALID_URL", "Invalid URL: \(urlString)")
        return
      }
      UploadQueueProbeClient.shared.post(to: url) { result in
        promise.resolve(result)
      }
    }
  }
}

/// A URLSession client that owns its delegate queue, the same way Alamofire's `Session` does.
final class UploadQueueProbeClient: NSObject, URLSessionDataDelegate, @unchecked Sendable {
  static let shared = UploadQueueProbeClient()

  private let rootQueue = DispatchQueue(label: "upload-queue-probe.rootQueue")
  private var uploadProgressCallbacks = 0
  private var completion: (([String: Any]) -> Void)?

  // Created on first use, after the dev client has installed the network inspector.
  private lazy var session: URLSession = {
    let delegateQueue = OperationQueue()
    delegateQueue.maxConcurrentOperationCount = 1
    delegateQueue.underlyingQueue = rootQueue
    return URLSession(configuration: .default, delegate: self, delegateQueue: delegateQueue)
  }()

  func post(to url: URL, completion: @escaping ([String: Any]) -> Void) {
    rootQueue.async {
      self.uploadProgressCallbacks = 0
      self.completion = completion
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.httpBody = Data("probe=1".utf8)
      self.session.dataTask(with: request).resume()
    }
  }

  func urlSession(
    _ session: URLSession,
    task: URLSessionTask,
    didSendBodyData bytesSent: Int64,
    totalBytesSent: Int64,
    totalBytesExpectedToSend: Int64
  ) {
    // URLSession calls delegate methods on `delegateQueue`. Alamofire's `Session.request(for:)` makes this same check.
    dispatchPrecondition(condition: .onQueue(rootQueue))
    uploadProgressCallbacks += 1
  }

  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    dispatchPrecondition(condition: .onQueue(rootQueue))
    let statusCode = (task.response as? HTTPURLResponse)?.statusCode ?? -1
    completion?([
      "statusCode": statusCode,
      "uploadProgressCallbacks": uploadProgressCallbacks,
      "error": error?.localizedDescription ?? ""
    ])
    completion = nil
  }
}
