//= require cmeditor-dependencies

this.CMEditor = (function(){

	//FIXME: IE kann kein Function.name (siehe log())
	//FIXME: custom elements funktionieren noch nicht
	//TODO: focus() hat probleme
	//TODO: Sachen optimieren? zB mehr dom-objekte speichern, dialoge nicht mit html und jquery erzeugen...
	//TODO: add loglevel

	function CMEditor(rootElem, options, instanceName){
		//allow the user to omit new
		if (!(this instanceof CMEditor)) return new CMEditor(rootElem, options, instanceName);
		var self = this;
		self.instanceNo = CMEditor.instanciated++;
		self.instanceName = instanceName !== undefined ? instanceName : "";
        if(self.instanceName == "")
            log("Warning: No instance name supplied, fullscreen mode will be disabled!");

		self.rootElem = $(rootElem);
		self.options  = options = options !== undefined ? options : {};
		self.options.ajax = options.ajax !== undefined ? options.ajax : {}
		self.options.mapping = options.mapping !== undefined ? options.mapping : {}
		self.options.defaultContent = options.defaultContent !== undefined ? options.defaultContent : "";

		self.docs = [];
		self.eventHooks = {};
		for(hookName in options.hooks){
			on(self, hookName, options["hooks"][hookName]);
		}

		initDialogs(self);
		initEventListeners(self);
		initCodeMirror(self, options);

		if(options.menu){
			var menuRootElem = self.rootElem.find(".cmeditor-menu");
			executeHooks(self, "preMenuInit", menuRootElem);
			self.menu = new CMEditorMenu(self, menuRootElem, options, instanceName);
			executeHooks(self, "postMenuInit", menuRootElem, [self.menu]);
		}

		insertNewUntitledDocument(self);
		syncTabIndent(self);

		$(document).bind("keydown", function(e){
			//disable some browser featues when the codeMirror has focus
			if(e.ctrlKey && self.rootElem.find("CodeMirror-focused").size() !== 0){
				e.preventDefault();
			}

			if(e.which == 122 && !self.codeMirror.getOption("readOnly") && (self.rootElem.find("*:focus").size() > 0 || self.codeMirror.hasFocus())){
				toggleFullscreen(self);
				e.preventDefault();
			}
		});

		if(self.options.preloadModules){
			preloadModules(self);
		}

		registerInstance(self.instanceName, self.instanceNo, self);

	}

	/*************************************************************************
	 *                    Begin 'static' methods                             *
	 *************************************************************************/
	var clazz = CMEditor;

	clazz.instanciated = 0;
	clazz.instancesNumber = {};
	clazz.instancesString = {};
	clazz.instances = [];
	clazz.loadedResources = [];

	/*
	 * Logs to the console. If possible prefixed by class name, instance number. The default logLevel is INFO.
	 * Possible values are: ERROR, WARNING, INFO, DEBUG. If Data is supplied, its entries will be printed
	 * one per line
	 *
	 * Possible Parameter combinations:
	 * Message (String), [Loglevel (String, "INFO"), [Data (List of Objects)]]
	 * Instance (Object), Message (String), [Loglevel (String, "INFO"), [Data (Object|List of Objects)]]]
	 */
	var LOGLEVELS = {ERROR: 0, WARNING: 5, INFO: 10, DEBUG: 15}
	var log = clazz.log = function(arg0, arg1, arg2, arg3){
		var className = ((typeof clazz.name != "undefined") ? clazz.name : "IE,really?");
		var instance = "";
		var message = "";
		var logLevel = LOGLEVELS.INFO;
		var data = [];

		if(arg0 instanceof clazz){
			instance = " #" + arg0.instanceNo + " '" + arg0.instanceName +"'";
			message = arg1;
			logLevel = (typeof arg2 != "undefined") ? LOGLEVELS[arg2] : LOGLEVELS.INFO;
			data = ((typeof arg3 != "undefined")? ((arg3 instanceof Array)? arg3 : [arg3]) : []);
		}else{
			message = arg0;
			logLevel = (typeof arg1 != "undefined") ? LOGLEVELS[arg1] : LOGLEVELS.INFO;
			data = ((typeof arg2 != "undefined")? ((arg2 instanceof Array)? arg2 : [arg2]) : []);
		}

		if(logLevel == LOGLEVELS.DEBUG)    var logF = function(data){console.log(data);}
		if(logLevel == LOGLEVELS.INFO)     var logF = function(data){console.info(data);}
		if(logLevel == LOGLEVELS.WARNING)  var logF = function(data){console.warn(data);}
		if(logLevel == LOGLEVELS.ERROR)    var logF = function(data){console.error(data);}

		logF(className + instance + ": " + message);
		if(data.length != 0){
			console.groupCollapsed != undefined && data.length > 1 && console.groupCollapsed();
			for(var i=0; i<data.length; i++){
				logF(data[i]);
			}
			console.groupEnd != undefined && data.length > 1 &&  console.groupEnd();
		}
	}

	/*
	 * Registers an instance so that it can be accessed with `getInstance`
	 */
	var registerInstance = clazz.registerInstance = function(instanceName, instanceNo, instance){
		clazz.instancesString[instanceName] = instance;
		clazz.instancesNumber[instanceNo]   = instance;
		clazz.instances.push(instance);
		log("registered new textAreaCMEditor instance #" + instanceNo + " '" + instanceName + "'", "INFO");
	}

	/*
	 * Returns an instance of this class
	 *
	 * Parameters: identifier (String|Number): the instance name or number
	 */
	var getInstance = clazz.getInstance = function(identifier){
	 	if(typeof identifier == "number")
	 		return clazz.instancesNumber[identifier];
	 	else
	 		return clazz.instancesString[identifier];
	}

	/*
	 * Returns all instances of this class
	 */
	var getInstances = clazz.getInstances = function(){
	 	return clazz.instances;
	}

	/*
	 * Loads a (css or js) resource if it is not yet loaded, then calls a callback
	 *
	 * Parameters: location String: the resource location
	 *             callback Function: called when resource was loaded successfully or is already available
	 */
	var loadResource = clazz.loadResource = function(location, callback){
        if($.inArray(location, clazz.loadedResources) != -1){
			if(callback !== undefined) callback();
			return;
		}

		$.ajax(location)
		 .done(function(data){
			//js is being evaluated automatically
			if(location.indexOf("css", location.length - 3) !== -1){
		 		$("head").append("<style>" + data + "</style>");
			}

			clazz.loadedResources.push(location);
			if(callback !== undefined)
				callback();
		 })
		 .fail(function(){
		 	log("Could not load the resource at "+location, "WARNING");
		 });
	}

	/*
	 * Loads a theme if it is not yet loaded, then calls a callback. Requires the static
	 * property "themeBaseURL" to be set correctly
	 *
	 * Parameters: themeName String: the theme's name
	 *             callback Function: called when resource was loaded successfully or is already available
	 */
	var loadTheme = clazz.loadTheme = function(themeName, callback){
		if(clazz.themeBaseURL === undefined){
			log("Could not load theme. Please set the themeBaseURL", "WARNING");
			return;
		}
		if(themeName == "default"){
			if(callback !== undefined) callback();
			return;
		}
		loadResource(clazz.themeBaseURL+themeName+".css", callback);
	}

	/*
	 * Loads a mode if it is not yet loaded, then calls a callback. Requires the static
	 * property "modeBaseURL" to be set correctly
	 *
	 * Parameters: modeName String: the mode's name
	 *             callback Function: called when resource was loaded successfully or is already available
	 */
	var loadMode = clazz.loadMode = function(modeName, callback){
		if(clazz.modeBaseURL === undefined){
            log("Could not load mode. Please set the modeBaseURL", "WARNING");
			return;
		}
		loadResource(clazz.modeBaseURL+modeName+"/"+modeName+".js", callback);
	}

	/*************************************************************************
	 *                    Begin 'private' methods                            *
	 *************************************************************************/

	/*
	 *	Initiates the actual CodeMirror and sets our own key map
	 */
	function initCodeMirror(self, options) {
		var keyMap = {
			"Ctrl-Space": "autocomplete",
			"Ctrl-S":     function(cm) { save(self);},
			"Ctrl-Q":     function(cm){ cm.foldCode(cm.getCursor()); },
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
			CodeMirror.commands.autocomplete = function(cm, getHints, hintOptions) {
				//var mergedOptions = $.extend({}, hintOptions, {cmeditorDefinitions: options.overlayDefinitionsVar});
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

		var codeMirror = self.codeMirror = CodeMirror.fromTextArea(self.rootElem.find(".cmeditor-main .cmTarget").get(0), codeMirrorOptions);

		if(options.useSession){
			if(localStorage["cmeditor-menu-binding"])
				codeMirror.setOption("keymap", localStorage["cmeditor-menu-binding"]);
			else
				codeMirror.setOption("keymap", "default");

			if(localStorage["cmeditor-menu-theme"])
				loadTheme(localStorage["cmeditor-menu-theme"], function(){codeMirror.setOption("theme", localStorage["cmeditor-menu-theme"]); copyCMTheme(self);});
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
			syncTabIndent(self);
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

		//changes in custom inputs
		mainForm.find(".cmeditor-field").keyup(function() { customElementChanged(self, $(this));});
		mainForm.find("select.cmeditor-field").change(function() {customElementChanged(self, $(this));});
		mainForm.find("input[type='checkbox'].cmeditor-field").change(function() { customElementChanged(self, $(this));});
	}

	/*
	 * Performs the actual deletion
	 */
	function ajax_delete(self) {
		if(self.options.readOnly){
			displayMessage("This document is read-only and cannot be deleted");
			return;
		}

		if (self.curDoc.hasID()) {

			var data = {};
			data[self.options.mapping.idField] = self.curDoc.getID();

			$.ajax({
				type:"GET",
				data: data,
				url: self.options.ajax.deleteURL,
				success:function(data, textStatus){
					if (data.status == "success") {
						removeDocument(self, self.curDoc);
						log(self, "Deleted a document from the server", "INFO");
					}else{
						log(self, "Could not delete this file from the server", "WARNING", data);
						log(self, "Message was:" + data.msg, "DEBUG");
					}
					if(data.msg)
						displayMessage(self, data.msg, textStatus);
					log(self, "Currently serving these documents locally:", "DEBUG", self.docs)
				},
				error:function(XMLHttpRequest,textStatus,errorThrown){
					displayMessage(self, "An error occured: "+ textStatus +" " + errorThrown);
					log(self, "Could not delete this file from the server", "WARNING", data);
				}
			});
		}

		return false;
	}

	/*
	 * Reinitiates the current document from the server
	 *
	 * Parameters: newId (Integer|String): If supplied the document will be replaced by this one
	 */
	function ajax_reload(self, newId) {
		if (self.curDoc) {
			if(typeof newId == "undefined")
				newId = self.curDoc.getID();

			removeDocument(self, self.curDoc);
			ajax_load(self, newId, true);
		}
	}

	/*
	 *	Triggers updating the document on server side and then reloads it from the server
	 */
	function ajax_update(self) {
		if (self.curDoc) {

			var data = {};
			jQuery.extend(data, self.curDoc.getCustomData()); //'clone' into the data object
			data[self.options.mapping.idField] = self.curDoc.getID();
			data[self.options.mapping.mode] = self.curDoc.getMode();
			data[self.options.mapping.name] = self.curDoc.getName();
			data[self.options.mapping.content] = self.curDoc.getContent();

			$.ajax({
				type: "POST",
				data: data,
				url: self.options.ajax.updateURL,
				success: function(data,textStatus){
					if (data.status == "success") {
						if (data.newId) {
							ajax_reload(self, data.newId);
						}else{
							ajax_reload(self);
						}
						log(self, "Saved a document to the server", "INFO");
					}else{
						log(self, "Could not save this document to the server.", "WARNING", data);
					}
					if(data.msg)
						displayMessage(self, data.msg, textStatus);
				},
				error:function(XMLHttpRequest,textStatus,errorThrown){
					displayMessage(self, "An error occured: "+ textStatus +" " + errorThrown);
					log(self, "Could not save this document to the server.", "WARNING", data);
				}
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

			// First handle the cases where a custom element corresponds to a mapped value
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

			} else if (key == self.options.mapping.idField) {
				old = self.curDoc.getID();
				sef.curDoc.setID(getCustomElementValue(self, elem));

			}
			//else handle all other cases
			else {
				if (elem.attr("data-field-property")) {
					if (self.curDoc.getCustomDataField(key)) {
						old = self.curDoc.getCustomDataField(key)[elem.attr("data-field-property")];
					} else {
						self.curDoc.setCustomDataField(key, {});
					}
					self.curDoc.getCustomDataField(key)[elem.attr("data-field-property")] = getCustomElementValue(self, elem);
				} else {
					old = self.curDoc.getCustomDataField(key);
					self.curDoc.setCustomDataField(key, getCustomElementValue(self, elem));
				}
			}

			if (doUpdate) {
				updateCurrentDocument(self, {cmeditor_custom_field: true, old:old, new:getCustomElementValue(self, elem)});
			}
		}

		log(self, "The user changed a custom element", "INFO");
	}

	/* (Public)
	 * Sets the code mirror theme and copies some styles to the CMEditor to match the theme as closely as possible
	 */
	function copyCMTheme(self){
		var id = self.rootElem.attr("id");
		var style = self.rootElem.children("style").eq(0);
		style.text("");

		function copyCSS(fromSelector, targetSelector, propertyName, targetPropertyName){
			var target =  "#" + id + (targetSelector!=null ? " " + targetSelector : "");
			if(targetPropertyName == undefined)
				targetPropertyName = propertyName;

			style.text(style.text()+"\n"+target+"{"+targetPropertyName+":"+self.rootElem.find(fromSelector).css(propertyName)+"}");
		}

		copyCSS(".CodeMirror-gutters", null, "background-color");
		copyCSS(".CodeMirror-linenumber", null, "color");
		copyCSS(".CodeMirror", "input", "color");
		copyCSS(".CodeMirror", "input", "background-color");

		copyCSS(".CodeMirror-gutters", "ul.tabs li", "border-right-color", "border-color");
		copyCSS(".CodeMirror-gutters", "ul.tabs li", "border-right-width", "border-width");
		style.text(style.text()+"\n #"+id+" ul.tabs li {border-bottom-width: 0px}");
		copyCSS(".CodeMirror", "ul.tabs li", "background-color");
		copyCSS(".CodeMirror", "ul.tabs li", "color");
	}

	/*
	 * Calculates and draws the diff
	 */
	function decorateDiffDialog(self) {

		var base    = difflib.stringAsLines(self.curDoc.getOrigContent()),
			newtxt  = difflib.stringAsLines(self.curDoc.getContent()),
			diffoutputdiv = self.diffDialog.find(".diffoutput"),
			contextSize   = self.diffDialog.find("input[name=contextSize]").val();

		var opcodes = new difflib.SequenceMatcher(base, newtxt).get_opcodes();

		diffoutputdiv.text("");
		contextSize = contextSize || null;

		if (opcodes && opcodes.length == 1 && opcodes[0][0] == "equal") {
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
	 * Executes all hooks that were registered using `on` on `eventName`
	 *
	 * Parameters: eventName String: the event of which all hooks should be called
	 *             context Object: the object that `this` should be set to in the hook
	 *             args Array: the parameters to pass to the hook as an array
	 */
	function executeHooks(self, eventName, context, args){
		for(var i=0; self.eventHooks[eventName] && i<self.eventHooks[eventName].length; i++){
			if(typeof self.eventHooks[eventName][i] == "function")
				self.eventHooks[eventName][i].apply(context, args);
			else
				log(self, "A hook was not executed because it is not a function", "WARNING");
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
		closeButton.on("click", function(e){
									var doc = getDocumentByName(self, newDoc.getName());

									if(doc.needsSaving()){
										showWarning(self, "Do you really want to close this buffer? Unsaved changes will be lost.",
											{Close: function(){removeDocument(self, doc); $(this).dialog("close");}})
									}else{
										removeDocument(self, doc);
									}
									e.stopPropagation();

								});
		li.appendChild(closeButton.get(0));

		if (self.codeMirror.getDoc() == newDoc.getCMDoc()) {
			markDocumentAsSelected(self, self.docs.length - 1);
			self.curDoc = newDoc;
		}

		selectDocumentByIndex(self, self.docs.length - 1);
		removeUntitledDocument(self);

		log(self, "Inserted a new document", "INFO");
		log(self, "This document was inserted", "DEBUG", newDoc);
	}

	/*
	 * Creates and registers a new (empty) document if there is none opened
	 */
	function insertNewUntitledDocument(self) {
		if (self.docs.length < 1) {
			var name = self.unregDocName = getUnambiguousName(self, "Untitled Document");

			var newDoc = new Doc(name, self.options.defaultMode, self.options.defaultContent,
									(self.options.readOnly||self.options.defaultReadOnly)?"nocursor":"");


			//insert custom data, if it is present in the form
			self.rootElem.find("form .cmeditor-field").each(function(){
				var elem = $(this);
				var key = elem.attr("name");
				newDoc.setCustomDataField(key, elem.attr('value')!=undefined?elem.attr('value'):"");
			});

			insertNewDocument(self, newDoc);
		}
	}

	/*
	 * Marks a document as changed by placing a star next to its name
	 *
	 * Parameters: pos Integer: the index of the document to change
	 */
	function markDocumentAsChanged(self, pos) {
		var docTab = self.rootElem.find(".tabs li:nth-child("+(pos+1)+") .tabName");
		docTab.text("*"+ self.docs[pos].getName());

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

	}

	/*
	 * Marks a document as unchanged by removing the star next to its name
	 *
	 * Parameters: pos Integer: the index of the document to change
	 */
	function markDocumentAsUnchanged(self, pos) {
		var docTab = self.rootElem.find(".tabs li:nth-child("+(pos+1)+") .tabName");
		docTab.text(self.docs[pos].getName());

	}

	/*
	 * Loads all modules in options.availableThemes and options.availableModes
	 */
	function preloadModules(self){
		for(var i=0; i<self.options.availableThemes.length; i++){
			loadTheme(self.options.availableThemes[i]);
		}
		for(var i=0; i<self.options.availableModes.length; i++){
			loadMode(self.options.availableModes[i]);
		}
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
	 * Syncs the indentation of the tabs to fit the indenation of the CodeMirror's gutter
	 */
	function syncTabIndent(self){
		self.rootElem.find(".docs").css("padding-left", self.rootElem.find(".CodeMirror-gutters").width());
	}

	/*
	 * Checks whether the list `data` has an entry with the value `name`. Type conversion is performed.
	 *
	 * Parameters: data List: the list of which to check the values
	 *             name Object: the value to look for
	 *
	 * Returns:    true if the entry is found, else false
	 */
	function listContainsElem(self, data, name) {
		for (var i = 0; i < data.length; ++i)
			if (data[i] == name)
				return true;

		return false
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
			}

			if (cmChangeObjects && !cmChangeObjects.propertyIsEnumerable("cmeditor_custom_field")) {
				self.curDoc.setContent(self.curDoc.getCMDoc().getValue());
				changed = true;
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

		return changed;
	}


	/*************************************************************************
	 *                                                                       *
	 *                     Begin 'public' methods                            *
	 *                                                                       *
	 *************************************************************************/

	/* (Public)
	 * Loads a document from the server
	 *
	 * Parameters: fileId (Integer|String): The document's id
	 *             readWrite Boolean: If true document will always be writable, else it will be readOnly
	 *                                if options.readOnly or options.defaultReadOnly is set to true
	 */
	function ajax_load(self, fileId, readWrite) {
		var data = {};
		data[self.options.mapping.idField] = fileId;

		$.ajax({
			type:"GET",
			data: data,
			url: self.options.ajax.getURL,
			success: function(data){
				if (data.status == "success" && data.result) {
					var newDoc = new Doc(data.result[self.options.mapping.name],
					                        data.result[self.options.mapping.mode] || self.options.defaultMode,
					                        data.result[self.options.mapping.content],
					                        readWrite ? "" : ((self.options.readOnly || self.options.defaultReadOnly) ? "nocursor" : ""));
					newDoc.setID(data.result[self.options.mapping.idField]);

					//insert custom data, if it is present in the form
					self.rootElem.find("form .cmeditor-field").each(function(){
						var elem = $(this);
						var key = elem.attr("name");

						if(listContainsElem(self, Object.keys(self.options.mapping), key))
							return true; //jquery-Each continue

						elem.val(data.result[key]);
						newDoc.setCustomDataField(key, data.result[key]!=undefined?data.result[key]:"");
					});

					newDoc.markUnchanged();
					insertNewDocument(self, newDoc);

					if(data.msg)
						displayMessage(self, data.msg);
				} else {
					displayMessage(self, data.msg);
				}
			},

		error:function(XMLHttpRequest,textStatus,errorThrown){displayMessage(self, "An error occured: "+ textStatus +" " + errorThrown);},
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
		var namesOnServer = [];
		if(self.options.ajax.listURL){
			$.ajax({
				url: self.options.ajax.listURL,
				success: function(json) {
					if (json.status == "success" && json.result) {
						for(var i=0; i<json.result.length; i++){
							namesOnServer.push(json.result[i][self.options.mapping["name"]]);
						}
					}
				},
				async:false
			});
		}
		var i = 0;
		while (getDocumentByName(self, name + (i || "")) || listContainsElem(self, namesOnServer, name + (i || "")))
			i++;

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
		if(self.options.readOnly){
			displayMessage("This editor read only!");
		}else{
			var name = prompt("Name of the new buffer", "");
			if (name == null)
				return;

			if(name.trim() == ""){
				displayMessage(self, "Please supply a filename");
				return;
			}

			name = getUnambiguousName(self, name.trim());

			var newDoc = new Doc(name, self.options.defaultMode, self.options.defaultContent,
									(self.options.readOnly || self.options.defaultReadOnly) ? "nocursor":"");


			insertNewDocument(self, newDoc);
			selectDocumentByIndex(self, self.docs.length - 1);
		}
	}

	/* (Public)
	 *
	 * Can be used to register callbacks for events.
	 *
	 * Available Events in CMEditor:
	 *
	 *     preSerializeDoc: Fired before the content of the current document is serialized to the form used to send the data to server.
	 *                      Basically this happens everytime something in the document changes.
	 *                      Your callback will be called in the context of the editor's root element and it will be passed
	 *                      the current document as first argument
	 *     postSerializeDoc: Fired after the content of the current document is serialized to the form used to send the data to server.
	 *                      Basically this happens everytime something in the document changes.
	 *                      Your callback will be called in the context of the editor's root element and it will be passed
	 *                      the current document as first argument
	 *
	 *     preMenuInit: Fired before the menu of this CMEditor is initiated, i.e. before its constructor is called
	 *                  This happens in the constructor of the CMEditor, so usually you have to set hooks to this event via
	 *                  the options object
	 *                  Your callback will be called in the context of the menu's root element
	 *     postMenuInit: Fired after the menu of this CMEditor is initiated, i.e. after its constructor has been called
	 *                  This happens in the constructor of the CMEditor, so usually you have to set hooks to this event via
	 *                  the options object
	 *                  Your callback will be called in the context of the menu's root element and passed the menu object as first
	 *                  argument
	 *
	 */
	function on(self, eventName, hook){
		if(self.eventHooks[eventName] === undefined)
			self.eventHooks[eventName] = [];

		self.eventHooks[eventName].push(hook);

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

			if(self.docs[docId].isRenamed())
				self.docs[docId].markUnsaved();
			else
				self.docs[docId].markChanged();

			updateCurrentDocument(self);

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
					Save: function() { ajax_update(self); $(this).dialog("close"); },
				};
			diff(self, additionalButtons);
		} else {
			self.rootElem.find(".cmeditor-main form").submit();
		}

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
		self.curDoc.setID("");

		save(self);
	}

	/* (Public)
	 * Sets whether this CMEditor should show a diff before it saves
	 */
	function setDoDiffBeforeSaving(self, value) {
		self.doDiffBeforeSaving = value;
	}

	/* (Public)
	 * Enters or leaves fullscreen mode
	 */
	function toggleFullscreen(self){
		if(self.instanceName == ""){
            return;
		}

        if(self.cssBeforeFullscreen == undefined){
            self.cssBeforeFullscreen = {"position": self.rootElem.css("position"),
                                "top":  self.rootElem.css("top"),
                                "left":  self.rootElem.css("left"),
                                "height":  self.rootElem.css("height"),
                                "width":  self.rootElem.css("width")};
            self.oldDocumentOverflow = document.documentElement.style.overflow;
            document.documentElement.style.overflow = "hidden";
            self.rootElem.css({"position": "fixed", "top": "0", "left": "0", "height": "100%", "width": "100%"});
            self.rootElem.addClass("cmeditor-fullscreen");

            self.layout = self.rootElem.layout({
					east__paneSelector:   "#cmeditor-"+self.instanceName+"-easternpane",
					center__paneSelector: "#cmeditor-"+self.instanceName+"-centerpane",
					north__paneSelector:  "#cmeditor-"+self.instanceName+"-northernpane",
					north__size: 75,
					north__resizable:false
					});

            self.codeMirror.refresh();
			syncTabIndent(self);

        }else{

        	self.layout.destroy();

            self.rootElem.removeClass("cmeditor-fullscreen");
            self.rootElem.css(self.cssBeforeFullscreen);
            document.documentElement.style.overflow = self.oldDocumentOverflow;
            self.cssBeforeFullscreen = undefined;

            self.codeMirror.refresh();
			syncTabIndent(self);
        }
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
	}

	/* (Public)
	 * Serializes the currently opened document to the editor's form
	 */
	function writeCurrentDocToForm(self) {
		executeHooks(self, "preSerializeDoc", self.rootElem, [self.curDoc]);

		self.rootElem.find("form .cmeditor-field").each(function(){
			var elem = $(this);
			var key = elem.attr("name");

			if (elem.attr("data-field-property") && self.curDoc.getCustomDataField(key)) {
				//if the element indicates to use the property of an object, use it
				setInputValue(self, elem, self.curDoc.getCustomDataField(key)[elem.attr("data-field-property")] || "");
			} else {
				setInputValue(self, elem, self.curDoc[key] || self.curDoc.getCustomDataField(key) || "");
			}
		});

		executeHooks(self, "postSerializeDoc", self.rootElem, [self.curDoc]);

	}



	CMEditor.prototype.constructor = CMEditor;

	//public methods
	CMEditor.prototype.ajax_load                 = function(){Array.prototype.unshift.call(arguments, this); return ajax_load.apply(this, arguments)};
	CMEditor.prototype.closeDoc                  = function(){Array.prototype.unshift.call(arguments, this); return close.apply(this, arguments)};
	CMEditor.prototype.copyCMTheme               = function(){Array.prototype.unshift.call(arguments, this); return copyCMTheme.apply(this, arguments)};
	CMEditor.prototype.diff                      = function(){Array.prototype.unshift.call(arguments, this); return diff.apply(this, arguments)};
	CMEditor.prototype.deleteDoc                 = function(){Array.prototype.unshift.call(arguments, this); return deleteDoc.apply(this, arguments)};
	CMEditor.prototype.getDocumentPositionByName = function(){Array.prototype.unshift.call(arguments, this); return getDocumentPositionByName.apply(this, arguments)};
	CMEditor.prototype.focus                     = function(){Array.prototype.unshift.call(arguments, this); return focus.apply(this, arguments)};
	CMEditor.prototype.getUnambiguousName        = function(){Array.prototype.unshift.call(arguments, this); return getUnambiguousName.apply(this, arguments)};
	CMEditor.prototype.getCurrentCMEditorMode    = function(){Array.prototype.unshift.call(arguments, this); return getCurrentCMEditorMode.apply(this, arguments)};
	CMEditor.prototype.getCodeMirror             = function(){Array.prototype.unshift.call(arguments, this); return getCodeMirror.apply(this, arguments)};
	CMEditor.prototype.goto                      = function(){Array.prototype.unshift.call(arguments, this); return goto.apply(this, arguments)};
	CMEditor.prototype.newDoc                    = function(){Array.prototype.unshift.call(arguments, this); return newDoc.apply(this, arguments)};
	CMEditor.prototype.on                        = function(){Array.prototype.unshift.call(arguments, this); return on.apply(this, arguments)};
	CMEditor.prototype.saveDoc                   = function(){Array.prototype.unshift.call(arguments, this); return save.apply(this, arguments)};
	CMEditor.prototype.saveDocAs                 = function(){Array.prototype.unshift.call(arguments, this); return saveas.apply(this, arguments)};
	CMEditor.prototype.setDoDiffBeforeSaving     = function(){Array.prototype.unshift.call(arguments, this); return setDoDiffBeforeSaving.apply(this, arguments)};
	CMEditor.prototype.toggleFullscreen          = function(){Array.prototype.unshift.call(arguments, this); return toggleFullscreen.apply(this, arguments)};
	CMEditor.prototype.renameDoc                 = function(){Array.prototype.unshift.call(arguments, this); return rename.apply(this, arguments)};
	CMEditor.prototype.update                    = function(){Array.prototype.unshift.call(arguments, this); return update.apply(this, arguments)};
	CMEditor.prototype.displayMessage            = function(){Array.prototype.unshift.call(arguments, this); return displayMessage.apply(this, arguments)};
	CMEditor.prototype.writeCurrentDocToForm     = function(){Array.prototype.unshift.call(arguments, this); return writeCurrentDocToForm.apply(this, arguments)};

	//public methods, deprecated; use the corresponding from above
	CMEditor.prototype.close                     = function(){log("using close is deprecated. use closeDoc instead", "WARNING");
                                                              Array.prototype.unshift.call(arguments, this); return close.apply(this, arguments)};
	CMEditor.prototype.delete                    = function(){log("using delete is deprecated. use deleteDoc instead", "WARNING");
                                                              Array.prototype.unshift.call(arguments, this); return deleteDoc.apply(this, arguments)};
	CMEditor.prototype.doc_id                    = function(){log("using doc_id is deprecated. use getDocumentPositionByName instead", "WARNING");
                                                              Array.prototype.unshift.call(arguments, this); return getDocumentPositionByName.apply(this, arguments)};
	CMEditor.prototype.get_name                  = function(){log("using get_name is deprecated. use getUnambiguousName instead", "WARNING");
                                                              Array.prototype.unshift.call(arguments, this); return getUnambiguousName.apply(this, arguments)};
	CMEditor.prototype.get_mode                  = function(){log("using get_mode is deprecated. use getCurrentCMEditorMode instead", "WARNING");
                                                              Array.prototype.unshift.call(arguments, this); return getCurrentCMEditorMode.apply(this, arguments)};
	CMEditor.prototype.new                       = function(){log("using new is deprecated. use newDoc instead", "WARNING");
                                                              Array.prototype.unshift.call(arguments, this); return newDoc.apply(this, arguments)};
	CMEditor.prototype.set_diff_before_save      = function(){log("using set_diff_before_save is deprecated. use setDoDiffBeforeSaving instead", "WARNING");
                                                              Array.prototype.unshift.call(arguments, this); return setDoDiffBeforeSaving.apply(this, arguments)};
	CMEditor.prototype.save                      = function(){log("using save is deprecated. use saveDoc instead", "WARNING");
                                                              Array.prototype.unshift.call(arguments, this); return save.apply(this, arguments)};
	CMEditor.prototype.saveas                    = function(){log("using saveas is deprecated. use saveDocAs instead", "WARNING");
                                                              Array.prototype.unshift.call(arguments, this); return saveas.apply(this, arguments)};
	CMEditor.prototype.rename_doc                = function(){log("using rename_doc is deprecated. use renameDoc instead", "WARNING");
                                                              Array.prototype.unshift.call(arguments, this); return rename.apply(this, arguments)};
	CMEditor.prototype.update_message            = function(){log("using update_message is deprecated. use displayMessage instead", "WARNING");
                                                              Array.prototype.unshift.call(arguments, this); return displayMessage.apply(this, arguments)};

	var Doc = CMEditor.Doc = function Doc(name, mode, content, readOnly, cmDoc){
		this.content = content;
		this.idField = null;
		this.mode = mode;
		this.name = name;
		this.origContent = content;
		this.origName = name;
		this.readOnly = readOnly;
		this.status = "new";
		this.customData = {};

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

	//Getter
	Doc.prototype.getCMDoc    = function(){return this.codeMirrorDoc};
	Doc.prototype.getContent  = function(){return this.content};
	Doc.prototype.getCustomData = function(){ return this.customData};
	Doc.prototype.getCustomDataField = function(key){return this.customData[key]};
	Doc.prototype.getID       = function(){return this.idField};
	Doc.prototype.getMode     = function(){return this.mode};
	Doc.prototype.getName     = function(){return this.name};
	Doc.prototype.getOrigContent = function(){return this.origContent};
	Doc.prototype.getReadOnly = function(){return this.readOnly};
	Doc.prototype.hasID       = function(){return this.idField !== undefined};
	Doc.prototype.isNew       = function(){return this.status == Doc.status.NEW};
	Doc.prototype.isChanged   = function(){return this.status == Doc.status.CHANGED};
	Doc.prototype.isUnchanged = function(){return this.status == Doc.status.UNCHANGED};
	Doc.prototype.isUnsaved   = function(){return this.status == Doc.status.UNSAVED};
	Doc.prototype.needsSaving = function(){return this.status == Doc.status.UNSAVED || this.status == Doc.status.CHANGED};
	Doc.prototype.isRenamed   = function(){return this.name != this.origName};

	//Setter
	Doc.prototype.setCustomDataField = function(key, value){this.customData[key] = value};
	Doc.prototype.markNew       = function(){this.status = Doc.status.NEW};
	Doc.prototype.markChanged   = function(){this.status = Doc.status.CHANGED};
	Doc.prototype.markUnsaved   = function(){this.status = Doc.status.UNSAVED};
	Doc.prototype.markUnchanged = function(){this.status = Doc.status.UNCHANGED};
	Doc.prototype.setContent    = function(content){this.content = content};
	Doc.prototype.setID         = function(id){this.idField = id};
	Doc.prototype.setMode       = function(mode){this.mode = mode};
	Doc.prototype.setName       = function(name){this.name = name;};
	Doc.prototype.setReadOnly   = function(readOnly){this.readOnly = readOnly};

	return CMEditor;
})();
