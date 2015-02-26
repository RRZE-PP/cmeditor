<asset:javascript src="CMEditor.js" />
<asset:stylesheet href="CMEditor.css" />
<r:require module="cmeditor-tabs" />

<div id="${name}" class="cmeditor">
	<div class="cmeditor-tab-message" style="display:none;"></div>

	<g:if test="${options.menu}">
		<g:render template="/shared/menu" plugin="cmeditor" model="[name:name, options:options]"></g:render>
	</g:if>
	<div class="cmeditor-settings"></div>
	<div class="cmeditor-main">
		<form method="post">
			<g:hiddenField name="_cmeditorContent" data-docField="content" class="cmeditor-field" value="" />
			<g:hiddenField name="_cmeditorMode" data-docField="mode" class="cmeditor-field" value="" />
			<g:hiddenField name="_cmeditorName" data-docField="name" class="cmeditor-field" value="" />
			<g:hiddenField name="_cmeditorOrigContent" data-docField="origContent" class="cmeditor-field" value="" />
			<g:hiddenField name="_cmeditorReadOnly" data-docField="readOnly" class="cmeditor-field" value="" />
			<g:hiddenField name="_cmeditorStatus" data-docField="status" class="cmeditor-field" value="" />
			${raw(body())}
			<ul class="docs tabs"></ul>
		</form>
	</div>
</div>
<script type="text/javascript">
	$(document).ready(function() {
		var codeMirrorEditorOptions = {
			addModes: <g:if test="${options.addModes}">${options.addModes}</g:if><g:else>[]</g:else>,
			                                                         //String[]: additional modes to add to the menu
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
			idField: "${options.idField}",                           //String:  the field by which documents can be identified towards the server
			mapping: {
				name: "${mapping.name}",                             //String:  the variable name in ajax calls/responses mapped to the document name
				mode: "${mapping.mode}",                             //String:  the variable name in ajax calls/responses mapped to the document mode
				content: "${mapping.content}"                        //String:  the variable name in ajax calls/responses mapped to the document content
			},
			menu: ${options.menu},                                   //Boolean: whether to display a menu or not
			overlayDefinitionsVar: typeof ${options.overlayDefinitionsVar} !== "undefined" ? ${options.overlayDefinitionsVar} : undefined,
                                                                     //Object or undefined: descriptions for additional highlights and completions
			readOnly: ${options.readOnly},                           //Boolean: whether the whole editor should be read-only
			theme: "${options.theme}",                               //String:  the default theme to use
			useSession: ${options.useSession}                        //Boolean: wether to save some data in the browser's localstorage
		};

		CMEditor($("#${name}"), codeMirrorEditorOptions, "${name}");

	});
</script>
