//
//  Batch.swift
//  PennMobile-Server
//
//  Created by Josh Doman on 6/16/17.
//
//

import JSON
import HTTP

// Ex Batch 
// request JSON:
// { "requests" : [
//        {
//            "method": "post",
//            "uri": "localhost:8080/test",
//            "values": {
//                "test1": 5,
//                "test2": "test"
//            }
//        },
//        {
//            "method": "get",
//            "uri": "localhost:8080/test2",
//            "values": {
//                "test1": 6,
//                "test2": "test2"
//            }
//        }
//    ]
// }
//
// response JSON:
// { "requests" : [
//        "Success!",
//        {
//            "name": "John Doe",
//            "email": "johndoe@seas.upenn.edu"
//        }
//    ]
// }

final class Batch: JSONInitializable {
    
    var requests: [Request] = []
    
    required init(json: JSON) throws {
        guard let jsonRequests: [JSON] = try json.get("requests") else {
            throw Abort(.badRequest, reason: "JSON does not have a requests key.")
        }
        for jsonRequest in jsonRequests {
            requests.append(try Request(json: jsonRequest))
        }
    }
    
    func respond(through router: Router) throws -> Response {
        var json = JSON()
        let resArr = try requests.map({ (req) -> JSON? in
            let res = try router.respond(to: req)
            if res.headers[.contentType] == "text/plain; charset=utf-8", let bytes = res.body.bytes {
                return try JSON(node: String(bytes: bytes))
            }
            return res.json
        })
        try json.set("responses", resArr)
        return Response(status: .ok, body: json)
    }
}

extension Request {
    func batch() throws -> Batch {
        guard let json = json else { throw Abort.badRequest }
        return try Batch(json: json)
    }
}

extension Request: JSONInitializable {
    
    public convenience init(json: JSON) throws {
        guard let methodString: String = try json.get("method") else {
            throw Abort(.badRequest, reason: "Method is not post, get, delete, or patch.")
        }
        
        let uri: String = try json.get("uri")
        self.init(method: Method(methodString), uri: uri)
        
        let optionalSubjson: JSON? = try json.get("values")
        if let subjson = optionalSubjson {
            self.headers["Content-Type"] = "application/json"
            self.body = try Body(subjson)
        }
    }
}

