import Foundation
import WebKit
import Combine

enum SearchStep {
    case settlement
    case street
    case house
}

@MainActor
class ScheduleSearchService: NSObject, WKNavigationDelegate, ObservableObject {
    private var webView: WKWebView!
    private let urlString = "https://poweron.loe.lviv.ua/shedule-off"
    
    @Published var isLoading = false
    @Published var error: Error?
    
    // Continuations for async operations
    private var searchContinuation: CheckedContinuation<[String], Error>?
    private var selectionContinuation: CheckedContinuation<Void, Error>?
    private var groupContinuation: CheckedContinuation<String, Error>?
    
    override init() {
        super.init()
        let config = WKWebViewConfiguration()
        // Allow JS
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs
        
        self.webView = WKWebView(frame: .zero, configuration: config)
        self.webView.navigationDelegate = self
    }
    
    func loadPage() async throws {
        isLoading = true
        return try await withCheckedThrowingContinuation { continuation in
             // We'll treat the "didFinish" as the success of loading, 
             // but we really need to wait for the React app to mount.
             // For now, let's just wait for navigation to finish.
             self.selectionContinuation = continuation
            
             if let url = URL(string: urlString) {
                 let request = URLRequest(url: url)
                 webView.load(request)
             } else {
                 continuation.resume(throwing: URLError(.badURL))
                 self.selectionContinuation = nil
             }
        }
    }
    
    // Generic search input handler
    // index: 0 for Settlement, 1 for Street, 2 for House
    func search(query: String, stepIndex: Int) async throws -> [String] {
        // Evaluate JS to type into the input and get options
        return try await withCheckedThrowingContinuation { continuation in
            self.searchContinuation = continuation
            
            // This JS needs to:
            // 1. Find the inputs (React Select inputs).
            // 2. Focus the correct one.
            // 3. Simulate typing (React needs 'input' event, maybe 'change').
            // 4. Wait for options to appear.
            // 5. Scrape options.
            
            // Note: React Select is tricky. Usually setting value isn't enough. 
            // We often need to dispatch events.
            
            // let js = ... (removed unused variable)
            
            // Revised strategy:
            // 1. Send input.
            // 2. Poll for options.
            
            var interactionScript = ""
            
            if query.isEmpty {
                 // Open menu by clicking. React Select needs robust events.
                 interactionScript = """
                 var inputs = document.querySelectorAll('input[type="text"]');
                 var input = inputs[\(stepIndex)];
                 if (input) {
                     input.focus();
                     // Dispatch mousedown on the input
                     var opts = { bubbles: true, cancelable: true, view: window, buttons: 1 };
                     input.dispatchEvent(new MouseEvent('mousedown', opts));
                     input.dispatchEvent(new MouseEvent('mouseup', opts));
                     input.click();
                     
                     // Also try dispatching on the parent 'control' div if accessible
                     // React Select input is usually inside a container.
                     // We keep going up until we find a div that might be the control.
                     var parent = input.parentElement; 
                     while (parent && parent.tagName !== 'DIV') {
                        parent = parent.parentElement;
                     }
                     if (parent) {
                        parent.dispatchEvent(new MouseEvent('mousedown', opts));
                        parent.dispatchEvent(new MouseEvent('mouseup', opts));
                        parent.click();
                     }
                 }
                 """
            } else {
                interactionScript = """
                var inputs = document.querySelectorAll('input[type="text"]');
                var input = inputs[\(stepIndex)];
                if (input) {
                    input.focus();
                    var nativeInputValueSetter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, "value").set;
                    nativeInputValueSetter.call(input, "\(query)");
                    input.dispatchEvent(new Event('input', { bubbles: true}));
                }
                """
            }
            
            webView.evaluateJavaScript(interactionScript) { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    self.searchContinuation = nil
                    return
                }
                
                // Start polling for options
                self.pollForOptions(attempt: 0)
            }
        }
    }
    
    private func pollForOptions(attempt: Int) {
        if attempt > 10 {
            self.searchContinuation?.resume(returning: [])
            self.searchContinuation = nil
            return
        }
        
        // JS to get options
        let getOptionsScript = """
            (function() {
                var options = document.querySelectorAll('[role="option"]');
                var results = [];
                for (var i = 0; i < options.length; i++) {
                    results.push(options[i].innerText);
                }
                return results;
            })()
        """
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.webView.evaluateJavaScript(getOptionsScript) { result, error in
                if let lines = result as? [String], !lines.isEmpty {
                    self.searchContinuation?.resume(returning: lines)
                    self.searchContinuation = nil
                } else {
                    self.pollForOptions(attempt: attempt + 1)
                }
            }
        }
    }
    
    func selectOption(name: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.selectionContinuation = continuation
            
            // JS to click the option with specific text
            // Need to escape quotes in name just in case
            let escapedName = name.replacingOccurrences(of: "'", with: "\\'")
            
            let script = """
            (function() {
                var options = document.querySelectorAll('[role="option"]');
                for (var i = 0; i < options.length; i++) {
                    if (options[i].innerText.includes('\(escapedName)')) {
                        options[i].click();
                        return true;
                    }
                }
                return false;
            })()
            """
            
            webView.evaluateJavaScript(script) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let success = result as? Bool, success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: NSError(domain: "App", code: 404, userInfo: [NSLocalizedDescriptionKey: "Option not found"]))
                }
                self.selectionContinuation = nil
            }
        }
    }
    
    func getScheduleGroup() async throws -> String {
         return try await withCheckedThrowingContinuation { continuation in
             self.groupContinuation = continuation
             self.pollForGroup(attempt: 0)
         }
    }
    
    private func pollForGroup(attempt: Int) {
        if attempt > 10 {
            self.groupContinuation?.resume(throwing: URLError(.timedOut))
            self.groupContinuation = nil
            return
        }
        
        // Looking for the Group text. Use the same logic as the Scraper or simpler if it's plainly visible.
        // Usually "Група 4.1" or similar.
        // It's in .power-off__group or similar class?
        // Let's rely on finding text "Група" visible on screen?
        // Or inspect the specific DOM element.
        // From previous analysis: "div.power-off__text" contains the schedule. 
        // But the group ID itself is usually in a header or we can extract it from the result.
        // Actually, let's just grab the whole text of the result container and regex for "Група X.X".
        
        let script = """
        (function() {
            var container = document.querySelector('div.power-off');
            return container ? container.innerText : null;
        })()
        """
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.webView.evaluateJavaScript(script) { result, error in
                if let text = result as? String {
                    // Try to regex for group
                    // Pattern: "Група 4.2"
                    if let range = text.range(of: "Група\\s+(\\d\\.\\d)", options: .regularExpression) {
                        let groupStr = String(text[range])
                        // Extract just the number
                        let number = groupStr.components(separatedBy: " ").last ?? ""
                        self.groupContinuation?.resume(returning: number)
                        self.groupContinuation = nil
                        return
                    }
                }
                
                self.pollForGroup(attempt: attempt + 1)
            }
        }
    }
    
    // WKNavigationDelegate
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Only resume if we are waiting for load
        if isLoading {
            isLoading = false
            selectionContinuation?.resume()
            selectionContinuation = nil
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if isLoading {
            isLoading = false
            selectionContinuation?.resume(throwing: error)
            selectionContinuation = nil
        }
    }
}
