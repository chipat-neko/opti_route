# ML Kit Text Recognition : on n'utilise QUE le script latin.
# R8 se plaint des classes japonais/coreen/chinois manquantes au moment
# du minify -- on les ignore proprement, le runtime ne les charge pas.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
