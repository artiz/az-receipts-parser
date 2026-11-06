package dev.artiz.az_budget

import android.Manifest
import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import java.io.File
import androidx.core.app.NotificationCompat
import android.net.Uri
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * Storage Access Framework bridge: the user picks a folder once (Google Drive,
 * Dropbox, iCloud/OneDrive document providers, or local storage) and the app
 * keeps a persisted read/write grant on it. Everything else is plain
 * DocumentsContract: list the folder, read a file, overwrite a file.
 *
 * I/O runs on a worker thread; results are posted back on the main thread.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "dev.artiz.az_budget/files"
    private val reqFolder = 4101
    private val reqDocument = 4102
    private val executor = Executors.newSingleThreadExecutor()
    private var pendingFolder: MethodChannel.Result? = null
    private var pendingDocument: MethodChannel.Result? = null

    private val notificationChannelName = "dev.artiz.az_budget/notifications"
    private val limitsChannelId = "limits"

    /** Files shared into the app, waiting for the Dart side to ask for them. */
    private val shareChannelName = "dev.artiz.az_budget/share"
    private var shareChannel: MethodChannel? = null
    private val pendingShares = mutableListOf<Map<String, Any?>>()

    /** The Dart side has asked for pending shares once, so it listens from now on. */
    private var dartListens = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (savedInstanceState == null) handleShareIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleShareIntent(intent)
    }

    /** Copies every shared stream into the cache and hands the list to Dart (or queues it). */
    private fun handleShareIntent(intent: Intent?) {
        if (intent == null) return
        val action = intent.action ?: return
        val uris = mutableListOf<Uri>()
        when (action) {
            Intent.ACTION_SEND -> intent.getParcelableExtraCompat(Intent.EXTRA_STREAM)?.let { uris.add(it) }
            Intent.ACTION_SEND_MULTIPLE -> intent.getParcelableArrayListExtraCompat(Intent.EXTRA_STREAM)?.let { uris.addAll(it) }
            Intent.ACTION_VIEW -> intent.data?.let { uris.add(it) }
            else -> return
        }
        val text = if (action == Intent.ACTION_SEND && uris.isEmpty()) intent.getStringExtra(Intent.EXTRA_TEXT) else null
        // Consumed: a recreated activity must not share the same files again.
        intent.action = Intent.ACTION_MAIN
        intent.removeExtra(Intent.EXTRA_STREAM)
        intent.removeExtra(Intent.EXTRA_TEXT)
        executor.execute {
            val items = mutableListOf<Map<String, Any?>>()
            for (uri in uris) {
                try {
                    val name = displayName(uri).ifEmpty { "shared" }
                    val mime = contentResolver.getType(uri) ?: guessMime(name)
                    val dir = File(cacheDir, "shared").apply { mkdirs() }
                    val target = File(dir, "${System.currentTimeMillis()}_${name.replace(Regex("[^A-Za-z0-9._-]"), "_")}")
                    contentResolver.openInputStream(uri)?.use { input -> target.outputStream().use { input.copyTo(it) } }
                    items.add(mapOf("path" to target.absolutePath, "mime" to mime, "name" to name))
                } catch (e: Exception) {
                    items.add(mapOf("error" to (e.message ?: e.toString()), "name" to uri.toString()))
                }
            }
            if (text != null && text.isNotBlank()) items.add(mapOf("text" to text, "mime" to "text/plain", "name" to "text"))
            if (items.isEmpty()) return@execute
            runOnUiThread {
                val channel = shareChannel
                if (dartListens && channel != null) channel.invokeMethod("shared", items) else pendingShares.addAll(items)
            }
        }
    }

    private fun guessMime(name: String): String = when (name.substringAfterLast('.', "").lowercase()) {
        "pdf" -> "application/pdf"
        "jpg", "jpeg" -> "image/jpeg"
        "png" -> "image/png"
        "webp" -> "image/webp"
        "txt" -> "text/plain"
        else -> "application/octet-stream"
    }

    @Suppress("DEPRECATION")
    private fun Intent.getParcelableExtraCompat(key: String): Uri? =
        if (Build.VERSION.SDK_INT >= 33) getParcelableExtra(key, Uri::class.java) else getParcelableExtra(key)

    @Suppress("DEPRECATION")
    private fun Intent.getParcelableArrayListExtraCompat(key: String): ArrayList<Uri>? =
        if (Build.VERSION.SDK_INT >= 33) getParcelableArrayListExtra(key, Uri::class.java) else getParcelableArrayListExtra(key)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        shareChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, shareChannelName).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPending" -> {
                        dartListens = true
                        result.success(pendingShares.toList())
                        pendingShares.clear()
                    }
                    "discard" -> {
                        call.argument<String>("path")?.let { File(it).delete() }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, notificationChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> {
                    if (Build.VERSION.SDK_INT >= 33 &&
                        checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
                    ) {
                        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 4201)
                    }
                    result.success(null)
                }
                "show" -> {
                    showNotification(
                        call.argument<Int>("id") ?: 1,
                        call.argument<String>("title") ?: "",
                        call.argument<String>("body") ?: "",
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickFolder" -> pickFolder(result)
                "pickDocument" -> pickDocument(call.argument<List<String>>("mimeTypes") ?: listOf("*/*"), result)
                "hasFolderPermission" -> result.success(hasPermission(Uri.parse(call.argument<String>("uri")!!)))
                "listFiles" -> background(result) { listFiles(Uri.parse(call.argument<String>("uri")!!)) }
                "readFile" -> background(result) { readFile(Uri.parse(call.argument<String>("uri")!!)) }
                "writeFile" -> background(result) {
                    writeFile(Uri.parse(call.argument<String>("uri")!!), call.argument<ByteArray>("bytes")!!)
                    null
                }
                "createFile" -> background(result) {
                    createFile(
                        Uri.parse(call.argument<String>("treeUri")!!),
                        call.argument<String>("name")!!,
                        call.argument<String>("mimeType") ?: "application/octet-stream",
                        call.argument<ByteArray>("bytes")!!,
                    )
                }
                "fileInfo" -> background(result) { fileInfo(Uri.parse(call.argument<String>("uri")!!)) }
                else -> result.notImplemented()
            }
        }
    }

    private fun background(result: MethodChannel.Result, work: () -> Any?) {
        executor.execute {
            try {
                val value = work()
                runOnUiThread { result.success(value) }
            } catch (e: Exception) {
                runOnUiThread { result.error("io", e.message ?: e.toString(), null) }
            }
        }
    }

    private fun pickFolder(result: MethodChannel.Result) {
        if (pendingFolder != null) {
            result.error("busy", "folder picker already open", null)
            return
        }
        pendingFolder = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).addFlags(
            Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                Intent.FLAG_GRANT_PREFIX_URI_PERMISSION,
        )
        startActivityForResult(intent, reqFolder)
    }

    private fun pickDocument(mimeTypes: List<String>, result: MethodChannel.Result) {
        if (pendingDocument != null) {
            result.error("busy", "document picker already open", null)
            return
        }
        pendingDocument = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT)
            .addCategory(Intent.CATEGORY_OPENABLE)
            .setType(if (mimeTypes.size == 1) mimeTypes[0] else "*/*")
            .putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes.toTypedArray())
        startActivityForResult(intent, reqDocument)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            reqFolder -> {
                val result = pendingFolder ?: return
                pendingFolder = null
                val uri = data?.data
                if (resultCode != Activity.RESULT_OK || uri == null) {
                    result.success(null)
                    return
                }
                contentResolver.takePersistableUriPermission(
                    uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
                )
                result.success(mapOf("uri" to uri.toString(), "name" to folderName(uri)))
            }
            reqDocument -> {
                val result = pendingDocument ?: return
                pendingDocument = null
                val uri = data?.data
                if (resultCode != Activity.RESULT_OK || uri == null) {
                    result.success(null)
                    return
                }
                background(result) {
                    mapOf("uri" to uri.toString(), "name" to displayName(uri), "bytes" to readFile(uri))
                }
            }
        }
    }

    private fun showNotification(id: Int, title: String, body: String) {
        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= 26) {
            manager.createNotificationChannel(
                NotificationChannel(limitsChannelId, "Limits", NotificationManager.IMPORTANCE_DEFAULT),
            )
        }
        if (Build.VERSION.SDK_INT >= 33 &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        val open = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(this, limitsChannelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setContentIntent(open)
            .setAutoCancel(true)
            .build()
        manager.notify(id, notification)
    }

    private fun hasPermission(uri: Uri): Boolean =
        contentResolver.persistedUriPermissions.any { it.uri == uri && it.isReadPermission && it.isWritePermission }

    private fun folderName(tree: Uri): String {
        val docId = DocumentsContract.getTreeDocumentId(tree)
        val docUri = DocumentsContract.buildDocumentUriUsingTree(tree, docId)
        return displayName(docUri)
    }

    private fun displayName(uri: Uri): String {
        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { c ->
            if (c.moveToFirst()) return c.getString(0) ?: uri.lastPathSegment ?: ""
        }
        return uri.lastPathSegment ?: ""
    }

    private fun listFiles(tree: Uri): List<Map<String, Any?>> {
        val parentId = DocumentsContract.getTreeDocumentId(tree)
        val children = DocumentsContract.buildChildDocumentsUriUsingTree(tree, parentId)
        val out = ArrayList<Map<String, Any?>>()
        val cols = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
            DocumentsContract.Document.COLUMN_LAST_MODIFIED,
            DocumentsContract.Document.COLUMN_SIZE,
        )
        contentResolver.query(children, cols, null, null, null)?.use { c ->
            while (c.moveToNext()) {
                val id = c.getString(0)
                out.add(
                    mapOf(
                        "uri" to DocumentsContract.buildDocumentUriUsingTree(tree, id).toString(),
                        "name" to c.getString(1),
                        "mimeType" to c.getString(2),
                        "lastModified" to (if (c.isNull(3)) null else c.getLong(3)),
                        "size" to (if (c.isNull(4)) null else c.getLong(4)),
                    ),
                )
            }
        }
        return out
    }

    private fun fileInfo(uri: Uri): Map<String, Any?>? {
        val cols = arrayOf(
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_LAST_MODIFIED,
            DocumentsContract.Document.COLUMN_SIZE,
        )
        contentResolver.query(uri, cols, null, null, null)?.use { c ->
            if (c.moveToFirst()) {
                return mapOf(
                    "name" to c.getString(0),
                    "lastModified" to (if (c.isNull(1)) null else c.getLong(1)),
                    "size" to (if (c.isNull(2)) null else c.getLong(2)),
                )
            }
        }
        return null
    }

    private fun readFile(uri: Uri): ByteArray =
        contentResolver.openInputStream(uri)?.use { it.readBytes() }
            ?: throw IllegalStateException("cannot open $uri")

    private fun writeFile(uri: Uri, bytes: ByteArray) {
        // "wt": truncate, so a shorter file never keeps stale tail bytes.
        val stream = contentResolver.openOutputStream(uri, "wt") ?: throw IllegalStateException("cannot write $uri")
        stream.use { it.write(bytes); it.flush() }
    }

    private fun createFile(tree: Uri, name: String, mimeType: String, bytes: ByteArray): String {
        val parentId = DocumentsContract.getTreeDocumentId(tree)
        val parent = DocumentsContract.buildDocumentUriUsingTree(tree, parentId)
        val created = DocumentsContract.createDocument(contentResolver, parent, mimeType, name)
            ?: throw IllegalStateException("cannot create $name")
        writeFile(created, bytes)
        return created.toString()
    }
}
