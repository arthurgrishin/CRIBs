//
//  Router.swift
//  Bender
//
//  Created by Arthur Grishin on 26/11/20.
//

import Combine

/// The lifecycle stages of a router scope.
public enum RouterLifecycle {

    /// Router did load.
    case didLoad
}

/// The scope of a `Router`, defining various lifecycles of a `Router`.
public protocol RouterScope: class {
}

/// The base protocol for all routers.
public protocol Routing: RouterScope {
    var interactable: Interactable { get }
    var children: [Routing] { get }

    /// Loads the `Router`.
    ///
    /// - note: This method is internally used by the framework. Application code should never
    ///   invoke this method explicitly.
    func load()

    /// Attaches the given router as a child.
    ///
    /// - parameter child: The child router to attach.
    func attachChild(_ child: Routing)

    /// Detaches the given router from the tree.
    ///
    /// - parameter child: The child router to detach.
    func detachChild(_ child: Routing)
}

/// The base class of all routers that does not own view controllers, representing application states.
///
/// A router acts on inputs from its corresponding interactor, to manipulate application state, forming a tree of
/// routers. A router may obtain a view controller through constructor injection to manipulate view controller tree.
/// The DI structure guarantees that the injected view controller must be from one of this router's ancestors.
/// Router drives the lifecycle of its owned `Interactor`.
///
/// Routers should always use helper builders to instantiate children routers.
open class Router<DependencyType, InteractorType>: Routing {

    public let dependency: DependencyType
    public let interactor: InteractorType
    public let interactable: Interactable

    public private(set) final var children: [Routing] = []

    public final var lifecycle: AnyPublisher<RouterLifecycle, Never> {
        return lifecycleSubject.eraseToAnyPublisher()
    }

    /// Initializer.
    ///
    /// - parameter interactor: The corresponding `Interactor` of this `Router`.
    public init(dependency: DependencyType, interactor: InteractorType) {
        self.dependency = dependency
        self.interactor = interactor
        guard let interactable = interactor as? Interactable else {
            fatalError("\(interactor) should conform to \(Interactable.self)")
        }
        self.interactable = interactable
    }

    /// Loads the `Router`.
    ///
    /// - note: This method is internally used by the framework. Application code should never invoke this method
    ///   explicitly.
    public final func load() {
        guard !didLoadFlag else {
            return
        }

        didLoadFlag = true
        internalDidLoad()
        didLoad()
    }

    /// Called when the router has finished loading.
    ///
    /// This method is invoked only once. Subclasses should override this method to perform one time setup logic,
    /// such as attaching immutable children. The default implementation does nothing.
    open func didLoad() {
        // No-op
    }

    /// Attaches the given router as a child.
    ///
    /// - parameter child: The child `Router` to attach.
    public final func attachChild(_ child: Routing) {
        assert(!(children.contains { $0 === child }), "Attempt to attach child: \(child), which is already attached to \(self).")

        children.append(child)

        child.interactable.activate()
        child.load()
    }

    /// Detaches the given `Router` from the tree.
    ///
    /// - parameter child: The child `Router` to detach.
    public final func detachChild(_ child: Routing) {
        child.interactable.deactivate()

        guard let objIndex = children.firstIndex(where: { $0 as AnyObject === child as AnyObject }) else {
            return
        }
        children.remove(at: objIndex)
    }

    // MARK: - Internal

    let deinitCancellable = CompositeCancellable()

    func internalDidLoad() {
        bindSubtreeActiveState()
        lifecycleSubject.send(.didLoad)
    }

    // MARK: - Private

    private let lifecycleSubject = PassthroughSubject<RouterLifecycle, Never>()
    private var didLoadFlag: Bool = false

    private func bindSubtreeActiveState() {

        let cancellable = interactable.isActiveStream
            // Do not retain self here to guarantee execution. Retaining self will cause the dispose bag
            // to never be disposed, thus self is never deallocated. Also cannot just store the disposable
            // and call dispose(), since we want to keep the subscription alive until deallocation, in
            // case the router is re-attached. Using weak does require the router to be retained until its
            // interactor is deactivated.
            .sink(receiveValue: { [weak self] (isActive: Bool) in
                // When interactor becomes active, we are attached to parent, otherwise we are detached.
                self?.setSubtreeActive(isActive)
            })
        deinitCancellable.insert(cancellable)
    }

    private func iterateSubtree(_ root: Routing, closure: (_ node: Routing) -> ()) {
        closure(root)

        for child in root.children {
            iterateSubtree(child, closure: closure)
        }
    }

    private func setSubtreeActive(_ active: Bool) {

        if active {
            iterateSubtree(self) { router in
                if !router.interactable.isActive {
                    router.interactable.activate()
                }
            }
        } else {
            iterateSubtree(self) { router in
                if router.interactable.isActive {
                    router.interactable.deactivate()
                }
            }
        }
    }

    private func detachAllChildren() {

        for child in children {
            detachChild(child)
        }
    }

    deinit {
        interactable.deactivate()
        
        lifecycleSubject.send(completion: .finished)

        if !children.isEmpty {
            detachAllChildren()
        }
    }
}

private extension Array {

    /// Remove the given element from this array, by comparing pointer references.
    ///
    /// - parameter element: The element to remove.
    mutating func removeElementByReference(_ element: Element) {

    }
}

