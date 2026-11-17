plugins { id("com.android.application"); id("org.jetbrains.kotlin.android"); id("dev.flutter.flutter-gradle-plugin") }
android { namespace="com.elora.app"; compileSdk=flutter.compileSdkVersion; ndkVersion=flutter.ndkVersion
 compileOptions { sourceCompatibility=JavaVersion.VERSION_17; targetCompatibility=JavaVersion.VERSION_17 }
 kotlinOptions { jvmTarget=JavaVersion.VERSION_17.toString() }
 defaultConfig { applicationId="com.elora.app"; minSdk=flutter.minSdkVersion; targetSdk=flutter.targetSdkVersion; versionCode=1; versionName="1.0.0" }
}
flutter { source="../.." }
