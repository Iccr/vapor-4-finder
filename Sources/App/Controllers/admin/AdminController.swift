//
//  File.swift
//  
//
//  Created by ccr on 25/10/2021.
//

import Foundation
import Vapor



class AdminController: RouteCollection {
    
    
    func boot(routes: RoutesBuilder) throws {
        
        let route = routes.grouped("admin")
        let secure = route.grouped(EnsureAdminUserMiddleware())
        route.get("login", use: new)
        route.post("login", use: login)
        
        secure.get("dashboard", use: dashboard)
        // rentals
        secure.get("rentals", use: rentals)
        secure.get("rentals", "verify", ":id", use: updateRoomVerify)
        // city
        secure.get("city", use: city)
        secure.post("city", use: cityCreate)
        secure.get("city", "new", use: cityNew)
        secure.post("city", "delete", use: cityDelete)
        secure.get("city", "edit", ":id", use: cityEdit)
        
        // pages
        secure.get("pages", use: pages)
        secure.post("pages", use: pagesCreate)
        
        secure.get("pages", "new", use: pagesNew)
        secure.post("pages", "delete", use: pagesDelete)
        secure.get("pages", "edit", ":id", use: pagesEdit)
        
        // api key
        secure.get("apiKey", use: apiKey)
        secure.post("apiKey", use: apiKeyCreate)
        
        secure.get("apiKey", "new", use: apiKeyNew)
        secure.post("apiKey", "delete", use: apiKeyDelete)
        secure.get("apiKey", "edit", ":id", use: apiKeyEdit)
        
        
    }
    
    func new(req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("admin/pages/login")
    }
    
    func login(req: Request) throws -> EventLoopFuture<View> {
        print(req)
        return req.view.render("admin/pages/login")
    }
    
    func dashboard(req: Request) throws -> EventLoopFuture<View> {
        let user = try req.auth.require(User.self)
        if user.hasRole(.admin) {
            return AdminDashboardStore().dashboard(req: req, user: user).flatMap { context in
                return req.view.render("admin/pages/dashboard", context)
            }
        }
        throw Abort.redirect(to: "/")
    }
    
    func rentals(req: Request) throws -> EventLoopFuture<View> {
        let user = try req.auth.require(User.self)
        struct RentalContext: Content {
            var rooms: [Room.Output]
        }
        return RoomStore().getAdminRooms(req: req).flatMap { rooms in
            return req.view.render("admin/pages/rentals", RentalContext(rooms: rooms))
            
        }
        
    }
    
    func updateRoomVerify(req: Request) -> EventLoopFuture<Response> {
        let id = req.parameters.get("id", as: Int.self)
        return Room.find(id, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { room in
                room.verified = !room.verified
                return room.update(on: req.db).map {
                    req.redirect(to: "/admin/rentals")
                }
            }
    }
    
    func city(req: Request) throws -> EventLoopFuture<View> {
        try CityStore().getAllCity(req: req).flatMap { cities in
            struct Context: Encodable {
                var items: [City]
                var alert: AppAlert?
            }
            return req.view.render("admin/pages/city", Context(items: cities, alert: req.alert))
        }
    }
    
    func cityNew(req: Request) throws -> EventLoopFuture<View> {
        struct Context: Encodable {
            var city: City?
            var edit = false
            var alert: AppAlert?
        }
        return req.view.render("admin/pages/cityForm", Context(alert: req.alert))
    }
    
    func cityCreate(req: Request) throws -> EventLoopFuture<Response> {
        let _city = try? req.content.decode(City.Input.self)
        do {
            if let _ = _city?.id {
                // update if id is present
                return try CityStore().update(req: req).map { city in
                    req.redirect(to: "/admin/city")
                }
            }else {
                return try CityStore().create(req: req).map { city in
                    return req.redirect(to: "/admin/city")
                }
            }
        } catch {
            return req.eventLoop.makeSucceededFuture(req.redirect(to: "/admin/city/new/?alert=\(error)&priority=3"))
        }
    }
    
    
    func cityDelete(req: Request) throws -> EventLoopFuture<Response> {
        try CityStore().delete(req: req).map { city in
            return req.redirect(to: "/admin/city")
        }
    }
    
    func cityEdit(req: Request) throws -> EventLoopFuture<View> {
        let id = req.parameters.get("id", as: Int.self)
        struct Context: Encodable {
            var city: City?
            var edit = true
        }
        
        return try CityStore().find(id, req: req)
            .unwrap(or: Abort(.notFound))
            .flatMap { city in
                req.view.render("/admin/pages/cityForm", Context(city: city))
            }
    }
    
    
    func pages(req: Request) throws -> EventLoopFuture<View> {
        try PageStore().getAllPages(req: req).flatMap { pages in
            struct Context: Encodable {
                var pages: [AppPage]
                var alert: AppAlert?
            }
            return req.view.render("admin/pages/pages", Context(pages: pages, alert: req.alert))
        }
    }
    
    
    func pagesCreate(req: Request) throws -> EventLoopFuture<Response> {
        let _city = try? req.content.decode(AppPage.Input.self)
        do {
            if let _ = _city?.id {
                // update if id is present
                return try PageStore().update(req: req).map { pages in
                    req.redirect(to: "/admin/pages")
                }
            }else {
                return try PageStore().create(req: req).map { city in
                    return req.redirect(to: "/admin/pages")
                }
            }
        } catch {
            return req.eventLoop.makeSucceededFuture(req.redirect(to: "/admin/pages/new/?alert=\(error)&priority=3"))
        }
    }
    
    func pagesNew(req: Request) throws -> EventLoopFuture<View> {
        struct Context: Encodable {
            var page: AppPage?
            var edit = false
            var alert: AppAlert?
        }
        return req.view.render("admin/pages/pagesForm", Context(alert: req.alert))
    }
    
    
    func pagesDelete(req: Request) throws -> EventLoopFuture<Response> {
        try PageStore().delete(req: req).map { city in
            return req.redirect(to: "/admin/pages")
        }
    }
    
    func pagesEdit(req: Request) throws -> EventLoopFuture<View> {
        let id = req.parameters.get("id", as: Int.self)
        struct Context: Encodable {
            var page: AppPage?
            var edit = true
        }
        
        return try PageStore().find(id, req: req)
            .unwrap(or: Abort(.notFound))
            .flatMap { pages in
                req.view.render("/admin/pages/pagesForm", Context(page: pages))
            }
    }
    
    
    // apikey
    
    func apiKey(req: Request) throws -> EventLoopFuture<View> {
        try ApiKeyStore().getAllKeys(req: req).flatMap { pages in
            struct Context: Encodable {
                var keys: [ApiKey]
                var alert: AppAlert?
            }
            return req.view.render("admin/pages/apiKey", Context(keys: pages, alert: req.alert))
        }
    }
    
    
    func apiKeyCreate(req: Request) throws -> EventLoopFuture<Response> {
        let _city = try? req.content.decode(ApiKey.Input.self)
        do {
            if let _ = _city?.id {
                // update if id is present
                return try ApiKeyStore().update(req: req).map { pages in
                    req.redirect(to: "/admin/apiKey")
                }
            }else {
                return try ApiKeyStore().create(req: req).map { city in
                    return req.redirect(to: "/admin/apiKey")
                }
            }
        } catch {
            return req.eventLoop.makeSucceededFuture(req.redirect(to: "/admin/apiKey/new/?alert=\(error)&priority=3"))
        }
    }
    
    func apiKeyNew(req: Request) throws -> EventLoopFuture<View> {
        struct Context: Encodable {
            var page: AppPage?
            var edit = false
            var alert: AppAlert?
        }
        return req.view.render("admin/pages/apiKeyForm", Context(alert: req.alert))
    }
    
    
    func apiKeyDelete(req: Request) throws -> EventLoopFuture<Response> {
        try ApiKeyStore().delete(req: req).map { city in
            return req.redirect(to: "/admin/apiKey")
        }
    }
    
    func apiKeyEdit(req: Request) throws -> EventLoopFuture<View> {
        let id = req.parameters.get("id", as: Int.self)
        struct Context: Encodable {
            var key: ApiKey?
            var edit = true
        }
        
        return try ApiKeyStore().find(id, req: req)
            .unwrap(or: Abort(.notFound))
            .flatMap { pages in
                req.view.render("/admin/pages/apiKeyForm", Context(key: pages))
            }
    }
}


extension Request {
    var alert: AppAlert? {
        try? query.decode(AppAlert.self)
    }
}







