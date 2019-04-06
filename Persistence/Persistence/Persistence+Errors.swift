//
//  Persistence+Errors.swift
//
//  Created by Jeff A. Campbell on 2/16/18.
//  Copyright © 2019 Southern California Public Radio. All rights reserved.
//

import Foundation

extension Persistence {
	/// Errors associated with reading.
	///
	/// - Author: Jeff A. Campbell
	///
	public enum ReadError: Error {
		/// Attempted to load from an invalid/non-existent directory.
		case invalidDirectory
		/// File does not exist at the location specified.
		case fileDoesNotExist
		/// Failed to load for an unspecified reason.
		case failed
	}

	/// Errors associated with writing.
	///
	/// - Author: Jeff A. Campbell
	///
	public enum WriteError: Error {
		/// Attempted to write to an invalid/non-existent directory.
		case invalidDirectory
		/// Failed to create a necessary directory.
		case couldNotCreateDirectory
		/// Failed to write the file.
		case couldNotWriteFile
		/// Failed to encode the specified class, struct, enum, or collection.
		case couldNotEncode
		/// Failed to write for an unspecified reason.
		case failed
	}
}
