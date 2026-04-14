package com.example.posipv

import android.app.Activity
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Debug
import android.print.PrintAttributes
import android.print.PrintManager
import android.provider.Settings
import android.util.Base64
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.net.InetSocketAddress
import java.net.Socket
import java.security.KeyFactory
import java.security.PublicKey
import java.security.Signature
import java.security.spec.X509EncodedKeySpec

class MainActivity : FlutterActivity() {
    companion object {
        private const val DEVICE_CHANNEL = "com.example.posipv/device_identity"
        private const val PICK_BACKUP_FILE_REQUEST = 7194
        private const val PICK_SYNC_FILE_REQUEST = 7195
        private const val LICENSE_PUBLIC_KEY = """
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAzdlxu8PUy6QwhHhqtR2Z
BxqIqHZJKLPET1z+zSrXUrnKcww4h/NsZNMSsCDVfXavyPMLHoAL/YrcQfZOfma6
MZ0DUik+lD6SXHiSuTm6enl3CLDOdFOzgX1jLZHDfcXi7Zqu6hMZP8UV6GY8LgQu
Ck2OF1YPuXA9KlsiRNzfJdr7pZy0CeA22O7qcDXwjLSEeOOvJcbYG2zoXzpPxiRW
uCNonuuIkHQFfL63xE1M4s4Gwv/9dGKYnBAOSmq/OvD+zqJIUA5BmZYfvTlhP/6m
20S1zdDA2J3d1uHEkAM8IkJCv00gJytt2JKMUwHitkQlymknh3Y7hWY0lE9wbuaC
RQIDAQAB
-----END PUBLIC KEY-----
"""
    }
    private var pendingBackupPickerResult: MethodChannel.Result? = null
    private var pendingSyncPickerResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DEVICE_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDeviceIdentity" -> {
                    result.success(
                        mapOf(
                            "hardwareId" to getHardwareId(),
                            "manufacturer" to Build.MANUFACTURER.orEmpty(),
                            "model" to Build.MODEL.orEmpty()
                        )
                    )
                }

                "verifyLicenseSignature" -> {
                    val payload = call.argument<String>("payload").orEmpty()
                    val signature = call.argument<String>("signature").orEmpty()
                    result.success(verifyLicenseSignature(payload, signature))
                }

                "inspectRuntimeSecurity" -> {
                    result.success(inspectRuntimeSecurity())
                }

                "shareText" -> {
                    val text = call.argument<String>("text").orEmpty()
                    val subject = call.argument<String>("subject")
                    result.success(shareText(text, subject))
                }

                "printTicketHtml" -> {
                    val html = call.argument<String>("html").orEmpty()
                    val jobName = call.argument<String>("jobName")
                        ?.trim()
                        ?.takeIf { it.isNotEmpty() }
                        ?: "Ticket POSIPV"
                    printTicketHtml(
                        html = html,
                        jobName = jobName,
                        result = result
                    )
                }

                "pickBackupFile" -> {
                    if (pendingBackupPickerResult != null || pendingSyncPickerResult != null) {
                        result.error(
                            "picker_busy",
                            "Ya hay un selector de archivo abierto.",
                            null
                        )
                        return@setMethodCallHandler
                    }
                    pendingBackupPickerResult = result
                    try {
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "*/*"
                            putExtra(
                                Intent.EXTRA_MIME_TYPES,
                                arrayOf(
                                    "application/octet-stream",
                                    "application/x-sqlite3",
                                    "application/vnd.sqlite3"
                                )
                            )
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
                        }
                        startActivityForResult(intent, PICK_BACKUP_FILE_REQUEST)
                    } catch (e: Exception) {
                        pendingBackupPickerResult = null
                        result.error(
                            "picker_launch_failed",
                            e.message ?: "No se pudo abrir el explorador de archivos.",
                            null
                        )
                    }
                }

                "pickSyncFile" -> {
                    if (pendingBackupPickerResult != null || pendingSyncPickerResult != null) {
                        result.error(
                            "picker_busy",
                            "Ya hay un selector de archivo abierto.",
                            null
                        )
                        return@setMethodCallHandler
                    }
                    pendingSyncPickerResult = result
                    try {
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "*/*"
                            putExtra(
                                Intent.EXTRA_MIME_TYPES,
                                arrayOf(
                                    "application/json",
                                    "text/plain",
                                    "application/octet-stream"
                                )
                            )
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
                        }
                        startActivityForResult(intent, PICK_SYNC_FILE_REQUEST)
                    } catch (e: Exception) {
                        pendingSyncPickerResult = null
                        result.error(
                            "picker_launch_failed",
                            e.message ?: "No se pudo abrir el explorador de archivos.",
                            null
                        )
                    }
                }

                "restartApp" -> {
                    try {
                        restartApplication()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error(
                            "restart_failed",
                            e.message ?: "No se pudo reiniciar la aplicación.",
                            null
                        )
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_BACKUP_FILE_REQUEST && requestCode != PICK_SYNC_FILE_REQUEST) {
            return
        }

        val isBackupPicker = requestCode == PICK_BACKUP_FILE_REQUEST
        val result = if (isBackupPicker) {
            pendingBackupPickerResult
        } else {
            pendingSyncPickerResult
        }
        if (isBackupPicker) {
            pendingBackupPickerResult = null
        } else {
            pendingSyncPickerResult = null
        }
        if (result == null) {
            return
        }

        if (resultCode != Activity.RESULT_OK) {
            result.success(null)
            return
        }

        val uri: Uri = data?.data ?: run {
            result.success(null)
            return
        }

        try {
            try {
                contentResolver.takePersistableUriPermission(
                    uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION
                )
            } catch (_: Exception) {
            }

            val targetSuffix = if (isBackupPicker) "db" else "json"
            val targetPrefix = if (isBackupPicker) "picked-backup" else "picked-sync"
            val target = File(cacheDir, "$targetPrefix-${System.currentTimeMillis()}.$targetSuffix")
            contentResolver.openInputStream(uri).use { input ->
                if (input == null) {
                    throw IllegalStateException("No se pudo abrir el archivo seleccionado.")
                }
                target.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
            result.success(target.absolutePath)
        } catch (e: Exception) {
            result.error(
                if (isBackupPicker) "pick_backup_failed" else "pick_sync_failed",
                e.message
                    ?: if (isBackupPicker) {
                        "No se pudo leer la copia seleccionada."
                    } else {
                        "No se pudo leer el archivo de sincronización seleccionado."
                    },
                null
            )
        }
    }

    private fun getHardwareId(): String {
        return Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ANDROID_ID
        )?.trim().orEmpty()
    }

    private fun restartApplication() {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        if (launchIntent == null) return
        launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
        startActivity(launchIntent)
        finishAffinity()
    }

    private fun verifyLicenseSignature(
        payloadSegment: String,
        signatureSegment: String
    ): Boolean {
        return try {
            if (payloadSegment.isBlank() || signatureSegment.isBlank()) {
                return false
            }

            val verifier = Signature.getInstance("SHA256withRSA")
            verifier.initVerify(loadPublicKey())
            verifier.update(payloadSegment.toByteArray(Charsets.UTF_8))
            verifier.verify(decodeBase64Url(signatureSegment))
        } catch (_: Exception) {
            false
        }
    }

    private fun loadPublicKey(): PublicKey {
        val normalized = LICENSE_PUBLIC_KEY
            .replace("-----BEGIN PUBLIC KEY-----", "")
            .replace("-----END PUBLIC KEY-----", "")
            .replace("\\s".toRegex(), "")
        val keyBytes = Base64.decode(normalized, Base64.DEFAULT)
        val spec = X509EncodedKeySpec(keyBytes)
        return KeyFactory.getInstance("RSA").generatePublic(spec)
    }

    private fun decodeBase64Url(value: String): ByteArray {
        val normalized = value
            .replace('-', '+')
            .replace('_', '/')
            .let { candidate ->
                when (candidate.length % 4) {
                    2 -> "$candidate=="
                    3 -> "$candidate="
                    else -> candidate
                }
            }
        return Base64.decode(normalized, Base64.DEFAULT)
    }

    private fun inspectRuntimeSecurity(): Map<String, Any> {
        val checkedAt = System.currentTimeMillis()
        val hasSuBinary = hasAnyFile(
            listOf(
                "/system/bin/su",
                "/system/xbin/su",
                "/sbin/su",
                "/su/bin/su",
                "/system/app/Superuser.apk"
            )
        )
        val hasRootManagementApp = hasAnyInstalledPackage(
            listOf(
                "com.topjohnwu.magisk",
                "eu.chainfire.supersu",
                "com.koushikdutta.superuser",
                "com.kingroot.kinguser",
                "com.devadvance.rootcloak"
            )
        )
        val hasXposedFiles = hasAnyFile(
            listOf(
                "/system/framework/XposedBridge.jar",
                "/system/lib/libxposed_art.so",
                "/system/lib64/libxposed_art.so"
            )
        )
        val hasFridaFiles = hasAnyFile(
            listOf(
                "/data/local/tmp/frida-server",
                "/data/local/tmp/re.frida.server",
                "/data/local/tmp/frida-gadget.so"
            )
        )
        val hasSuspiciousFiles = hasAnyFile(
            listOf(
                "/system/bin/.ext/.su",
                "/system/usr/we-need-root/su-backup",
                "/system/xbin/mu"
            )
        )
        val isDebugBuild =
            (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        val hasFridaPort = hasOpenLocalPort(27042) || hasOpenLocalPort(27043)

        return mapOf(
            "checkedAt" to checkedAt,
            "isSupported" to true,
            "isDebugBuild" to isDebugBuild,
            "isDebuggerAttached" to (Debug.isDebuggerConnected() || Debug.waitingForDebugger()),
            "isEmulator" to isProbablyEmulator(),
            "hasTestKeys" to (Build.TAGS?.contains("test-keys") == true),
            "hasSuBinary" to hasSuBinary,
            "hasRootManagementApp" to hasRootManagementApp,
            "hasXposedFiles" to hasXposedFiles,
            "hasXposedClasses" to hasXposedClasses(),
            "hasFridaFiles" to hasFridaFiles,
            "hasFridaPort" to hasFridaPort,
            "hasSuspiciousFiles" to hasSuspiciousFiles,
            "adbEnabled" to isAdbEnabled()
        )
    }

    private fun isProbablyEmulator(): Boolean {
        val fingerprint = Build.FINGERPRINT.orEmpty()
        val model = Build.MODEL.orEmpty()
        val manufacturer = Build.MANUFACTURER.orEmpty()
        val brand = Build.BRAND.orEmpty()
        val device = Build.DEVICE.orEmpty()
        val product = Build.PRODUCT.orEmpty()
        val hardware = Build.HARDWARE.orEmpty()

        return fingerprint.startsWith("generic") ||
            fingerprint.contains("emulator", ignoreCase = true) ||
            fingerprint.contains("vbox", ignoreCase = true) ||
            model.contains("Emulator", ignoreCase = true) ||
            model.contains("Android SDK built for", ignoreCase = true) ||
            manufacturer.contains("Genymotion", ignoreCase = true) ||
            brand.startsWith("generic") && device.startsWith("generic") ||
            product.contains("sdk", ignoreCase = true) ||
            hardware.contains("goldfish", ignoreCase = true) ||
            hardware.contains("ranchu", ignoreCase = true)
    }

    private fun hasXposedClasses(): Boolean {
        return try {
            Class.forName("de.robv.android.xposed.XposedBridge")
            true
        } catch (_: Throwable) {
            try {
                Class.forName("com.saurik.substrate.MS")
                true
            } catch (_: Throwable) {
                false
            }
        }
    }

    private fun hasAnyInstalledPackage(packageNames: List<String>): Boolean {
        return packageNames.any { packageName -> isPackageInstalled(packageName) }
    }

    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.getPackageInfo(
                    packageName,
                    PackageManager.PackageInfoFlags.of(0)
                )
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(packageName, 0)
            }
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun hasAnyFile(paths: List<String>): Boolean {
        return paths.any { path -> File(path).exists() }
    }

    private fun hasOpenLocalPort(port: Int): Boolean {
        return try {
            Socket().use { socket ->
                socket.connect(InetSocketAddress("127.0.0.1", port), 80)
                true
            }
        } catch (_: Exception) {
            false
        }
    }

    private fun isAdbEnabled(): Boolean {
        return try {
            Settings.Global.getInt(contentResolver, Settings.Global.ADB_ENABLED, 0) == 1
        } catch (_: Exception) {
            false
        }
    }

    private fun shareText(text: String, subject: String?): Boolean {
        if (text.isBlank()) {
            return false
        }
        return try {
            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, text)
                if (!subject.isNullOrBlank()) {
                    putExtra(Intent.EXTRA_SUBJECT, subject)
                }
            }
            startActivity(Intent.createChooser(shareIntent, "Compartir"))
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun printTicketHtml(
        html: String,
        jobName: String,
        result: MethodChannel.Result
    ) {
        if (html.isBlank()) {
            result.error(
                "print_invalid_input",
                "No hay contenido para imprimir.",
                null
            )
            return
        }
        runOnUiThread {
            try {
                val printManager = getSystemService(PRINT_SERVICE) as? PrintManager
                if (printManager == null) {
                    result.error(
                        "print_unavailable",
                        "El servicio de impresion no esta disponible.",
                        null
                    )
                    return@runOnUiThread
                }
                val webView = WebView(this)
                var completed = false
                webView.settings.javaScriptEnabled = false
                webView.webViewClient = object : WebViewClient() {
                    override fun onPageFinished(view: WebView?, url: String?) {
                        super.onPageFinished(view, url)
                        if (completed) {
                            return
                        }
                        completed = true
                        try {
                            val printAdapter = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                                webView.createPrintDocumentAdapter(jobName)
                            } else {
                                @Suppress("DEPRECATION")
                                webView.createPrintDocumentAdapter()
                            }
                            printManager.print(
                                jobName,
                                printAdapter,
                                PrintAttributes.Builder().build()
                            )
                            result.success(true)
                        } catch (e: Exception) {
                            result.error(
                                "print_failed",
                                e.message ?: "No se pudo iniciar la impresion.",
                                null
                            )
                        } finally {
                            webView.postDelayed({ webView.destroy() }, 800)
                        }
                    }
                }
                webView.loadDataWithBaseURL(
                    null,
                    html,
                    "text/HTML",
                    "UTF-8",
                    null
                )
            } catch (e: Exception) {
                result.error(
                    "print_failed",
                    e.message ?: "No se pudo preparar la impresion.",
                    null
                )
            }
        }
    }
}
