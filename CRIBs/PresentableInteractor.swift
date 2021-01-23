//
//  PresentableInteractor.swift
//  Bender
//
//  Created by Arthur Grishin on 26/11/20.
//

import Foundation

/// Base class of an `Interactor` that actually has an associated `Presenter` and `View`.
open class PresentableInteractor<DependencyType, PresenterType>: Interactor<DependencyType> {

    /// The `Presenter` associated with this `Interactor`.
    public let presenter: PresenterType

    /// Initializer.
    ///
    /// - note: This holds a strong reference to the given `Presenter`.
    ///
    /// - parameter presenter: The presenter associated with this `Interactor`.
    public init(dependency: DependencyType, presenter: PresenterType) {
        self.presenter = presenter
        super.init(dependency: dependency)
    }
}
