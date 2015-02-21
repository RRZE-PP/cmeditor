<asset:javascript src="textAreaCMEditor.js" />
<asset:stylesheet href="textAreaCMEditor.css" />
<r:require module="cmeditor-textarea" />

<div id="${name}" class="cmeditor">
	<g:if test="${options.menu}"><g:render template="/shared/menu" plugin="cm-editor" model="[name:name, options:options]"></g:render></g:if>
	<div class="cmeditor-settings"></div>
	<div class="cmeditor-main">
		<g:textArea  name="${name}" value="${value}" />
	</div>
</div>
<script type="text/javascript">


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
			}
		}

		textAreaCMEditor($("#${name}"), textAreaCMEditorOptions);
	});
</script>
