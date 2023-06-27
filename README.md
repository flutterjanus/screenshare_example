# screen_sharing_call

Example project that implements screensharing support using `Broadcast Extension` and `flutter_call_keep` in ios and `flutter_foreground_task` (for foreground service) in android

## Android Setup
AndroidManifest.xml should look like below
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.screen_sharing_call">
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.CHANGE_NETWORK_STATE" />
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
    <application
        android:label="screen_sharing_call"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <!-- Specifies an Android theme to apply to this Activity as soon as
                 the Android process has started. This theme is visible to the user
                 while the Flutter UI initializes. After that, this theme continues
                 to determine the Window background behind the Flutter UI. -->
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme"
            />
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        <service
            android:foregroundServiceType="mediaProjection"
            android:name="com.pravera.flutter_foreground_task.service.ForegroundService"
            android:stopWithTask="true" />
        <!-- Don't delete the meta-data below.
             This is used by the Flutter tool to generate GeneratedPluginRegistrant.java -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

### IOS setup
follow this [solved issue](https://github.com/flutter-webrtc/flutter-webrtc/issues/1383) for ios setup 

#### TLDR;
- Make sure you are using latest ios version at the time of writing it is 16
- Setup Broadcast Extension using xcode following [official setup](https://github.com/flutter-webrtc/flutter-webrtc/wiki/iOS-Screen-Sharing),[detailed explanation](https://docs.videosdk.live/react-native/guide/video-and-audio-calling-api-sdk/extras/react-native-ios-screen-share)
- finally make sure you have enabled `background Modes` since background processing is only allowed with voip operations so make sure you are using callkeep as used in this example project 