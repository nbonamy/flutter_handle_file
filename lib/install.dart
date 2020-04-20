import 'dart:io';
import 'package:flutter_handle_file/string_templates.dart';
import 'package:yaml/yaml.dart';

class HandleFileInstall {
  final String _yamlKey = 'flutter_handle_file';
  final String _yamlBundleIdentifier = 'bundle_identifier';
  final String _yamlBundleTypeName = 'bundle_type_name';
  final String _yamlExtensions = 'extensions';
  final String _yamlMimeType = 'mime_type';
  final String _yamlIOSInPlace = 'in_place';

  final String _androidManifestFileName =
      'android/app/src/main/AndroidManifest.xml';
  final String _iOSInfoPlistFileName = 'ios/Runner/Info.plist';

  final String _androidActivity = '.MainActivity';

  final String _delimiter = '<!-- flutter_handle_file -->';

  void install(List<String> arguments) {
    // check configuration
    YamlMap config = _loadConfigFile();
    if (!config.containsKey(_yamlBundleIdentifier) ||
        !config.containsKey(_yamlBundleTypeName) ||
        !config.containsKey(_yamlExtensions)) {
      throw new Exception(
          'Configuration expects $_yamlExtensions, $_yamlBundleIdentifier, $_yamlBundleTypeName and $_yamlMimeType');
    }

    // platform configuration
    String andConfiguration = '';
    String iosConfiguration = '';

    // iterate on extensions
    for (YamlMap extensionEntry in config[_yamlExtensions]) {
      String fileExtension = extensionEntry.keys.first;
      String mimeType = extensionEntry.values.first;

      // add to templates
      andConfiguration += androidManifestTemplate(
        fileExtension,
        mimeType,
      );
      iosConfiguration += iosInfoPlistTemplate(
        config[_yamlBundleIdentifier],
        config[_yamlBundleTypeName],
        fileExtension,
        mimeType,
      );
    }

    // add delimiters
    andConfiguration = '$_delimiter\n$andConfiguration\n$_delimiter';

    // add additional configuration
    iosConfiguration += '\n' + iosAdditionalConfiguration(
      config[_yamlIOSInPlace]
    );

    // now add
    updateAndroidManifest(andConfiguration);
    updateIosInfoPlist(iosConfiguration);
  }

  YamlMap _loadConfigFile() {
    final File file = File('pubspec.yaml');
    final String yamlString = file.readAsStringSync();
    final Map yamlMap = loadYaml(yamlString);

    // test
    if (yamlMap == null || !(yamlMap[_yamlKey] is Map)) {
      throw new Exception('$_yamlKey was not found');
    }

    // done
    return yamlMap[_yamlKey];
  }

  void updateAndroidManifest(String andConfiguration) async {
    // read the file
    final File androidManifestFile = File(_androidManifestFileName);
    final List<String> lines = await androidManifestFile.readAsLines();

    // iterate
    bool inActivity = false;
    bool inTargetActivity = false;
    bool inPreviousContent = false;
    List<String> newLines = List();
    for (int x = 0; x < lines.length; x++) {
      // get
      String line = lines[x];

      // delimiter
      if (line.contains(_delimiter)) {
        inPreviousContent = !inPreviousContent;
        continue;
      }

      // end of activity
      if (line.contains('</activity>')) {
        // add our content
        if (inTargetActivity) {
          newLines.addAll(andConfiguration.split('\n'));
        }

        // done
        inActivity = false;
      }

      // start of activity
      if (line.contains('<activity')) {
        inActivity = true;
      }
      if (inActivity && line.contains(_androidActivity)) {
        inTargetActivity = true;
      }

      // done
      if (inPreviousContent == false) {
        newLines.add(line);
      }
    }

    // update
    androidManifestFile.writeAsString(newLines.join('\n'));
    print('Android Manifest updated ($_androidManifestFileName)');
  }

  void updateIosInfoPlist(String iosConfiguration) async {
    // read the file
    final File iOSInfoPlistFile = File(_iOSInfoPlistFileName);
    final List<String> lines = await iOSInfoPlistFile.readAsLines();

    // iterate
    int arrayDictDepth = 0;
    bool inSkippedLines = false;
    List<String> newLines = List();
    for (int x = 0; x < lines.length; x++) {

      // get
      String line = lines[x];

      // count depth
      if (line.contains('<array>') || line.contains('<dict>')) {
        arrayDictDepth++;
      }
      if (line.contains('</array>') || line.contains('</dict>')) {
        if (--arrayDictDepth == 0) {
          inSkippedLines = false;
        }
      }

      // now do we need to skip
      if (line.contains('<key>') && arrayDictDepth == 1) {
        //print('Stop skipping because of $line');
        inSkippedLines = false;
      }
      if (line.contains('CFBundleDocumentTypes') ||
          line.contains('UTExportedTypeDeclarations') ||
          line.contains('LSSupportsOpeningDocumentsInPlace')) {
        //print('Start skipping because of $line');
        inSkippedLines = true;
      }

      // end of dict
      if (line.contains('</plist>')) {
        newLines.insertAll(newLines.length - 1, iosConfiguration.split('\n'));
      }

      // done
      if (inSkippedLines == false && line.trim().length > 0) {
        newLines.add(line);
      }
    }

    // update
    iOSInfoPlistFile.writeAsString(newLines.join('\n'));
    print('Android Manifest updated ($_iOSInfoPlistFileName)');
  }
}
