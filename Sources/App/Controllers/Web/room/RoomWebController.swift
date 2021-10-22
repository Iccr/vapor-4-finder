//
//  File.swift
//  
//
//  Created by ccr on 10/10/2021.
//

import Foundation
import Vapor
import Fluent

class RoomWebController {
    func index(req: Request) throws -> EventLoopFuture<View> {
        let query = try req.query.decode(Room.Querry.self)
        let user = req.auth.get(User.self)
        return RoomStore().getAllRooms(query, req: req).flatMap { page in
            return req.view.render(
                "index",
                Room.getContext(baseUrl: req.baseUrl, page: page, query: query, user: user)
            )
        }
    }
}

