//
//  Persistence.swift
//
//  Created by Jeff A. Campbell on 2/16/18.
//  Copyright © 2019 Southern California Public Radio. All rights reserved.
//

import Foundation

/// This class handles all loading and saving behaviors provided by the Persistence framework.
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

	/// Whether a named file at a specified location is older than a supplied time interval. Optionally specifying that the file is versioned.
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

	/// Saves a `Codable`-compliant class, struct, enum, or collection to a named file at a specified location. Can optionally version the file (so that it does not persist between app versions).
	///
	/// - Parameters:
	///     - encodableItem: A `Codable`-conformant class, struct, enum, or collection.
	///     - fileName: The name of the file to save.
	///     - location: The on-device `FileLocation` where the file is to be saved.
	///
	/// - Author: Jeff A. Campbell
	///
	public func save<T>(_ encodableItem:T, toFileNamed fileName:String, location:Persistence.FileLocation) throws -> Void where T : Encodable {
		guard let locationDirectoryURL = self.directoryURL(forLocation: location) else {
			throw SaveError.invalidDirectory
		}

		if self.createDirectory(locationDirectoryURL) == false {
			throw SaveError.couldNotCreateDirectory
		}

		let fileURL				= locationDirectoryURL.appendingPathComponent(fileName)

		var saved	= false
		do {
			let data				= try self.jsonEncoder.encode(encodableItem)

			NSFileCoordinator().coordinate(writingItemAt: fileURL, options: [], error: nil, byAccessor: { (writeURL) in
				if FileManager.default.createFile(atPath: writeURL.path, contents: data, attributes: nil) == true {
					saved = true
				}
			})
		} catch {
			throw SaveError.couldNotEncode
		}

		if saved == false {
			throw SaveError.failed
		}
	}

	/// Loads a `Codable`-compliant class, struct, enum, or collection from a named file at a specified location. Optionally attempts to load from a version-specific location.
	///
	/// - Parameters:
	///     - fileName: The name of the file to load.
	///     - type: The `Codable`-conformant class, struct, enum, or collection.
	///     - location: The on-device `FileLocation` where the file is to be loaded from.
	///     - completion: A completion handler that returns the loaded class, struct, enum, or collection.
	///
	/// - Author: Jeff A. Campbell
	///
	public func load<T>(fromFileNamed fileName:String, asType type:T.Type, location:Persistence.FileLocation, completion: @escaping (T?) -> Void) throws -> Void where T : Decodable {
		guard let locationDirectoryURL = self.directoryURL(forLocation: location) else {
			throw LoadError.invalidDirectory
		}

		let fileURL				= locationDirectoryURL.appendingPathComponent(fileName)

		if FileManager.default.fileExists(atPath: fileURL.path) == false {
			throw LoadError.fileDoesNotExist
		}

		var loaded	= false
		NSFileCoordinator().coordinate(readingItemAt: fileURL, options: [], error: nil) { [weak self] (readURL) in
			guard let _self = self else {
				return
			}

			let data = FileManager.default.contents(atPath: readURL.path)

			if let data = data {
				do {
					let instance				= try _self.jsonDecoder.decode(type, from: data)

					loaded = true

					completion(instance)
				} catch _ {
				}
			}
		}

		if loaded == false {
			throw LoadError.failed
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
