//
//  File.swift
//  
//
//  Created by ccr on 03/09/2021.
//


import Fluent
import Vapor
import JWT





final class User : Model, Content {
    static let schema = "users"

    @ID(custom: "id")
    var id: Int?
    
    @Children(for: \.$user)
    var rooms: [Room]
    
    @Field(key: "email")
    var email : String?
    
    @Field(key: "image")
    var image : String?
    
   
    
    @Field(key: "name")
    var name : String?
    
    @Field(key: "token")
    var token : String?
    
    @Field(key: "appleUserIdentifier")
    var appleUserIdentifier: String?
    
    @Field(key: "fcm_token")
    var fcm : String?
    
    @Enum(key: "role")
    var role: Role
    
    var authToken: String?
      
    @Field(key: "provider")
    var provider : String?
    
    
  @Field(key: "auth_token")
  var auth_token : String?
    
    @Field(key: "device_id")
    var device_id : String?
    
    
    @Field(key: "device_type")
    var device_type : String?
    
    @Field(key: "fb_id")
    var fb_id : String?
    
    @Field(key: "fb_id")
    var g_id : String?
    
    

    
    //    auth_token
    //    device_id
    //    device_type
    //    fc -> fcm_token
    //    fb_id
    //    g_id
    //    updated_at -> updatedAt
    //    created_at -> createdAt


    
    @Timestamp(key: "createdAt", on: .create)
        var createdAt: Date?


    @Timestamp(key: "updatedAt", on: .update)
    var updatedAt: Date?
    

    init() { }
    
    init(user: User) throws {
      self.id = try user.requireID()
      self.email = user.email
      self.name = user.name
      
    }
    
    init(id: Int?,
         email: String,
         imageurl: String?,
         name : String?,
         token : String?,
         appleUserIdentifier: String?,
         provider : String?,
         fcm: String?) {
        self.email = email
        self.id = id
        self.image = imageurl
        self.name = name
        self.token = token
        self.appleUserIdentifier = appleUserIdentifier
        self.provider = provider
        self.fcm = fcm
    }
 
}

extension User {
    struct Profile: Codable {
        var id: Int?
        var name: String?
        var email: String?
        var image: String?
    }
    
    struct BasicProfile: Codable {
        var name: String?
        var image: String?
    }
    
    func getBasicProfile() -> BasicProfile {
        return .init(name: self.name, image: self.image)
    }
    
    func getProfile() -> User.Profile {
        return Profile(id: self.id , name: self.name, email: self.email, image: self.image)
    }
}


// MARK: - Token Creation
extension User {
  func createAccessToken(req: Request) throws -> Token {
    let expiryDate = Date() + Apple.AccessToken.expirationTime
    let payload = JwtModel(
        subject: SubjectClaim(value: "\(self.id!)"),
        expiration: .init(value: .distantFuture)
    )
    
    let generatedToken = try req.jwt.sign(payload)
    
    return try Token(
      userID: requireID(),
      token: generatedToken,
      expiresAt: expiryDate
    )
  }
}

// MARK: - Helpers
extension User {
  static func assertUniqueEmail(_ email: String, req: Request) -> EventLoopFuture<Void> {
    findByEmail(email, req: req)
      .flatMap {
        guard $0 == nil else {
          return req.eventLoop.makeFailedFuture(UserError.emailTaken)
        }
        return req.eventLoop.future()
    }
  }



  static func findByAppleIdentifier(_ identifier: String, req: Request) -> EventLoopFuture<User?> {
    User.query(on: req.db)
      .filter(\.$appleUserIdentifier == identifier)
      .first()
  }
    
    static func findByEmail(_ email: String, req: Request) -> EventLoopFuture<User?> {
      User.query(on: req.db)
        .filter(\.$email == email)
        .first()
    }
}


extension User {
    static func getUser(from: FacebookResponseModel) -> User {
        return User.init(id: nil, email: from.email ?? "", imageurl: from.picture?.data?.url, name: from.first_name, token: nil, appleUserIdentifier: nil, provider: "facebook", fcm: nil)
    }
}

extension User: Authenticatable {}
extension User: ModelSessionAuthenticatable {}


struct UserAuthenticator: BearerAuthenticator {
    typealias User = App.User

    func authenticate(
        bearer: BearerAuthorization,
        for request: Request
    ) -> EventLoopFuture<Void> {
        if let payload = try? request.jwt.verify(as: JwtModel.self), let id = Int(payload.subject.value)  {
            return User.query(on: request.db).filter(\.$id == id).first().map { user in
                if let user = user {
                    request.auth.login(user)
                }
            }
        }
       return request.eventLoop.makeSucceededFuture(())
   }
}



extension User {
    enum Role: String, Codable {
        case admin = "1"
        case normalUser = "2"
    }
    
    func hasRole(_ role: Role) -> Bool {
        return self.role == role
    }
    
    var isAdmin: Bool {
        return self.role == .admin
    }
}


final class UserContainer : Codable {
    let user : User?

    enum CodingKeys: String, CodingKey {

        case user = "user"
    }

    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        user = try values.decodeIfPresent(User.self, forKey: .user)
    }

}
