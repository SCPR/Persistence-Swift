//
//  Persistence+FileLocations.swift
//
//  Created by Jeff A. Campbell on 2/16/18.
//  Copyright © 2019 Southern California Public Radio. All rights reserved.
//

import Foundation

extension Persistence {
	/// The location (containing directory) where a file will be loaded from and saved to.
	///
	/// - Author: Jeff A. Campbell
	///
	public enum FileLocation {
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
	}
}

