<div id="${name}" class="cmeditor">
	<style></style>
	<div id="cmeditor-${name}-northernpane">
		<div class="cmeditor-tab-message" style="display:none;"></div>

		<g:if test="${options.menu}">
				<g:render template="/shared/menu" plugin="cmeditor" model="[name:name, options:options]"></g:render>
		</g:if>
		<div class="cmeditor-settings"></div>
		</div>
	<div class="cmeditor-main">
		<form method="post">
			<div id="cmeditor-${name}-easternpane">
				${bodyContent}
			</div>
			<div id="cmeditor-${name}-centerpane">
				<ul class="docs tabs"></ul>

				<textarea class="cmTarget"></textarea>
			</div>
		</form>
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
		var codeMirrorEditorOptions = {
			addModes: <g:if test="${options.addModes}">${options.addModes}</g:if><g:else>[]</g:else>,
			                                                         //String[]: additional modes to add to the menu //TODO: Do we still need this for some obscure reason, see availableModes?
			ajax:{
				deleteURL: "${ajax.deleteURL}",                      //String:  a document deletion ca be triggered via this url
				updateURL: "${ajax.updateURL}",                      //String:  a document update can be sent to this url
				getURL: "${ajax.getURL}",                            //String:  a document can be acquired via this url
				listURL: "${ajax.listURL}"                           //String:  a list of filenames can be acquired via this url
			},
			binding: "${options.binding}",                           //String:  the initial key-binding of the codeMirror
			defaultContent: "${options.defaultContent}",             //String:  the default content for the editor
			defaultMode: "${options.defaultMode}",                   //String:  the default mode (e.g. 'htmlmixed', 'javascript') for the editor
			defaultDiffBeforeSave: ${options.defaultDiffBeforeSave}, //Boolean: whether a diff should be shown when saving
			hooks:{                                                  //Object; with the keys being event names (see `CMEditor.on`) and the values being functions
				"preMenuInit": function(){if(typeof cmeditor_${name}_preMenuInit != "undefined"){cmeditor_${name}_preMenuInit.apply(this, arguments)}},
				"postMenuInit": function(){if(typeof cmeditor_${name}_postMenuInit != "undefined"){cmeditor_${name}_postMenuInit.apply(this, arguments)}},
				"preSerializeDoc": function(){if(typeof cmeditor_${name}_preSerializeDoc != "undefined"){cmeditor_${name}_preSerializeDoc.apply(this, arguments)}},
				"postSerializeDoc": function(){if(typeof cmeditor_${name}_postSerializeDoc != "undefined"){cmeditor_${name}_postSerializeDoc.apply(this, arguments)}}
			},
			mapping: {
				content: "${mapping.content}",                       //String:  the variable name in ajax calls/responses mapped to the document content
				folder: "${mapping.folder}",                         //String:  the variable name in ajax calls/responses mapped to the document's folder
				idField: "${mapping.idField}",                       //String:  the field by which documents can be identified towards the server
				mode: "${mapping.mode}",                             //String:  the variable name in ajax calls/responses mapped to the document mode
				name: "${mapping.name}",                             //String:  the variable name in ajax calls/responses mapped to the document name
			},
			menu: ${options.menu},                                   //Boolean: whether to display a menu or not
			overlayDefinitionsVar: typeof ${options.overlayDefinitionsVar} !== "undefined" ? ${options.overlayDefinitionsVar} : undefined,
                                                                     //Object or undefined: descriptions for additional highlights and completions
			readOnly: ${options.readOnly},                           //Boolean: whether the whole editor should be read-only
			theme: "${options.theme}",                               //String:  the default theme to use
			useSession: ${options.useSession},                       //Boolean: whether to save some data in the browser's localstorage
			<g:applyCodec encodeAs="raw"> <%-- do not encode the already encoded json --%>
			availableThemes: ${availableThemes.encodeAsJSON()},      //List of Strings: names of all themes that should be available to the user
			availableModes:  ${availableModes.encodeAsJSON()},       //List of Strings: names of all modes (file extensions) that should be available to the user
			</g:applyCodec>
			preloadModules: ${options.preloadModules},				 //Boolean: whether to load themes and modules at document load or on demand
			messages: {
				fileselectplaceholder : "${g.message(code:'cmeditor.menu.messages.fileselectplaceholder')}",
				hints: {
					filewillbehidden:	"${g.message(code:'cmeditor.menu.messages.hints.filewillbehidden')}",
					numberappended:		"${g.message(code:'cmeditor.menu.messages.hints.numberappended')}",
				},
				errorIntro:		"${g.message(code:'cmeditor.menu.messages.errorIntro')}",
				errors: {
					validlineno:	"${g.message(code:'cmeditor.menu.messages.errors.validlineno')}",
					supplyaname:	"${g.message(code:'cmeditor.menu.messages.errors.supplyaname')}",
					selectafile:	"${g.message(code:'cmeditor.menu.messages.errors.selectafile')}",
				},
				buttons : {
					cancel:		"${g.message(code:'cmeditor.menu.messages.buttons.cancel')}",
					create:		"${g.message(code:'cmeditor.menu.messages.buttons.create')}",
					open:		"${g.message(code:'cmeditor.menu.messages.buttons.open')}",
					rename:		"${g.message(code:'cmeditor.menu.messages.buttons.rename')}",
					import:		"${g.message(code:'cmeditor.menu.messages.buttons.import')}",
					goto:		"${g.message(code:'cmeditor.menu.messages.buttons.goto')}",
				}
			}
		};
		CMEditor($("#${name}"), codeMirrorEditorOptions, "${name}");

	});
</script>
