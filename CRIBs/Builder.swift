//
//  Builder.swift
//  Bender
//
//  Created by Arthur Grishin on 26/11/20.
//

import Foundation

public protocol Buildable: class {}

open class Builder<DependencyType>: Buildable {
    public let dependency: DependencyType

    /// Initializer.
    ///
    /// - parameter dependency: The dependency used for this builder to build the RIB
    public init(dependency: DependencyType) {
        self.dependency = dependency
    }
}
