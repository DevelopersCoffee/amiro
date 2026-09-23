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
    project.evaluationDependsOn(":app")
}

// isar_flutter_libs (3.1.0+1, 2023) predates AGP's namespace requirement and
// relies on the removed AndroidManifest `package` attribute fallback. AGP 9
// dropped that fallback, so builds fail with "Namespace not specified" unless
// we backfill it here from the plugin's own manifest.
subprojects {
    val backfillNamespace: () -> Unit = {
        val androidExt = extensions.findByType(com.android.build.gradle.BaseExtension::class.java)
        if (androidExt != null) {
            if (androidExt.namespace == null) {
                val manifestFile = file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val packageAttr =
                        Regex("package=\"([^\"]+)\"").find(manifestFile.readText())?.groupValues?.get(1)
                    if (packageAttr != null) {
                        androidExt.namespace = packageAttr
                    }
                }
            }
            // isar_flutter_libs (3.1.0+1, 2023) also hardcodes compileSdkVersion
            // 30, too low for several current AndroidX transitive deps (which
            // need 31-34). Bump it to match the app's own compileSdk rather
            // than editing the plugin in the pub cache.
            if ((androidExt.compileSdkVersion?.removePrefix("android-")?.toIntOrNull() ?: 0) < 34) {
                androidExt.compileSdkVersion("android-36")
            }
        }
    }
    // :app's evaluationDependsOn(":app") above can leave some subprojects
    // already evaluated by the time this block runs — afterEvaluate() throws
    // on an already-evaluated project, so branch on state instead of always
    // deferring.
    if (state.executed) backfillNamespace() else afterEvaluate { backfillNamespace() }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
