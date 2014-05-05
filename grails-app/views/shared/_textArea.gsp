<r:require modules="cmeditor" />

<div class="cmeditor">
	<g:if test="${options.menu}"><g:render template="/shared/menu" plugin="cm-editor" model="[name:name, options:options]"></g:render></g:if>
	<div class="cmeditor-settings"></div>
	<div class="cmeditor-main">
		<g:textArea name="${name}" value="${value}" />
	</div>
</div>
<r:script>
	var cmeditor_${name};
	function cmeditor_${name}_init() {
		var keyMap = {
			"Ctrl-Space": "autocomplete",
			"Ctrl-Q": function(cm){ cm.foldCode(cm.getCursor()); },
			"F11": function(cm) {
				if (!cm.getOption("readOnly")) {
					cm.setOption("fullScreen", !cm.getOption("fullScreen"));
		        }
		    },
	  	};
	  	<g:if test="${options.overlayDefinitionsVar}">
	  		//console.log(Object.keys(${options.overlayDefinitionsVar}));
			for(var name in ${options.overlayDefinitionsVar}) {
				//console.log(name+" baseMode: "+ ${options.overlayDefinitionsVar}[name]['baseMode']);
				//console.log(name+" definition: "+ ${options.overlayDefinitionsVar}[name]['definition']);
				cmeditorall_add_overlay_definition(name, ${options.overlayDefinitionsVar}[name]['baseMode'], ${options.overlayDefinitionsVar}[name]['definition']);
			}
		</g:if>
		CodeMirror.commands.autocomplete = function(cm, getHints, options) { CodeMirror.showHint(cm, null, {cmeditorDefinitions: ${options.overlayDefinitionsVar}}) };
		cmeditor_${name} = CodeMirror.fromTextArea($('textarea#${name}')[0], {
			lineNumbers: true,
			smartIndent: false,
	        lineWrapping: true,
	        matchBrackets: true,
	        autoCloseBrackets: true,
	        autoCloseTags: true,
	        //cursorHeight: 1.0,						   
	        viewportMargin: Infinity,
			<g:if test="${options.mode}">mode: '${options.mode}',</g:if>
			<g:if test="${options.defaultReadOnly||options.readOnly}">readOnly: 'nocursor',</g:if>
			foldGutter: true,
   			gutters: ["CodeMirror-linenumbers", "CodeMirror-foldgutter"],
			extraKeys: keyMap,
		});
		
		cmeditor_${name}.setOption("mode", "${options.mode}");
		<g:if test="${options.useSession}">
		if (localStorage['cmeditor-menu-binding']) cmeditor_${name}.setOption("keymap", localStorage['cmeditor-menu-binding']);
		else cmeditor_${name}.setOption("keymap", "default");
		if (localStorage['cmeditor-menu-theme']) cmeditor_${name}.setOption("theme", localStorage['cmeditor-menu-theme']);
		else cmeditor_${name}.setOption("theme", "default");
		</g:if><g:else>
		cmeditor_${name}.setOption("keymap", "${options.binding}");
		cmeditor_${name}.setOption("theme", "${options.theme}");
		</g:else>
		if (cmeditor_${name}.getOption("keymap") == 'vim') {
			cmeditor_${name}.setOption("vimMode", true);
		} else {
			cmeditor_${name}.setOption("vimMode", false);
		}
	}
	
	function cmeditor_${name}_update() {
		console.log("cmeditor_${name}_update was performed.")
	}
	
	$(document).ready(function() {
		cmeditor_${name}_init();
		<g:if test="${options.menu}">cmeditor_menu_${name}_init();</g:if>
		console.log("cmeditor_${name} loaded.")
	});
</r:script>
