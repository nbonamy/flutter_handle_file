// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/flutter_handle_file.dart';

void main() {

  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel mChannel = const MethodChannel('flutter_handle_file/messages');
  final List<MethodCall> log = <MethodCall>[];
  mChannel.setMockMethodCallHandler((MethodCall methodCall) async {
    log.add(methodCall);
  });

  tearDown(() {
    log.clear();
  });

  test('getInitialFile', () async {
    await getInitialFile();
    expect(
      log,
      <Matcher>[isMethodCall('getInitialFile', arguments: null)],
    );
  });

  test('getInitialUri', () async {
    await getInitialUri();
    expect(
      log,
      <Matcher>[isMethodCall('getInitialFile', arguments: null)],
    );
  });

  test('getFilesStream', () async {
    Stream<String> stream = getFilesStream();
    expect(stream, isInstanceOf<Stream<String>>());
  });

  test('getUriFilesStream', () async {
    Stream<Uri> stream = getUriFilesStream();
    expect(stream, isInstanceOf<Stream<Uri>>());
  });
}
