// Copyright 2018 Evo Stamatov. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';

const MethodChannel _mChannel = const MethodChannel('flutter_handle_file/messages');
const EventChannel _eChannel = const EventChannel('flutter_handle_file/events');
Stream<String> _stream;

/// Returns a [Future], which completes to one of the following:
///
///   * the initially stored link (possibly null), on successful invocation;
///   * a [PlatformException], if the invocation failed in the platform plugin.
Future<String> getInitialFile() async {
  final String initialFile = await _mChannel.invokeMethod('getInitialFile');
  if (initialFile == null) return null;
  return Uri.parse(initialFile)?.path;
}

/// A convenience method that returns the initially stored link
/// as a new [Uri] object.
///
/// If the link is not valid as a URI or URI reference,
/// a [FormatException] is thrown.
Future<Uri> getInitialUri() async {
  final String link = await _mChannel.invokeMethod('getInitialFile');
  if (link == null) return null;
  return Uri.parse(link);
}

/// Sets up a broadcast stream for receiving incoming link change events.
///
/// Returns a broadcast [Stream] which emits events to listeners as follows:
///
///   * a decoded data ([String]) event (possibly null) for each successful
///   event received from the platform plugin;
///   * an error event containing a [PlatformException] for each error event
///   received from the platform plugin.
///
/// Errors occurring during stream activation or deactivation are reported
/// through the `FlutterError` facility. Stream activation happens only when
/// stream listener count changes from 0 to 1. Stream deactivation happens
/// only when stream listener count changes from 1 to 0.
Stream<String> getStream() {
  if (_stream == null) {
    _stream = _eChannel.receiveBroadcastStream().cast<String>();
  }
  return _stream;
}

/// A convenience transformation of the stream to a `Stream<String>`.
///
/// If the link is not valid as a URI or URI reference,
/// a [FormatException] is thrown.
///
/// Refer to `getLinksStream` about error/exception details.
///
/// If the app was stared by a link intent or user activity the stream will
/// not emit that initial uri - query either the `getInitialFile` instead.
Stream<String> getFilesStream() {
  return getStream().transform<String>(
    new StreamTransformer<String, String>.fromHandlers(
      handleData: (String link, EventSink<String> sink) {
        if (link == null) {
          sink.add(null);
        } else {
          sink.add(Uri.parse(link)?.path);
        }
      },
    ),
  );
}


/// A convenience transformation of the stream to a `Stream<Uri>`.
///
/// If the link is not valid as a URI or URI reference,
/// a [FormatException] is thrown.
///
/// Refer to `getLinksStream` about error/exception details.
///
/// If the app was stared by a link intent or user activity the stream will
/// not emit that initial uri - query either the `getInitialUri` instead.
Stream<Uri> getUriFilesStream() {
  return getStream().transform<Uri>(
    new StreamTransformer<String, Uri>.fromHandlers(
      handleData: (String link, EventSink<Uri> sink) {
        if (link == null) {
          sink.add(null);
        } else {
          sink.add(Uri.parse(link));
        }
      },
    ),
  );
}
