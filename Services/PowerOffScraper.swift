import Foundation
import WebKit
import SwiftSoup

@MainActor
class PowerOffScraper: NSObject, WKNavigationDelegate {
    private var webView: WKWebView!
    private var continuation: CheckedContinuation<[ScheduleGroup], Error>?
    
    override init() {
        super.init()
        let config = WKWebViewConfiguration()
        self.webView = WKWebView(frame: .zero, configuration: config)
        self.webView.navigationDelegate = self
    }
    
    /// Loads the page and waits for specific content to render.
    func scrapeSchedule(url: String) async throws -> [ScheduleGroup] {
        guard let urlObj = URL(string: url) else { throw URLError(.badURL) }
        
        // Ensure no pending continuation exists
        if self.continuation != nil {
            self.complete(with: .failure(URLError(.cancelled)))
        }
        
        return try await withTaskCancellationHandler {
            return try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
                let request = URLRequest(url: urlObj)
                
                self.webView.load(request)
                
                // Set a timeout
                DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
                    // If still pending, timeout
                    if self?.continuation != nil {
                        self?.complete(with: .failure(URLError(.timedOut)))
                        self?.webView.stopLoading()
                    }
                }
            }
        } onCancel: {
            Task { @MainActor in
                self.complete(with: .failure(URLError(.cancelled)))
                self.webView.stopLoading()
            }
        }
    }
    
    // Old parseToGroups removed in favor of multi-day parsing
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Start polling for the content
        pollForContent(attempt: 0)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        complete(with: .failure(error))
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        complete(with: .failure(error))
    }
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        complete(with: .failure(URLError(.networkConnectionLost)))
        webView.reload()
    }
    
    private func pollForContent(attempt: Int) {
        // Max attempts: 20 * 0.5s = 10 seconds
        guard attempt < 20 else {
            complete(with: .failure(URLError(.timedOut)))
            return
        }
        
        // If continuation is nil, we are redundant. Stop.
        if continuation == nil { return }
        
        // Check for specific element.
        // There can be multiple .power-off__text containers (one for each day)
        // Let's get the outerHTML of all of them wrapped in a container string.
        let js = """
            (function() {
               var divs = document.querySelectorAll('div.power-off__text');
               if (divs.length === 0) return null;
               var result = "";
               for(var i=0; i<divs.length; i++) {
                 result += "<div>" + divs[i].innerHTML + "</div>";
               }
               return result;
            })()
        """
        
        webView.evaluateJavaScript(js) { [weak self] result, error in
            guard let self = self else { return }
            
            // Re-check continuation in async callback
            if self.continuation == nil { return }
            
            if let error = error {
                self.complete(with: .failure(error))
                return
            }
            
            if let html = result as? String {
                // Content found!
                do {
                    let doc = try SwiftSoup.parse(html)
                    // Each top level div corresponds to a day block found by JS
                    // Actually JS wrapped them in <div>...</div>.
                    // But wait, the date is inside the <p> text usually: "Графік погодинних відключень на 26.01.2026"
                    
                    // Strategy:
                    // 1. We have a string containing concatenated innerHTMLs of respective days.
                    // 2. We need to split them or process them to find date + schedule lines.
                    // 3. Let's parse the whole thing. `doc` will have multiple "chunks" of text.
                    // 4. Ideally we should have structured parsing.
                    
                    // Use Soup to select paragraphs. Iterate and look for Date header, then Groups.
                    let paragraphs = try doc.select("p")
                    let lines = paragraphs.array().compactMap { try? $0.text() }.filter { !$0.isEmpty }
                    
                    // Try to find the "Information as of" timestamp
                    // Pattern: "Інформація станом на 18:05 25.01.2026"
                    // Or just look for the first line usually?
                    // Let's search in all lines.
                    var timestamp: String?
                    let timestampPattern = "Інформація станом на (\\d{2}:\\d{2} \\d{2}\\.\\d{2}\\.\\d{4})"
                    let tsRegex = try? NSRegularExpression(pattern: timestampPattern, options: [])
                    
                    for line in lines {
                        if let match = tsRegex?.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count)) {
                            let nsString = line as NSString
                            timestamp = nsString.substring(with: match.range(at: 1))
                            break
                        }
                    }
                    
                    let groups = self.parseMultiDayGroups(lines: lines, timestamp: timestamp)
                    self.complete(with: .success(groups))
                } catch {
                    self.complete(with: .success([]))
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.pollForContent(attempt: attempt + 1)
                }
            }
        }
    }
    
    private func parseMultiDayGroups(lines: [String], timestamp: String?) -> [ScheduleGroup] {
        // We need to map [GroupID -> [Date: Text]]
        var tempMap: [String: [String: String]] = [:] // "1.1" -> ["26.01.2026": "00-04..."]
        
        var currentDate: String? = nil
        let datePattern = "на (\\d{2}\\.\\d{2}\\.\\d{4})"
        let groupPattern = "^Група\\s+(\\d\\.\\d)"
        
        for line in lines {
            // Check for date line
            if line.range(of: datePattern, options: .regularExpression) != nil {
                // Extract date
                let nsString = line as NSString
                let regex = try? NSRegularExpression(pattern: datePattern, options: [])
                if let match = regex?.firstMatch(in: line, options: [], range: NSRange(location: 0, length: nsString.length)) {
                    let dateRange = match.range(at: 1)
                    currentDate = nsString.substring(with: dateRange)
                }
                continue 
            }
            
            guard let date = currentDate else { continue }
            
            // Check for group line
            var groupId: String?
            
            if line.range(of: groupPattern, options: .regularExpression) != nil {
                let nsString = line as NSString
                let regex = try? NSRegularExpression(pattern: groupPattern, options: [])
                if let match = regex?.firstMatch(in: line, options: [], range: NSRange(location: 0, length: nsString.length)) {
                    groupId = nsString.substring(with: match.range(at: 1))
                }
            } else if let range = line.range(of: "\\b(\\d\\.\\d)\\b", options: .regularExpression) {
                groupId = String(line[range])
            }
            
            if let id = groupId {
                // We found a group line for the current date.
                // Store it.
                if tempMap[id] == nil {
                    tempMap[id] = [:]
                }
                tempMap[id]?[date] = line
            }
        }
        
        // Convert map to [ScheduleGroup]
        var groups: [ScheduleGroup] = []
        for (id, schedules) in tempMap {
            let group = ScheduleGroup(id: id, subGroupName: id, schedules: schedules, lastUpdateTimestamp: timestamp)
            groups.append(group)
        }
        
        return groups.sorted { $0.id < $1.id }
    }
    
    private func complete(with result: Result<[ScheduleGroup], Error>) {
        guard let continuation = self.continuation else { return }
        self.continuation = nil // Nullify BEFORE resuming
        
        switch result {
        case .success(let groups):
            continuation.resume(returning: groups)
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }
}
