import Vapor
import HTTP

/// Here we have a controller that helps facilitate
/// RESTful interactions with our Users table
final class UserController: ResourceRepresentable {
    /// When users call 'GET' on '/users'
    /// it should return an index of all available users
    func index(req: Request) throws -> ResponseRepresentable {
        return try User.all().makeJSON()
    }

    /// When consumers call 'User' on '/users' with valid JSON
    /// create and save the user
    func create(request: Request) throws -> ResponseRepresentable {
        let user = try request.user()
        if try user.dbAlready(has: .token) {
            return "Device token already stored. Use 'PUT' request to replace or 'PATCH' to update user."
        } else if try user.dbAlready(has: .device) {
            return "Device ID already stored. Use 'PUT' request to replace or 'PATCH' to update user."
        }
        try user.save()
        return user
    }

    /// When the consumer calls 'GET' on a specific resource, ie:
    /// '/users/13rd88' we should show that specific user
    func show(req: Request, user: User) throws -> ResponseRepresentable {
        return user
    }

    /// When the consumer calls 'DELETE' on a specific resource, ie:
    /// 'users/l2jd9' we should remove that resource from the database
    func delete(req: Request, user: User) throws -> ResponseRepresentable {
        try user.delete()
        return Response(status: .ok)
    }

    /// When the consumer calls 'DELETE' on the entire table, ie:
    /// '/users' we should remove the entire table
    func clear(req: Request) throws -> ResponseRepresentable {
        try User.makeQuery().delete()
        return Response(status: .ok)
    }

    /// When the user calls 'PATCH' on a specific resource, we should
    /// update that resource to the new values.
    func update(req: Request, user: User) throws -> ResponseRepresentable {
        // See `extension User: Updateable`
        try user.update(for: req)
        // Save and return the updated user.
        try user.save()
        return user
    }

    /// When a user calls 'PUT' on a specific resource, we should replace any
    /// values that do not exist in the request with null.
    /// This is equivalent to creating a new User with the same ID.
    func replace(req: Request, user: User) throws -> ResponseRepresentable {
        // First attempt to create a new User from the supplied JSON.
        // If any required fields are missing, this request will be denied.
        let new = try req.user()

        // Update the user with all of the properties from
        // the new user
        user.deviceID = new.deviceID
        user.email = new.email
        user.token = new.token
        try user.save()

        // Return the updated user
        return user
    }

    /// When making a controller, it is pretty flexible in that it
    /// only expects closures, this is useful for advanced scenarios, but
    /// most of the time, it should look almost identical to this 
    /// implementation
    func makeResource() -> Resource<User> {
        return Resource(
            index: index,
            store: create,
            show: show,
            update: update,
            replace: replace,
            destroy: delete,
            clear: clear
        )
    }
}

extension Request {
    /// Create a user from the JSON body
    /// return BadRequest error if invalid 
    /// or no JSON
    func user() throws -> User {
        guard let json = json else { throw Abort(.badRequest, reason: "JSON not included in request.") }
        return try User(json: json)
    }
}

/// Since UserController doesn't require anything to 
/// be initialized we can conform it to EmptyInitializable.
///
/// This will allow it to be passed by type.
extension UserController: EmptyInitializable { }
