import VaporAPNS
import Foundation
import Configs
import JSON

class APNSCenter: NSObject {
    
    static let shared = APNSCenter()
    
    var vaporAPNS: VaporAPNS!
    
    func config(with config: Config) throws {
        guard let bundleId = config["apns", "bundleId"]?.string, let teamId = config["apns", "teamId"]?.string, let keyId = config["apns", "keyId"]?.string else {
            throw Abort(.notFound, reason: "Could not find apns.json file in Config")
        }
        
        //Uncomment once download Push Notification key
        
        //let options = try Options(topic: bundleId, teamId: teamId, keyId: keyId, keyPath: "Config/secrets/[Push Notification Key Here]")
        //self.vaporAPNS = try VaporAPNS(options: options)
    }
    
    func sendTestPayload() {
        let payload = Payload(title: "Title", body: "Your push message comes here")
        payload.sound = "default"
        let pushMessage = ApplePushMessage(priority: .immediately, payload: payload, sandbox: true)
        let result = vaporAPNS.send(pushMessage, to: "d556f9721288133a8606d3450039bd0e1e9f3bc848ec96ffd6f5a932aef31fe2")
        print(result)
    }
}


final class NotificationPayload: Payload, JSONInitializable {
    
    required convenience init(json: JSON) throws {
        self.init()
        
        self.title = try json.get("title")
        self.body = try json.get("message")
    }
}
