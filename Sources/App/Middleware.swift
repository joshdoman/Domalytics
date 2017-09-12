//
//  Middleware.swift
//  PennMobile-Server
//
//  Created by Josh Doman on 6/17/17.
//
//

import HTTP

final class AuthMiddleware: Middleware {
    
    let authToken: String
    
    public init(config: Config) throws {
        // Set auth token to be auth token from JSON file in "secrets"
        guard let authToken = config["secrets", "authToken"]?.string else {
            throw ConfigError.missingFile("secrets/secrets")
        }
        self.authToken = authToken
    }
    
    func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        guard request.headers[.authorization] == authToken else {
            throw Abort(.badRequest, reason: "The auth token was incorrect or not included in the header.")
        }
        return try next.respond(to: request)
    }
}
