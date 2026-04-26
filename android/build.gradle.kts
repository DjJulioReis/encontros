allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Organiza o build dentro da pasta do projeto no disco C
rootProject.layout.buildDirectory.set(file("${rootDir}/../build"))

subprojects {
    val newSubprojectBuildDir = rootProject.layout.buildDirectory.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}