package com.gestioncomida.gestioncomida_front

import io.flutter.embedding.android.FlutterActivity
import android.content.Intent

class MainActivity: FlutterActivity() {
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
