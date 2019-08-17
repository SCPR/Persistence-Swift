import XCTest

import PersistenceTests

var tests = [XCTestCaseEntry]()
tests += PersistenceTests.allTests()
XCTMain(tests)
