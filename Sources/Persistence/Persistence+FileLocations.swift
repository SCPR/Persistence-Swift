//
//  Persistence+FileLocations.swift
//
//  Created by Jeff A. Campbell on 2/16/18.
//  Copyright © 2019 Southern California Public Radio. All rights reserved.
//

import Foundation

extension Persistence {
	/// The location (containing directory) where a file will be read from and written to.
	///
	/// - Author: Jeff A. Campbell
	///
	public enum FileLocation {
		/// A specified URL.
		///
		/// If versioning is enabled, specifies a subdirectory based on the build number (ie. "/<directory>/1234").
		case url(_ url:URL, versioned: Bool)

		/// Within the Application directory. Optionally within a version-specific subdirectory.
		///
		/// If versioning is enabled, specifies a subdirectory based on the build number (ie. "/<directory>/1234").
		case applicationDirectory(versioned: Bool)

		/// Within the Application directory in a specified App Group. Optionally within a version-specific subdirectory.
		///
		/// If versioning is enabled, specifies a subdirectory based on the build number (ie. "/<directory>/1234").
		case applicationDirectoryInAppGroup(appGroupIdentifier: String, versioned: Bool)

		/// Within the Caches directory. Optionally within a version-specific subdirectory.
		///
		/// If versioning is enabled, specifies a subdirectory based on the build number (ie. "/<directory>/1234").
		case cachesDirectory(versioned: Bool)

		/// Within the Caches directory in a specified App Group. Optionally within a version-specific subdirectory.
		///
		/// If versioning is enabled, specifies a subdirectory based on the build number (ie. "/<directory>/1234").
		case cachesDirectoryInAppGroup(appGroupIdentifier: String, versioned: Bool)

		/// Within the Documents directory. Optionally within a version-specific subdirectory.
		///
		/// If versioning is enabled, specifies a subdirectory based on the build number (ie. "/<directory>/1234").
		case documentsDirectory(versioned: Bool)

		/// Within the Documents directory in a specified App Group. Optionally within a version-specific subdirectory.
		///
		/// If versioning is enabled, specifies a subdirectory based on the build number (ie. "/<directory>/1234").
		case documentsDirectoryInAppGroup(appGroupIdentifier: String, versioned: Bool)

		/// Within the Application Support directory. Optionally within a version-specific subdirectory.
		///
		/// If versioning is enabled, specifies a subdirectory based on the build number (ie. "/<directory>/1234").
		case applicationSupportDirectory(versioned: Bool)

		/// Within the Application Support directory in a specified App Group. Optionally within a version-specific subdirectory.
		///
		/// If versioning is enabled, specifies a subdirectory based on the build number (ie. "/<directory>/1234").
		case applicationSupportDirectoryInAppGroup(appGroupIdentifier: String, versioned: Bool)

		/// Returns a `FileLocation` for the on-device directory of a specified location with an appended directory.
		///
		/// - Parameters:
		///     - name: The directory name to append to the `FileLocation`.
		///
		/// - Returns:
		///     - An optional `FileLocation` for the on-device directory, if it exists.
		///
		/// - Author: Jeff A. Campbell
		///
		public func appendingDirectory(withName name:String) -> FileLocation? {
			guard let locationURL = self.directoryURL() else { return nil }

			let appendingURL = locationURL.appendingPathComponent(name, isDirectory: true)

			let appendedLocation = FileLocation.url(appendingURL, versioned: false)

			return appendedLocation
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
		public func directoryURL() -> URL? {
			var locationDirectoryURL:URL?
			var isVersioned = false

			switch self {
			case .url(let url, let versioned):
				locationDirectoryURL	= url
				isVersioned				= versioned
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
	}
}
