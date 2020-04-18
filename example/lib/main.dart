import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_handle_file/flutter_handle_file.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  String _latestFile = 'Unknown';
  Uri _latestUri;

  StreamSubscription _sub;

  final List<String> _cmds = getCmds();
  final TextStyle _cmdStyle = const TextStyle(
    fontFamily: 'Courier',
    fontSize: 12.0,
    fontWeight: FontWeight.w700,
  );
  final _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  initState() {
    super.initState();
    initPlatformState();
  }

  @override
  dispose() {
    if (_sub != null) _sub.cancel();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  initPlatformState() async {
    await initPlatformStateForStringHandleFile();
    await initPlatformStateForUriHandleFile();
  }

  /// An implementation using a [String] link
  initPlatformStateForStringHandleFile() async {
    // Attach a listener to the links stream
    _sub = getFilesStream().listen((String file) {
      if (!mounted) return;
      setState(() {
        _latestFile = file ?? 'Unknown';
      });
    }, onError: (err) {
      if (!mounted) return;
      setState(() {
        _latestFile = 'Failed to get latest link: $err.';
      });
    });

    // Attach a second listener to the stream
    getFilesStream().listen((String link) {
      print('got link: $link');
    }, onError: (err) {
      print('got err: $err');
    });

    // Get the latest link
    String initialFile;
    Uri initialUri;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      initialFile = await getInitialFile();
      initialUri = await getInitialUri();
      print('initial link: $initialFile');
    } on PlatformException {
      initialFile = 'Failed to get initial link.';
      initialUri = null;
    } on FormatException {
      initialFile = 'Failed to parse the initial link as Uri.';
      initialUri = null;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _latestFile = initialFile;
      _latestUri = initialUri;
    });
  }

  /// An implementation using the [Uri] convenience helpers
  initPlatformStateForUriHandleFile() async {
    // Attach a listener to the Uri links stream
    _sub = getUriFilesStream().listen((Uri uri) {
      if (!mounted) return;
      setState(() {
        _latestUri = uri;
      });
    }, onError: (err) {
      if (!mounted) return;
      setState(() {
        _latestUri = null;
      });
    });

    // Attach a second listener to the stream
    getUriFilesStream().listen((Uri uri) {
      print('got uri: ${uri?.path} ${uri?.queryParametersAll}');
    }, onError: (err) {
      print('got err: $err');
    });

    // Get the latest Uri
    Uri initialUri;
    String initialFile;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      initialUri = await getInitialUri();
      print('initial uri: ${initialUri?.path}'
          ' ${initialUri?.queryParametersAll}');
      initialFile = await getInitialFile();
    } on PlatformException {
      initialUri = null;
      initialFile = 'Failed to get initial uri.';
    } on FormatException {
      initialUri = null;
      initialFile = 'Bad parse the initial link as Uri.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _latestUri = initialUri;
      _latestFile = initialFile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        key: _scaffoldKey,
        appBar: new AppBar(
          title: new Text('Plugin example app'),
        ),
        body: new ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(8.0),
          children: <Widget>[
            new ListTile(
              title: const Text('String'),
              subtitle: new Text('$_latestFile'),
            ),
            new ListTile(
              title: const Text('Uri Path'),
              subtitle: new Text('${_latestUri.toString()}'),
            ),
            _cmdsCard(_cmds),
          ],
        ),
      ),
    );
  }

  Widget _cmdsCard(commands) {
    Widget platformCmds;

    if (commands == null) {
      platformCmds = const Center(
        child: const Text('Unsupported platform'),
      );
    } else {
      platformCmds = new Column(
        children: <List<Widget>>[
          [
            const Text(
                'To populate above fields open a terminal shell and run:\n'),
          ],
          intersperse(
            commands.map<Widget>(
              (cmd) => new InkWell(
                onTap: () => _printAndCopy(cmd),
                child: new Text(
                  '\n$cmd\n',
                  style: _cmdStyle,
                ),
              ),
            ),
            const Text('or'),
          ),
          [
            new Text(
                '(tap on any of the above commands to print it to'
                ' the console/logger and copy to the device clipboard.)',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.caption),
          ]
        ].expand((el) => el).toList(),
      );
    }

    return new Card(
      margin: const EdgeInsets.only(top: 20.0),
      child: new Padding(
        padding: const EdgeInsets.all(10.0),
        child: platformCmds,
      ),
    );
  }

  _printAndCopy(String cmd) async {
    print(cmd);
    await Clipboard.setData(new ClipboardData(text: cmd));
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
      content: const Text('Copied to Clipboard'),
    ));
  }
}

List<String> getCmds() {
  if (Platform.isIOS) {
    return [
      '/usr/bin/xcrun simctl openurl booted "file://\$(pwd)/data/test.pdf"'
    ];
  } else if (Platform.isAndroid) {
    return ['adb push ./data/test.pdf /sdcard', 'Use Files app on device'];
  } else {
    return null;
  }
}

List<Widget> intersperse(Iterable<Widget> list, Widget item) {
  List<Widget> initialValue = [];
  return list.fold(initialValue, (all, el) {
    if (all.length != 0) all.add(item);
    all.add(el);
    return all;
  });
}
