//
//  Giveaway.swift
//  TFG
//
//  Created by Ignacio on 12/5/25.
//


import Foundation

struct Giveaway: Identifiable, Decodable {
    let id: Int
    let title: String
    let worth: String
    let description: String
    let image: String
    let open_giveaway_url: String
}
