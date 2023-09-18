//
//  Logger+Extensions.swift
//
//
//  Created by Jeff Campbell on 9/16/23.
//

import OSLog

extension Logger {
//	private static let appIdentifier = Bundle.main.bundleIdentifier ?? ""
	private static let subsystem = "Persistence"

	static let io = Logger(subsystem: subsystem, category: "I/O")
}
