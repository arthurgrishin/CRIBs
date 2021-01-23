//
//  Workflow.swift
//  CRIBs
//
//  Created by Arthur Grishin on 23/1/21.
//

import Combine

open class Workflow<ActionableItemType> {

    open func didComplete() {
        // No-op
    }

    open func didFork() {
        // No-op
    }

    open func didReceiveError(_ error: Error) {
        // No-op
    }

    public init() {}

    public final func on<NextActionableItemType, NextValueType>(step: @escaping (ActionableItemType) -> AnyPublisher<(NextActionableItemType, NextValueType), AnyError>) -> Step<ActionableItemType, NextActionableItemType, NextValueType> {
        let publisher = subject.prefix(1).eraseToAnyPublisher()
        return Step(workflow: self, publisher: publisher).on { (actionableItem: ActionableItemType, _) in
            step(actionableItem)
        }
    }

    public final func subscribe(_ actionableItem: ActionableItemType) -> some Cancellable {
        guard compositeCancellable.count > 0 else {
            fatalError("Attempt to subscribe to \(self) before it is comitted.")
        }

        subject.send((actionableItem, ()))
        return compositeCancellable
    }

    // MARK: - Private

    private let subject = PassthroughSubject<(ActionableItemType, ()), AnyError>()
    private var didInvokeComplete = false

    fileprivate let compositeCancellable = CompositeCancellable()

    fileprivate func didCompleteIfNotYet() {
        guard !didInvokeComplete else { return }
        didInvokeComplete = true
        didComplete()
    }
}

open class Step<WorkflowActionableItemType, ActionableItemType, ValueType> {

    private let workflow: Workflow<WorkflowActionableItemType>
    private var publisher: AnyPublisher<(ActionableItemType, ValueType), AnyError>

    fileprivate init(workflow: Workflow<WorkflowActionableItemType>,
                     publisher: AnyPublisher<(ActionableItemType, ValueType), AnyError>) {
        self.workflow = workflow
        self.publisher = publisher
    }

    public final func on<NextActionableItemType, NextValueType>(step: @escaping (ActionableItemType, ValueType) -> AnyPublisher<(NextActionableItemType, NextValueType), AnyError>
    ) -> Step<WorkflowActionableItemType, NextActionableItemType, NextValueType> {
        let confinedNextStep = publisher
            .flatMap { (actionableItem, value) -> AnyPublisher<(Bool, ActionableItemType, ValueType), AnyError> in
                if let interactor = actionableItem as? Interactable {
                    return interactor
                        .isActiveStream
                        .map({ (isActive: Bool) -> (Bool, ActionableItemType, ValueType) in
                            (isActive, actionableItem, value)
                        })
                        .mapError({ AnyError($0) }).eraseToAnyPublisher()
                } else {
                    return Just((true, actionableItem, value))
                        .mapError({ AnyError($0) })
                        .eraseToAnyPublisher()
                }

            }
            .filter { (isActive: Bool, _, _) -> Bool in
                isActive
            }
            .prefix(1)
            .flatMap { (_, actionableItem: ActionableItemType, value: ValueType) -> AnyPublisher<(NextActionableItemType, NextValueType), AnyError> in
                step(actionableItem, value)
            }
            .prefix(1)
            .share()
            .eraseToAnyPublisher()

        return Step<WorkflowActionableItemType, NextActionableItemType, NextValueType>(workflow: workflow, publisher: confinedNextStep)
    }

    @discardableResult
    public final func commit() -> Workflow<WorkflowActionableItemType> {
        // Side-effects must be chained at the last observable sequence, since errors and complete
        // events can be emitted by any observables on any steps of the workflow.
        let cancellable = publisher
            .sink(receiveCompletion: { [weak workflow = self.workflow] completion in
                switch completion {
                case .finished: workflow?.didCompleteIfNotYet()
                case .failure(let error): workflow?.didReceiveError(error)
                }
            }, receiveValue: { _ in })

        workflow.compositeCancellable.insert(cancellable)
        return workflow
    }

    public final func eraseToAnyPublisher() -> AnyPublisher<(ActionableItemType, ValueType), AnyError> {
        return publisher
    }
}

public extension Publisher {
    func fork<WorkflowActionableItemType, ActionableItemType, ValueType>(_ workflow: Workflow<WorkflowActionableItemType>) -> Step<WorkflowActionableItemType, ActionableItemType, ValueType>? {
        if let stepPublisher = self as? AnyPublisher<(ActionableItemType, ValueType), AnyError> {
            workflow.didFork()
            return Step(workflow: workflow, publisher: stepPublisher)
        }
        return nil
    }
}

public extension Cancellable {
    func cancelWith<ActionableItemType>(workflow: Workflow<ActionableItemType>) {
        workflow.compositeCancellable.insert(self)
    }
}

// MARK: - AnyError

public struct AnyError: Swift.Error {
    public let error: Swift.Error

    public init(_ error: Swift.Error) {
        if let anyError = error as? AnyError {
            self = anyError
        } else {
            self.error = error
        }
    }
}

extension AnyError: CustomStringConvertible {
    public var description: String {
        return String(describing: error)
    }
}

extension AnyError: LocalizedError {
    public var errorDescription: String? {
        return error.localizedDescription
    }

    public var failureReason: String? {
        return (error as? LocalizedError)?.failureReason
    }

    public var helpAnchor: String? {
        return (error as? LocalizedError)?.helpAnchor
    }

    public var recoverySuggestion: String? {
        return (error as? LocalizedError)?.recoverySuggestion
    }
}
