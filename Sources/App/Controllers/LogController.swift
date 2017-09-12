import Vapor
import HTTP

final class LogController: ResourceRepresentable {

    func index(req: Request) throws -> ResponseRepresentable {
        return try Log.all().makeJSON()
    }
    
    func create(request: Request) throws -> ResponseRepresentable {
        let log = try request.log()
        try log.save()
        return log
    }
    

    func makeResource() -> Resource<Log> {
        return Resource(
            index: index,
            store: create
        )
    }
}

extension LogController: EmptyInitializable { }
