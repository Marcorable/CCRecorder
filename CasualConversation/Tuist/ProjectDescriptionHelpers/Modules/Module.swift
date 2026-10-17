//
//  Module.swift
//  ProjectDescriptionHelpers
//
//  Created by 김용우 on 3/30/24.
//

import ProjectDescription

protocol Module {
    static var name: String { get }
    static var packages: [Package] { get }
    static var target: Target { get }
    static var test: Target { get }
    static var schemes: [Scheme] { get }
}
