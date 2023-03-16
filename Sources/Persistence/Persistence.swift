//
//  Persistence.swift
//
//  Created by Jeff A. Campbell on 2/16/18.
//  Copyright © 2019 Southern California Public Radio. All rights reserved.
//

import Foundation

/// This class handles all reading and writing behaviors provided by the Persistence framework.
///
/// - Author: Jeff A. Campbell
///
public class Persistence {
	public enum DebugLevel: String {
		/// Display no debugging output.
		case disabled

		/// Display only basic/minimal debugging output.
		case basic

		/// Display all available debugging output.
		case verbose
	}

	private var debugLevel	= DebugLevel.disabled

	private let jsonEncoder	= JSONEncoder()
	private let jsonDecoder	= JSONDecoder()

	public init() {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"

		self.setDateFormatter(dateFormatter)
	}

	/// Initialize Persistence with optional debugging and an optional `DateFormatter` to use when encoding and decoding Date instances.
	///
	/// - Parameters:
	///     - debugLevel: What level of debugging output to display.
	///     - dateFormatter: An optional DateFormatter used for encoding and decoding.
	///
	/// - Author: Jeff A. Campbell
	///
	public convenience init(withDebugLevel debugLevel:DebugLevel, dateFormatter:DateFormatter? = nil) {
		self.init()

		self.debugLevel = debugLevel

		if let dateFormatter = dateFormatter {
			self.setDateFormatter(dateFormatter)
		}
	}

	/// Set the `DateFormatter` used by Persistence when encoding and decoding `Date` instances.
	///
	/// - Parameters:
	///     - dateFormatter: The `DateFormatter` used for encoding and decoding.
	///
	/// - Author: Jeff A. Campbell
	///
	public func setDateFormatter(_ dateFormatter:DateFormatter?) {
		if let dateFormatter = dateFormatter {
			self.jsonEncoder.dateEncodingStrategy	= .formatted(dateFormatter)
			self.jsonDecoder.dateDecodingStrategy	= .formatted(dateFormatter)
		} else {
			self.jsonEncoder.dateEncodingStrategy	= .secondsSince1970
			self.jsonDecoder.dateDecodingStrategy	= .secondsSince1970
		}
	}

	/// Whether a named file at a specified location is older than a supplied time interval. Optionally refers to a versioned location (so that it does not persist between app builds).
	///
	/// - Parameters:
	///     - ageThreshold: The TimeInterval used as a threshold for the file's age.
	///     - fileName: The name of the file whose age is to be checked.
	///     - location: The on-device `FileLocation` where the file is located.
	///
	/// - Returns:
	///		- True if the file is older than the specified `ageThreshold`, false if not. Will also return true if the file does not exist.
	///
	/// - Author: Jeff A. Campbell
	///
	public func file(isOlderThan ageThreshold:TimeInterval, fileNamed fileName:String, location:FileLocation) -> Bool {
		guard let locationDirectoryURL = location.directoryURL() else {
			return false
		}

		let fileURL				= locationDirectoryURL.appendingPathComponent(fileName)

		if FileManager.default.fileExists(atPath: fileURL.path) {
			do {
				var fileAge:TimeInterval	= 0

				let fileAttributes			= try FileManager.default.attributesOfItem(atPath: fileURL.path)
				let modificationDate		= fileAttributes[FileAttributeKey.modificationDate] as! Date

				fileAge						= modificationDate.timeIntervalSinceNow

				if self.debugLevel == .verbose {
					print("Age: File '\(fileName)' in location '\(locationDirectoryURL.path)' is \(abs(fileAge)) seconds old. Threshold is \(ageThreshold) seconds.")
				}

				if abs(fileAge) > ageThreshold {
					return true
				} else {
					return false
				}
			} catch _ {
				return true
			}
		}

		return true
	}

	/// Writes an `Encodable`-compliant class, struct, enum, or collection to a named file at a specified location.
	///
	/// - Parameters:
	///     - encodableItem: A `Codable`-conformant class, struct, enum, or collection.
	///     - fileName: The name of the file to write.
	///     - location: The on-device `FileLocation` where the file is to be written.
	///
	/// - Returns:
	///     - A .success() Result with a true Bool if the write succeeded, or a .failure() with a WriteError if it did not.
	///
	/// - Author: Jeff A. Campbell
	///
	@discardableResult public func write<T>(_ encodableItem:T, toFileNamed fileName:String, location:FileLocation) -> Result<Bool, WriteError> where T : Encodable {
		guard let locationDirectoryURL = location.directoryURL() else {
			if self.debugLevel == .basic || self.debugLevel == .verbose {
				print("Write: Failure - Invalid directory.")
			}

			return .failure(.invalidDirectory)
		}

		if self.debugLevel == .verbose {
			print("Write: Writing file '\(fileName)' in location '\(locationDirectoryURL.path)'.")
		}

		if self.createDirectory(locationDirectoryURL) == false {
			if self.debugLevel == .basic || self.debugLevel == .verbose {
				print("Write: Failure - Could not create directory in location '\(locationDirectoryURL.path)'.")
			}

			return .failure(.couldNotCreateDirectory)
		}

		let fileURL				= locationDirectoryURL.appendingPathComponent(fileName)

		do {
			var saved				= false
			let data				= try self.jsonEncoder.encode(encodableItem)

			NSFileCoordinator().coordinate(writingItemAt: fileURL, options: [], error: nil, byAccessor: { (writeURL) in
				if FileManager.default.createFile(atPath: writeURL.path, contents: data, attributes: nil) == true {
					saved = true
				}
			})

			if saved == false {
				if self.debugLevel == .basic || self.debugLevel == .verbose {
					print("Write: Failure - Could not write file '\(fileName)' in location '\(locationDirectoryURL.path)'.")
				}

				return .failure(.couldNotWriteFile)
			}
		} catch {
			if self.debugLevel == .basic || self.debugLevel == .verbose {
				print("Write: Failure - Could not encode.")
			}

			return .failure(.couldNotEncode)
		}

		if self.debugLevel == .verbose {
			print("Write: Success - Wrote to file '\(fileName)' in location '\(locationDirectoryURL.path)'.")
		}

		return .success(true)
	}

	/// Writes an `Encodable`-compliant class, struct, enum, or collection to a named file at a specified location using async/await.
	///
	/// - Parameters:
	///     - encodableItem: A `Codable`-conformant class, struct, enum, or collection.
	///     - fileName: The name of the file to write.
	///     - location: The on-device `FileLocation` where the file is to be written.
	///
	/// - Returns:
	///     - A .success() Result with a true Bool if the write succeeded, or a .failure() with a WriteError if it did not.
	///
	/// - Author: Jeff A. Campbell
	///
	public func write<T>(_ encodableItem:T, toFileNamed fileName:String, location:FileLocation) async throws where T : Encodable {
		try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) -> Void in
			let result = self.write(encodableItem, toFileNamed: fileName, location: location)

			switch result {
			case .success(_):
				continuation.resume()
			case .failure(let error):
				return continuation.resume(throwing: error)
			}
		}
	}

	/// Reads a `Decodable`-compliant class, struct, enum, or collection from a named file at a specified location.
	///
	/// - Parameters:
	///     - fileName: The name of the file to read.
	///     - type: The `Codable`-conformant class, struct, enum, or collection.
	///     - location: The on-device `FileLocation` where the file is to be read from.
	///     - completion: A completion handler that returns a .success() Result with the read class, struct, enum, or collection if the read succeeded, or a .failure() with a ReadError if it did not.
	///
	/// - Author: Jeff A. Campbell
	///
	public func read<T>(fromFileNamed fileName:String, asType type:T.Type, location:FileLocation, completion: @escaping (Result<T, ReadError>) -> Void) where T : Decodable {
		guard let locationDirectoryURL = location.directoryURL() else {
			if self.debugLevel == .basic || self.debugLevel == .verbose {
				print("Read: Failure - Invalid directory.")
			}

			completion(.failure(ReadError.invalidDirectory))
			return
		}

		let fileURL				= locationDirectoryURL.appendingPathComponent(fileName)

		if self.debugLevel == .verbose {
			print("Read: Reading file '\(fileName)' in location '\(locationDirectoryURL.path)'.")
		}

		if FileManager.default.fileExists(atPath: fileURL.path) == false {
			if self.debugLevel == .basic || self.debugLevel == .verbose {
				print("Read: Failure - File '\(fileName)' does not exist in location '\(locationDirectoryURL.path)'.")
			}

			completion(.failure(ReadError.fileDoesNotExist))
		} else {
			NSFileCoordinator().coordinate(readingItemAt: fileURL, options: [], error: nil) { [weak self] (readURL) in
				guard let _self = self else {
					completion(.failure(ReadError.failed))
					return
				}

				if let data = FileManager.default.contents(atPath: readURL.path) {
					do {
						let instance = try _self.jsonDecoder.decode(type, from: data)

						if _self.debugLevel == .verbose {
							print("Read: Success - Decoded content of file '\(fileName)' with type \(type) from location '\(locationDirectoryURL.path)'.")
						}

						completion(.success(instance))
					} catch let error {
						if _self.debugLevel == .basic || _self.debugLevel == .verbose {
							print("Read: Failure - Could not decode content of file '\(fileName)' with type \(type) from location '\(locationDirectoryURL.path)'.")
							print("Error: \(error)")
						}

						completion(.failure(ReadError.failed))
					}
				} else {
					if _self.debugLevel == .basic || _self.debugLevel == .verbose {
						print("Read: Failure - Could not read file '\(fileName)' from location '\(locationDirectoryURL.path)'.")
					}

					completion(.failure(ReadError.failed))
				}
			}
		}
	}

	/// Reads a `Decodable`-compliant class, struct, enum, or collection from a named file at a specified location using async/await.
	///
	/// - Parameters:
	///     - fileName: The name of the file to read.
	///     - type: The `Codable`-conformant class, struct, enum, or collection.
	///     - location: The on-device `FileLocation` where the file is to be read from.
	///
	/// - Author: Jeff A. Campbell
	///
	public func read<T>(fromFileNamed fileName:String, asType type:T.Type, location:FileLocation) async throws -> T where T : Decodable {
		try await withCheckedThrowingContinuation { continuation in
			self.read(fromFileNamed: fileName, asType: type, location: location) { result in
				switch result {
				case .success(let resultDecodable):
					continuation.resume(returning: resultDecodable)
				case .failure(let error):
					return continuation.resume(throwing: error)
				}
			}
		}
	}
	
	/// Deletes named file at a specified location.
	///
	/// - Parameters:
	///     - fileName: The name of the file to delete.
	///     - location: The on-device `FileLocation` where the file is to be written.
	///
	/// - Returns:
	///     - A .success() Result with a true Bool if the delete succeeded, or a .failure() with a DeleteError if it did not.
	///
	/// - Author: Jeff A. Campbell
	///
	@discardableResult public func delete(fileNamed fileName:String, location:FileLocation) -> Result<Bool, DeleteError> {
		guard let locationDirectoryURL = location.directoryURL() else {
			if self.debugLevel == .basic || self.debugLevel == .verbose {
				print("Delete: Failure - Invalid directory.")
			}

			return .failure(.invalidDirectory)
		}

		if self.debugLevel == .verbose {
			print("Delete: Deleting file '\(fileName)' in location '\(locationDirectoryURL.path)'.")
		}

		let fileURL				= locationDirectoryURL.appendingPathComponent(fileName)

		var deleted				= false

		NSFileCoordinator().coordinate(writingItemAt: fileURL, options: [], error: nil, byAccessor: { (deleteURL) in
			if FileManager.default.isDeletableFile(atPath: deleteURL.path) {
				do {
					try FileManager.default.removeItem(at: deleteURL)

					deleted = true
				} catch {
				}
			}
		})

		if deleted == false {
			if self.debugLevel == .basic || self.debugLevel == .verbose {
				print("Delete: Failure - Could not delete file '\(fileName)' in location '\(locationDirectoryURL.path)'.")
			}

			return .failure(.couldNotDeleteFile)
		}

		if deleted == false {
			if self.debugLevel == .basic || self.debugLevel == .verbose {
				print("Delete: Failure - Could not delete.")
			}

			return .failure(.couldNotDeleteFile)
		}

		if self.debugLevel == .verbose {
			print("Delete: Success - Deleted file '\(fileName)' in location '\(locationDirectoryURL.path)'.")
		}

		return .success(true)
	}
}

extension Persistence {
	/// Creates a directory at the supplied `URL`.
	///
	/// This method will create all intermediate directories as needed,
	///
	/// - Parameters:
	///     - directoryURL: A `URL` for the directory to be created.
	///
	/// - Returns:
	///     - Returns true if the directory was created or already exists, otherwise false.
	///
	/// - Author: Jeff A. Campbell
	///
	private func createDirectory(_ directoryURL:URL) -> Bool {
		if FileManager.default.fileExists(atPath: directoryURL.path) == false {
			do {
				try FileManager.default.createDirectory(atPath: directoryURL.path, withIntermediateDirectories: true, attributes: nil)

				return true
			} catch {
				return false
			}
		}

		return true
	}
}
