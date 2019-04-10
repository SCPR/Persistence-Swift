# Persistence-Swift

Persistence is a data persistence framework for iOS and macOS, used to easily persist Codable-conformant classes, structs, etc. to a device (in [JSON format](https://en.wikipedia.org/wiki/JSON)) and read them back easily.

Persistence is written in Swift 5.

## License

This project is licensed under the MIT license.

## Installation

To integrate this framework into your Xcode project, clone (or otherwise download) it onto your development machine and drag the included _Persistence.xcodeproj_ file into your project's file navigator in Xcode.

Once you have done so, drag the appropriate framework file from the _Products_ group into the Embedded Binaries section of the targets you wish to build it with. Then make sure to _import_ the framework at the top of any file(s) you wish to use it in.

## Inline Documentation

Option-clicking any method name will provide 'Quick Help' inline documentation for that method.

## Codable

Persistence is designed make persisting Codable-conformant classes, structs, etc. to a device and reading them back simple. But what is Codable?

Codable, supported in Swift 4 and newer, is a protocol that allows for the easy serialization (encoding) and deserialization (decoding) of model instances, usually to/from a format such as JSON (as is the case with Persistence). This is often used to ingest API responses, but can often be of use in saving instance data to a device and loading it back again.

To learn more about the Codable protocol, check out the [official Swift documentation](https://developer.apple.com/documentation/swift/codable).

## Saving Serialized Data

The call below will save an array of `String` instances - which are naturally Codable-conformant - to a file named _Strings.json_ in the app's _Documents_ directory.

```swift
let stringInstances = ["Steve", "Woz", "Tim", "Jony"]

let fileLocation = Persistence.FileLocation.documentsDirectory(versioned: false)

Persistence().write(stringInstances, toFileNamed: "Strings.json", location: fileLocation)
```

The file's contents would look like this:

```json
["Steve", "Woz", "Tim", "Jony"]
```

The write method returns a `Result` instance - either a `.success()` (if the file is written) or `.failure()` (with a `SaveError`) if it is not. The result is ignored in the example above, but you could handle errors explicitly as follows:

```
let stringInstances = ["Steve", "Woz", "Tim", "Jony"]

let fileLocation = Persistence.FileLocation.documentsDirectory(versioned: false)

let result = Persistence().write(stringInstances, toFileNamed: "Strings.json", location: fileLocation)
switch result {
case .success(_):
   print("Yay!")
case .failure(let error):
   print("Boo! error = \(error.localizedDescription)")
}
```

This is done using Swift 5's new Result functionality. If you are not familiar with it, [this blog post](https://theswiftdev.com/2019/01/28/how-to-use-the-result-type-to-handle-errors-in-swift/) goes into the feature in great detail.

## Loading Serialized Data

The process of loading a file is similar to saving it. To do so, use the following method:

```swift
let fileLocation = Persistence.FileLocation.documentsDirectory(versioned: false)

Persistence().read(fromFileNamed: "Strings.json", asType: [String].self, location: fileLocation, completion: { result in
   let strings = try? result.get()
})
```

One major difference is that, as the file has not yet been loaded, you must specify the _expected_ type (in this case, an array of `String` instances, as `[String].self`) that will be loaded. This is to aid with their deserialization.

This method also returns a Result - this time within the completion closure. As before, you can switch over the result and handle errors (using `LoadError`) individually.

```
let fileLocation = Persistence.FileLocation.documentsDirectory(versioned: false)
Persistence().read(fromFileNamed: "Strings.json", asType: [String].self, location: fileLocation, completion: { result in
   switch result {
   case .success(let strings):
      print("Yay! strings = \(strings)")
   case .failure(let error):
      print("Boo! error = \(error)")
   }
})
```

## File Locations

There are various locations within a device's file system where you might wish to save or load files. In the example above, for example, we specified the `Documents` directory.

Depending on your needs, though, you might want to store files in the `Caches` directory, the `Application Support` directory, etc. Various convenience methods are provided by `Persistence.FileLocation` that allow you to customize where files are saved.

Pass the returned `FileLocation` to the read or write method you wish to use and it will take care of the rest.

##### Versioning

Each `FileLocation` method has an optional `versioned` parameter that, if set to true, appends a _version-specific_ subdirectory to the specified location. This is based on the build number of the process running Persistence, so as this is incremented from build to build the file location will change.

This is particularly useful for files that you do not wish to persist between builds, such as a cache.

Note that if you use App Groups to coordinate data between different apps or an app and its extensions, you will want to ensure that they each share the same build number.

##### App Groups

If you use App Groups to coordinate file access between different apps or an app and bundled extensions, there are App Group-specific methods you can use to specify common locations _within_ an App Group by specifying the associated App Group's identifier. Persistence will take care of coordinating reads and writes for you.

## Other Features

##### Debugging

You can enable debug output by using optional debug level parameter in the Persistence initializer.

```
Persistence(withDebugLevel: .verbose)
```

Choose between `.basic` and `.verbose` options depending on your need for insight into what Persistence is doing, or `.disabled` (the default) for no output.

##### Age Checks

A common operation when using Persistence for caching is checking to see how old a file is on the device. You can do this using the following method:

```
let fileLocation = Persistence.FileLocation.documentsDirectory(versioned: false)

if Persistence().file(isOlderThan: 60 * 10, fileNamed: "Strings.json", location: fileLocation) == true {
   // File is older than 10 minutes...
} else {
   // File is not older than 10 minutes...
}
```

##### URLs

You can see what URL a FileLocation refers to by calling its `directoryURL()` method.

```
let fileLocation = Persistence.FileLocation.documentsDirectory(versioned: false)

let fileLocationURL = fileLocation.directoryURL()

print(fileLocationURL!.path)
```
