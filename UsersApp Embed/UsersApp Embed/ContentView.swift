import SwiftUI
import WebKit
import UIKit

struct ContentView: View {
    @State private var firstInput: String = ""
    @State private var secondInput: String = ""
    @State private var isWebViewPresented = false
    @State private var finalURL: String = ""

    var isIP: Bool {
        let ipRegex = #"^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$"#
        return firstInput.range(of: ipRegex, options: .regularExpression) != nil
    }

    var validPort: Bool {
        guard let port = Int(secondInput), (1...65535).contains(port) else { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Enter IP or Domain")
                    .font(.title)
                
                TextField("Enter IP or Domain", text: $firstInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onChange(of: firstInput) { _ in
                        secondInput = "" // Reset port when switching between IP and domain
                    }

                if isIP {
                    TextField("Enter Port", text: $secondInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .padding()
                }

                Button("Go") {
                    openWebView()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isIP && !validPort)

                Spacer()
            }
            .padding()
            .fullScreenCover(isPresented: $isWebViewPresented) {
                WebView(urlString: $finalURL) // ✅ Pass finalURL as a Binding
            }
        }
    }
    
    func openWebView() {
        if isIP, validPort {
            finalURL = "http://\(firstInput):\(secondInput)"
        } else {
            finalURL = firstInput.lowercased().hasPrefix("http") ? firstInput.lowercased() : "https://\(firstInput.lowercased())"
        }
        
        print("🔹 Final URL before opening WebView: \(finalURL)")
        
        guard !finalURL.isEmpty, let validURL = URL(string: finalURL) else {
            print("❌ Error: Generated an empty or invalid URL -> \(finalURL)")
            return
        }
        
        print("✅ URL is valid: \(validURL.absoluteString)")
        
        // ⏳ Delay presenting WebView to ensure finalURL updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.isWebViewPresented = true
        }
    }
}

// MARK: - WebView
struct WebView: View {
    @Binding var urlString: String // ✅ Uses Binding to always get the latest URL
    
    var body: some View {
        WebViewWrapper(urlString: urlString)
            .edgesIgnoringSafeArea(.all)
    }
}

struct WebViewWrapper: UIViewRepresentable {
    let urlString: String

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebViewWrapper

        init(parent: WebViewWrapper) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("🚀 WebView started loading: \(webView.url?.absoluteString ?? "Unknown URL")")
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ WebView finished loading: \(webView.url?.absoluteString ?? "Unknown URL")")
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ WebView failed: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("❌ WebView failed to start loading: \(error.localizedDescription)")
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()

        // Allow insecure certificates in development
        let preference = WKPreferences()
        preference.javaScriptEnabled = true
        config.preferences = preference

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator

        return webView
    }


    func updateUIView(_ uiView: WKWebView, context: Context) {
        print("🔍 WebView received URL: \(urlString.isEmpty ? "EMPTY STRING" : urlString)")

        guard !urlString.isEmpty, let url = URL(string: urlString) else {
            print("❌ Invalid URL detected: \(urlString)")
            return
        }

        print("🌍 WebView loading URL: \(url.absoluteString)")
        uiView.load(URLRequest(url: url))
    }
}



class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Disable SSL validation for local development
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 30
        sessionConfig.timeoutIntervalForResource = 30

        return true
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
