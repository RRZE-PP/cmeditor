#!/bin/bash
VERSION=$1
PLUGIN=cm-editor

curl -i -X PUT -data-binary @grails-${PLUGIN}-${VERSION}.zip http://localhost:8081/artifactory/plugins-release-local/org/grails/plugins/${PLUGIN}/${VERSION}/${PLUGIN}-${VERSION}.zip
curl -i -X PUT -d @target/pom.xml http://localhost:8081/artifactory/plugins-release-local/org/grails/plugins/${PLUGIN}/${VERSION}/${PLUGIN}-${VERSION}.pom
