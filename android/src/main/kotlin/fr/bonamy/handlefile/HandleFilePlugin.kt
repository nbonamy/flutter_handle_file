package fr.bonamy.handlefile

import android.content.BroadcastReceiver
import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.MediaStore
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.io.OutputStream

private const val LOG_TAG = "IntentFileHandler"

/** FlutterIntentFileHandlerPlugin */
class HandleFilePlugin : FlutterPlugin, MethodCallHandler,
    EventChannel.StreamHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var changeReceiver: BroadcastReceiver? = null
    private var initialFile: String? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "flutter_handle_file/messages"
        )
        channel.setMethodCallHandler(this)

        eventChannel =
            EventChannel(flutterPluginBinding.binaryMessenger, "flutter_handle_file/events")
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "getInitialFile") {
            result.success(initialFile)
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onListen(arguments: Any?, events: EventSink?) {
        if (events != null) {
            changeReceiver = createChangeReceiver(events)
        }
    }

    override fun onCancel(arguments: Any?) {
        changeReceiver = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        handleIntent(binding.activity.applicationContext, binding.activity.intent, true)
        binding.addOnNewIntentListener {
            handleIntent(binding.activity.applicationContext, it, false)
            false
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {}

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}

    override fun onDetachedFromActivity() {}

    private fun handleIntent(context: Context, intent: Intent, initial: Boolean) {
        val filename = extractFileFromIntent(context, intent)
        if (filename != null) {
            if (initial) {
                initialFile = filename
            }
            if (changeReceiver != null) {
                changeReceiver!!.onReceive(context, intent)
            }
        }
    }

    private fun createChangeReceiver(events: EventSink): BroadcastReceiver {
        return object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                val dataString: String? = extractFileFromIntent(context, intent)
                if (dataString == null) {
                    events.error("UNAVAILABLE", "File unavailable", null)
                } else {
                    events.success(dataString)
                }
            }
        }
    }

    private fun extractFileFromIntent(context: Context, intent: Intent): String? {
        try {
            val action = intent.action
            if (Intent.ACTION_VIEW == action) {

                val scheme = intent.scheme
                Log.i(LOG_TAG, "Intent scheme = $scheme")
                val resolver = context.contentResolver

                val uri = intent.data!!
                val filename = when {
                    scheme!!.compareTo(ContentResolver.SCHEME_CONTENT) == 0 -> {
                        getContentName(resolver, uri)
                    }
                    scheme.compareTo(ContentResolver.SCHEME_FILE) == 0 -> {
                        uri.lastPathSegment
                    }
                    else -> {
                        null
                    }
                }
                val input = resolver.openInputStream(uri)

                if (filename != null && input != null) {

                    // write a temporary file
                    val cacheDir = context.cacheDir
                    val tempFile = File(cacheDir, filename)
                    inputStreamToFile(input, tempFile)
                    return tempFile.absolutePath
                }
            }
        } catch (e: Exception) {
            Log.e(LOG_TAG, "Error while parsing intent", e)
        }
        return null
    }

    private fun getContentName(resolver: ContentResolver, uri: Uri): String? {
        val cursor =
            resolver.query(uri, arrayOf(MediaStore.MediaColumns.DISPLAY_NAME), null, null, null)
        cursor!!.moveToFirst()
        val nameIndex = cursor.getColumnIndex(MediaStore.MediaColumns.DISPLAY_NAME)
        return if (nameIndex >= 0) {
            val name = cursor.getString(nameIndex)
            cursor.close()
            name
        } else {
            cursor.close()
            null
        }
    }

    private fun inputStreamToFile(`in`: InputStream, file: File) {
        try {
            var size: Int
            val buffer = ByteArray(1024)
            val out: OutputStream = FileOutputStream(file)
            while (`in`.read(buffer).also { size = it } != -1) {
                out.write(buffer, 0, size)
            }
            out.close()
        } catch (e: Exception) {
            Log.e(LOG_TAG, "inputStreamToFile", e)
        }
    }

}
