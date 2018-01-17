String assetsFolder = "../grails-app/assets"
String libFolder    = "${assetsFolder}/lib/"
String jsFolder     = "${assetsFolder}/javascripts/"

println "Checking for missing dependencies within ${jsFolder}/cmeditor-dependencies.js"

if (getClass().protectionDomain.codeSource.location.path != new File(getClass().simpleName + '.groovy').canonicalPath) {
    println "Run this script in the folder where it resides!"
    return
}

File f = new File("${jsFolder}/cmeditor-dependencies.js")
f.eachLine { l ->
    if (l.startsWith('//= require')) {
        def target = l.replace('//= require', '').trim()
        def targetFile = new File("${libFolder}${target}.js")
        if (!targetFile.exists()) {
            targetFile = new File("${jsFolder}/${target}.js")
            if (!targetFile.exists()) {
                println "ERROR: $target (${libFolder}${target}) not found!"
            }
        }
    }
}

println "Done."