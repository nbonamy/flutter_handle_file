# Flutter Handle File

[![Travis' Continuous Integration build status](https://api.travis-ci.org/nbonamy/flutter_handle_file.svg?branch=master)](https://travis-ci.org/nbonamy/flutter_handle_file)

A Flutter plugin project to help with associating files with your app and handling the opening of such files.

Make sure you read both the Installation and the Usage guides.

This work is more than heavily derived from https://github.com/avioli/uni_links.

## Installation

To use the plugin, add `flutter_handle_file` as a
[dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).


### Permission

Android will need to be able to read and write from local storage. You need to add the following permissions to your manifest:

```xml
<uses-permission android:name="android.permission.WRITE_INTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### Setup

The plugin can add the required entries both in your `AndroidManifest.xml` and `Info.plist` files. In order to do this, you need to add a specific `flutter_handle_file` section to your `pubspec.yaml` file:

```yml
flutter_handle_file:
  bundle_identifier: <iOS bundle identifier>
  bundle_type_name: <Description of your file (iOS only)>
  extensions:
    - <extension1>: <associated mime type>
    - <extension2>: <associated mime type>
```

In most cases you should be able to use `$(PRODUCT_BUNDLE_IDENTIFIER)` for the `bundle_identifier` key.

For instance, your final configuration could be:

```yml
flutter_handle_file:
  bundle_identifier: $(PRODUCT_BUNDLE_IDENTIFIER)
  bundle_type_name: Portable Document Format
  extensions:
    - pdf: application/pdf
```

Once this is ready, you can ask `flutter_handle_file` to add the appropriate entries in `AndroidManifest.xml` and `Info.plist`:

```sh
flutter pub run flutter_handle_file:main
```

### Specific platform configuration

You can also specify the `in_place` option for iOS. By default the `LSSupportsOpeningDocumentsInPlace` key will be created with the `false` value. Please check [this page](https://developer.apple.com/document-based-apps/) for more details about this value.

## Usage

There are two ways your app will receive a file - from cold start and brought.

### Initial File

Returns the link that the app was started with, if any.

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter_handle_file/flutter_handle_file.dart';

// ...

  Future<Null> initHandleFile() async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      String initialFile = await getInitialFile();
      if (initialFile != null) {
        // do something with the file
      }
    } on PlatformException {
      // Handle exception by warning the user their action did not succeed
      // return?
    }
  }

// ...
```

### On change event (String)

Usually you would check the `getInitialFile` and also listen for changes.

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter_handle_file/flutter_handle_file.dart';

// ...

  StreamSubscription _sub;

  Future<Null> initHandleFile() async {
    // ... check initialFile

    // Attach a listener to the stream
    _sub = getFilesStream().listen((String link) {
      if (file != null) {
        // do something with the file
      }
    }, onError: (err) {
      // Handle exception by warning the user their action did not succeed
    });

    // NOTE: Don't forget to call _sub.cancel() in dispose()
  }

// ...
```

### More about app start from a link

If the app was terminated (or rather not running in the background) and the OS
must start it anew - that's a cold start. In that case, `getInitialFile` will
have the link that started your app and the Stream won't produce a link (at
that point in time).

Alternatively - if the app was running in the background and the OS must bring
it to the foreground the Stream will be the one to produce the link, while
`getInitialFile` will be either `null`, or the initial link, with which the
app was started.

Because of these two situations - you should always add a check for the
initial link (or URI) and also subscribe for a Stream of links (or URIs).


## Tools for launching files

### Android

On Android, you need to use adb to push a local file to the device.

```
adb push <local_file> /sdcard/
```

You can then use the `Files` application on the device (or emulator) to click on the file.

### iOS

Assuming you've got Xcode already installed:

```sh
/usr/bin/xcrun simctl openurl booted "file://<local_file>"
```

If you've got `xcrun` (or `simctl`) in your path, you could invoke it directly.

The flag `booted` assumes an open simulator (you can start it via
`open -a Simulator`) with a booted device. You could target specific device by
specifying its UUID (found via `xcrun simctl list` or `flutter devices`),
replacing the `booted` flag.

## Contributing

For help on editing plugin code, view the
[documentation](https://flutter.io/platform-plugins/#edit-code).
