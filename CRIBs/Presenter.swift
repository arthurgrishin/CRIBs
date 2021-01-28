//
//  Presenter.swift
//  Bender
//
//  Created by Arthur Grishin on 26/11/20.
//

import SwiftUI

public protocol Presentable: ObservableObject {}

open class Presenter<ModelType>: Presentable {
    @Published public var model: ModelType

    public init(model: ModelType) {
        self.model = model
    }
}
