//
//  RootRouter.swift
//  Bender
//
//  Created by Arthur Grishin on 26/11/20.
//

import UIKit

/// The root `Router` of an application.
public protocol RootRouting: ViewableRouting {

    /// Launches the router tree.
    ///
    /// - parameter window: The application window to launch from.
    func launch(from window: UIWindow)
}

/// The application root router base class, that acts as the root of the router tree.
open class RootRouter<DependencyType, InteractorType, ViewControllerType>: ViewableRouter<DependencyType, InteractorType, ViewControllerType>, RootRouting {

    /// Initializer.
    ///
    /// - parameter interactor: The corresponding `Interactor` of this `Router`.
    /// - parameter viewController: The corresponding `ViewController` of this `Router`.
    public override init(dependency: DependencyType, interactor: InteractorType, viewController: ViewControllerType) {
        super.init(dependency: dependency, interactor: interactor, viewController: viewController)
    }

    /// Launches the router tree.
    ///
    /// - parameter window: The window to launch the router tree in.
    public final func launch(from window: UIWindow) {
        window.rootViewController = viewControllable.uiviewController
        window.makeKeyAndVisible()

        interactable.activate()
        load()
    }
}
