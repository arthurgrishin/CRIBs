//
//  Copyright (c) 2020. Uber Technologies
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Combine
import XCTest
@testable import CRIBs

final class WorkerflowTests: XCTestCase {

    func test_nestedStepsDoNotRepeat() {
        var outerStep1RunCount = 0
        var outerStep2RunCount = 0
        var outerStep3RunCount = 0

        var innerStep1RunCount = 0
        var innerStep2RunCount = 0
        var innerStep3RunCount = 0

        let emptyObservable = Just(((), ())).mapError({ error in AnyError(error)}).eraseToAnyPublisher()

        let workflow = Workflow<String>()
        _ = workflow
            .on { (mock) -> AnyPublisher<((), ()), AnyError> in
                outerStep1RunCount += 1

                return emptyObservable
            }
            .on { (_, _) -> AnyPublisher<((), ()), AnyError> in
                outerStep2RunCount += 1

                return emptyObservable
            }
            .on { (_, _) -> AnyPublisher<((), ()), AnyError> in
                outerStep3RunCount += 1

                let innerStep: Step<String, (), ()>? = emptyObservable.fork(workflow)

                innerStep?
                    .on(step: { (_, _) -> AnyPublisher<((), ()), AnyError> in
                        innerStep1RunCount += 1
                        return emptyObservable
                    })
                    .on(step: { (_, _) -> AnyPublisher<((), ()), AnyError> in
                        innerStep2RunCount += 1
                        return emptyObservable
                    })
                    .on(step: { (_, _) -> AnyPublisher<((), ()), AnyError> in
                        innerStep3RunCount += 1
                        return emptyObservable
                    })
                    .commit()

                return emptyObservable
            }
            .commit()
            .subscribe("Test Actionable Item")

        XCTAssertEqual(outerStep1RunCount, 1, "Outer step 1 should not have been run more than once")
        XCTAssertEqual(outerStep2RunCount, 1, "Outer step 2 should not have been run more than once")
        XCTAssertEqual(outerStep3RunCount, 1, "Outer step 3 should not have been run more than once")

        XCTAssertEqual(innerStep1RunCount, 1, "Inner step 1 should not have been run more than once")
        XCTAssertEqual(innerStep2RunCount, 1, "Inner step 2 should not have been run more than once")
        XCTAssertEqual(innerStep3RunCount, 1, "Inner step 3 should not have been run more than once")
    }

    func test_workflowReceivesError() {
        let workflow = TestWorkflow()

        let emptyObservable = Just(((), ()))
            .mapError({ error in AnyError(error)})
            .eraseToAnyPublisher()
        
        _ = workflow
            .on { _ -> AnyPublisher<((), ()), AnyError> in
                return emptyObservable
            }
            .on { _, _ -> AnyPublisher<((), ()), AnyError> in
                return emptyObservable
            }
            .on { _, _ -> AnyPublisher<((), ()), AnyError> in
                return Fail(error: AnyError(WorkflowTestError.error))
                    .eraseToAnyPublisher()
            }
            .on { _, _ -> AnyPublisher<((), ()), AnyError> in
                return emptyObservable
            }
            .commit()
            .subscribe(())

        XCTAssertEqual(0, workflow.completeCallCount)
        XCTAssertEqual(0, workflow.forkCallCount)
        XCTAssertEqual(1, workflow.errorCallCount)
    }

    func test_workflowDidComplete() {
        let workflow = TestWorkflow()

        let emptyObservable = Just(((), ())).mapError({ error in AnyError(error)}).eraseToAnyPublisher()
        _ = workflow
            .on { _ -> AnyPublisher<((), ()), AnyError> in
                return emptyObservable
            }
            .on { _, _ -> AnyPublisher<((), ()), AnyError> in
                return emptyObservable
            }
            .on { _, _ -> AnyPublisher<((), ()), AnyError> in
                return emptyObservable
            }
            .commit()
            .subscribe(())

        XCTAssertEqual(1, workflow.completeCallCount)
        XCTAssertEqual(0, workflow.forkCallCount)
        XCTAssertEqual(0, workflow.errorCallCount)
    }

    func test_workflowDidFork() {
        let workflow = TestWorkflow()

        let emptyObservable = Just(((), ())).mapError({ error in AnyError(error)}).eraseToAnyPublisher()
        _ = workflow
            .on { _ -> AnyPublisher<((), ()), AnyError> in
                return emptyObservable
            }
            .on { _, _ -> AnyPublisher<((), ()), AnyError> in
                return emptyObservable
            }
            .on { _, _ -> AnyPublisher<((), ()), AnyError> in
                return emptyObservable
            }
            .on { _, _ -> AnyPublisher<((), ()), AnyError> in
                let forkedStep: Step<(), (), ()>? = emptyObservable.fork(workflow)
                forkedStep?
                    .on { _, _ -> AnyPublisher<((), ()), AnyError> in
                        return emptyObservable
                    }
                    .commit()
                return emptyObservable
            }
            .commit()
            .subscribe(())

        XCTAssertEqual(1, workflow.completeCallCount)
        XCTAssertEqual(1, workflow.forkCallCount)
        XCTAssertEqual(0, workflow.errorCallCount)
    }

    func test_fork_verifySingleInvocationAtRoot() {
        let workflow = TestWorkflow()

        var rootCallCount = 0
        let emptyObservable = Just(((), ())).mapError({ error in AnyError(error)}).eraseToAnyPublisher()
        let rootStep = workflow
            .on { _ -> AnyPublisher<((), ()), AnyError> in
                rootCallCount += 1
                return emptyObservable
        }

        let firstFork: Step<(), (), ()>? = rootStep.eraseToAnyPublisher().fork(workflow)
        _ = firstFork?
            .on { (_, _) -> AnyPublisher<((), ()), AnyError> in
                return Just(((), ())).mapError({ error in AnyError(error)}).eraseToAnyPublisher()
            }
            .commit()

        let secondFork: Step<(), (), ()>? = rootStep.eraseToAnyPublisher().fork(workflow)
        _ = secondFork?
            .on { (_, _) -> AnyPublisher<((), ()), AnyError> in
                return Just(((), ())).mapError({ error in AnyError(error)}).eraseToAnyPublisher()
            }
            .commit()

        XCTAssertEqual(0, rootCallCount)

        _ = workflow.subscribe(())

        XCTAssertEqual(1, rootCallCount)
    }
}

private enum WorkflowTestError: Error {
    case error
}

private class TestWorkflow: Workflow<()> {
    var completeCallCount = 0
    var errorCallCount = 0
    var forkCallCount = 0

    override func didComplete() {
        completeCallCount += 1
    }

    override func didFork() {
        forkCallCount += 1
    }

    override func didReceiveError(_ error: Error) {
        errorCallCount += 1
    }
}
