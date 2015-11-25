//
//  IPMessagingService.swift
//  IPMQuickstartTux
//
//  Created by Brent Schooley on 11/19/15.
//  Copyright © 2015 Twilio. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class IPMessagingService {
    var client: TwilioIPMessagingClient? = nil
    var identity: String? = nil
    var token: String? = nil
    
    static let sharedService = IPMessagingService()
    
    func initializeClient(device: String, completionHandler: () -> Void) {
        Alamofire.request(.GET, "https://brent.ngrok.io/token", parameters: ["device": "iphone"])
            .responseJSON { response in
                guard let tokenResult = response.result.value else {
                    print("Error: did not receive data")
                    return
                }
                
                var json = JSON(tokenResult)
                self.identity = json["identity"].stringValue
                self.token = json["token"].stringValue
                
                self.client = TwilioIPMessagingClient.ipMessagingClientWithToken(self.token, delegate: nil)
                completionHandler()
        }
    }
}