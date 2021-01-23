//
//  LaunchRouterTests.swift
//  CRIBsTests
//
//  Created by Arthur Grishin on 23/1/21.
//

@testable import CRIBs
import XCTest

final class RootRouterTests: XCTestCase {
    
    private class DependencyMock {}
    private class InteractableMock: Interactor<DependencyMock> {}
    private class ViewControllableMock: ViewControllable {
        let uiviewController = UIViewController(nibName: nil, bundle: nil)
    }

    
    private let dependency = DependencyMock()
    private var rootRouter: RootRouting!

    private var interactor: InteractableMock!
    private var viewController: ViewControllableMock!

    // MARK: - Setup
    override func setUp() {
        super.setUp()

        
        interactor = InteractableMock(dependency: dependency)
        viewController = ViewControllableMock()
        rootRouter = RootRouter(dependency: dependency, interactor: interactor, viewController: viewController)
    }

    // MARK: - Tests
    func test_launchFromWindow() {
        let window = WindowMock(frame: .zero)
        rootRouter.launch(from: window)

        XCTAssert(window.rootViewController === viewController.uiviewController)
        XCTAssert(window.isKeyWindow)
    }
}

private class WindowMock: UIWindow {
    
    override var isKeyWindow: Bool {
        return internalIsKeyWindow
    }
    
    override var rootViewController: UIViewController? {
        get { return internalRootViewController }
        set { internalRootViewController = newValue }
    }
    
    override func makeKeyAndVisible() {
        internalIsKeyWindow = true
    }
    
    // MARK: - Private
    
    private var internalIsKeyWindow: Bool = false
    private var internalRootViewController: UIViewController?
}
