allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    afterEvaluate {
        // Backward-compatible fallback for old Android library plugins
        // that do not define namespace in their build.gradle.
        if (plugins.hasPlugin("com.android.library")) {
            val androidExt = extensions.findByName("android") ?: return@afterEvaluate
            try {
                val getNamespace = androidExt.javaClass.methods.firstOrNull {
                    it.name == "getNamespace" && it.parameterCount == 0
                }
                val currentNamespace = getNamespace?.invoke(androidExt) as? String
                if (currentNamespace.isNullOrBlank()) {
                    val setNamespace = androidExt.javaClass.methods.firstOrNull {
                        it.name == "setNamespace" && it.parameterCount == 1
                    }
                    val manifestFile = project.file("src/main/AndroidManifest.xml")
                    val manifestNamespace =
                        if (manifestFile.exists()) {
                            Regex("package\\s*=\\s*\"([^\"]+)\"")
                                .find(manifestFile.readText())
                                ?.groupValues
                                ?.getOrNull(1)
                        } else {
                            null
                        }
                    val fallbackNamespace =
                        manifestNamespace
                            ?: "com.hibiscusefsya.plugins.${project.name.replace('-', '_')}"
                    setNamespace?.invoke(androidExt, fallbackNamespace)
                }

                // Some legacy plugins still compile with very old SDK levels.
                // Force a modern compileSdk so AndroidX resources resolve properly.
                val getCompileSdk = androidExt.javaClass.methods.firstOrNull {
                    it.name == "getCompileSdk" && it.parameterCount == 0
                }
                val currentCompileSdk = (getCompileSdk?.invoke(androidExt) as? Int) ?: 0
                if (currentCompileSdk in 1..33) {
                    val setCompileSdk = androidExt.javaClass.methods.firstOrNull {
                        it.name == "setCompileSdk" && it.parameterCount == 1
                    }
                    val setCompileSdkVersion = androidExt.javaClass.methods.firstOrNull {
                        it.name == "setCompileSdkVersion" && it.parameterCount == 1
                    }
                    when {
                        setCompileSdk != null -> setCompileSdk.invoke(androidExt, 34)
                        setCompileSdkVersion != null -> setCompileSdkVersion.invoke(androidExt, "android-34")
                    }
                }
            } catch (_: Exception) {
                // Ignore and let Gradle report the original configuration error.
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
