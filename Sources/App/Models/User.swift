//
//  User.swift
//  PennMobile-Server
//
//  Created by Josh Doman on 6/10/17.
//
//

import PostgreSQLProvider

final class User: Model {
    
    enum UserParameter: String {
        case device = "device_id"
        case token = "token"
        case email = "email"
    }
    
    let storage = Storage()
    
    static var idKey: String = "user_id"
    static var foreignIdKey: String = "user_id"

    var deviceID: String //Device token (comes from app)
    var token: String? //for notifications
    var email: String?
    
    /// Creates a new User
    init(deviceID: String, token: String? = nil, email: String? = nil) {
        self.deviceID = deviceID
        self.token = token
        self.email = email
    }
        
    /// Initializes the User from the
    /// database row
    init(row: Row) throws {
        email = try row.get(UserParameter.email.rawValue)
        deviceID = try row.get(UserParameter.device.rawValue)
        token = try row.get(UserParameter.token.rawValue)
    }
    
    func dbAlready(has identifier: UserParameter) throws -> Bool {
        let query = try makeQuery()
        let val = identifier == .device ? deviceID : token
        return try query.filter(identifier.rawValue, val).first() != nil
    }
}

extension User: RowRepresentable {
    // Serializes the User to the database
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(UserParameter.device.rawValue, deviceID)
        try row.set(UserParameter.email.rawValue, email)
        try row.set(UserParameter.token.rawValue, token)
        return row
    }
}

// MARK: Fluent Preparation

extension User: Preparation {
    /// Prepares a table/collection in the database
    /// for storing the User
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string(UserParameter.device.rawValue)
            builder.string(UserParameter.email.rawValue, optional: true)
            builder.string(UserParameter.token.rawValue, optional: true)
        }
    }
    
    /// Undoes what was done in `prepare`
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

// MARK: JSON

// How the model converts from / to JSON.
// For example when:
//     - Creating a new User (User /users)
//     - Fetching a user (GET /ust, GET /users/:id)
//
extension User: JSONConvertible {
    convenience init(json: JSON) throws {
        try self.init(
            deviceID: json.get(UserParameter.device.rawValue),
            token: json.get(UserParameter.token.rawValue),
            email: json.get(UserParameter.email.rawValue)
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(UserParameter.device.rawValue, deviceID)
        try json.set(UserParameter.email.rawValue, email)
        try json.set(UserParameter.token.rawValue, token)
        return json
    }
}

// MARK: HTTP

// This allows User models to be returned
// directly in route closures
extension User: ResponseRepresentable { }

// MARK: Update

// This allows the User model to be updated
// dynamically by the request.
extension User: Updateable {
    // Updateable keys are called when `user.update(for: req)` is called.
    // Add as many updateable keys as you like here.
    static var updateableKeys: [UpdateableKey<User>] {
        get {
            return [
                // If the request contains a String at key "email"
                // the setter callback will be called.
                UpdateableKey(UserParameter.email.rawValue, String.self) { user, email in
                    user.email = email
                },
                
                UpdateableKey(UserParameter.token.rawValue, String.self) { user, token in
                    user.token = token
                }
            ]
        }
    }
}

extension User: Timestampable { }

extension User: Parameterizable {
    
    static var uniqueSlug: String {
        return "deviceId"
    }
    
    static func make(for parameter: String) throws -> User {
        if let user = try User.makeQuery().filter(UserParameter.device.rawValue, parameter).first() {
            return user
        }
        throw Abort.notFound
    }
}

extension User {
    var logs: Children<User, Log> {
        return children()
    }
}

extension User {
    static func findForDeviceId(_ deviceId: String) throws -> User? {
        return try User.makeQuery().filter(User.UserParameter.device.rawValue, deviceId).first()
    }
}

