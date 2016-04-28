package de.rrze.cmeditor

import grails.plugins.*

class GrailsCmeditorGrailsPlugin extends Plugin {

    // the version or versions of Grails the plugin is designed for
    def grailsVersion = "3.1.4 > *"
    // resources that are excluded from plugin packaging
    def pluginExcludes = [
        "grails-app/views/error.gsp"
    ]

    // TODO Fill in these fields
    def title = "CM Editor Plugin" // Headline display name of the plugin
    def author = "Frank Tröger"
    def authorEmail = "frank.troeger@fau.de"
    def description = 'CMEditor is an easy way to use the popular CodeMirror web editor in grails applications'

    def profiles = ['web']

    // URL to the plugin's documentation
    def documentation = "http://grails.org/plugin/grails-cmeditor"

    // Extra (optional) plugin metadata
    def license = "APACHE"
    def organization = [ name: "RRZE", url: "http://www.rrze.de/" ]
    def developers = [ [ name: "t-animal", email: "tilman.adler@fau.de" ] ]
    def issueManagement = [ system: "GITHUB", url: "https://github.com/RRZE-PP/grails-cmeditor/issues" ]
    def scm = [ url: "https://github.com/RRZE-PP/grails-cmeditor" ]


    Closure doWithSpring() { {->
            // TODO Implement runtime spring config (optional)
        }
    }

    void doWithDynamicMethods() {
        // TODO Implement registering dynamic methods to classes (optional)
    }

    void doWithApplicationContext() {
        // TODO Implement post initialization spring config (optional)
    }

    void onChange(Map<String, Object> event) {
        // TODO Implement code that is executed when any artefact that this plugin is
        // watching is modified and reloaded. The event contains: event.source,
        // event.application, event.manager, event.ctx, and event.plugin.
    }

    void onConfigChange(Map<String, Object> event) {
        // TODO Implement code that is executed when the project configuration changes.
        // The event is the same as for 'onChange'.
    }

    void onShutdown(Map<String, Object> event) {
        // TODO Implement code that is executed when the application shuts down (optional)
    }
}
