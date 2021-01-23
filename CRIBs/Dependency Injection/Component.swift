//
//  Component.swift
//  Bender
//
//  Created by Arthur Grishin on 26/11/20.
//

import Foundation

/// The base class for all components.
///
/// A component defines private properties a RIB provides to its internal `Router`, `Interactor`, `Presenter` and
/// view units, as well as public properties to its child RIBs.
///
/// A component subclass implementation should conform to child 'Dependency' protocols, defined by all of its immediate
/// children.
open class Component<DependencyType>: Dependency {

    /// The dependency of this `Component`.
    public let dependency: DependencyType

    /// Initializer.
    ///
    /// - parameter dependency: The dependency of this `Component`, usually provided by the parent `Component`.
    public init(dependency: DependencyType) {
        self.dependency = dependency
    }
}

/// The special empty component.
open class EmptyComponent: EmptyDependency {

    /// Initializer.
    public init() {}
}
