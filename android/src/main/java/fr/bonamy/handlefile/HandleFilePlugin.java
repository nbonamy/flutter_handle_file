package fr.bonamy.handlefile;

import android.content.BroadcastReceiver;
import android.content.ContentResolver;
import android.content.Context;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.provider.MediaStore;
import android.util.Log;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

//import android.content.IntentFilter;

/** HandleFilePlugin */
public class HandleFilePlugin implements MethodCallHandler, StreamHandler, PluginRegistry.NewIntentListener {

  private static final String LOG_TAG = "HandleFilePlugin";

  private static final String MESSAGES_CHANNEL = "flutter_handle_file/messages";
  private static final String EVENTS_CHANNEL = "flutter_handle_file/events";

  private BroadcastReceiver changeReceiver;
  private Registrar registrar;

  private String initialFile;
  private String latestFile;

  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    // Detect if we've been launched in background
    if (registrar.activity() == null) {
      return;
    }

    HandleFilePlugin instance = new HandleFilePlugin(registrar);

    final MethodChannel mChannel = new MethodChannel(registrar.messenger(), MESSAGES_CHANNEL);
    mChannel.setMethodCallHandler(instance);

    final EventChannel eChannel = new EventChannel(registrar.messenger(), EVENTS_CHANNEL);
    eChannel.setStreamHandler(instance);

    registrar.addNewIntentListener(instance);
  }

  private HandleFilePlugin(Registrar registrar) {
    this.registrar = registrar;
    handleIntent(registrar.context(), registrar.activity().getIntent(), true);
  }

  private String extractFileFromIntent(Context context, Intent intent) {

    try {

      String action = intent.getAction();

      if (Intent.ACTION_VIEW.equals(action)) {

        // get
        String scheme = intent.getScheme();
        Log.i(LOG_TAG, "Intent scheme = " + scheme);
        ContentResolver resolver = context.getContentResolver();

        // needed
        String filename = null;
        InputStream input = null;

        if (scheme.compareTo(ContentResolver.SCHEME_CONTENT) == 0) {
          Uri uri = intent.getData();
          filename = getContentName(resolver, uri);
          input = resolver.openInputStream(uri);
        } else if (scheme.compareTo(ContentResolver.SCHEME_FILE) == 0) {
          Uri uri = intent.getData();
          filename = uri.getLastPathSegment();
          input = resolver.openInputStream(uri);
        }

        // done
        if (filename != null && input != null) {

          // write a temporary file
          File cacheDir = context.getCacheDir();
          File tempFile = new File(cacheDir, filename);
          inputStreamToFile(input, tempFile);
          return tempFile.getAbsolutePath();

        }
      }
    } catch (Exception e) {
      Log.e(LOG_TAG, "Error while parsing intent", e);
    }

    // too bad
    return null;

  }

  private void handleIntent(Context context, Intent intent, Boolean initial) {

    String filename = extractFileFromIntent(context, intent);
    if (filename != null) {
      if (initial) {
        initialFile = filename;
      }
      latestFile = filename;
      if (changeReceiver != null) {
        changeReceiver.onReceive(context, intent);
      }
    }

  }

	private String getContentName(ContentResolver resolver, Uri uri) {
		Cursor cursor = resolver.query(uri, new String[]{MediaStore.MediaColumns.DISPLAY_NAME}, null, null, null);
		cursor.moveToFirst();
		int nameIndex = cursor.getColumnIndex(MediaStore.MediaColumns.DISPLAY_NAME);
		if (nameIndex >= 0) {
			return cursor.getString(nameIndex);
		}
		return null;
	}

  private void inputStreamToFile(InputStream in, File file) {
    try {
      int size = 0;
      byte[] buffer = new byte[1024];
      OutputStream out = new FileOutputStream(file);
      while ((size = in.read(buffer)) != -1) {
        out.write(buffer, 0, size);
      }
      out.close();
    } catch (Exception e) {
      Log.e(LOG_TAG, "inputStreamToFile", e);
    }
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (call.method.equals("getInitialFile")) {
      result.success(initialFile);
      // } else if (call.method.equals("getLatestFile")) {
      //   result.success(latestFile);
    } else {
      result.notImplemented();
    }
  }

  @Override
  public void onListen(Object arguments, EventSink events) {
    changeReceiver = createChangeReceiver(events);
    // registrar.activity().registerReceiver(
    // changeReceiver, new IntentFilter(Intent.ACTION_VIEW));
  }

  @Override
  public void onCancel(Object arguments) {
    // registrar.activity().unregisterReceiver(changeReceiver);
    changeReceiver = null;
  }

  @Override
  public boolean onNewIntent(Intent intent) {
    handleIntent(registrar.context(), intent, false);
    return false;
  }

  private BroadcastReceiver createChangeReceiver(final EventSink events) {
    return new BroadcastReceiver() {
      @Override
      public void onReceive(Context context, Intent intent) {
        String dataString = extractFileFromIntent(context, intent);
        if (dataString == null) {
          events.error("UNAVAILABLE", "File unavailable", null);
        } else {
          events.success(dataString);
        }
      }
    };
  }
}
