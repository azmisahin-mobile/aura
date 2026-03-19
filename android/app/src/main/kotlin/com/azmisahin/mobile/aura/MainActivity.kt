package com.azmisahin.mobile.aura

import io.flutter.embedding.android.FlutterActivity
import com.ryanheise.audioservice.AudioServiceActivity // EKLENEN KISIM

// FlutterActivity yerine AudioServiceActivity'den miras alıyoruz
class MainActivity : AudioServiceActivity()