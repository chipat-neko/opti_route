# ML Kit Text Recognition : on n'utilise QUE le script latin.
# R8 se plaint des classes japonais/coreen/chinois manquantes au moment
# du minify -- on les ignore proprement, le runtime ne les charge pas.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
# Keep latin (le SEUL script charge au runtime via TextRecognitionScript.latin)
# pour eviter une obfuscation R8 qui ferait crasher l'OCR en release.
-keep class com.google.mlkit.vision.text.latin.** { *; }
-keep class com.google.mlkit.vision.text.** { *; }

# flutter_local_notifications : utilise Gson + TypeToken pour serialiser
# les notifs planifiees. R8 mange les generiques par defaut -> crash
# "Missing type parameter" au cancel(). Issue upstream :
# https://github.com/MaikuB/flutter_local_notifications/issues/1838
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep public class * implements java.lang.reflect.Type
-keep class com.dexterous.** { *; }
