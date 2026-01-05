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
    
    // Configure Java and Kotlin version for all subprojects (including Flutter plugins)
    afterEvaluate {
        val android = project.extensions.findByName("android")
        if (android != null) {
            try {
                // Set Java compatibility
                val compileOptions = android.javaClass.getMethod("getCompileOptions").invoke(android)
                val javaVersion = JavaVersion::class.java.getField("VERSION_17").get(null) as JavaVersion
                compileOptions.javaClass.getMethod("setSourceCompatibility", JavaVersion::class.java)
                    .invoke(compileOptions, javaVersion)
                compileOptions.javaClass.getMethod("setTargetCompatibility", JavaVersion::class.java)
                    .invoke(compileOptions, javaVersion)
                
                // Set Kotlin JVM target
                val kotlinOptions = android.javaClass.getMethod("getKotlinOptions").invoke(android)
                kotlinOptions.javaClass.getMethod("setJvmTarget", String::class.java)
                    .invoke(kotlinOptions, "17")
            } catch (e: Exception) {
                // Ignore if plugin doesn't support this configuration
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
