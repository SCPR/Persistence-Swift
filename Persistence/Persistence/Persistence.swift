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
	private var debug		= false

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
	///     - debug: Whether to enable debug output.
	///     - dateFormatter: An optional DateFormatter used for encoding and decoding.
	///
	/// - Author: Jeff A. Campbell
	///
	public convenience init(withDebug debug:Bool, dateFormatter:DateFormatter?) {
		self.init()

		self.debug = debug

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

	/// Returns a `URL` for the on-device directory of a specified location.
	/// Optionally versions the location.
	///
	/// - Parameters:
	///     - location: The on-device `FileLocation` where the directory is located.
	///
	/// - Returns:
	///     - An optional `URL` for the on-device directory, if it exists.
	///
	/// - Author: Jeff A. Campbell
	///
	public func directoryURL(forLocation location:Persistence.FileLocation) -> URL? {
		var locationDirectoryURL:URL?
		var isVersioned = false

		switch location {
		case .applicationDirectory(let versioned):
			locationDirectoryURL	= FileManager.default.urls(for: .applicationDirectory, in: .userDomainMask).first
			isVersioned				= versioned
		case .applicationDirectoryInAppGroup(let appGroupIdentifier, let versioned):
			locationDirectoryURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
			isVersioned				= versioned
		case .applicationSupportDirectoryInAppGroup(let appGroupIdentifier, let versioned):
			locationDirectoryURL	= FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
			locationDirectoryURL?.appendPathComponent("Library", isDirectory: true)
			locationDirectoryURL?.appendPathComponent("Application Support", isDirectory: true)
			isVersioned				= versioned
		case .cachesDirectoryInAppGroup(let appGroupIdentifier, let versioned):
			locationDirectoryURL	= FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
			locationDirectoryURL?.appendPathComponent("Library", isDirectory: true)
			locationDirectoryURL?.appendPathComponent("Caches", isDirectory: true)
			isVersioned				= versioned
		case .documentsDirectoryInAppGroup(let appGroupIdentifier, let versioned):
			locationDirectoryURL	= FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
			locationDirectoryURL?.appendPathComponent("Documents", isDirectory: true)
			isVersioned				= versioned
		case .applicationSupportDirectory(versioned: let versioned):
			locationDirectoryURL	= FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
			isVersioned				= versioned
		case .cachesDirectory(versioned: let versioned):
			locationDirectoryURL	= FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
			isVersioned				= versioned
		case .documentsDirectory(versioned: let versioned):
			locationDirectoryURL	= FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
			isVersioned				= versioned
		}

		if isVersioned == true {
			locationDirectoryURL?.appendPathComponent(self.stringForBuildNumber(), isDirectory: true)
		}

		return locationDirectoryURL
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
	public func file(isOlderThan ageThreshold:TimeInterval, fileNamed fileName:String, location:Persistence.FileLocation) -> Bool {
		guard let locationDirectoryURL = self.directoryURL(forLocation: location) else {
			return false
		}

		let fileURL				= locationDirectoryURL.appendingPathComponent(fileName)

		if FileManager.default.fileExists(atPath: fileURL.path) {
			do {
				var fileAge:TimeInterval	= 0

				let fileAttributes			= try FileManager.default.attributesOfItem(atPath: fileURL.path)
				let modificationDate		= fileAttributes[FileAttributeKey.modificationDate] as! Date

				fileAge						= modificationDate.timeIntervalSinceNow

				if (fileAge <= -1 * (ageThreshold)) {
					return false
				}
			} catch _ {
				return false
			}
		}

		return true
	}

	/// Writes a `Codable`-compliant class, struct, enum, or collection to a named file at a specified location.
	///
	/// - Parameters:
	///     - encodableItem: A `Codable`-conformant class, struct, enum, or collection.
	///     - fileName: The name of the file to write.
	///     - location: The on-device `FileLocation` where the file is to be written.
	///
	/// - Returns:
	///     - A .success() Result with a true Bool if the write succeeded, or a .failure() with a Persistence.WriteError if it did not.
	///
	/// - Author: Jeff A. Campbell
	///
	public func write<T>(_ encodableItem:T, toFileNamed fileName:String, location:Persistence.FileLocation) -> Result<Bool, WriteError> where T : Encodable {
		guard let locationDirectoryURL = self.directoryURL(forLocation: location) else {
			return .failure(.invalidDirectory)
		}

		if self.createDirectory(locationDirectoryURL) == false {
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
				return .failure(.couldNotWriteFile)
			}
		} catch {
			return .failure(.couldNotEncode)
		}

		return .success(true)
	}

	/// Reads a `Codable`-compliant class, struct, enum, or collection from a named file at a specified location.
	///
	/// - Parameters:
	///     - fileName: The name of the file to read.
	///     - type: The `Codable`-conformant class, struct, enum, or collection.
	///     - location: The on-device `FileLocation` where the file is to be read from.
	///     - completion: A completion handler that returns a .success() Result with the read class, struct, enum, or collection if the read succeeded, or a .failure() with a Persistence.ReadError if it did not.
	///
	/// - Author: Jeff A. Campbell
	///
	public func read<T>(fromFileNamed fileName:String, asType type:T.Type, location:Persistence.FileLocation, completion: @escaping (Result<T, ReadError>) -> Void) where T : Decodable {
		guard let locationDirectoryURL = self.directoryURL(forLocation: location) else {
			completion(.failure(ReadError.invalidDirectory))
			return
		}

		let fileURL				= locationDirectoryURL.appendingPathComponent(fileName)

		if FileManager.default.fileExists(atPath: fileURL.path) == false {
			completion(.failure(ReadError.fileDoesNotExist))
		} else {
			NSFileCoordinator().coordinate(readingItemAt: fileURL, options: [], error: nil) { [weak self] (readURL) in
				guard let _self = self else {
					completion(.failure(ReadError.failed))
					return
				}

				if let data = FileManager.default.contents(atPath: readURL.path) {
					if let instance = try? _self.jsonDecoder.decode(type, from: data) {
						completion(.success(instance))
					} else {
						completion(.failure(ReadError.failed))
					}


//					do {
//						let instance				= try _self.jsonDecoder.decode(type, from: data)
//
//						completion(.success(instance))
//					} catch _ {
//						completion(.failure(ReadError.failed))
//					}
				} else {
					completion(.failure(ReadError.failed))
				}
			}
		}
	}
}

extension Persistence {
	/// Returns a string for use in versioned subdirectories. Based on the current `CFBundleVersion` (application build number),
	///
	/// - Returns:
	///     - A string for use with versioned subdirectory names.
	///
	/// - Author: Jeff A. Campbell
	///
	private func stringForBuildNumber() -> String {
		var buildString:String = ""

		guard let infoDictionary = Bundle.main.infoDictionary else {
			return ""
		}

		if let buildVersion = infoDictionary["CFBundleVersion"] as? String {
			buildString  = buildVersion
		}

		return buildString
	}

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
