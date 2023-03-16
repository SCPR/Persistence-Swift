import XCTest
import Foundation
@testable import Persistence

final class PersistenceTests: XCTestCase {
	struct Test:Codable {
		var test:String
	}
	
	func testWrite() async {
		do {
			let test = Test(test: "Test")

			try await Persistence(withDebugLevel: .verbose).write(test, toFileNamed: "PersistenceTest.txt", location: .applicationSupportDirectory(versioned: false))

			XCTAssertEqual(1, 1)
		} catch let error {
			XCTAssertNil(error, "Received error: \(error)")
		}
	}
	
	func testRead() async {
		do {
			let content = try await Persistence(withDebugLevel: .verbose).read(fromFileNamed: "PersistenceTest.txt", asType: Test.self, location: .applicationSupportDirectory(versioned: false))

			print("content = \(content.test)")

			XCTAssertEqual(content.test, "Test")
		} catch let error {
			XCTAssertNil(error, "Received error: \(error)")
		}
	}
}
