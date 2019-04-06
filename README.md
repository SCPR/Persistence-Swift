# Persistence-Swift

Persistence is a data persistence framework for iOS (and, potentially, platforms such as macOS - through it hasn't been extensively tested on them), used to easily persist Codable-conformant classes, structs, etc. to a device (in [JSON format](https://en.wikipedia.org/wiki/JSON)) and read them back easily.

Persistence is written in Swift.

## License

This project is licensed under the MIT license.

## Installation

To integrate this framework into your Xcode project, clone (or otherwise download) it onto your development machine and drag the included _Persistence.xcodeproj_ file into your project's file navigator in Xcode.

Once you have done so, drag the appropriate framework file from the _Products_ group into the Embedded Binaries section of the targets you wish to build it with. Then make sure to _import_ Persistence at the top of any file(s) you wish to use it in.

## Inline Documentation

Option-clicking any method name will provide 'Quick Help' inline documentation for that method.

## Codable

Persistence is designed make persisting Codable-conformant classes, structs, etc. to a device and reading them back simple. But what is Codable?

Codable, supported in Swift 4 and newer, is a protocol that allows for the easy serialization (encoding) and deserialization (decoding) of model instances, usually to/from a format such as JSON (as is the case with Persistence). This is often used to ingest API responses, but can often be of use in saving instance data to a device and loading it back again.

To learn more about the Codable protocol, check out the [official Swift documentation](https://developer.apple.com/documentation/swift/codable).

## Saving Serialized Data

The call below will save an array of `String` instances - which are naturally Codable-conformant - to a file named _Strings.json_ in the app's _Documents_ directory.

```swift
let stringInstances = ["one", "two", "three"]
let fileLocation = Persistence.FileLocation.documentsDirectory(versioned: false)

try? Persistence().save(stringInstances, toFileNamed: "Strings.json", location: fileLocation)
```

The file's contents would look like this:

```json
["one","two","three"]
```

If there is an error, a `SaveError` will be thrown. We silently ignore any thrown errors using the `try?` operator in the example above, but you could catch these using Swift's [do/catch error handling](https://docs.swift.org/swift-book/LanguageGuide/ErrorHandling.html).

## Loading Serialized Data

The process of loading a file is similar to saving it. To do so, use the following method:

```swift
let fileLocation	= Persistence.FileLocation.documentsDirectory(versioned: false)

try? Persistence().load(fromFileNamed: "Strings.json", asType: [String].self, location: fileLocation, completion: { (stringInstances) in
  // Access stringInstances here...
})
```

One major difference is that, as the file has not yet been loaded, you must specify the _expected_ type (in this case, an array of `String` instances, as `[String].self`) that will be loaded. This is to aid with their deserialization.

If the load and deserialization works properly, a `[String]` optional will be returned within the specified completion block. Otherwise, the method will throw a `LoadError` error.

## File Locations

There are various locations within a device's file system where you might wish to save or load files. In the example above, for example, we specified the `Documents` directory.

Depending on your needs, though, you might want to store files in the `Caches` directory, the `Application Support` directory, etc. Various methods provided by `Persistence.FileLocation` will allow you to customize where files are saved. Pass the returned `FileLocation` to the load or save methods and it will take care of the rest.

##### Versioning

Each `FileLocation` method has an optional `versioned` parameter that appends a _version-specific_ subdirectory to the specified location. This is based on the build number of the process running Persistence, so as this is incremented from build to build the file location will change.

This is particularly useful for files that you do not wish to persist between builds, such as a cache.

Note that if you use App Groups to coordinate data between different apps or an app and its extensions, you will want to ensure that they each share the same build number.

##### App Groups

If you use App Groups to coordinate file access between different apps or an app and bundled extensions, there are App Group-specific methods you can use to specify common locations _within_ an App Group by specifying the associated App Group's identifier. Persistence will take care of coordinating reads and writes for you.

## Errors

As mentioned above, saving and loading will throw errors (`SaveError` and `LoadError`, respectively) if they fail.

Common errors for saving include a directory not being writable, a failure in instance serialization, etc. For loading, common errors include the specified file not existing, failing to deserialize correctly, etc.
