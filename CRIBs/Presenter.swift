//
//  Presenter.swift
//  Bender
//
//  Created by Arthur Grishin on 26/11/20.
//

import Foundation

/// The base protocol for all `Presenter`s.
public protocol Presentable: class {}

/// The base class of all `Presenter`s. A `Presenter` translates business models into values the corresponding
/// `ViewController` can consume and display. It also maps UI events to business logic method, invoked to
/// its listener.
open class Presenter<ViewControllerType>: Presentable {

    /// The view controller of this presenter.
    public let viewController: ViewControllerType

    /// Initializer.
    ///
    /// - parameter viewController: The `ViewController` of this `Pesenters`.
    public init(viewController: ViewControllerType) {
        self.viewController = viewController
    }
}
