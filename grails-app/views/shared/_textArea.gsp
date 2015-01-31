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
			keymap: "${options.binding}",
			overlayDefinitionsVar: typeof ${options.overlayDefinitionsVar} !== "undefined" ? ${options.overlayDefinitionsVar} : undefined,
			theme: "${options.theme}",
			menu: ${options.menu}

		}

		textAreaCMEditor($("#${name}"), textAreaCMEditorOptions);
		console.log("textAreaCMEditor loaded.")
	});

	this.textAreaCMEditor = function (){

		function textAreaCMEditor(rootElem, options){
			//allow the user to omit new
			if (!(this instanceof textAreaCMEditor)) return new textAreaCMEditor(rootElem, options);
			var self = this;
			self.instanceNo = textAreaCMEditor.instanciated++;

			var rootElem = self.rootElem = $(rootElem);
			self.options  = options  = options !== undefined ? options : {};

			init(self, rootElem, options);

			if(options.menu)
				self.menu = new CMEditorMenu(self, self.rootElem.find(".cmeditor-menu"), options);
		}

		textAreaCMEditor.instanciated=0;
		function log(self, msg){console.log("textAreaCMEditor #"+self.instanceNo+": "+msg);}

		function init(self, rootElem, options) {
			var keyMap = {
				"Ctrl-Space": "autocomplete",
				"Ctrl-Q": function(cm){ cm.foldCode(cm.getCursor()); },
				"F11": function(cm) {
					if (!cm.getOption("readOnly")) {
						cm.setOption("fullScreen", !cm.getOption("fullScreen"));
					}
				},
				"Alt-Up": function(cm) { cmeditorbase_moveUp(cm); },
				"Alt-Down": function(cm) { cmeditorbase_moveDown(cm); },
				"Ctrl-7": function(cm) { cmeditorbase_comment(cm); },
			};

			if (typeof self.options.overlayDefinitionsVar !== 'undefined') {
				for(var name in self.options.overlayDefinitionsVar) {
					cmeditorall_add_overlay_definition(name, self.options.overlayDefinitionsVar[name]['baseMode'], self.options.overlayDefinitionsVar[name]['definition']);
				}
				CodeMirror.commands.autocomplete = function(cm, getHints, options) { CodeMirror.showHint(cm, null, {cmeditorDefinitions: self.options.overlayDefinitionsVar}) };
			}

			var codeMirrorOptions = {
				lineNumbers: true,
				smartIndent: false,
				lineWrapping: true,
				matchBrackets: true,
				autoCloseBrackets: true,
				autoCloseTags: true,
				//cursorHeight: 1.0,
				viewportMargin: Infinity,
				foldGutter: true,
				gutters: ["CodeMirror-linenumbers", "CodeMirror-foldgutter"],
				extraKeys: keyMap,
			}

			if(options.mode)
				codeMirrorOptions.mode = options.mode;
			if(options.defaultReadOnly || options.readOnly)
				codeMirrorOptions.readOnly = 'nocursor';

			var codeMirror = self.codeMirror = CodeMirror.fromTextArea(rootElem.find("textarea")[0], codeMirrorOptions);

			if(self.options.useSession){
				if (localStorage['cmeditor-menu-binding'])
					codeMirror.setOption("keymap", localStorage['cmeditor-menu-binding']);
				else
					codeMirror.setOption("keymap", "default");

				if (localStorage['cmeditor-menu-theme'])
					codeMirror.setOption("theme", localStorage['cmeditor-menu-theme']);
				else
					codeMirror.setOption("theme", "default");
			}else{
				codeMirror.setOption("keymap", self.options.binding);
				codeMirror.setOption("theme", self.options.theme);
			}

			if (codeMirror.getOption("keymap") == 'vim') {
				codeMirror.setOption("vimMode", true);
			} else {
				codeMirror.setOption("vimMode", false);
			}
		}

		function update(self) {
			log(self, "update was performed.")
		}

		function getCodeMirror(self){
			return self.codeMirror;
		}

		function focus(self){
			self.codeMirror.focus();
		}

		textAreaCMEditor.prototype.constructor = CMEditor;

		//Zugegriffen aus Menu
		textAreaCMEditor.prototype.focus         = function(){Array.prototype.unshift.call(arguments, this); return focus.apply(this, arguments)};
		textAreaCMEditor.prototype.update        = function(){Array.prototype.unshift.call(arguments, this); return update.apply(this, arguments)};
		textAreaCMEditor.prototype.getCodeMirror = function(){Array.prototype.unshift.call(arguments, this); return getCodeMirror.apply(this, arguments)};

		return textAreaCMEditor;

	}();
</script>
