//
//  ViewControllable.swift
//  Bender
//
//  Created by Arthur Grishin on 26/11/20.
//

import UIKit

/// Basic interface between a `Router` and the UIKit `UIViewController`.
public protocol ViewControllable: class {

    var uiviewController: UIViewController { get }
}

/// Default implementation on `UIViewController` to conform to `ViewControllable` protocol
public extension ViewControllable where Self: UIViewController {

    var uiviewController: UIViewController {
        return self
    }
}
