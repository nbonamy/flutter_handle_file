String androidManifestTemplate(
  String fileExtension,
  String mimeType,
) {
  return '''
            <intent-filter>
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <data android:scheme="file"/>
                <data android:host="*"/>
                <data android:pathPattern=".*\\.$fileExtension"/>
            </intent-filter>
            <intent-filter>
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <category android:name="android.intent.category.BROWSABLE"/>
                <data android:mimeType="*/*"/>
                <data
                    android:host="*"
                    android:scheme="content"
                    android:pathPattern=".*\\.$fileExtension"/>
                <data
                    android:host="*"
                    android:scheme="file"
                    android:pathPattern=".*\\.$fileExtension"/>
            </intent-filter>
            <intent-filter>
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.BROWSABLE"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <data
                    android:host="*"
                    android:scheme="file"
                    android:pathPattern=".*\\.$fileExtension"
                    android:mimeType="text/plain"/>
                <data
                    android:host="*"
                    android:scheme="content"
                    android:pathPattern=".*\\.$fileExtension"
                    android:mimeType="text/plain"/>
            </intent-filter>
            <intent-filter>
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.BROWSABLE"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <data
                    android:host="*"
                    android:scheme="file"
                    android:pathPattern=".*\\.$fileExtension"
                    android:mimeType="application/octet-stream"/>
                <data
                    android:host="*"
                    android:scheme="content"
                    android:pathPattern=".*\\.$fileExtension"
                    android:mimeType="application/octet-stream"/>
            </intent-filter>
            <intent-filter>
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.BROWSABLE"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <data
                    android:host="*"
                    android:scheme="file"
                    android:pathPattern=".*\\.$fileExtension"
                    android:mimeType="$mimeType"/>
                <data
                    android:host="*"
                    android:scheme="content"
                    android:pathPattern=".*\\.$fileExtension"
                    android:mimeType="$mimeType"/>
            </intent-filter>''';
}

String iosInfoPlistTemplate(
  String bundleIdentifier,
  String bundleTypeName,
  String fileExtension,
  String mimeType,
) {
  return '''
	<key>CFBundleDocumentTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeName</key>
			<string>$bundleTypeName</string>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>LSHandlerRank</key>
			<string>Owner</string>
			<key>LSItemContentTypes</key>
			<array>
				<string>$bundleIdentifier.ttm</string>
			</array>
		</dict>
	</array>
	<key>UTExportedTypeDeclarations</key>
	<array>
		<dict>
			<key>UTTypeConformsTo</key>
			<array>
				<string>public.data</string>
			</array>
			<key>UTTypeDescription</key>
			<string>$bundleTypeName</string>
			<key>UTTypeIdentifier</key>
			<string>$bundleIdentifier.ttm</string>
			<key>UTTypeSize64IconFile</key>
			<string></string>
			<key>UTTypeTagSpecification</key>
			<dict>
				<key>public.filename-extension</key>
				<array>
					<string>$fileExtension</string>
				</array>
				<key>public.mime-type</key>
				<string>$mimeType</string>
			</dict>
		</dict>
	</array>''';
}

String iosAdditionalConfiguration(bool supportsInPlace) {
  return '''
	<key>LSSupportsOpeningDocumentsInPlace</key>
	<${supportsInPlace == true ? 'true' : 'false'}/>''';
}
