allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
val sharedBuild = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(sharedBuild)
subprojects {
    layout.buildDirectory.value(sharedBuild.dir(project.name))
    evaluationDependsOn(":app")
}
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
