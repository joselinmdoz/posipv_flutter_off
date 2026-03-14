package com.example.posipv

import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Debug
import android.provider.Settings
import android.util.Base64
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

                else -> result.notImplemented()
            }
        }
    }

    private fun getHardwareId(): String {
        return Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ANDROID_ID
        )?.trim().orEmpty()
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
            startActivity(Intent.createChooser(shareIntent, "Compartir codigo"))
            true
        } catch (_: Exception) {
            false
        }
    }
}
