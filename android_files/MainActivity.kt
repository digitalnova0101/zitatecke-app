package __PACKAGE__

import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "zitatecke/whatsapp")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shareImage" -> {
                        val path = call.argument<String>("path")
                        val text = call.argument<String>("text")
                        result.success(path != null && shareToWhatsApp(path, text))
                    }
                    "email" -> result.success(
                        sendEmail(
                            call.argument<String>("to") ?: "",
                            call.argument<String>("subject") ?: "",
                            call.argument<String>("body") ?: "",
                        )
                    )
                    "open" -> result.success(openUrl(call.argument<String>("url") ?: ""))
                    "deviceInfo" -> result.success(
                        "Android ${android.os.Build.VERSION.RELEASE} (SDK ${android.os.Build.VERSION.SDK_INT}), " +
                            "${android.os.Build.MANUFACTURER} ${android.os.Build.MODEL}"
                    )
                    else -> result.notImplemented()
                }
            }
    }

    /** E-Mail-App mit Empfänger, Betreff und Text öffnen. */
    private fun sendEmail(to: String, subject: String, body: String): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_SENDTO).apply {
                data = android.net.Uri.parse("mailto:")
                putExtra(Intent.EXTRA_EMAIL, arrayOf(to))
                putExtra(Intent.EXTRA_SUBJECT, subject)
                putExtra(Intent.EXTRA_TEXT, body)
            }
            startActivity(Intent.createChooser(intent, "E-Mail senden"))
            true
        } catch (e: Exception) {
            false
        }
    }

    /** Link öffnen (Play Store, Browser). market:// fällt auf https zurück. */
    private fun openUrl(url: String): Boolean {
        return try {
            startActivity(Intent(Intent.ACTION_VIEW, android.net.Uri.parse(url)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            true
        } catch (e: Exception) {
            if (url.startsWith("market://")) {
                openUrl(url.replace("market://details", "https://play.google.com/store/apps/details"))
            } else {
                false
            }
        }
    }

    /** Image seedha WhatsApp (ya WhatsApp Business) mein kholta hai. */
    private fun shareToWhatsApp(path: String, text: String?): Boolean {
        return try {
            val uri = FileProvider.getUriForFile(this, "$packageName.zitatecke_files", File(path))
            for (pkg in listOf("com.whatsapp", "com.whatsapp.w4b")) {
                val intent = Intent(Intent.ACTION_SEND).apply {
                    type = "image/png"
                    setPackage(pkg)
                    putExtra(Intent.EXTRA_STREAM, uri)
                    if (!text.isNullOrEmpty()) putExtra(Intent.EXTRA_TEXT, text)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                if (intent.resolveActivity(packageManager) != null) {
                    startActivity(intent)
                    return true
                }
            }
            false
        } catch (e: Exception) {
            false
        }
    }
}
