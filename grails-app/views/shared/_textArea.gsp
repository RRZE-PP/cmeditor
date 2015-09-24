<div id="${name}" class="cmeditor" style="height:100px; overflow:hidden;position:relative">
	<div class="loadingSpinner" style="background-color:#555;opacity:0.8; z-index:10000; height:100%;width:100%;position:absolute;top:0;left:0">&nbsp;</div>
	<style></style>

	<div class="loadingContainer" style="height:0px;overflow:hidden">
		<g:if test="${options.menu}"><div  id="cmeditor-${name}-northernpane"><g:render template="/shared/menu" plugin="cmeditor" model="[name:name, options:options]"></g:render></div></g:if>
		<div class="cmeditor-settings"></div>
		<div  id="cmeditor-${name}-centerpane" class="cmeditor-main">
			<g:textArea  name="${name}" value="${value}" />
		</div>
	</div>
</div>
<script type="text/javascript">
	(function(){
		var initializationSpinner = new Spinner({lines: 9, width: 12, length: 0, radius: 18, corners: 0.9,
		            opacity: 0, trail: 79, shadow: true, className: ""});
		initializationSpinner.spin($("#${name} .loadingSpinner").get(0));
		textAreaCMEditor.on("postInitialization",
					function(){
						$("#${name}").attr('style', '')
						$("#${name} .loadingContainer").children().appendTo("#${name}")
						$("#${name} .loadingSpinner").remove();
						initializationSpinner.stop();
					},
					"${name}");
	})();

	<plugin:isAvailable name="resources">
	textAreaCMEditor.themeBaseURL = "${resource(dir: '/static/lib/codemirror-5.3/theme/')}";
	textAreaCMEditor.modeBaseURL = "${resource(dir: '/static/lib/codemirror-5.3/mode/')}";
	</plugin:isAvailable>

	<plugin:isAvailable name="asset-pipeline">
	textAreaCMEditor.themeBaseURL = "${assetPath(src: 'codemirror-5.3/theme/')}";
	textAreaCMEditor.modeBaseURL = "${assetPath(src: 'codemirror-5.3/mode/')}";
	</plugin:isAvailable>

	if("${name}".length === 125){
		console.log("WARNING: It looks like you forgot to specify a name-attribute in the cmeditor:textArea-tag. No worries, I generated one for you. However this might lead to collisions! You have been warned.");
	}

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
			<g:applyCodec encodeAs="raw"> <%-- do not encode the already encoded json --%>
			availableThemes: ${availableThemes.encodeAsJSON()},      //List of Strings: names of all themes that should be available to the user
			availableModes:  ${availableModes.encodeAsJSON()},       //List of Strings: names of all modes (file extensions) that should be available to the user
			</g:applyCodec>
			preloadModules: ${options.preloadModules}				 //Boolean: whether to load themes and modules at document load or on demand
		}

		textAreaCMEditor($("#${name}"), textAreaCMEditorOptions, "${name}");
	});
</script>
