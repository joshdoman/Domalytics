import Vapor

extension Droplet {
    func setupRoutes() throws {

        get("info") { req in
            return req.description
        }
        
        // TODO: Send notification to all users (currently retrieves all tokens and returns first)
        post("notification") { (req) -> ResponseRepresentable in
            let tokens = try User.makeQuery().all().filter({ (user) -> Bool in
                return user.token != nil
            }) .map({ (user) -> String in
                return user.token ?? "No token available"
            })
            return tokens.first ?? "No token available"
        }
        
        // "Batch" end point so that apps can send multiple requests in single network call
        post("batch") { req in
            return try req.batch().respond(through: self.router)
        }
                
        let users = UserController()
        resource("users", users)
        
        let logs = LogController()
        resource("logs", logs)
        
        // Return all logs for a give user
        get("logs", User.parameter) { req in
            let user = try req.parameters.next(User.self)
            let logs = try user.logs.all()
            return try JSON(node: logs)
        }
        
        // Temporary end point for testing purposes
        post("sendNotification") { req in
            APNSCenter.shared.sendTestPayload()
            return "success"
        }

    }
}
