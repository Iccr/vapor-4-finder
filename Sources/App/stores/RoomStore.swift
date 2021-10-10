//
//  File.swift
//  
//
//  Created by ccr on 07/10/2021.
//

import Foundation
import Vapor
import Fluent

class RoomStore {
    func getAllRooms(_ searchQuery: Room.Querry, req: Request) -> EventLoopFuture<Page<Room.Output>> {
        let query =  Room.query(on: req.db)
        return self.querries(query: query, params: searchQuery)
            .with(\.$city)
            .with(\.$user)
            .paginate(for: req).map { page in
                page.map { $0.responseFrom(baseUrl: req.baseUrl)
                }
            }
    }
//        City.query(on: req.db)
//            .with(\.$rooms)
//            .filter(\.$id == (searchQuery.city_id ?? -1))
//            .first()
//            .flatMap { city in
//                if let city = city {
//                    let query =  city.$rooms.query(on: req.db)
//                    return self.querries(query: query, params: searchQuery)
//                        .paginate(for: req).map { page in
//                            page.map { $0.responseFrom(baseUrl: req.baseUrl)
//                            }
//                        }
//                }else {
//                    let query =
//                        Room.query(on: req.db)
//                        .with(\.$city)
//                    return self.querries(query: query, params: searchQuery)
//                        .paginate(for: req).map { page in
//                            page.map { $0.responseFrom(baseUrl: req.baseUrl)}
//                        }
//                    //                        .all()
//                    //                        .mapEach {$0.responseFrom(baseUrl: req.baseUrl)}
//
//                }
//            }
//    }
    
    func create(req: Request, room: Room, input: Room.Entity, user: User ) ->  EventLoopFuture<Room.Output> {
        let uploadPath = req.application.directory.publicDirectory + "uploads/"
        return input.images.map { file -> EventLoopFuture<String> in
            let filename = "\(Date().timeIntervalSince1970)_" + file.filename.replacingOccurrences(of: " ", with: "")
            return req.fileio.writeFile(file.data, at: uploadPath + filename ).map { filename }
        }.flatten(on: req.eventLoop).map { filenames in
            room.vimages = filenames
        }.flatMap { _ in
            return City.query(on: req.db)
                .filter(\.$id == input.city_id)
                .first()
        }.flatMap { city in
            room.$user.id = user.id ?? -1
            room.$city.id = city?.id ?? -1
            return room.create(on: req.db).map {
                return room.responseFrom(baseUrl: req.baseUrl)
            }
        }
    }
    
    func getWithId(req: Request) throws -> EventLoopFuture<Room.Output> {
        if let _id = req.parameters.get("id"), let id = Int(_id) {
            return Room.find(id, on: req.db).flatMapThrowing { room in
                if let room = room {
                    return room.responseFrom(baseUrl: req.baseUrl)
                }
                throw Abort(.notFound)
            }
        }
        throw Abort(.notFound)
    }
    
    func getMyRooms(req: Request, user: User) -> EventLoopFuture<[Room.Output]> {
        return user.$rooms.get(on: req.db).mapEach {$0.responseFrom(baseUrl: req.baseUrl)}
    }
    
    func update(req: Request, input: Room.Update) throws -> EventLoopFuture<Room.Output> {
        return Room.find(input.id, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { room in
                return room.get(update: input).update(on: req.db).map {
                    room.responseFrom(baseUrl: req.baseUrl)
                }
            }
    }
    
//    if let room  = room {
//        room.occupied = input.occupied
//        return room.update(on: req.db).map {
//         return room.responseFrom(baseUrl: req.baseUrl)
//       }
//    }
//    throw Abort(.notFound)
    
}


extension RoomStore {
    func querries(query: QueryBuilder<Room>, params: Room.Querry) -> QueryBuilder<Room> {
        if let val = params.city_id {
            query.filter(\.$city.$id == val)
        }
        
        if let val = params.type {
            query.filter(\.$type ~~ val)
        }
        if let val = params.kitchen {
            query.filter(\.$kitchen ~~ val)
        }
        if let val = params.floor {
            query.filter(\.$floor ~~ val)
        }
        
        if let val = params.address {
            query.filter(\.$address ~~ val)
        }
        
        if let val = params.district {
            query.filter(\.$district ~~ val)
        }
        
        if let val = params.state {
            query.filter(\.$state ~~ val)
        }
        
        if let val = params.localGov {
            query.filter(\.$localGov ~~ val)
        }
        
        if let val = params.parking {
            query.filter(\.$parking ~~ val)
        }
        
        if let val = params.water {
            query.filter(\.$water ~~ val)
        }
        
        if let val = params.internet {
            query.filter(\.$internet ~~ val)
        }
        
        if let val = params.preference {
            query.filter(\.$preference ~~ val)
        }
        
        
        if let val = params.lowerPrice {
            query.filter(\.$price >= val)
        }
        
        if let val = params.upperPrice {
            query.filter(\.$price <= val)
        }
        
        if let val = params.price {
            if val == "low-to-high" {
               query.sort(\.$price, .ascending)
            }else {
                 query.sort(\.$price, .descending)
            }
        }
        return query
    }
}
