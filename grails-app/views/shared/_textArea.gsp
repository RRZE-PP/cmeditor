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
			"F11": function(cm) {
		          cm.setOption("fullScreen", !cm.getOption("fullScreen"));
		        },
	  	};
	  	<g:if test="${options.keywordOverlayVar}">
			for(name of Object.keys(${options.keywordOverlayVar})) {
				cmeditorall_keyword_overlay(name, ${options.keywordOverlayVar}[name]['baseMode'], ${options.keywordOverlayVar}[name]['keywords']);
			}
		</g:if>
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
