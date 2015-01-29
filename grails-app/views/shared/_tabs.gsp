<div id="cmEditor" class="cmeditor">
	<div class="cmeditor-tab-message" style="display:none;"></div>

	<g:if test="${options.menu}">
		<g:render template="/shared/menu" plugin="cm-editor" model="[name:name, options:options]"></g:render>
	</g:if>
	<div class="cmeditor-settings"></div>
	<div class="cmeditor-main">
		<form method="post">
			<g:hiddenField name="_cmeditorName" class="cmeditor-field" value="" />
			<g:hiddenField name="_cmeditorMode" class="cmeditor-field" value="" />
			<g:hiddenField name="_cmeditorStatus" class="cmeditor-field" value="" />
			<g:hiddenField name="_cmeditorReadOnly" class="cmeditor-field" value="" />
			<g:hiddenField name="_cmeditorOrigContent" class="cmeditor-field" value="" />
			<g:hiddenField name="_cmeditorContent" class="cmeditor-field" value="" />
			${raw(body())}
			<ul class="docs tabs"></ul>
		</form>
	</div>
</div>
<script type="text/javascript">

	//TODO: Einmal drueber grepen und alle TODOS fixen
	//TODO: Fuer bessere doku sollten dokumente auch eine klasse sein
	//TODO: Doku fuer options
	//TODO: console.log auf ein sinnvolles mass begrenzen und praefixen
	//TODO: Sachen optimieren? zB mehr dom-objekte speichern, dialoge nicht mit html und jquery erzeugen...
	//TODO: Anfuehrungszeichen vereinheitlichen
	//TODO: API vereinheitlichen (entw. ueberall position oder ueberall ein doc oder ueberall ein name...)

	var codeMirrorEditor;

	$(document).ready(function() {
		var codeMirrorEditorOptions = {
			addModes: "${options.addModes}",
			ajax:{
				deleteURL: "${ajax.deleteURL}",
				updateURL: "${ajax.updateURL}",
				getURL: "${ajax.getURL}",
				listURL: "${ajax.listURL}"
			},
			binding: "${options.binding}",
			defaultContent: "${options.defaultContent}",
			defaultMode: "${options.defaultMode}",
			defaultDiffBeforeSave: ${options.defaultDiffBeforeSave},
			idField: "${options.idField}",
			mapping: {
				name: "${mapping.name}",
				mode: "${mapping.mode}",
				content: "${mapping.content}"

			},
			menu: ${options.menu},
			overlayDefinitionsVar: typeof ${options.overlayDefinitionsVar} !== "undefined" ? ${options.overlayDefinitionsVar} : undefined,
			readOnly: ${options.readOnly},
			theme: "${options.theme}",
			useSession: ${options.useSession}
		};

		codeMirrorEditor = CMEditor($("#cmEditor"), codeMirrorEditorOptions);
	});

	this.CMEditor = (function(){
		function CMEditor(rootElem, options){
			//allow the user to omit new
			if (!(this instanceof CMEditor)) return new CMEditor(rootElem, options);
			var self = this;

			self.rootElem = $(rootElem);
			self.options  = options  = options !== undefined ? options : {};
			self.options.ajax = options.ajax !== undefined ? options.ajax : {}

			options.defaultContent = options.defaultContent !== undefined ? options.defaultContent : "";

			self.docs = [];

			initDialogs(self);
			initEventListeners(self)
			initCodeMirror(self, options);

			if(options.menu)
				self.menu = new CMEditorMenu(self, $("#cmEditorMenu"), options);

			insertNewUntitledDocument(self);

			//disable some browser featues when the codeMirror has focus
			//CLARIFY: wollen wir das?
			$(document).bind("keydown", function(e){
				if(e.ctrlKey && self.rootElem.find("CodeMirror-focused").size() !== 0){
					e.preventDefault();
				}
			});

			console.log("cmeditor loaded.")
		}

		/*
		 *	Initiates the actual CodeMirror and sets our own key map
		 *  TODO: make CM options available via our options
		 */
		function initCodeMirror(self, options) {
			var keyMap = {
				"Ctrl-Space": "autocomplete",
				"Ctrl-S":     function(cm) { save(self);},
				"Ctrl-Q":     function(cm){ cm.foldCode(cm.getCursor()); },
				"F11":        function(cm) {
				                 if (!cm.getOption("readOnly")) {
				                 	cm.setOption("fullScreen", !cm.getOption("fullScreen"));
				                 }
				               },
				"Alt-Up":     function(cm) { cmeditorbase_moveUp(cm); },
				"Alt-Down":   function(cm) { cmeditorbase_moveDown(cm); },
				"Ctrl-7":     function(cm) { cmeditorbase_comment(cm); },
				"Ctrl-L":     function(cm) { goto(self); },
			};

			if (typeof options.overlayDefinitionsVar !== 'undefined') {
				for(var name in options.overlayDefinitionsVar) {
					cmeditorall_add_overlay_definition(name, options.overlayDefinitionsVar[name]['baseMode'],
					                                       options.overlayDefinitionsVar[name]['definition']);
				}
				CodeMirror.commands.autocomplete = function(cm, getHints, options) {
					CodeMirror.showHint(cm, null, {cmeditorDefinitions: options.overlayDefinitionsVar})
				};
			}

			var codeMirrorOptions = {
				lineNumbers: true,
				smartIndent: false,
				lineWrapping: true,
				matchBrackets: true,
				autoCloseBrackets: true,
				autoCloseTags: true,
				styleActiveLine: true,
				viewportMargin: Infinity,
				foldGutter: true,
				gutters: ["CodeMirror-linenumbers", "CodeMirror-foldgutter"],
				extraKeys: keyMap,
			}

			if(options.mode)
				codeMirrorOptions.mode = options.mode;
			if(options.defaultReadOnly || options.readOnly)
				codeMirrorOptions.readOnly = 'nocursor';

			var codeMirror = self.codeMirror = CodeMirror(self.rootElem.find(".cmeditor-main form").get(0), codeMirrorOptions);

			if(options.useSession){
				if(localStorage['cmeditor-menu-binding'])
					codeMirror.setOption("keymap", localStorage['cmeditor-menu-binding']);
				else
					codeMirror.setOption("keymap", "default");

				if(localStorage['cmeditor-menu-theme'])
					codeMirror.setOption("theme", localStorage['cmeditor-menu-theme']);
				else
					codeMirror.setOption("theme", "default");

				if(localStorage['cmeditor-menu-diffBeforeSave'] === null)
					setDoDiffBeforeSaving(self, localStorage['cmeditor-menu-diffBeforeSave']);
				else
					setDoDiffBeforeSaving(self, options.defaultDiffBeforeSave);
			}else{
				codeMirror.setOption("keymap", options.binding);
				codeMirror.setOption("theme", options.theme);
				setDoDiffBeforeSaving(self, options.defaultDiffBeforeSave);
			}

			if (codeMirror.getOption("keymap") == 'vim') {
				codeMirror.setOption("vimMode", true);
			} else {
				codeMirror.setOption("vimMode", false);
			}

			codeMirror.on("changes", function(cm, cmChangeObjects) {
				updateCurrentDocument(self, cmChangeObjects);
			});
		}

		/*
		 *	Initiates dialogs for user interaction
		 */
		function initDialogs(self){
			var diff = self.diffDialog = $('<div class="dialog diffDialog" title="diff" style="display: none;"> \
										<div class="diffoutput"> </div> \
										<p><strong>Context size (optional):</strong><input name="contextSize" value="1" type="number" /></p> \
										<p><input type="radio" name="_viewtype" id="sidebyside" checked="checked" /> <label for="sidebyside">Side by Side Diff</label> \
											&nbsp; &nbsp; <input type="radio" name="_viewtype" id="inline" /> <label for="inline">Inline Diff</label> </p> \
										</div>');

			diff.find("input[name=contextSize]").on("keyup", function(){decorateDiffDialog(self)});
			diff.find("input[name=_viewtype]").on("click",   function(){decorateDiffDialog(self)});

			diff.dialog({
				autoOpen: false,
				resize:'auto',
				width: 'auto',
				height: 'auto',
			});


			var warn = self.warningDialog = $('<div class="dialog warningDialog" title="warning" style="display: none;"></div>');
			warn.dialog({
				autoOpen: false,
				resize:'auto',
				width: 'auto',
				height: 'auto',
			});


			var go = self.gotoDialog = $('<div class="dialog gotoDialog" title="Go to Line" style="display: none;"><p class="gotoLabel"></p> \
										<input type="text" /><p class="gotoError">&nbsp;</p></div>');
			go.dialog({
				autoOpen: false,
				dialogClass: 'dialog-goto',
				resize:'auto',
				width: 'auto',
				height: 'auto',
				buttons: {Cancel: 	function() { $(this).dialog("close"); },
						  Ok: 		function() {
										var line = parseInt(self.gotoDialog.find('input').val())-1;
										self.codeMirror.doc.setCursor(line, 0);
										$(this).dialog("close");
									}
						  }

			});
		}

		/*
		 *	Registers event listeners for user interaction
		 */
		function initEventListeners(self){
			var mainForm = self.rootElem.find(".cmeditor-main form");

			//switch tabs
			self.rootElem.find(".tabs").on("click", function(e) {
				var target = e.target;
				if(target.nodeName.toLowerCase() != "li" && target.parentNode.nodeName.toLowerCase() == "li")
					target = target.parentNode;

				if (target.nodeName.toLowerCase() != "li") return true;
				for (var i = 0, c = target.parentNode.firstChild; ; ++i, (c = c.nextSibling)) {
					if (c == target) return selectDocumentByIndex(self, i);
				}
			});

			//save document
			mainForm.on("submit", function(e){
				ajax_update(self, $(this).serialize());
				e.preventDefault();
			});

			//changes in custom inputs
			mainForm.find(".cmeditor-field").keyup(function() { customElementChanged(self, $(this));});
			mainForm.find("select.cmeditor-field").change(function() {customElementChanged(self, $(this));});
			mainForm.find("input[type='checkbox'].cmeditor-field").change(function() { customElementChanged(self, $(this));});
		}

		/*************************************************************************
		 *                    Begin private functions                            *
		 *************************************************************************/


		/*
		 * Performs the actual deletion
		 */
		function ajax_delete(self) {
			if(self.options.readOnly){
				displayMessage("This document is read-only and cannot be deleted");
				return;
			}

			if (self.curDoc[self.options.idField]) {

				$.ajax({
					type:'GET',
					data: {id: self.curDoc[self.options.idField]},
					url: options.ajax.deleteURL,
					success:function(data, textStatus){
						if (data.status == 'success') {
							// do sth
						}
						displayMessage(self, data.msg, textStatus);
						//cmeditor_${name}_ajax_reload();
					},
					error:function(XMLHttpRequest,textStatus,errorThrown){}
				});
			}

			removeDocument(self, self.curDoc);

			return false;
		}

		/*
		 * Reinitiates the current document from the server
		 *
		 * Parameters: newname String: If supplied the document will be replaced by this one
		 */
		function ajax_reload(self, newname) {
			if (self.curDoc) {
				var name = self.curDoc._cmeditorName;
				removeDocument(self, self.curDoc);

				if(typeof newname !== "undefined") {
					ajax_load(self, newname, true);
				} else {
					ajax_load(self, name, true);
				}
			}
		}

		/*
		 *	Triggers an update
		 *
		 *  Parameters: data Object: TODO: i don't know yet
		 */
		function ajax_update(self, data) {
			if (self.curDoc) {
				$.ajax({
					type: 'POST',
					data: data,
					url: self.options.ajax.updateURL,
					success:function(data,textStatus){
						if (data.status == 'success') {
							if (data.newname) {
								ajax_reload(self, data.newname);
							}else{
								ajax_reload(self);
							}
						}
						displayMessage(self, data.msg, textStatus);
					},
					error:function(XMLHttpRequest,textStatus,errorThrown){}
				});
				return false;
			}
		}

		/*
		 * Triggered, when a custom input was changed
		 */
		function customElementChanged(self, elem) {
			var key = elem.attr('id');

			if (self.curDoc) {
				var old = null;
				var doUpdate = true;

				if (key == self.options.mapping.name) {
					rename(self, getCustomElementValue(self, elem));
					doUpdate = false;

				} else if (key == self.options.mapping.mode) {
					old = self.curDoc._cmeditorMode;
					self.curDoc._cmeditorMode = getCustomElementValue(self, elem);
					if(self.options.menu)
						self.menu.update();

				} else if (key == self.options.mapping.content) {
					old = self.curDoc._cmeditorContent;
					sef.curDoc._cmeditorContent = getCustomElementValue(self, elem);

				} else {
					if (elem.attr('data-field-property') && self.curDoc[key] !== 'undefined') {
						if (self.curDoc[key]) {
							old = self.curDoc[key][elem.attr('data-field-property')];
						} else {
							self.curDoc[key] = {};
						}
						self.curDoc[key][elem.attr('data-field-property')] = getCustomElementValue(self, elem);
					} else {
						old = self.curDoc[key];
						self.curDoc[key] = getCustomElementValue(self, elem);
					}
				}

				if (doUpdate) {
					updateCurrentDocument(self, {cmeditor_custom_field: true, old:old, new:getCustomElementValue(self, elem)});
				}
			}
		}

		/*
		 * Calculates and draws the diff
		 */
		function decorateDiffDialog(self) {

			var base    = difflib.stringAsLines(self.rootElem.find("input[name=_cmeditorOrigContent]").eq(0).val()),
				newtxt  = difflib.stringAsLines(self.rootElem.find("input[name=_cmeditorContent]").eq(0).val()),
				opcodes = new difflib.SequenceMatcher(base, newtxt).get_opcodes(),
				diffoutputdiv = self.diffDialog.find(".diffoutput"),
				contextSize   = self.diffDialog.find("input[name=contextSize]").val();

			diffoutputdiv.text("");
			contextSize = contextSize || null;

			if (opcodes && opcodes.length == 1) {
				diffoutputdiv.html("<p>No changes!</p>");
			} else {
				diffoutputdiv.append(diffview.buildView({
					baseTextLines: base,
					newTextLines: newtxt,
					opcodes: opcodes,
					baseTextName: "Base Text",
					newTextName: "New Text",
					contextSize: contextSize,
					viewType: self.diffDialog.find("input[name=viewType]:checked").val()
				}));
			}
		}

		/*
		 * TODO
		 */
		function getCustomElementValue(self, elem) {
			if (elem.attr('type') == 'checkbox') {
				return elem.is(":checked");
			} else {
				return elem.val();
			}
		}

		/*
		 * Gets the document by document name
		 *
		 * Parameters: name String: The name of the document
		 * Returns:    TODO: the document
		 */
		function getDocumentByName(self, name) {
			return self.docs[getDocumentIdByName(self, name)];
		}

		/*
		 * Prompts the user for a line, then sets the line number to that line
		 */
		function goto(self) {
			var first = self.codeMirror.doc.firstLine()+1;
			var last = self.codeMirror.doc.lastLine()+1;

			self.gotoDialog.find('.gotoLabel').text('Enter line number ('+first+'..'+last+'):');
			self.gotoDialog.find('input').val(self.codeMirror.doc.getCursor().line+1);
			self.gotoDialog.find("input").on("keyup", function() {
				var lineInput = $(this).val();

				var errMsg = '';
				if (lineInput !== '') {
					if (cmeditorbase_is_int(lineInput)) {
						var line = parseInt(lineInput);

						if(line < first || line > last) {
							errMsg = "Line number out of range";
						}
					} else {
						errMsg = "Not a number";
					}
				}

				if(errMsg !== '' && lineInput !== ''){
					self.gotoDialog.find(":button:contains('Ok')").prop("disabled", true).addClass("ui-state-disabled");
				}else{
					self.gotoDialog.find(":button:contains('Ok')").prop("disabled", true).removeClass("ui-state-disabled");
				}
				self.gotoDialog.find(".gotoError").text(errMsg);
			});

			self.gotoDialog.dialog("open");
		}
		/*
		 * (Private)
		 * Creates a new tab and sets the supplied document as its content
		 *
		 * Parameters: data Object: TODO: don't know
		 */
		function insertNewDocument(self, data) {
			self.docs.push(data);

			var docTabs = self.rootElem.find(".docs").get(0);
			var li = docTabs.appendChild(document.createElement("li"));
			li.appendChild($("<span class='tabName'></span>").text(data._cmeditorName).get(0));

			var closeButton = $("<span class='closeButton'>&#10005;</span>");
			closeButton.on("click", function(){
										var doc = getDocumentByName(self, data._cmeditorName);

										if(doc._cmeditorStatus == 'changed' || doc._cmeditorStatus == "unsaved"){
											showWarning(self, "Do you really want to close this buffer? Unsaved changes will be lost.",
												{Close: function(){removeDocument(self, doc); $(this).dialog("close");}})
										}else{
											removeDocument(self, doc)
										}

									});
			li.appendChild(closeButton.get(0));

			if (self.codeMirror.getDoc() == data._cmeditorDoc) {
				markDocumentAsSelected(self, self.docs.length - 1);
				self.curDoc = data;
			}

			selectDocumentByIndex(self, self.docs.length - 1);
			removeUntitledDocument(self);

			console.log("insertNewDocument '"+data._cmeditorName+"' was performed. Current doc: "+self.curDoc)
		}

		/*
		 * Creates and registers a new (empty) document if there is none opened
		 */
		function insertNewUntitledDocument(self) {
			if (self.docs.length < 1) {
				self.unregDocName = getUnambiguousName(self, 'Untitled Document');

				var data = {_cmeditorName: self.unregDocName,
				            _cmeditorMode: self.options.defaultMode,
				            _cmeditorStatus:'new',
				            _cmeditorContent: self.options.defaultContent,
				            _cmeditorOrigContent: self.options.defaultContent,
				        	_cmeditorReadOnly: (self.options.readOnly||self.options.defaultReadOnly)?'nocursor':''};

				data._cmeditorDoc = new CodeMirror.Doc(data._cmeditorContent, self.options.defaultMode);
				insertNewDocument(self, data);
			}
			console.log("insertNewUntitledDocument "+self.curDoc._cmeditorName+" was performed.");
		}

		/*
		 * Marks a document as changed by placing a star next to its name
		 *
		 * Parameters: pos Integer: the index of the document to change
		 */
		function markDocumentAsChanged(self, pos) {
			var docTab = self.rootElem.find(".tabs li:nth-child("+(pos+1)+") .tabName");
			docTab.text("*"+ self.docs[pos]._cmeditorName);

			console.log("changed " + self.docs[pos]._cmeditorName);
			console.log("markDocumentAsChanged '"+pos+"' was performed.");
		}

		/*
		 * (Private)
		 * Adds a selected class to a document and removes it from all others
		 *
		 * Parameters: pos Integer: the index of the document to add the class to
		 */
		function markDocumentAsSelected(self, pos) {
			var docTabs = self.rootElem.find(".tabs").children();
			docTabs.removeClass("selected");
			docTabs.eq(pos).addClass("selected");

			console.log("markDocumentAsSelected "+ pos +" was performed.")
		}

		/*
		 * Marks a document as unchanged by removing the star next to its name
		 *
		 * Parameters: pos Integer: the index of the document to change
		 */
		function markDocumentAsUnchanged(self, pos) {
			var docTab = self.rootElem.find(".tabs li:nth-child("+(pos+1)+") .tabName");
			docTab.text(self.docs[pos]._cmeditorName);

			console.log("unchanged " + self.docs[pos]._cmeditorName);
			console.log("markDocumentAsUnchanged '"+pos+"' was performed.");
		}

		/*
		 * Removes a tab
		 *
		 * Parameters: doc Object: TODO
		 */
		function removeDocument(self, doc) {
			for (var i = 0; i < self.docs.length && doc != self.docs[i]; ++i) {}
			self.docs.splice(i, 1);

			var docList = self.rootElem.find(".docs").get(0);
			docList.removeChild(docList.childNodes[i]);

			insertNewUntitledDocument(self);
			selectDocumentByIndex(self, Math.max(0, i - 1));

			console.log("removeDocument "+doc._cmeditorName+" was performed.");
		}

		/*
		 * (Private)
		 * Unregisters a document previously created by `insertNewUntitledDocument`
		 */
		function removeUntitledDocument(self) {
			if (self.docs.length > 1) {
				var doc = getDocumentByName(self, self.unregDocName)
				if (doc && doc._cmeditorStatus == 'new') {
					removeDocument(self, doc);
				}
			}
			console.log("removeUntitledDocument was performed.");
		}

		/*
		 * Selects a document and displays its contents in the editor
		 *
		 * Parameters: pos Integer: the index of the document to select
		 */
		function selectDocumentByIndex(self, pos) {
			markDocumentAsSelected(self, pos);
			self.curDoc = self.docs[pos];

			self.codeMirror.swapDoc(self.curDoc._cmeditorDoc);
			updateCurrentDocument(self);

			if(self.options.menu){
				self.menu.update();
			}
			console.log("selectDocumentByIndex "+ self.curDoc._cmeditorName +" "+ pos +" was performed.")
		}

		/*
		 * Displays a modal window with a message, a cancel button which closes the dialog
		 * and optionally further buttons which can trigger functions
		 *
		 * Parameters: message String: A message to display
		 *             additionalButtons Object (optional): keys: Button labels
		 *                                                  values: callbacks for button click
		 */
		function showWarning(self, message, additionalButtons){
			var buttons = {
					Cancel: function() { $(this).dialog("close");},
			};

			if (additionalButtons) {
				for (var name in additionalButtons) {
					buttons[name] = additionalButtons[name];
				}
			}

			self.warningDialog.text(message);
			self.warningDialog.dialog("option", "buttons", buttons);
			self.warningDialog.dialog("open");
		}

		/*
		 * TODO
		 */
		function set_form_doc(self) {
			if (typeof self.set_form_doc_before == 'function') self.set_form_doc_before();

			self.rootElem.find("form .cmeditor-field").each(function(){
				var elem = $(this);
				var key = elem.attr('name');

				if (elem.attr('data-field-property') && self.curDoc[key]) {
					set_form_doc_field(self, elem, self.curDoc[key][elem.attr('data-field-property')] || '');
				} else {
					set_form_doc_field(self, elem, self.curDoc[key] || '');
				}
			});

			self.rootElem.find("form #"+self.options.mapping.name+".cmeditor-field").val(self.curDoc._cmeditorName||'');
			self.rootElem.find("form #"+self.options.mapping.mode+".cmeditor-field").val(self.curDoc._cmeditorMode||'');
			self.rootElem.find("form #"+self.options.mapping.content+".cmeditor-field").val(self.curDoc._cmeditorContent||'');

			if (typeof self.set_form_doc_after == 'function') self.set_form_doc_after();

			console.log("set_form_doc "+ self.curDoc._cmeditorName +" was performed.")
		}

		/*
		 * Sets the value of `elem` to `val`
		 *
		 * Parameters: elem jQuery: the element to set the value on
		 *             val String or Boolean: the value to set or if elem is a checkbox whether it should be checked or
		 *                                    unchecked
		 */
		function set_form_doc_field(self, elem, val) {
			if (elem.attr('type') == 'checkbox') {
				if (val) {
					elem.prop('checked', true);
				} else {
					elem.prop('checked', false);
				}
			} else {
				elem.val(val);
			}
		}

		/*
		 * Called on every change of a document inside `self.codeMirror`
		 *
		 * Parameters: cmChangeObjects (optional) Object: TODO
		 * Returns:    Boolean whether this document has changed
		 */
		function updateCurrentDocument(self, cmChangeObjects) {
			var docName = 'no curDoc';
			var changed = false;

			if (self.curDoc) {
				docName = self.curDoc._cmeditorName;

				if (self.curDoc._cmeditorMode != self.codeMirror.getOption("mode")) {
					self.codeMirror.setOption("mode", self.curDoc._cmeditorMode);
					changed = true;
					console.log("mode changed");
				}

				if (cmChangeObjects && !cmChangeObjects.propertyIsEnumerable('cmeditor_custom_field')) {
					self.curDoc._cmeditorContent = self.curDoc._cmeditorDoc.getValue();
					changed = true;
					console.log("content changed" + cmChangeObjects);
				}

				if (self.curDoc._cmeditorReadOnly != self.codeMirror.getOption('readOnly')) {
					if (self.curDoc._cmeditorReadOnly) {
						self.codeMirror.setOption('readOnly', self.curDoc._cmeditorReadOnly);
					} else {
						self.codeMirror.setOption('readOnly', false);
					}
				}

				if (cmChangeObjects && cmChangeObjects.propertyIsEnumerable('cmeditor_custom_field')) {
					changed = true;
					console.log("custom field changed")
				}

				if (changed || cmChangeObjects) {
					markDocumentAsChanged(self, getDocumentIdByName(self, self.curDoc._cmeditorName));
					if (self.curDoc._cmeditorStatus == 'new') {
						self.curDoc._cmeditorStatus = 'unsaved';
					} else if (self.curDoc._cmeditorStatus == 'unchanged') {
						self.curDoc._cmeditorStatus = 'changed';
					}
				}

				set_form_doc(self);
			}

			console.log("updateCurrentDocument "+ docName +" was performed.")
			return changed;
		}


		/*************************************************************************
		 *                                                                       *
		 *                     Begin public functions                            *
		 *                                                                       *
		 *************************************************************************/

		/* (Public)
		 * Loads a document from the server
		 *
		 * Parameters: name String: The document name to load
		 *             readWrite Boolean: If true document will always be writable, else it will be readOnly
		 *                                if options.readOnly or options.defaultReadOnly is set to true
		 */
		function ajax_load(self, name, readWrite) {
			$.ajax({
				type:'GET',
				url: self.options.ajax.getURL+name,
				success: function(data){
					if (data.status == 'success' && data.result) {
						data.result._cmeditorName = data.result[self.options.mapping.name];
						data.result._cmeditorMode = data.result[self.options.mapping.mode] || options.defaultMode;
						if (readWrite) {
							data.result._cmeditorReadOnly = '';
						} else {
							data.result._cmeditorReadOnly = (options.readOnly || options.defaultReadOnly) ? 'nocursor' : '';
						}
						data.result._cmeditorContent = data.result[self.options.mapping.content];
						data.result._cmeditorOrigContent = data.result[self.options.mapping.content];
						data.result._cmeditorStatus = 'unchanged';
						data.result._cmeditorDoc = new CodeMirror.Doc(data.result._cmeditorContent, data.result._cmeditorMode);

						insertNewDocument(self, data.result);

						console.log("ajax_load '"+name+"' was performed.");
						console.log(data.result.version)
					} else {
						displayMessage(self, data.msg);
					}
				},
				error:function(XMLHttpRequest,textStatus,errorThrown){
					displayMessage(self, textStatus + ": " + errorThrown);
				},
			});
		}

		/* (Public)
		 * Closes the currently opened document
		 */
		function close(self, cm) {
			var status = self.curDoc._cmeditorStatus;
			if (status == 'changed' || status == 'unsaved') {
				showWarning(self, "The changes to the current document will be lost",
					{Close: function() {
								removeDocument(self, self.curDoc);
								$(this).dialog("close");
							}
					});
			} else {
				removeDocument(self, self.curDoc);
			}
		}


		/* (Public)
		 *	Deletes the currently opened document, asks for confirmation first
		 */
		function deleteDoc(self) {
			showWarning(self, "Are you sure that you want to delete this document?",
					{Delete: function() {
								ajax_delete(self);
								$(this).dialog("close");
							}
					});
		}

		/* (Public)
		 * Shows a diff of the current document.
		 *
		 * Parameters: additionalButtons: Object: The keys are the button labels and the values are the
		 *                                        callbacks for when the associated button is clicked.
		 */
		function diff(self, additionalButtons) {
			var buttons = {
					Cancel: function() { $(this).dialog("close");},
			};

			if (additionalButtons) {
				for (var name in additionalButtons) {
					buttons[name] = additionalButtons[name];
				}
			}

			decorateDiffDialog(self);

			self.diffDialog.dialog("option", "buttons", buttons);
			self.diffDialog.dialog("open");
		}

		/* (Public)
		 * Displays a message for 3 seconds
		 *
		 * Parameters: message String: The message to be displayed
		 */
		function displayMessage(self, message) {
			self.rootElem.find('.cmeditor-tab-message').text(message)
			                .toggle('slide', {'direction':'up'})
			                .delay(3000)
			                .toggle('slide', {'direction':'up'});
		}

		/* (Public)
		 *
		 * Sets focus to the text editor
		 */
		function focus(self){
			self.codeMirror.focus();
		}

		/* (Public)
		 *
		 * Gets the document id by document name
		 *
		 * Parameters: name String: The name of the document
		 * Returns:    Integer: the id of the document
		 */
		function getDocumentIdByName(self, name) {
			for (var i = 0; i < self.docs.length; ++i)
				if (self.docs[i]._cmeditorName == name) return i;
		}


		/* (Public)
		 * Returns the mode in which the current document is opened
		 */
		function getCurrentCMEditorMode(self) {
			return self.curDoc._cmeditorMode;
		}

		/* (Public)
		 *
		 * Appends a number to a filename so that it is unambigous
		 *
		 * Parameters: name String: The name of the document
		 */
		function getUnambiguousName(self, name) {
			console.log(name);
			var data = [];
			if(self.options.ajax.listURL){
				$.ajax({
					url: self.options.ajax.listURL,
					success: function(json) {
						if (json.status == 'success' && json.result) {
							data = json.result;
						}
					},
					async:false
				});
			}

			var i = 0;
			while (getDocumentByName(self, name + (i || "")) || cmeditortabs_is_in_list(data, name + (i || ""))) ++i;
			return name + (i || "");
		}

		/* (Public)
		 *
		 * Returns the underlying codeMirror instance
		 */
		function getCodeMirror(self){
			return self.codeMirror;
		}

		/* (Public)
		 * Creates a new document
		 */
		function newDoc(self) {
			console.log("creating new doc");
			if(self.options.readOnly){
				displayMessage("This document is opened read only!");
			}else{
				var name = prompt("Name of the new buffer", "");
				if (name == null) return;
				if (!name) name = "test";
				var data = {_cmeditorName: getUnambiguousName(self, name),
				            _cmeditorMode: self.options.defaultMode,
				            _cmeditorStatus:'new',
				            _cmeditorContent: self.options.defaultContent};
				data._cmeditorDoc = new CodeMirror.Doc(data._cmeditorContent, data._cmeditorMode);

				insertNewDocument(self, data);
				selectDocumentByIndex(self, self.docs.length - 1);
			}
		}

		/* (Public)
		 * Renames the currently opened document. Shows an error message if the document is read only
		 *
		 * Parameters: newName String: the new name of the document
		 */
		function rename(self, newName) {
			if(self.options.readOnly){
				displayMessage("This document is opened read only and cannot be renamed!");
			}else{
				var docId = getDocumentIdByName(self, self.curDoc._cmeditorName);
				var oldName = self.docs[docId]._cmeditorName;

				self.docs[docId]._cmeditorName = newName;
				markDocumentAsChanged(self, docId);
				updateCurrentDocument(self);

				console.log("rename '"+oldName+"', '"+newName+"' was performed.");
			}
		}

		/* (Public)
		 * Saves the currently opened document. If it is opened read-only only displays a dialog.
		 */
		function save(self) {
			if(self.options.readOnly === true){
				displayMessage("This document is opened read only and cannot be saved!");
				return;
			}

			var pos = getDocumentIdByName(self, self.curDoc._cmeditorName);
			updateCurrentDocument(self);

			if (self.doDiffBeforeSaving) {
				var additionalButtons = {
						Save: function() { self.rootElem.find(".cmeditor-main form").submit(); $(this).dialog("close"); },
					};
				diff(self, additionalButtons);
			} else {
				self.rootElem.find(".cmeditor-main form").submit();
			}

			console.log("save "+ self.curDoc._cmeditorName +" ("+ pos +") was performed.");
		}

		/* (Public)
		 * Renames then saves the current document
		 */
		function saveas(self) {
			if(self.options.readOnly){
				displayMessage("This document is opened read only and cannot be saved!");
			}
			var name = prompt("Name of the new buffer", "");
			if (name == null) return;
			if (!name) name = "test";

			rename(self, getUnambiguousName(self, name));
			self.curDoc[self.options.idField] = '';

			save(self);
			console.log("saveas was performed.");
		}

		/* (Public)
		 * Sets whether this CMEditor should show a diff before it saves
		 */
		function setDoDiffBeforeSaving(self, value) {
			self.doDiffBeforeSaving = value;
			console.log("setDoDiffBeforeSaving " + value + " was performed.")
		}

		/* (Public)
		 * Reinitialises some values on the current doc TODO: This docu is crap
		 */
		function update(self) {
			var docName = 'no curDoc';
			if(self.curDoc){
				docName = self.curDoc._cmeditorName;

				if(self.curDoc._cmeditorReadOnly != self.codeMirror.getOption('readOnly')){
					self.curDoc._cmeditorReadOnly = self.codeMirror.getOption('readOnly');
				}

				if(self.curDoc._cmeditorMode != self.codeMirror.getOption('mode')){
					self.curDoc._cmeditorMode = self.codeMirror.getOption('mode');

					markDocumentAsChanged(getDocumentIdByName(self, self.curDoc._cmeditorName));

					if (self.curDoc._cmeditorStatus == 'new'){
						self.curDoc._cmeditorStatus = 'unsaved';
					}else if(self.curDoc._cmeditorStatus == 'unchanged'){
						self.curDoc._cmeditorStatus = 'changed';
					}
				}

				updateCurrentDocument(self);
			}
			console.log("update "+ docName +" was performed.")
		}


		CMEditor.prototype.constructor = CMEditor;

		//Zugegriffen aus Menu
		CMEditor.prototype.ajax_load      = function(){Array.prototype.unshift.call(arguments, this); return ajax_load.apply(this, arguments)};
		CMEditor.prototype.close          = function(){Array.prototype.unshift.call(arguments, this); return close.apply(this, arguments)};
		CMEditor.prototype.diff           = function(){Array.prototype.unshift.call(arguments, this); return diff.apply(this, arguments)};
		CMEditor.prototype.delete         = function(){Array.prototype.unshift.call(arguments, this); return deleteDoc.apply(this, arguments)};
		CMEditor.prototype.doc_id         = function(){Array.prototype.unshift.call(arguments, this); return getDocumentIdByName.apply(this, arguments)};
		CMEditor.prototype.focus          = function(){Array.prototype.unshift.call(arguments, this); return focus.apply(this, arguments)};
		CMEditor.prototype.get_name       = function(){Array.prototype.unshift.call(arguments, this); return getUnambiguousName.apply(this, arguments)};
		CMEditor.prototype.get_mode       = function(){Array.prototype.unshift.call(arguments, this); return getCurrentCMEditorMode.apply(this, arguments)};
		CMEditor.prototype.getCodeMirror  = function(){Array.prototype.unshift.call(arguments, this); return getCodeMirror.apply(this, arguments)};
		CMEditor.prototype.goto           = function(){Array.prototype.unshift.call(arguments, this); return goto.apply(this, arguments)};
		CMEditor.prototype.new            = function(){Array.prototype.unshift.call(arguments, this); return newDoc.apply(this, arguments)};
		CMEditor.prototype.save           = function(){Array.prototype.unshift.call(arguments, this); return save.apply(this, arguments)};
		CMEditor.prototype.saveas         = function(){Array.prototype.unshift.call(arguments, this); return saveas.apply(this, arguments)};
		CMEditor.prototype.set_diff_before_save = function(){Array.prototype.unshift.call(arguments, this); return setDoDiffBeforeSaving.apply(this, arguments)};;
		CMEditor.prototype.rename_doc     = function(){Array.prototype.unshift.call(arguments, this); return rename.apply(this, arguments)};;
		CMEditor.prototype.update         = function(){Array.prototype.unshift.call(arguments, this); return update.apply(this, arguments)};;
		CMEditor.prototype.update_message = function(){Array.prototype.unshift.call(arguments, this); return displayMessage.apply(this, arguments)};;

		return CMEditor;
	})();
</script>
