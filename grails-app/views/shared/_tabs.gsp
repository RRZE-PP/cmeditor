<div id="${name}" class="cmeditor">
	<div class="cmeditor-tab-message" style="display:none;"></div>

	<g:if test="${options.menu}">
		<g:render template="/shared/menu" plugin="cm-editor" model="[name:name, options:options]"></g:render>
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

	//TODO: focus() hat probleme
	//TODO: Sachen optimieren? zB mehr dom-objekte speichern, dialoge nicht mit html und jquery erzeugen...

	var codeMirrorEditor;

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

		${name} = codeMirrorEditor = CMEditor($("#${name}"), codeMirrorEditorOptions);
	});

	this.CMEditor = (function(){

		function CMEditor(rootElem, options){
			//allow the user to omit new
			if (!(this instanceof CMEditor)) return new CMEditor(rootElem, options);
			var self = this;
			self.instanceNo = CMEditor.instanciated++;

			self.rootElem = $(rootElem);
			self.options  = options = options !== undefined ? options : {};
			self.options.ajax = options.ajax !== undefined ? options.ajax : {}
			self.options.mapping = options.mapping !== undefined ? options.mapping : {}

			options.defaultContent = options.defaultContent !== undefined ? options.defaultContent : "";

			self.docs = [];

			initDialogs(self);
			initEventListeners(self)
			initCodeMirror(self, options);

			if(options.menu)
				self.menu = new CMEditorMenu(self, self.rootElem.find(".cmeditor-menu"), options);

			insertNewUntitledDocument(self);

			//disable some browser featues when the codeMirror has focus
			$(document).bind("keydown", function(e){
				if(e.ctrlKey && self.rootElem.find("CodeMirror-focused").size() !== 0){
					e.preventDefault();
				}
			});

			log(self, "cmeditor loaded.");
		}

		CMEditor.instanciated = 0;
		function log(self, msg){console.log("CMEditor #"+self.instanceNo+": "+msg);}


		/*
		 *	Initiates the actual CodeMirror and sets our own key map
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

			if (typeof options.overlayDefinitionsVar !== "undefined") {
				for(var name in options.overlayDefinitionsVar) {
					cmeditorall_add_overlay_definition(name, options.overlayDefinitionsVar[name]["baseMode"],
					                                       options.overlayDefinitionsVar[name]["definition"]);
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
				codeMirrorOptions.readOnly = "nocursor";

			var codeMirror = self.codeMirror = CodeMirror(self.rootElem.find(".cmeditor-main form").get(0), codeMirrorOptions);

			if(options.useSession){
				if(localStorage["cmeditor-menu-binding"])
					codeMirror.setOption("keymap", localStorage["cmeditor-menu-binding"]);
				else
					codeMirror.setOption("keymap", "default");

				if(localStorage["cmeditor-menu-theme"])
					codeMirror.setOption("theme", localStorage["cmeditor-menu-theme"]);
				else
					codeMirror.setOption("theme", "default");

				if(localStorage["cmeditor-menu-diffBeforeSave"] === null)
					setDoDiffBeforeSaving(self, localStorage["cmeditor-menu-diffBeforeSave"]);
				else
					setDoDiffBeforeSaving(self, options.defaultDiffBeforeSave);
			}else{
				codeMirror.setOption("keymap", options.binding);
				codeMirror.setOption("theme", options.theme);
				setDoDiffBeforeSaving(self, options.defaultDiffBeforeSave);
			}

			if (codeMirror.getOption("keymap") == "vim") {
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
				resize:"auto",
				width: "auto",
				height: "auto",
			});


			var warn = self.warningDialog = $('<div class="dialog warningDialog" title="warning" style="display: none;"></div>');
			warn.dialog({
				autoOpen: false,
				resize:"auto",
				width: "auto",
				height: "auto",
			});


			var go = self.gotoDialog = $('<div class="dialog gotoDialog" title="Go to Line" style="display: none;"><p class="gotoLabel"></p> \
										<input type="text" /><p class="gotoError">&nbsp;</p></div>');
			go.dialog({
				autoOpen: false,
				dialogClass: "dialog-goto",
				resize:"auto",
				width: "auto",
				height: "auto",
				buttons: {Cancel: 	function() { $(this).dialog("close"); },
						  Ok: 		function() {
										var line = parseInt(self.gotoDialog.find("input").val())-1;
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
					type:"GET",
					data: {id: self.curDoc[self.options.idField]},
					url: options.ajax.deleteURL,
					success:function(data, textStatus){
						if (data.status == "success") {
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
				var name = self.curDoc.getName();
				removeDocument(self, self.curDoc);

				if(typeof newname !== "undefined") {
					ajax_load(self, newname, true);
				} else {
					ajax_load(self, name, true);
				}
			}
		}

		/*
		 *	Triggers updating the document on server side and then reloads it from the server
		 *
		 *  Parameters: data Object: the data as the server expects it
		 */
		function ajax_update(self, data) {
			if (self.curDoc) {
				$.ajax({
					type: "POST",
					data: data,
					url: self.options.ajax.updateURL,
					success: function(data,textStatus){
						if (data.status == "success") {
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
			var key = elem.attr("id");

			if (self.curDoc) {
				var old = null;
				var doUpdate = true;

				if (key == self.options.mapping.name) {
					rename(self, getCustomElementValue(self, elem));
					doUpdate = false;

				} else if (key == self.options.mapping.mode) {
					old = self.curDoc.getMode();
					self.curDoc.setMode(getCustomElementValue(self, elem));
					if(self.options.menu)
						self.menu.update();

				} else if (key == self.options.mapping.content) {
					old = self.curDoc.getContent();
					sef.curDoc.setContent(getCustomElementValue(self, elem));

				} else {
					if (elem.attr("data-field-property") && self.curDoc[key] !== "undefined") {
						if (self.curDoc[key]) {
							old = self.curDoc[key][elem.attr("data-field-property")];
						} else {
							self.curDoc[key] = {};
						}
						self.curDoc[key][elem.attr("data-field-property")] = getCustomElementValue(self, elem);
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
		 * Returns the element value of an input resp. if the input is a checkbox whether it is checked or not
		 *
		 * Parameters: Elem jQuery: The element to examine
		 * Returns: String or Boolean: The value of the element
		 */
		function getCustomElementValue(self, elem) {
			if (elem.attr("type") == "checkbox") {
				return elem.is(":checked");
			} else {
				return elem.val();
			}
		}

		/*
		 * Gets the document by document name
		 *
		 * Parameters: name String: The name of the document
		 * Returns:    CMEditor.Doc: The document
		 */
		function getDocumentByName(self, name) {
			return self.docs[getDocumentPositionByName(self, name)];
		}

		/*
		 * Prompts the user for a line, then sets the line number to that line
		 */
		function goto(self) {
			var first = self.codeMirror.doc.firstLine()+1;
			var last = self.codeMirror.doc.lastLine()+1;

			self.gotoDialog.find(".gotoLabel").text("Enter line number ("+first+".."+last+"):");
			self.gotoDialog.find("input").val(self.codeMirror.doc.getCursor().line+1);
			self.gotoDialog.find("input").on("keyup", function() {
				var lineInput = $(this).val();

				var errMsg = "";
				if (lineInput !== "") {
					if (cmeditorbase_is_int(lineInput)) {
						var line = parseInt(lineInput);

						if(line < first || line > last) {
							errMsg = "Line number out of range";
						}
					} else {
						errMsg = "Not a number";
					}
				}

				if(errMsg !== "" && lineInput !== ""){
					self.gotoDialog.find(":button:contains('Ok')").prop("disabled", true).addClass("ui-state-disabled");
				}else{
					self.gotoDialog.find(":button:contains('Ok')").prop("disabled", true).removeClass("ui-state-disabled");
				}
				self.gotoDialog.find(".gotoError").text(errMsg);
			});

			self.gotoDialog.dialog("open");
		}
		/*
		 * Creates a new tab and sets the supplied document as its content
		 *
		 * Parameters: newDoc CMEditor.Doc: The document to insert
		 */
		function insertNewDocument(self, newDoc) {
			self.docs.push(newDoc);

			var docTabs = self.rootElem.find(".docs").get(0);
			var li = docTabs.appendChild(document.createElement("li"));
			li.appendChild($('<span class="tabName"></span>').text(newDoc.getName()).get(0));

			var closeButton = $('<span class="closeButton">&#10005;</span>');
			closeButton.on("click", function(){
										var doc = getDocumentByName(self, newDoc.getName());

										if(doc.needsSaving()){
											showWarning(self, "Do you really want to close this buffer? Unsaved changes will be lost.",
												{Close: function(){removeDocument(self, doc); $(this).dialog("close");}})
										}else{
											removeDocument(self, doc)
										}

									});
			li.appendChild(closeButton.get(0));

			if (self.codeMirror.getDoc() == newDoc.getCMDoc()) {
				markDocumentAsSelected(self, self.docs.length - 1);
				self.curDoc = newDoc;
			}

			selectDocumentByIndex(self, self.docs.length - 1);
			removeUntitledDocument(self);

			log(self, "insertNewDocument '"+newDoc.getName()+"' was performed. Current doc: "+self.curDoc)
		}

		/*
		 * Creates and registers a new (empty) document if there is none opened
		 */
		function insertNewUntitledDocument(self) {
			if (self.docs.length < 1) {
				var name = self.unregDocName = getUnambiguousName(self, "Untitled Document");

				var newDoc = new Doc(name, self.options.defaultMode, self.options.defaultContent,
										(self.options.readOnly||self.options.defaultReadOnly)?"nocursor":"");

				insertNewDocument(self, newDoc);
			}
			log(self, "insertNewUntitledDocument "+self.curDoc.getName()+" was performed.");
		}

		/*
		 * Marks a document as changed by placing a star next to its name
		 *
		 * Parameters: pos Integer: the index of the document to change
		 */
		function markDocumentAsChanged(self, pos) {
			var docTab = self.rootElem.find(".tabs li:nth-child("+(pos+1)+") .tabName");
			docTab.text("*"+ self.docs[pos].getName());

			log(self, "changed " + self.docs[pos].getName());
			log(self, "markDocumentAsChanged '"+pos+"' was performed.");
		}

		/*
		 * Adds a selected class to a document and removes it from all others
		 *
		 * Parameters: pos Integer: the index of the document to add the class to
		 */
		function markDocumentAsSelected(self, pos) {
			var docTabs = self.rootElem.find(".tabs").children();
			docTabs.removeClass("selected");
			docTabs.eq(pos).addClass("selected");

			log(self, "markDocumentAsSelected "+ pos +" was performed.")
		}

		/*
		 * Marks a document as unchanged by removing the star next to its name
		 *
		 * Parameters: pos Integer: the index of the document to change
		 */
		function markDocumentAsUnchanged(self, pos) {
			var docTab = self.rootElem.find(".tabs li:nth-child("+(pos+1)+") .tabName");
			docTab.text(self.docs[pos].getName());

			log(self, "unchanged " + self.docs[pos].getName());
			log(self, "markDocumentAsUnchanged '"+pos+"' was performed.");
		}

		/*
		 * Removes a document from the editor and its tab from the DOM
		 *
		 * Parameters: doc CMEditor.Doc: The document to remove
		 */
		function removeDocument(self, doc) {
			for (var i = 0; i < self.docs.length && doc != self.docs[i]; ++i) {}
			self.docs.splice(i, 1);

			var docList = self.rootElem.find(".docs").get(0);
			docList.removeChild(docList.childNodes[i]);

			insertNewUntitledDocument(self);
			selectDocumentByIndex(self, Math.max(0, i - 1));

			log(self, "removeDocument "+doc.getName()+" was performed.");
		}

		/*
		 * Unregisters a document previously created by `insertNewUntitledDocument`
		 */
		function removeUntitledDocument(self) {
			if (self.docs.length > 1) {
				var doc = getDocumentByName(self, self.unregDocName)
				if (doc && doc.isNew()) {
					removeDocument(self, doc);
				}
			}
			log(self, "removeUntitledDocument was performed.");
		}

		/*
		 * Selects a document and displays its contents in the editor
		 *
		 * Parameters: pos Integer: the index of the document to select
		 */
		function selectDocumentByIndex(self, pos) {
			markDocumentAsSelected(self, pos);
			self.curDoc = self.docs[pos];

			self.codeMirror.swapDoc(self.curDoc.getCMDoc());
			updateCurrentDocument(self);

			if(self.options.menu){
				self.menu.update();
			}

			focus(self);
			log(self, "selectDocumentByIndex "+ self.curDoc.getName() +" "+ pos +" was performed.")
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
		 * Serializes the currently opened document to the editor's form
		 */
		function writeCurrentDocToForm(self) {
			if (typeof self.set_form_doc_before == "function") self.set_form_doc_before();

			self.rootElem.find("form .cmeditor-field").each(function(){
				var elem = $(this);
				var key = elem.attr("data-docField") || elem.attr("name");

				if (elem.attr("data-field-property") && self.curDoc[key]) {
					setInputValue(self, elem, self.curDoc[key][elem.attr("data-field-property")] || "");
				} else {
					setInputValue(self, elem, self.curDoc[key] || "");
				}
			});

			self.rootElem.find("form #"+self.options.mapping.name+".cmeditor-field").val(self.curDoc.getName()||"");
			self.rootElem.find("form #"+self.options.mapping.mode+".cmeditor-field").val(self.curDoc.getMode()||"");
			self.rootElem.find("form #"+self.options.mapping.content+".cmeditor-field").val(self.curDoc.getContent()||"");

			if (typeof self.set_form_doc_after == "function") self.set_form_doc_after();

			log(self, "writeCurrentDocToForm "+ self.curDoc.getName() +" was performed.")
		}

		/*
		 * Sets the value of `elem` to `val`
		 *
		 * Parameters: elem jQuery: the element to set the value on
		 *             val String or Boolean: the value to set or if elem is a checkbox whether it should be checked or
		 *                                    unchecked
		 */
		function setInputValue(self, elem, val) {
			if (elem.attr("type") == "checkbox") {
				if (val) {
					elem.prop("checked", true);
				} else {
					elem.prop("checked", false);
				}
			} else {
				elem.val(val);
			}
		}

		/*
		 * Synchronizes the current document with the codeMirror instance.
		 * Called on every change of a document inside `self.codeMirror`
		 *
		 * Parameters: cmChangeObjects (optional) Object: See codeMirror docu on the 'changes' event
		 * Returns:    Boolean whether this document has changed
		 */
		function updateCurrentDocument(self, cmChangeObjects) {
			var docName = "no curDoc";
			var changed = false;

			if (self.curDoc) {
				docName = self.curDoc.getName();

				if (self.curDoc.getMode() != self.codeMirror.getOption("mode")) {
					self.codeMirror.setOption("mode", self.curDoc.getMode());
					changed = true;
					log(self, "mode changed");
				}

				if (cmChangeObjects && !cmChangeObjects.propertyIsEnumerable("cmeditor_custom_field")) {
					self.curDoc.setContent(self.curDoc.getCMDoc().getValue());
					changed = true;
					log(self, "content changed" + cmChangeObjects);
				}

				if (self.curDoc.getReadOnly() != self.codeMirror.getOption("readOnly")) {
					if (self.curDoc.getReadOnly()) {
						self.codeMirror.setOption("readOnly", self.curDoc.getReadOnly());
					} else {
						self.codeMirror.setOption("readOnly", false);
					}
				}

				if (cmChangeObjects && cmChangeObjects.propertyIsEnumerable("cmeditor_custom_field")) {
					changed = true;
					log(self, "custom field changed")
				}

				if (changed || cmChangeObjects) {
					markDocumentAsChanged(self, getDocumentPositionByName(self, self.curDoc.getName()));
					if (self.curDoc.isNew()) {
						self.curDoc.markUnsaved();
					} else if (self.curDoc.isUnchanged()) {
						self.curDoc.markChanged()
					}
				}

				writeCurrentDocToForm(self);
			}

			log(self, "updateCurrentDocument "+ docName +" was performed.")
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
				type:"GET",
				url: self.options.ajax.getURL+name,
				success: function(data){
					if (data.status == "success" && data.result) {
						var newDoc = new Doc(data.result[self.options.mapping.name],
						                        data.result[self.options.mapping.mode] || options.defaultMode,
						                        data.result[self.options.mapping.content],
						                        readWrite ? "" : ((options.readOnly || options.defaultReadOnly) ? "nocursor" : ""));
						newDoc[self.options.idField] = data.result[self.options.idField];
						newDoc.markUnchanged();
						insertNewDocument(self, newDoc);

						log(self, "ajax_load '"+name+"' was performed.");
						log(self, data.result.version)
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
			if (self.curDoc.needsSaving()) {
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
			self.rootElem.find(".cmeditor-tab-message").text(message)
			                .toggle("slide", {"direction":"up"})
			                .delay(3000)
			                .toggle("slide", {"direction":"up"});
		}

		/* (Public)
		 *
		 * Sets focus to the text editor
		 */
		function focus(self){
			//FIXME: warum funktioniert das nicht sofort?
			window.setTimeout(function(){self.codeMirror.focus()}, 50);
		}

		/* (Public)
		 *
		 * Gets the document id by document name
		 *
		 * Parameters: name String: The name of the document
		 * Returns:    Integer: the id of the document
		 */
		function getDocumentPositionByName(self, name) {
			for (var i = 0; i < self.docs.length; ++i)
				if (self.docs[i].getName() == name) return i;
		}

		/* (Public)
		 * Returns the mode in which the current document is opened
		 */
		function getCurrentCMEditorMode(self) {
			return self.curDoc.getMode();
		}

		/* (Public)
		 *
		 * Appends a number to a filename so that it is unambigous
		 *
		 * Parameters: name String: The name of the document
		 */
		function getUnambiguousName(self, name) {
			log(self, name);
			var data = [];
			if(self.options.ajax.listURL){
				$.ajax({
					url: self.options.ajax.listURL,
					success: function(json) {
						if (json.status == "success" && json.result) {
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
		 * Creates a new document with a name supplied by the user
		 */
		function newDoc(self) {
			log(self, "creating new doc");
			if(self.options.readOnly){
				displayMessage("This editor read only!");
			}else{
				var name = prompt("Name of the new buffer", "");
				if (name == null || name == "") return;
				name = getUnambiguousName(self, name);

				var newDoc = new Doc(name, self.options.defaultMode, self.options.defaultContent,
										(self.options.readOnly || self.options.defaultReadOnly) ? "nocursor":"");

				insertNewDocument(self, newDoc);
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
				var docId = getDocumentPositionByName(self, self.curDoc.getName());
				var oldName = self.docs[docId].getName();

				self.docs[docId].setName(newName);
				markDocumentAsChanged(self, docId);
				updateCurrentDocument(self);

				log(self, "rename '"+oldName+"', '"+newName+"' was performed.");
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

			var pos = getDocumentPositionByName(self, self.curDoc.getName());
			updateCurrentDocument(self);

			if (self.doDiffBeforeSaving) {
				var additionalButtons = {
						Save: function() { self.rootElem.find(".cmeditor-main form").submit(); $(this).dialog("close"); },
					};
				diff(self, additionalButtons);
			} else {
				self.rootElem.find(".cmeditor-main form").submit();
			}

			log(self, "save "+ self.curDoc.getName() +" ("+ pos +") was performed.");
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
			self.curDoc[self.options.idField] = "";

			save(self);
			log(self, "saveas was performed.");
		}

		/* (Public)
		 * Sets whether this CMEditor should show a diff before it saves
		 */
		function setDoDiffBeforeSaving(self, value) {
			self.doDiffBeforeSaving = value;
			log(self, "setDoDiffBeforeSaving " + value + " was performed.")
		}

		/* (Public)
		 * Updates mode and read-onlyness of the current document to the corresponding properties
		 * of the underlying codeMirror
		 */
		function update(self) {
			var docName = "no curDoc";
			if(self.curDoc){
				docName = self.curDoc.getName();

				if(self.curDoc.getReadOnly() != self.codeMirror.getOption("readOnly")){
					self.curDoc.setReadOnly(self.codeMirror.getOption("readOnly"));
				}

				if(self.curDoc.getMode() != self.codeMirror.getOption("mode")){
					self.curDoc.setMode(self.codeMirror.getOption("mode"));

					markDocumentAsChanged(self, getDocumentPositionByName(self, self.curDoc.getName()));

					if (self.curDoc.isNew()){
						self.curDoc.markUnsaved();
					}else if(self.curDoc.isUnchanged()){
						self.curDoc.markChanged();
					}
				}

				updateCurrentDocument(self);
			}
			log(self, "update "+ docName +" was performed.")
		}


		CMEditor.prototype.constructor = CMEditor;

		//Zugegriffen aus Menu
		CMEditor.prototype.ajax_load      = function(){Array.prototype.unshift.call(arguments, this); return ajax_load.apply(this, arguments)};
		CMEditor.prototype.close          = function(){Array.prototype.unshift.call(arguments, this); return close.apply(this, arguments)};
		CMEditor.prototype.diff           = function(){Array.prototype.unshift.call(arguments, this); return diff.apply(this, arguments)};
		CMEditor.prototype.delete         = function(){Array.prototype.unshift.call(arguments, this); return deleteDoc.apply(this, arguments)};
		CMEditor.prototype.doc_id         = function(){Array.prototype.unshift.call(arguments, this); return getDocumentPositionByName.apply(this, arguments)};
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


		var Doc = CMEditor.Doc = function Doc(name, mode, content, readOnly, cmDoc){
			this.content = content;
			this.mode = mode;
			this.name = name;
			this.origContent = content;
			this.readOnly = readOnly;
			this.status = "new";

			if(cmDoc === undefined)
				this.codeMirrorDoc = new CodeMirror.Doc(content, mode);
			else
				this.codeMirrorDoc = cmDoc;
		}

		Doc.status = {NEW: "new",             // the document has never been saved and has not been changed yet
					  UNSAVED: "unsaved",     // the document has never been saved and has been changed
					  CHANGED: "changed",     // the document has been saved or opened and has been changed since
					  UNCHANGED: "unchanged", // the document has been saved or opened and not been changed since
					 };

		Doc.prototype.constructor = Doc;

		Doc.prototype.getCMDoc    = function(){return this.codeMirrorDoc};
		Doc.prototype.getContent  = function(){return this.content};
		Doc.prototype.getMode     = function(){return this.mode};
		Doc.prototype.getName     = function(){return this.name};
		Doc.prototype.getReadOnly = function(){return this.readOnly};
		Doc.prototype.isNew       = function(){return this.status == Doc.status.NEW};
		Doc.prototype.isChanged   = function(){return this.status == Doc.status.CHANGED};
		Doc.prototype.isUnchanged = function(){return this.status == Doc.status.UNCHANGED};
		Doc.prototype.isUnsaved   = function(){return this.status == Doc.status.UNSAVED};
		Doc.prototype.needsSaving = function(){return this.status == Doc.status.UNSAVED || this.status == Doc.status.CHANGED};

		Doc.prototype.markNew       = function(){this.status = Doc.status.NEW};
		Doc.prototype.markChanged   = function(){this.status = Doc.status.CHANGED};
		Doc.prototype.markUnsaved   = function(){this.status = Doc.status.UNSAVED};
		Doc.prototype.markUnchanged = function(){this.status = Doc.status.UNCHANGED};
		Doc.prototype.setContent    = function(content){this.content = content};
		Doc.prototype.setMode       = function(mode){this.mode = mode};
		Doc.prototype.setName       = function(name){this.name = name};
		Doc.prototype.setReadOnly   = function(readOnly){this.readOnly = readOnly};

		return CMEditor;
	})();
</script>
