//
//  RouterTests.swift
//  CRIBsTests
//
//  Created by Arthur Grishin on 23/1/21.
//

import Combine
import XCTest
@testable import CRIBs

final class RouterTests: XCTestCase {
    
    private class DependencyMock {}
    private class InteractableMock: Interactor<DependencyMock> {}

    private var router: Router<DependencyMock, Interactable>!
    private var lifecycleCancellable: AnyCancellable!

    // MARK: - Setup
    override func setUp() {
        super.setUp()

        let dependency = DependencyMock()
        router = Router(dependency: dependency, interactor: InteractableMock(dependency: dependency))
    }

    override func tearDown() {
        super.tearDown()

        lifecycleCancellable.cancel()
    }

    // MARK: - Tests
    func test_load_verifyLifecyclePublisher() {
        var currentLifecycle: RouterLifecycle?
        var didComplete = false
        lifecycleCancellable = router
            .lifecycle
            .sink(receiveCompletion: { _ in
                currentLifecycle = nil
                didComplete = true
            }, receiveValue: { lifecycle in
                currentLifecycle = lifecycle
            })
        
        XCTAssertNil(currentLifecycle)
        XCTAssertFalse(didComplete)

        router.load()

        XCTAssertEqual(currentLifecycle, RouterLifecycle.didLoad)
        XCTAssertFalse(didComplete)

        router = nil

        XCTAssertNil(currentLifecycle)
        XCTAssertTrue(didComplete)
    }
}
