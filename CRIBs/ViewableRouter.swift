//
//  ViewableRouter.swift
//  Bender
//
//  Created by Arthur Grishin on 26/11/20.
//

import SwiftUI

/// The base protocol for all routers that own their own view controllers.
public protocol ViewableRouting: Routing {

    // The following methods must be declared in the base protocol, since `Router` internally invokes these methods.
    // In order to unit test router with a mock child router, the mocked child router first needs to conform to the
    // custom subclass routing protocol, and also this base protocol to allow the `Router` implementation to execute
    // base class logic without error.

    /// The base view controllable associated with this `Router`.
    var viewable: AnyView { get }
}

/// The base class of all routers that owns view controllers, representing application states.
///
/// A `Router` acts on inputs from its corresponding interactor, to manipulate application state and view state,
/// forming a tree of routers that drives the tree of view controllers. Router drives the lifecycle of its owned
/// interactor. `Router`s should always use helper builders to instantiate children `Router`s.
open class ViewableRouter<DependencyType, InteractorType, ViewType: Viewable>: Router<DependencyType, InteractorType>, ViewableRouting {

    /// The corresponding `ViewController` owned by this `Router`.
    public let view: ViewType

    /// The base `ViewControllable` associated with this `Router`.
    public var viewable: AnyView {
        guard let viewable = view as? AnyView else {
            fatalError("\(view) should be to \(AnyView.self)")
        }

        return viewable
    }

    /// Initializer.
    ///
    /// - parameter interactor: The corresponding `Interactor` of this `Router`.
    /// - parameter viewController: The corresponding `ViewController` of this `Router`.
    public init(dependency: DependencyType, interactor: InteractorType, view: ViewType) {
        self.view = view

        super.init(dependency: dependency, interactor: interactor)
    }
}
