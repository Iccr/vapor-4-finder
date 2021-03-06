import Fluent
import Vapor

struct Todos: Content {
    var title: String
    
}

func routes(_ app: Application) throws {
    
    app.routes.caseInsensitive = true
    let imperialController = ImperialController()
    try app.routes.register(collection: imperialController)
    
    //    api
    
    let api = app.grouped("api", "v1")
//    api = app.grouped(EnsureApiDomainMiddleware())
    try api.group(EnsureApiDomainMiddleware()) { api in
        try api.register(collection: RoomController())
        try api.register(collection: LoginController())
        try api.register(collection: CityController())
        try api.register(collection: BannerController())
        try api.register(collection: ReportController())
        try api.register(collection: AppInfoController())
        try api.register(collection: UserAccountDeleteController())
        
        
    }
    
    
    
    app.get("admin") { req in
        return req.view.render("admin/adminMaster")
    }
    
    
    // web
    try app.register(collection: LoginWebController())
    try app.register(collection: RoomWebController())
    try app.register(collection: UserWebController())
    
    
    
    // admin
    
    try app.register(collection: AdminController())
//    try app.register(collection: StaticFileController())
        try app.register(collection: PagesController())
    
    app.get  { req  in
        try  RoomWebController().index(req: req)
        
    }
}
