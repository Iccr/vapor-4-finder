//
//  File.swift
//  File
//
//  Created by ccr on 16/11/2021.
//

import Foundation
import Vapor

extension Request {
    var baseUrl: String {
        return Environment.get("SERVER_URL") ?? ""
    }
}
