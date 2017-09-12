//
//  Log.swift
//  PennMobile-Server
//
//  Created by Josh Doman on 6/14/17.
//
//

import PostgreSQLProvider
import Foundation

final class Log: Model {
    
    enum LogParameter: String {
        case vc = "vc"
        case user = "user_id"
        case session = "session"
        case device = "device_id"
        case event = "event"
        case action = "action"
        case desc = "desc"
        case timestamp = "timestamp"
    }
    
    let storage = Storage()
    
    static let idType: IdentifierType = .uuid
    static let idKey: String = "log_id"
    static let foreignIdKey: String = "log_id"
    
    let userId: Int
    let vc: String?
    let session: Int?
    let event: String? //
    let action: String? //
    let desc: String?
    let timestamp: Date
    
    var user: Parent<Log, User> {
        return parent(id: Identifier(.int(userId)))
    }
    
    init(userId: Int, session: Int?, vc: String?, event: String?, action: String?, desc: String?, timestamp: Date) {
        self.vc = vc
        self.userId = userId
        self.session = session
        self.event = event
        self.action = action
        self.desc = desc
        self.timestamp = timestamp
    }

    init(row: Row) throws {
        session = try row.get(LogParameter.session.rawValue)
        vc = try row.get(LogParameter.vc.rawValue)
        userId = try row.get(LogParameter.user.rawValue)
        event = try row.get(LogParameter.event.rawValue)
        action = try row.get(LogParameter.action.rawValue)
        desc = try row.get(LogParameter.desc.rawValue)
        timestamp = try row.get(LogParameter.timestamp.rawValue)
    }
}

extension Log: RowRepresentable {
    // Serializes the User to the database
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(LogParameter.user.rawValue, userId)
        try row.set(LogParameter.session.rawValue, session)
        try row.set(LogParameter.vc.rawValue, vc)
        try row.set(LogParameter.event.rawValue, event)
        try row.set(LogParameter.action.rawValue, action)
        try row.set(LogParameter.desc.rawValue, desc)
        try row.set(LogParameter.timestamp.rawValue, timestamp)
        return row
    }
}

// MARK: Fluent Preparation

extension Log: Preparation {
    /// Prepares a table/collection in the database
    /// for storing the User
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.int(LogParameter.user.rawValue)
            builder.string(LogParameter.session.rawValue, optional: true)
            builder.string(LogParameter.vc.rawValue, optional: true)
            builder.string(LogParameter.event.rawValue, optional: true)
            builder.string(LogParameter.action.rawValue, optional: true)
            builder.string(LogParameter.desc.rawValue, optional: true)
            builder.date(LogParameter.timestamp.rawValue)
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
extension Log: JSONConvertible {
    convenience init(json: JSON) throws {
        let deviceId: String = try json.get(LogParameter.device.rawValue)
        let timestampString: String = try json.get(LogParameter.timestamp.rawValue)
        if let userId = try User.findForDeviceId(deviceId)?.id?.wrapped.int, let timestamp = Log.convertBetween(timestamp: timestampString)?.0 {
            try self.init(
                userId: userId,
                session: json.get(LogParameter.session.rawValue),
                vc: json.get(LogParameter.vc.rawValue),
                event: json.get(LogParameter.event.rawValue),
                action: json.get(LogParameter.action.rawValue),
                desc: json.get(LogParameter.desc.rawValue),
                timestamp: timestamp
            )
        } else {
            throw Abort.notFound
        }
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        if let id = id?.wrapped.string {
            try json.set(idKey, id)
        }
        if let deviceId = try user.get()?.deviceID {
            try json.set(LogParameter.device.rawValue, deviceId)
        }
        try json.set(LogParameter.session.rawValue, session)
        try json.set(LogParameter.vc.rawValue, vc)
        try json.set(LogParameter.event.rawValue, event)
        try json.set(LogParameter.action.rawValue, action)
        try json.set(LogParameter.desc.rawValue, desc)
        try json.set(LogParameter.timestamp.rawValue, Log.convertBetween(date: timestamp)?.1)
        return json
    }
    
    private static func convertBetween(date: Date? = nil, timestamp: String? = nil) -> (Date, String)? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZ"
        if let date = date {
            return (date, formatter.string(from: date))
        } else if let timestamp = timestamp {
            return (formatter.date(from: timestamp) ?? Date(), timestamp)
        }
        return nil
    }
}
    

// MARK: HTTP

// This allows Log models to be returned
// directly in route closures
extension Log: ResponseRepresentable { }

extension Request {
    func log() throws -> Log {
        guard let json = json else { throw Abort(.badRequest, reason: "JSON not included in request.") }
        return try Log(json: json)
    }
}
