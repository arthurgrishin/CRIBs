//
//  Interactor.swift
//  Bender
//
//  Created by Arthur Grishin on 26/11/20.
//

import Foundation
import Combine
import UIKit

/// Protocol defining the activeness of an interactor's scope.
public protocol InteractorScope: class {
    var isActive: Bool { get }
    var isActiveStream: AnyPublisher<Bool, Never> { get }
}

/// The base protocol for all interactors.
public protocol Interactable: InteractorScope {
    func activate()
    func deactivate()
}

open class Interactor<DependencyType>: Interactable {

    public final var isActive: Bool {
        return isActiveSubject.value
    }

    public final var isActiveStream: AnyPublisher<Bool, Never> {
        return isActiveSubject.removeDuplicates().eraseToAnyPublisher()
    }

    let dependency: DependencyType
    public init(dependency: DependencyType) {
        self.dependency = dependency
    }

    public final func activate() {
        guard !isActive else {
            return
        }

        isActiveSubject.send(true)

        didBecomeActive()
    }

    open func didBecomeActive() {
        // No-op
    }

    public final func deactivate() {
        guard isActive else {
            return
        }

        willResignActive()

        activenessCancellable?.cancel()
        activenessCancellable = nil

        isActiveSubject.send(false)
    }

    /// Callend when the `Interactor` will resign the active state.
    ///
    /// This method is driven by the detachment of this interactor's owner router. Subclasses should override this
    /// method to cleanup any resources and states of the `Interactor`. The default implementation does nothing.
    open func willResignActive() {
        // No-op
    }

    // MARK: - Private
    fileprivate var isActiveSubject = CurrentValueSubject<Bool, Never>(false)
    fileprivate var activenessCancellable: CompositeCancellable?

    deinit {
        if isActive {
            deactivate()
        }
        isActiveSubject.send(completion: .finished)
    }
}

public final class CompositeCancellable : Cancellable {

    private var lock = NSRecursiveLock()

    // state
    private var cancellables: Array<Cancellable>? = Array()

    public var isCanceled: Bool {
        self.lock.performLocked { self.cancellables == nil }
    }

    public init() {
    }
    /**
     Adds a disposable to the CompositeDisposable or disposes the disposable if the CompositeDisposable is disposed.

     - parameter disposable: Disposable to add.
     - returns: Key that can be used to remove disposable from composite disposable. In case dispose bag was already
     disposed `nil` will be returned.
     */
    public func insert(_ cancellable: Cancellable) {
        lock.performLocked {
            cancellables!.append(cancellable)
        }
    }

    /// - returns: Gets the number of disposables contained in the `CompositeDisposable`.
    public var count: Int {
        self.lock.performLocked { self.cancellables?.count ?? 0 }
    }

    /// Disposes all disposables in the group and removes them from the group.
    public func cancel() {
        if let cancellables = self._cancel() {
            cancellables.forEach { $0.cancel() }
        }
    }

    private func _cancel() -> Array<Cancellable>? {
        lock.performLocked {
            let currentCancellables = cancellables
            cancellables = nil
            return currentCancellables
        }
    }
}

private extension NSRecursiveLock {
    @inline(__always)
    final func performLocked<T>(_ action: () -> T) -> T {
        self.lock(); defer { self.unlock() }
        return action()
    }
}


/// Interactor related `Disposable` extensions.
public extension Cancellable {

    /// Disposes the subscription based on the lifecycle of the given `Interactor`. The subscription is disposed
    /// when the interactor is deactivated.
    ///
    /// - note: This is the preferred method when trying to confine a subscription to the lifecycle of an
    ///   `Interactor`.
    ///
    /// When using this composition, the subscription closure may freely retain the interactor itself, since the
    /// subscription closure is disposed once the interactor is deactivated, thus releasing the retain cycle before
    /// the interactor needs to be deallocated.
    ///
    /// If the given interactor is inactive at the time this method is invoked, the subscription is immediately
    /// terminated.
    ///
    /// - parameter interactor: The interactor to dispose the subscription based on.
    @discardableResult
    func cancelOnDeactivate<T>(interactor: Interactor<T>) -> Cancellable {
        if let activenessCancellable = interactor.activenessCancellable {
            activenessCancellable.insert(self)
        } else {
            cancel()
            print("Subscription immediately terminated, since \(interactor) is inactive.")
        }
        return self
    }
}
