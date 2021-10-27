import Fluent
import FluentPostgresDriver
import FluentMySQLDriver
import Leaf
import Vapor
import JWT



import Foundation
// configures your application
public func configure(_ app: Application) throws {
    let file = FileMiddleware(publicDirectory: app.directory.publicDirectory)
    app.middleware = .init()
    app.middleware.use(MyErrorMiddleware())
    app.views.use(.leaf)
    app.middleware.use(file)
    app.routes.defaultMaxBodySize = "10mb"
    app.logger.logLevel = .debug

    let jwtSecret = Environment.get("JWT_SECRET") ?? "blablaSecret"
    app.jwt.signers.use(.hs256(key: jwtSecret))
    let hostname = Environment.get("DATABASE_HOST") ?? "127.0.0.1"
//    var port: Int = 5433
        var port: Int = 3306
    if let _p = Environment.get("PORT"), let _port = Int(_p) {
        port = _port
    }
    let username = Environment.get("USER") ?? "deploy"
    let dbName = Environment.get("DATABASE") ?? "roomfinder"
    let dbPassword = Environment.get("PASSWORD") ?? "P@ssword"
    
//    app.middleware.use(app.sessions.middleware)
    
    
    app.middleware.use(app.sessions.middleware)
    app.middleware.use(User.sessionAuthenticator())
    print("\(username)@\(hostname):\(port)/\(dbName)")
    app.databases.use(
        .mysql(configuration: .init(
                hostname: "localhost",
                port: 3306,
                username: "deploy",
                password: "P@ssword",
                database: "roomfinder",
                tlsConfiguration: .none
        )),
        as: .mysql)
//    app.databases.use(
//        .postgres(
//            hostname: hostname,
//            port: port,
//            username: username,
//            password: dbPassword,
//            database: dbName,
//            maxConnectionsPerEventLoop: 5),
//        as: .psql)
    app.logger.log(level: .info, "database setup done")
    app.logger.log(level: .info, "starting migration")
    
    app.migrations.add(City.CreateCityMigration())
    app.migrations.add(Banner.CreateBannerMigration())
//    app.migrations.add(User.CreateUserMigration())
//    app.migrations.add(Room.CreateRoomMigration())
//    app.migrations.add(TokenMigration())
    app.migrations.add(Room.AddCityNameToRoomMigration())
    app.migrations.add(User.AddRoleToUser())
    app.migrations.add(User.AddStatusToCity())
    app.migrations.add(Room.AddCityIdToRoomReference())
    app.migrations.add(User.AddImageToUser())
    
    
    

    try app.autoMigrate().wait()
    //    seed(app.db)
    app.logger.log(level: .info, "migration complete")
    try routes(app)
    app.routes.all.forEach { route in
        print(route)
    }
    
}

func seed(_ db: Database)  {
    let kathmandu = City(
        name: "Kathmandu",
        image: "/samples/kathmandu.jpg",
        description: "Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book."
    )
    
    let pokhara = City(
        name: "Pokhara",
        image: "/samples/kathmandu.jpg",
        description: "Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book."
    )
    
   
    
    _ = db.query(City.self).count()
        .flatMapThrowing { count in
        if count == 0 {
            _ =   [kathmandu, pokhara].create(on: db)
        }
    }
    
    
    // banner
    
    let b1 = Banner( title: "Start Earning", image: "/samples/kathmandu.jpg", subtitle: "List a place", type: "property", value: "1")
    
    let b2 = Banner( title: "Monetary Parntership", image: "/samples/kathmandu.jpg", subtitle: "List second place", type: "property", value: "2")
    
    _ = db.query(Banner.self).count()
        .flatMapThrowing { count in
        if count == 0 {
            _ =   [b1, b2].create(on: db)
        }
    }
}






struct CommonResponse<T: Content>: Content {
    let data: T
}



class Apple {
    struct AccessToken {
      static let expirationTime: TimeInterval = 30 * 24 * 60 * 60 // 30 days
    }

    struct SIWA {
      static let applicationIdentifier =  Environment.get("IOS_APP_ID") ?? ""
      static let servicesIdentifier = "SIWA_SERVICES_IDENTIFIER" //e.g. com.raywenderlich.siwa-vapor.services
      static let redirectURL = "SIWA_REDIRECT_URL" // e.g. https://foobar.ngrok.io/web/auth/siwa/callback
    }
}


extension Request {
    var baseUrl: String {
        return Environment.get("SERVER_URL") ?? ""
    }
}
