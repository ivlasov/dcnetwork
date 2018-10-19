//
//  DCNetwork
//

import UIKit
import DCNetwork

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let request = HTTP.Request(url: URL(string: "http://google.com")!)
        request.shouldHandleCookies = true
        HTTP.Session.shared.send(request: request) { (response) in
            print(response)
        }
    }
    
}
