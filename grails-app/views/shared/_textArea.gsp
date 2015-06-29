<div id="${name}" class="cmeditor">
	<style></style>
	<g:if test="${options.menu}"><div  id="cmeditor-${name}-northernpane"><g:render template="/shared/menu" plugin="cmeditor" model="[name:name, options:options]"></g:render></div></g:if>
	<div class="cmeditor-settings"></div>
	<div  id="cmeditor-${name}-centerpane" class="cmeditor-main">
		<g:textArea  name="${name}" value="${value}" />
	</div>
</div>
<script type="text/javascript">

	<plugin:isAvailable name="resources">
	CMEditor.themeBaseURL = "${resource(dir: '/static/lib/codemirror-5.3/theme/')}";
	CMEditor.modeBaseURL = "${resource(dir: '/static/lib/codemirror-5.3/mode/')}";
	</plugin:isAvailable>

	<plugin:isAvailable name="asset-pipeline">
	CMEditor.themeBaseURL = "${assetPath(src: 'codemirror-5.3/theme/')}";
	CMEditor.modeBaseURL = "${assetPath(src: 'codemirror-5.3/mode/')}";
	</plugin:isAvailable>

	$(document).ready(function() {
		var textAreaCMEditorOptions = {
			binding: "${options.binding}",                           //String:  the initial key-binding of the codeMirror
			overlayDefinitionsVar: typeof ${options.overlayDefinitionsVar} !== "undefined" ? ${options.overlayDefinitionsVar} : undefined,
                                                                     //Object or undefined: descriptions for additional highlights and completions
			theme: "${options.theme}",                               //String:  the default theme to use
			menu: ${options.menu},                                   //Boolean: whether to display a menu or not
			hooks:{                                                  //Object: with the keys being event names (see `CMEditor.on`) and the values being functions
				"preMenuInit": function(){if(typeof cmeditor_${name}_preMenuInit != "undefined"){cmeditor_${name}_preMenuInit.apply(this, arguments)}},
				"postMenuInit": function(){if(typeof cmeditor_${name}_postMenuInit != "undefined"){cmeditor_${name}_postMenuInit.apply(this, arguments)}},
			},
			mode: "${options.mode}",
			readOnly: ${options.readOnly},                           //Boolean: whether the whole editor should be read-only
			useSession: ${options.useSession},                       //Boolean: whether to save some settings like theme in the browser's localstorage
			availableThemes: 										 //List of Strings: names of all themes that should be available to the user
				["default", "cobalt", "eclipse", "mbo", "night", "rubyblue", "solarized", "the-matrix", "twilight", "zenburn"],
			availableModes: 										 //List of Strings: names of all modes (file extensions) that should be available to the user
				["htmlmixed", "htmlembedded", "javascript", "xml", "css", "groovy", "java", "properties"],
			preloadModules: false									 //Boolean: whether to load themes and modules at document load or on demand
		}

		textAreaCMEditor($("#${name}"), textAreaCMEditorOptions, "${name}");
	});
</script>
