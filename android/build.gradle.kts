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
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            android.apply {
                compileSdkVersion(36)
                buildToolsVersion("36.0.0")
            }
            
            // Set namespace if missing
            if (android.namespace == null) {
                android.namespace = when (project.name) {
                    "isar_flutter_libs" -> "dev.isar.isar_flutter_libs"
                    else -> "com.petpal.health.${project.name.replace("-", ".")}"
                }
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
