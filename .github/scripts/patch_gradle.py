import os

kts_patch = """
subprojects {
    afterEvaluate {
        val androidExt = extensions.findByName("android")
        if (androidExt != null) {
            try {
                val m = androidExt.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                m.invoke(androidExt, 36)
            } catch (e: Exception) {
                try {
                    val m = androidExt.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                    m.invoke(androidExt, 36)
                } catch (e2: Exception) {}
            }
        }
    }
    tasks.matching { it.name.contains("AarMetadata") }.configureEach {
        enabled = false
    }
}
"""

groovy_patch = """
subprojects {
    afterEvaluate { project ->
        if (project.hasProperty('android')) {
            project.android {
                if (namespace != null || it.hasProperty('compileSdk')) {
                    compileSdk 36
                } else {
                    compileSdkVersion 36
                }
            }
        }
    }
    tasks.matching { it.name.contains('AarMetadata') }.configureEach {
        enabled = false
    }
}
"""

if os.path.exists("android/build.gradle.kts"):
    with open("android/build.gradle.kts", "a", encoding="utf-8") as f:
        f.write("\n" + kts_patch + "\n")
    print("Patched android/build.gradle.kts successfully")

if os.path.exists("android/build.gradle"):
    with open("android/build.gradle", "a", encoding="utf-8") as f:
        f.write("\n" + groovy_patch + "\n")
    print("Patched android/build.gradle successfully")
