import os

kts_patch = """
allprojects {
    tasks.matching { it.name.contains("AarMetadata") }.configureEach {
        enabled = false
    }
}

subprojects {
    if (project.state.executed) {
        val androidExt = project.extensions.findByName("android")
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
    } else {
        project.afterEvaluate {
            val androidExt = project.extensions.findByName("android")
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
    }
}
"""

groovy_patch = """
allprojects {
    tasks.matching { it.name.contains("AarMetadata") }.configureEach {
        enabled = false
    }
}

subprojects { project ->
    def configureAndroid = {
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
    if (project.state.executed) {
        configureAndroid()
    } else {
        project.afterEvaluate {
            configureAndroid()
        }
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
