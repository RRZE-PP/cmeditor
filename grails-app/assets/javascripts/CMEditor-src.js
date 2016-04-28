//= require cmeditor-dependencies

this.CMEditor = (function(){
	"use strict";

	function CMEditor(rootElem, options, instanceName){
		//allow the user to omit new
		if (!(this instanceof CMEditor)) return new CMEditor(rootElem, options, instanceName);

		var self = this;
		self.state = {};

		self.state.instanceNo = CMEditor.instanciated++;
		self.state.instanceName = instanceName !== undefined ? instanceName : "";
		if(self.state.instanceName == "")
			log("Warning: No instance name supplied, fullscreen mode will be disabled!");

		self.rootElem = $(rootElem);
		self.options  = options = options !== undefined ? options : {};
		self.options.ajax = options.ajax !== undefined ? options.ajax : {}
		self.options.mapping = options.mapping !== undefined ? options.mapping : {}
		self.options.defaultContent = options.defaultContent !== undefined ? options.defaultContent : "";

		self.state.docs = [];
		self.state.eventHooks = {};
		for(var hookName in options.hooks){
			on(self, hookName, options["hooks"][hookName]);
		}

		executeHooks(self, "preInitialization", self, [rootElem, options, instanceName]);

		initDialogs(self);
		initEventListeners(self);
		initCodeMirror(self, options);

		if(options.menu){
			var menuRootElem = self.rootElem.find(".cmeditor-menu");
			executeHooks(self, "preMenuInit", menuRootElem);
			self.menu = new CMEditorMenu(self, menuRootElem, options, instanceName);
			executeHooks(self, "postMenuInit", menuRootElem, [self.menu]);
		}

		self.rootElem.find(".docs").sortable({containment: "parent", tolerance: "pointer", distance: 8, appendTo: self.rootElem,
			sort: function (event, ui) {
				var self = $(this),
				width = ui.helper.outerWidth(),
				top = ui.helper.position().top;

				self.children().each(function () {
					if($(this).hasClass('ui-sortable-placeholder')){
						$(this).css("height", "");
					}
					if ($(this).hasClass('ui-sortable-helper') || $(this).hasClass('ui-sortable-placeholder')) {
						return true;
					}
					// If overlap is more than half of the dragged item
					var distance = Math.abs(ui.position.left - $(this).position().left),
					before = ui.position.left > $(this).position().left;

					if ((width - distance) > (width / 2) && (distance < width) && $(this).position().top === top) {
						if (before) {
							$('.ui-sortable-placeholder', self).insertBefore($(this));
						} else {
							$('.ui-sortable-placeholder', self).insertAfter($(this));
						}
						return false;
					}
				});
			}
		});
		insertNewUntitledDocument(self);
		syncTabIndent(self);

		$(document).bind("keydown", function(e){
			//disable some browser featues when the codeMirror has focus
			if(e.ctrlKey && self.rootElem.find("CodeMirror-focused").size() !== 0){
				e.preventDefault();
			}

			//122 == F11
			if(e.which == 122 && (self.rootElem.find("*:focus").size() > 0 || self.codeMirror.hasFocus())){
				toggleFullscreen(self);
				e.preventDefault();
			}
		});


		if(self.options.preloadModules){
			preloadModules(self);
		}

		registerInstance(self.state.instanceName, self.state.instanceNo, self);

		executeHooks(self, "postInitialization", self, [rootElem, options, instanceName]);
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
	clazz.eventHooks = {};
	clazz.filteredEventHooks = {};

	/*
	 * Checks if any files are unsaved in any instance and warns the user
	 */
	var checkForUnsavedFiles = clazz.checkForUnsavedFiles = function(e){
		var hasUnsaved = false;
		for(var i=0; i<clazz.instances.length; i++){
			var instance = clazz.instances[i];
			for(var j=0; j<instance.state.docs.length; j++){
				if(instance.state.docs[j].isChanged()){
					hasUnsaved = true;
					break;
				}
			}
		}

		if(hasUnsaved){
			return clazz.instances[0].options.messages.warnings.confirmLeaving;
		}
	}
	$(window).bind("beforeunload", checkForUnsavedFiles);

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
			instance = " #" + arg0.state.instanceNo + " '" + arg0.state.instanceName +"'";
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
	 * Can be used to register callbacks for events statically (i.e. for all instances)
	 *
	 * Events in CMEditor which can be set only statically:
	 *
	 *     preMenuInit: Fired before the menu of this CMEditor is initiated, i.e. before its constructor is called
	 *                  Your callback will be called in the context of the menu's root element
	 *     postMenuInit: Fired after the menu of this CMEditor is initiated, i.e. after its constructor has been called
	 *                  Your callback will be called in the context of the menu's root element and passed the menu object as first
	 *                  argument
	 *     preInitialization: Fired inside the constructor of the CMEditor, after a minimal state of the object was created
	 *                  Your callback will be called in the context of the CMEditor to be created and it will be passed the same arguments
	 *                  as the constructor (the rootElement, the options and the instance name)
	 *     postInitialization: Fired inside the constructor of the CMEditor, after any other instruction was executed (right before return)
	 *                  Your callback will be called in the context of the CMEditor to be created and it will be passed the same arguments
	 *                  as the constructor (the rootElement, the options and the instance name)
	 *
	 * Parameters: eventName String: the event's name as mentioned above
	 *             hook Function: the function to call
	 *             nameFilter String (optional): execute only for instances whose name matches this String
	 *
	 */
	var staticOn = clazz.on = function(eventName, hook, nameFilter){
		if(typeof nameFilter === "undefined"){
			if(typeof clazz.eventHooks[eventName] === "undefined")
				clazz.eventHooks[eventName] = [];

			clazz.eventHooks[eventName].push(hook);
		}else{
			if(typeof clazz.filteredEventHooks[nameFilter] === "undefined")
				clazz.filteredEventHooks[nameFilter] = {};

			if(typeof clazz.filteredEventHooks[nameFilter][eventName] === "undefined")
				clazz.filteredEventHooks[nameFilter][eventName] = [];

			clazz.filteredEventHooks[nameFilter][eventName].push(hook);
		}
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
		$.ajax(clazz.themeBaseURL+themeName+".css")
			.done(function(data){
				$("head").append("<style>" + data + "</style>");

				clazz.loadedResources.push(location);

				if(callback !== undefined)
					callback();
			})
			.fail(function(){
				log("Could not load the resource at "+location, "WARNING");
			});
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

		CodeMirror.modeURL = clazz.modeBaseURL+"%N/%N.js";
		CodeMirror.requireMode(modeName, callback);
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
			"Ctrl-L":     function(cm) { if(options.menu) self.menu.menus.viewMenu.goto(); },
		};

		if (typeof options.overlayDefinitionsVar !== "undefined") {
			self.state.overlays = [];
			for(var name in options.overlayDefinitionsVar) {
				cmeditorall_add_overlay_definition(name, options.overlayDefinitionsVar[name]["baseMode"],
				                                       options.overlayDefinitionsVar[name]["definition"]);
				self.state.overlays.push(name);
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
		self.dialogs = {};

		var diff = self.dialogs.diffDialog = self.rootElem.find(".diffDialog");
		diff.find("input[type=radio]").each(function(idx, elem){$(elem).attr("id", $(elem).attr("id")+self.state.instanceNo)});
		diff.find("label").each(function(idx, elem){$(elem).attr("for", $(elem).attr("for")+self.state.instanceNo)});

		diff.find("input[name=contextSize]").on("keyup", function(){decorateDiffDialog(self)});
		diff.find("input[name=_viewType]").on("click",   function(){decorateDiffDialog(self)});

		diff.dialog({
			autoOpen: false,
			resize:"auto",
			width: "auto",
			height: "auto",
		});


		var warn = self.dialogs.warningDialog = self.rootElem.find(".warningDialog")
		warn.dialog({
			autoOpen: false,
			resize:"auto",
			width: "auto",
			height: "auto",
		});


		// .cmeditor-ui-dialog s have the defaultButton-thingie activated
		$.each(self.dialogs, function(key, val){val.parent().addClass("cmeditor-ui-dialog")});
	}

	/*
	 *	Registers event listeners for user interaction
	 */
	function initEventListeners(self){
		var customBody = self.rootElem.find(".cmeditor-main .customBody");

		//switch tabs
		self.rootElem.find(".tabs").delegate("li", "click", function(e) {
			var target = $(e.target);
			if(!target.is("li")){
				target = target.parent();
			}
			selectDocumentByIndex(self, self.rootElem.find(".tabs li").index(target));
		});

		//changes in custom inputs
		customBody.find(".cmeditor-field").on("change input blur", function() { customElementChanged(self, $(this));});
		customBody.find("select.cmeditor-field").on("change input blur", function() {customElementChanged(self, $(this));});
		customBody.find("input[type='checkbox'].cmeditor-field").on("change input blur", function() { customElementChanged(self, $(this));});
	}

	/*
	 * Performs the actual deletion
	 */
	function ajax_delete(self) {
		executeHooks(self, "prePerformDeleteDoc", self, []);

		if(isReadOnly(self) || self.state.curDoc.isReadOnly()){
			displayMessage(self, self.options.messages.hints.noDeleteReadOnly);
			return;
		}

		if (self.state.curDoc.hasID()) {

			var data = {};
			data[self.options.mapping.idField] = self.state.curDoc.getID();

			$.ajax({
				type:"GET",
				data: data,
				url: self.options.ajax.deleteURL,
				success:function(response, textStatus){
					if (response.status == "success") {
						removeDocument(self, self.state.curDoc);
						log(self, "Deleted a document from the server", "INFO");
					}else{
						log(self, "Could not delete this file from the server", "WARNING", response);
						log(self, "Message was:" + response.msg, "DEBUG");
					}
					if(response.msg)
						displayMessage(self, response.msg, textStatus);
					log(self, "Currently serving these documents locally:", "DEBUG", self.state.docs)

					executeHooks(self, "postPerformDeleteDoc", self, [data, response]);
				},
				error:function(XMLHttpRequest,textStatus,errorThrown){
					displayMessage(self, self.options.messages.errorIntro +" "+ textStatus +" " + errorThrown);
					log(self, "Could not delete this file from the server", "WARNING", data);
				}
			});
		}

		return false;
	}

	/*
	 * Loads a document from the server
	 *
	 * Parameters: fileId (Integer|String): The document's id
	 *             readWrite Boolean: If true document will always be writable, else it will be readOnly
	 *                                if options.readOnly or options.defaultReadOnly is set to true
	 *             finishedCallback Function: This will be called after the document was loaded and passed
	 *                                        the loaded CMEditor.Doc
	 */
	function ajax_load(self, fileId, readWrite, finishedCallback) {
		var data = {};
		data[self.options.mapping.idField] = fileId;

		executeHooks(self, "prePerformLoadDoc", self, [data]);

		$.ajax({
			type:"GET",
			data: data,
			url: self.options.ajax.getURL,
			success: function(response){
				if (response.status == "success" && response.result) {
					var newDoc = new Doc(response.result[self.options.mapping.name],
					                        response.result[self.options.mapping.folder] || null,
					                        response.result[self.options.mapping.mode] || self.options.defaultMode,
					                        response.result[self.options.mapping.content],
					                        readWrite ? false : ((self.options.readOnly || self.options.defaultReadOnly) ? true : false));
					newDoc.setID(response.result[self.options.mapping.idField]);

					//insert custom data, if it is present in the provided data
					self.rootElem.find(".customBody .cmeditor-field").each(function(){
						var elem = $(this);
						var key = elem.attr("name");

						//ignore mapped values
						if(listContainsElem(self, Object.keys(self.options.mapping), key))
							return true; //jquery-Each continue

						var value = response.result;
						var subkeys = key.split(".");
						for(var i=0; i<subkeys.length; i++){
							if(value !== null && typeof value !== "undefined")
								value = value[subkeys[i]];
						}
						elem.val(value);
						newDoc.setCustomDataField(key, value != undefined ? value : "");
					});

					newDoc.markStateAsSaved();
					finishedCallback(newDoc);

					if(response.msg)
						displayMessage(self, response.msg);
				} else {
					displayMessage(self, response.msg ? response.msg : "An unknown error occured");
				}
				executeHooks(self, "postPerformLoadDoc", self, [data, response]);
			},

		error:function(XMLHttpRequest,textStatus,errorThrown){displayMessage(self, self.options.messages.errorIntro +" "+ textStatus +" " + errorThrown);},
		});
	}

	/*
	 * Reinitiates the current document from the server
	 *
	 * Parameters: newId (Integer|String): If supplied the document will be replaced by this one
	 */
	function ajax_reload(self, newId) {
		if (self.state.curDoc) {
			if(typeof newId == "undefined")
				newId = self.state.curDoc.getID();

			var curDocIdx;
			for(curDocIdx=0; curDocIdx<self.state.docs.length; curDocIdx++){
				if(self.state.docs[curDocIdx] === self.state.curDoc){
					break;
				}
			}

			ajax_load(self, newId, true, function(newDoc){
				//this duplicates a lot of code from insertNewDocument, maybe refactor this?
				var curCursorPos = self.codeMirror.getCursor();

				newDoc.setTabElem(self.state.curDoc.getTabElem());
				self.state.docs[curDocIdx] = newDoc;
				self.state.curDoc = newDoc;


				newDoc.getTabElem().attr("title", newDoc.getFolder() !== null
					? newDoc.getFolder()+newDoc.getName()
					: newDoc.getName()+" "+self.options.messages.noFolder);

				var closeButton = newDoc.getTabElem().find(".closeButton");
				closeButton.off("click");
				closeButton.on("click", function(e){close(self, newDoc);e.stopPropagation()});


				newDoc.markStateAsSaved();
				selectDocument(self, newDoc);
				updateTabText(self);
				updateCurrentDocument(self);

				self.codeMirror.setCursor(curCursorPos);
			});
		}
	}

	/*
	 *	Triggers updating the document on server side and then reloads it from the server
	 */
	function ajax_update(self) {
		if (self.state.curDoc) {

			var data = {};
			jQuery.extend(data, self.state.curDoc.getCustomData()); //'clone' into the data object
			data[self.options.mapping.idField] = self.state.curDoc.getID();
			data[self.options.mapping.folder] = self.state.curDoc.getFolder();
			data[self.options.mapping.mode] = self.state.curDoc.getMode();
			data[self.options.mapping.name] = self.state.curDoc.getName();
			data[self.options.mapping.content] = self.state.curDoc.getContent();

			executeHooks(self, "prePerformSaveDoc", self, [data]);

			$.ajax({
				type: "POST",
				data: data,
				url: self.options.ajax.updateURL,
				success: function(response,textStatus){
					if (response.status == "success") {
						if (response.newId) {
							ajax_reload(self, response.newId);
						}else{
							ajax_reload(self);
						}
						log(self, "Saved a document to the server", "INFO");
					}else{
						log(self, "Could not save this document to the server.", "WARNING", response);
					}
					if(response.msg)
						displayMessage(self, response.msg, textStatus);

					executeHooks(self, "postPerformSaveDoc", self, [data, response]);
				},
				error:function(XMLHttpRequest,textStatus,errorThrown){
					displayMessage(self, self.options.messages.errorIntro + " " + textStatus +" " + errorThrown);
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
		var key = elem.attr("name");

		if (self.state.curDoc) {
			var old = null;
			var doUpdate = true;

			// First handle the cases where a custom element corresponds to a mapped value
			if (key == self.options.mapping.name) {
				rename(self, getCustomElementValue(self, elem));

			} else if (key == self.options.mapping.mode) {
				self.state.curDoc.setMode(getCustomElementValue(self, elem));
				if(self.options.menu)
					self.menu.update();

			} else if (key == self.options.mapping.content) {
				sef.curDoc.setContent(getCustomElementValue(self, elem));

			} else if (key == self.options.mapping.idField) {
				sef.curDoc.setID(getCustomElementValue(self, elem));

			}
			//else handle all other cases
			else {
				if (elem.attr("data-field-property")) {
					if (self.state.curDoc.getCustomDataField(key)) {
						old = self.state.curDoc.getCustomDataField(key)[elem.attr("data-field-property")];
					} else {
						self.state.curDoc.setCustomDataField(key, {});
					}
					self.state.curDoc.getCustomDataField(key)[elem.attr("data-field-property")] = getCustomElementValue(self, elem);
				} else {
					old = self.state.curDoc.getCustomDataField(key);
					self.state.curDoc.setCustomDataField(key, getCustomElementValue(self, elem));
				}
			}

			update(self);
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
		log(self, "Decorating a diff dialog", "INFO");

		var origContent = self.state.curDoc.getOrigContent();
		var base    = difflib.stringAsLines(typeof origContent !== "undefined"? origContent : ""),
			newtxt  = difflib.stringAsLines(self.state.curDoc.getContent()),
			diffoutputdiv = self.dialogs.diffDialog.find(".diffoutput"),
			contextSize   = self.dialogs.diffDialog.find("input[name=contextSize]").val();

		var opcodes = new difflib.SequenceMatcher(base, newtxt).get_opcodes();

		diffoutputdiv.text("");
		contextSize = contextSize || null;

		if (opcodes && opcodes.length == 1 && opcodes[0][0] == "equal") {
			self.dialogs.diffDialog.find(".noChanges").show(0);
		} else {
			self.dialogs.diffDialog.find(".noChanges").hide(0);
			diffoutputdiv.append(diffview.buildView({
				baseTextLines: base,
				newTextLines: newtxt,
				opcodes: opcodes,
				baseTextName: "Base Text",
				newTextName: "New Text",
				contextSize: contextSize,
				viewType: parseInt(self.dialogs.diffDialog.find("input[name=_viewType]:checked").val())
			}));
		}
	}

	/*
	 * Executes all hooks that were registered using `on` on `eventName`, either per-instance or on all
	 * instances using `CMEditor.on`
	 *
	 * Parameters: eventName String: the event of which all hooks should be called
	 *             context Object: the object that `this` should be set to in the hook
	 *             args Array: the parameters to pass to the hook as an array
	 */
	function executeHooks(self, eventName, context, args){
		for(var i=0; self.state && self.state.eventHooks[eventName] && i<self.state.eventHooks[eventName].length; i++){
			if(typeof self.state.eventHooks[eventName][i] === "function")
				self.state.eventHooks[eventName][i].apply(context, args);
			else
				log(self, "A hook was not executed because it is not a function", "WARNING");
		}

		for(var i=0; clazz.eventHooks[eventName] && i<clazz.eventHooks[eventName].length; i++){
			if(typeof clazz.eventHooks[eventName][i] === "function")
				clazz.eventHooks[eventName][i].apply(context, args);
			else
				log(self, "A hook was not executed because it is not a function", "WARNING");
		}

		if(clazz.filteredEventHooks[self.state.instanceName] !== undefined){
			for(var i=0; clazz.filteredEventHooks[self.state.instanceName][eventName] && i<clazz.filteredEventHooks[self.state.instanceName][eventName].length; i++){
				if(typeof clazz.filteredEventHooks[self.state.instanceName][eventName][i] === "function")
					clazz.filteredEventHooks[self.state.instanceName][eventName][i].apply(context, args);
				else
					log(self, "A hook was not executed because it is not a function", "WARNING");
			}
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
	 * Creates a new tab and sets the supplied document as its content
	 *
	 * Parameters: newDoc CMEditor.Doc: The document to insert
	 */
	function insertNewDocument(self, newDoc) {
		self.state.docs.push(newDoc);

		var docTabs = self.rootElem.find(".docs");
		var li = $("<li/>");
		var name = $('<span class="tabName"></span>').text(newDoc.getName());
		var closeButton = $('<span class="closeButton">&#10005;</span>');

		docTabs.append(li);
		li.attr("title", newDoc.getFolder() !== null?newDoc.getFolder()+newDoc.getName():newDoc.getName()+" "+self.options.messages.noFolder);
		li.append(name);
		li.append(closeButton);

		closeButton.on("click", function(e){close(self, newDoc); e.stopPropagation();});

		newDoc.setTabElem($(li));

		updateTabText(self);

		if (self.codeMirror.getDoc() == newDoc.getCMDoc()) {
			markDocumentAsSelected(self, newDoc);
			self.state.curDoc = newDoc;
		}

		selectDocument(self, newDoc);
		removeUntitledDocument(self);
		docTabs.sortable( "refreshPositions" );

		log(self, "Inserted a new document", "INFO");
		log(self, "This document was inserted", "DEBUG", newDoc);
	}

	/*
	 * Creates and registers a new (empty) document if there is none opened
	 */
	function insertNewUntitledDocument(self) {
		if (self.state.docs.length < 1) {
			var name = getUnambiguousName(self, self.options.messages.untitledDocName);

			var newDoc = new Doc(name, "/", self.options.defaultMode, self.options.defaultContent,
									(self.options.readOnly||self.options.defaultReadOnly)?true:false);


			//insert custom data, if it is present in the provided data
			self.rootElem.find(".customBody .cmeditor-field").each(function(){
				var elem = $(this);
				var key = elem.attr("name");
				newDoc.setCustomDataField(key, elem.attr('value')!=undefined?elem.attr('value'):"");
			});

			self.state.initialDoc = newDoc;
			newDoc.markStateAsSaved();
			insertNewDocument(self, newDoc);
		}
	}

	/*
	 * Marks a document as changed by placing a star next to its name
	 *
	 * Parameters: doc CMEditor.Document: the document to mark
	 */
	function markDocumentAsChanged(self, doc) {
		doc.getTabElem().find(".tabName").addClass("changed");
	}

	/*
	 * Adds a selected class to a document and removes it from all others
	 *
	 * Parameters: doc CMEditor.Document: the document to mark
	 */
	function markDocumentAsSelected(self, doc) {
		var docTabs = self.rootElem.find(".tabs").children();
		docTabs.removeClass("selected");
		doc.getTabElem().addClass("selected");

	}

	/*
	 * Marks a document as unchanged by removing the star next to its name
	 *
	 * Parameters: doc CMEditor.Document: the document to mark
	 */
	function markDocumentAsUnchanged(self, doc) {
		doc.getTabElem().find(".tabName").removeClass("changed");
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
		executeHooks(self, "prePerformCloseDoc", self, [doc]);

		for (var i=0; i < self.state.docs.length; ++i) {
			if(self.state.docs[i] === doc){
				self.state.docs.splice(i, 1);
				break;
			}
		}
		doc.getTabElem().remove();

		updateTabText(self);

		insertNewUntitledDocument(self);
		selectDocumentByIndex(self, Math.max(0, i - 1));

		executeHooks(self, "postPerformCloseDoc", self, [doc]);
	}

	/*
	 * Unregisters a document previously created by `insertNewUntitledDocument`
	 */
	function removeUntitledDocument(self) {
		if (self.state.docs.length > 1) {
			var doc = self.state.initialDoc;
			if (doc !== null && !doc.isChanged()) {
				removeDocument(self, doc);
			}
			self.state.initialDoc = null;
		}
	}

	/*
	 * Selects a document and displays its contents in the editor
	 *
	 * Parameters: doc CMEditor.Doc: the document to select
	 */
	function selectDocument(self, newDoc) {
		self.state.curDoc = newDoc;
		markDocumentAsSelected(self, self.state.curDoc);

		self.codeMirror.swapDoc(self.state.curDoc.getCMDoc());
		setMode(self, self.state.curDoc.getMode());
		updateCurrentDocument(self);

		if(self.options.menu){
			self.menu.update();
		}

		focus(self);
	}

	/*
	 * Selects a document and displays its contents in the editor
	 *
	 * Parameters: pos Integer: the tab-index of the document to select
	 */
	function selectDocumentByIndex(self, pos) {
		var nthTab = self.rootElem.find(".docs li:eq("+pos+")");
		var newDoc = null;
		for(var i=0; i<self.state.docs.length; i++){
			var curDoc = self.state.docs[i];
			if(nthTab.get(0) === curDoc.getTabElem().get(0)){
				newDoc = curDoc;
				break;
			}
		}

		selectDocument(self, newDoc);

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
		var buttons = {};
		buttons[self.options.messages.buttons.cancel] = function() {
			$(this).dialog("close");
		};

		if (additionalButtons) {
			for (var name in additionalButtons) {
				buttons[name] = additionalButtons[name];
			}
		}

		self.dialogs.warningDialog.text(message);
		self.dialogs.warningDialog.dialog("option", "buttons", buttons);
		self.dialogs.warningDialog.dialog("open");
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

		return false;
	}

	/*
	 * Synchronizes the current document with the codeMirror instance.
	 * Called on every change of a document inside `self.codeMirror`
	 *
	 * Parameters: cmChangeObjects (optional) Object: See codeMirror docu on the 'changes' event
	 * Returns:    Boolean whether this document has changed
	 */
	function updateCurrentDocument(self, cmChangeObjects) {
		var changed = false;

		if (self.state.curDoc) {
			if (self.state.curDoc.getMode() != self.codeMirror.getOption("mode")) {
				setMode(self, self.state.curDoc.getMode());
			}

			if (cmChangeObjects && !cmChangeObjects.propertyIsEnumerable("cmeditor_custom_field")) {
				self.state.curDoc.setContent(self.state.curDoc.getCMDoc().getValue());
			}

			if (self.state.curDoc.isReadOnly() != self.codeMirror.getOption("readOnly")) {
				if (self.state.curDoc.isReadOnly()) {
					self.codeMirror.setOption("readOnly", self.state.curDoc.isReadOnly());
				} else {
					self.codeMirror.setOption("readOnly", false);
				}
			}

			if(self.state.curDoc.isChanged())
				markDocumentAsChanged(self, self.state.curDoc);
			else
				markDocumentAsUnchanged(self, self.state.curDoc);

			writeCurrentDocToForm(self);
		}

		return changed;
	}

	/*
	 * Updates the names of all tabs so that no two tabs show the same name (by appending or removing,
	 * the document's folder to the tab) and all tabs show their document's name correctly
	 */
	function updateTabText(self){
		for(var i=0; i<self.state.docs.length; i++){
			var firstDoc = self.state.docs[i];
			firstDoc.getTabElem().find(".tabName").text(firstDoc.getName());
			for(var j=0; j<self.state.docs.length; j++){
				var otherDoc = self.state.docs[j];
				if(otherDoc.getName() === firstDoc.getName() && otherDoc !== firstDoc){
					otherDoc.getTabElem().find(".tabName").text((otherDoc.getFolder()!==null?otherDoc.getFolder():"")+otherDoc.getName());
					firstDoc.getTabElem().find(".tabName").text((firstDoc.getFolder()!==null?firstDoc.getFolder():"")+firstDoc.getName());
				}
			}
		}
	}


	/*************************************************************************
	 *                                                                       *
	 *                     Begin 'public' methods                            *
	 *                                                                       *
	 *************************************************************************/

	/* (Public)
	 * Closes the currently opened document
	 *
	 * Parameters: doc CMEditor.Doc: if supplied this document will be closed,
	 *                               else the current document
	 */
	function close(self, doc) {
		var closeThis = typeof doc === "undefined" ? self.state.curDoc : doc;

		executeHooks(self, "preCloseDoc", self, [doc]);

		if (closeThis.isChanged()) {
			var button = {};
			button[self.options.messages.buttons.close] = function() {
				removeDocument(self, closeThis);
				updateTabText(self);
				$(this).dialog("close");
			};
			showWarning(self, self.options.messages.warnings.changesWillBeLost, button);
		} else {
			removeDocument(self, closeThis);
			updateTabText(self);
		}

		executeHooks(self, "postCloseDoc", self, [doc]);
	}


	/* (Public)
	 *	Deletes the currently opened document, asks for confirmation first
	 */
	function deleteDoc(self) {
		executeHooks(self, "preDeleteDoc", self, []);

		var button = {};
		button[self.options.messages.buttons.delete] = function() {
			ajax_delete(self);
			$(this).dialog("close");
			executeHooks(self, "postDeleteDoc", self, []);
		};
		showWarning(self, self.options.messages.warnings.deleteFile, button);
	}

	/* (Public)
	 * Shows a diff of the current document.
	 *
	 * Parameters: additionalButtons: Object: The keys are the button labels and the values are the
	 *                                        callbacks for when the associated button is clicked.
	 *             defaultButton function (optional): if supplied, this function will be called when
	 *                                                the user hits enter while the dialog has focus
	 */
	function diff(self, additionalButtons, defaultButton) {
		var buttons = {};
		buttons[self.options.messages.buttons.close] = function() {
			self.dialogs.diffDialog.dialog("close");
		};

		if (additionalButtons) {
			for (var name in additionalButtons) {
				buttons[name] = additionalButtons[name];
			}
		}

		decorateDiffDialog(self);

		self.dialogs.diffDialog.dialog("option", "defaultButton",
			typeof defaultButton === "undefined" ? buttons[self.options.messages.buttons.close] : defaultButton);
		self.dialogs.diffDialog.dialog("option", "buttons", buttons);
		self.dialogs.diffDialog.dialog("open");
	}

	/* (Public)
	 * Displays a message for 3 seconds
	 *
	 * Parameters: message String: The message to be displayed
	 */
	function displayMessage(self, message) {
		if(typeof self.state.messagesToDisplay === "undefined" || self.state.messagesToDisplay.length === 0){
			self.state.messagesToDisplay = [message];
		}else{
			self.state.messagesToDisplay.push(message);
			return;
		}

		function displayRemainingMessages(){
			if(self.state.messagesToDisplay.length === 0)
				return;
			self.rootElem.find(".cmeditor-tab-message").text(self.state.messagesToDisplay[0])
			                .toggle("slide", {"direction":"up"})
			                .delay(3000)
			                .toggle({effect: "slide",
			                         direction: "up",
			                         complete: function(){self.state.messagesToDisplay.shift(); displayRemainingMessages()}});
		}

		displayRemainingMessages();
	}

	/* (Public)
	 *
	 * Exports the current document as a download
	 */
	function exportDoc(self){
		var file = new Blob([self.state.curDoc.getContent()], {type: self.state.curDoc.getMode()+";charset=UTF-8"});
		window.saveAs(file, self.state.curDoc.getName());
	}

	/* (Public)
	 *
	 * Sets focus to the text editor
	 */
	function focus(self){
		self.codeMirror.focus();
	}

	/* (Public)
	 * Returns the mode in which the current document is opened
	 */
	function getCurDoc(self) {
		return self.state.curDoc;
	}

	/* (Public)
	 * Returns the mode in which the current document is opened
	 */
	function getCurrentCMEditorMode(self) {
		return self.state.curDoc.getMode();
	}

	/* (Public)
	 *
	 * Appends a number to a filename so that it is unambigous
	 *
	 * Parameters: name String: The name of the document
	 *             folder String (optional): if supplied, will only search for collisions within this directory; null matches all folders
	 */
	function getUnambiguousName(self, name, folder) {
		var namesOnServer = [];
		if(self.options.ajax.listURL){
			$.ajax({
				url: self.options.ajax.listURL,
				success: function(json) {
					if (json.status == "success" && json.result) {
						for(var i=0; i<json.result.length; i++){
							if((typeof folder === "undefined" || folder === null
									|| json.result[i][self.options.mapping["folder"]] === folder
									|| json.result[i][self.options.mapping["folder"]] === null)){
								namesOnServer.push(json.result[i][self.options.mapping["name"]]);
							}
						}
					}
				},
				async:false
			});
		}
		var i = 0;
		while (true){
			var isCurrentlyOpened = false;
			$.each(self.state.docs, function(idx, doc){
				if(doc.getName() === name + (i || "") && (folder === null || typeof folder === "undefined" || folder === doc.getFolder() || doc.getFolder() === null))
					isCurrentlyOpened = true;
			});

			if(!listContainsElem(self, namesOnServer, name + (i || "")) && !isCurrentlyOpened){
				break;
			}

			i++;
		}

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
	 *
	 * Imports a file into the editor
	 *
	 * Parameters: fileName String: the filename of the document to import
	 *             fileContent String: the content of the file to import
	 *             fileMode String (optional): if set the file will have this mode, else the options.default mode
	 */
	function importDoc(self, fileName, fileContent, fileMode){
		if(isReadOnly(self)){
			displayMessage(self, self.options.messages.hints.editorIsReadOnly);
			return;
		}

		var newDoc = new Doc(fileName,
		                        "/imported/",
		                        fileMode || self.options.defaultMode,
		                        fileContent,
		                        (self.options.readOnly || self.options.defaultReadOnly) ? true : false);
		insertNewDocument(self, newDoc);
	}

	/* (Public)
	 * Returns whether the whole editor is read only
	 */
	function isReadOnly(self){
		return self.options.readOnly;
	}

	/* (Public)
	 *
	 * Moves the current file to another folder
	 */
	function moveDoc(self, newFolder){
		if(isReadOnly(self) || self.state.curDoc.isReadOnly()){
			displayMessage(self, self.options.messages.hints.noMoveReadOnly);
			return;
		}

		if(newFolder === self.state.curDoc.getFolder())
			return;

		self.state.curDoc.setFolder(newFolder);
		updateTabText(self);
	}

	/* (Public)
	 * Creates a new document with a name supplied by the user
	 *
	 * Parameters: fileName String: the new filename
	 *             folder String: the folder (or null)
	 */
	function newDoc(self, fileName, folder) {
		if(isReadOnly(self)){
			displayMessage(self, self.options.messages.hints.editorIsReadOnly);
			return;
		}

		var newDoc = new Doc(fileName, folder, self.options.defaultMode, self.options.defaultContent,
								(self.options.readOnly || self.options.defaultReadOnly) ? true:false);


		insertNewDocument(self, newDoc);
		selectDocument(self, newDoc);
		markDocumentAsChanged(self, newDoc);
	}

	/* (Public)
	 *
	 * Can be used to register callbacks for events.
	 *
	 * Available Events in CMEditor:
	 *    Where not noted otherwise the Callbacks are executed in the context of the CMEditor (i.e. 'this' points to the CMEditor instance).
	 *    The post-Hooks might not be called if an error occurs (e.g. server is unreachable)
	 *
	 *     preSerializeDoc: Fired before the content of the current document is serialized to the form used to send the data to server.
	 *                      Basically this happens everytime something in the document changes.
	 *                      Arguments: <The current document>
	 *     postSerializeDoc: Fired after the content of the current document is serialized to the form used to send the data to server.
	 *                      Basically this happens everytime something in the document changes.
	 *                      Arguments: <The current document>
	 *
	 *      preDeleteDoc: 	Fired when the user requests deleting the current document (this.state.curDoc).
	 *     postDeleteDoc: 	Fired when the user requests document deletion, after all user interaction has been performed and the deletion
	 *                      was triggered (i.e. `prePerformDeleteDoc` was fired)
	 *      prePerformDeleteDoc: Fired before the request to delete a document is sent to the server.
	 *     postPerformDeleteDoc: Fired after the request to delete a document was executed by the server (successfully or unsuccessfully).
	 *                           Arguments: <The data sent to the server>, <The server's response>
	 *
	 *      preCloseDoc: 	Fired when the user requests closing a document. Arguments: <The document to close>
	 *     postCloseDoc: 	Fired when the user requests closing a document, after all user interaction was performed and the document was closed
	 *                      Arguments: <The document which was closed>
	 *
	 *      preSaveDoc: 	Fired when the user requests saving the current document (this.state.curDoc)
	 *     postSaveDoc: 	Fired when the user requests document saving, after all user interaction has been performed and the saving was
	 *                      triggered (i.e. `prePerformSaveDoc` was fired).
	 *      prePerformSaveDoc: Fired before the request to save a document is sent to the server. Arguments: <The data to send>
	 *     postPerformSaveDoc: Fired after the request to save a document was executed by the server (successfully or unsuccessfully).
	 *                         Arguments: <The data sent to the server>, <The server's response>
	 *
	 *      preOpenDoc: 	Fired when the user requests opening a document. Arguments: <The fileId to open>
	 *     postOpenDoc: 	Fired after a document was opened. Arguments: <The document which was opened>
	 *
	 *      prePerformLoadDoc: Fired before a document is (re-)loaded from the server. This happens on opening or saving a document.
	 *                      Arguments: <The data to send to the server>
	 *     postPerformLoadDoc: Fired after a document was (re-)loaded from the server. This happens on opening or saving a document.
	 *                      Arguments: <The data to sent to the server>, <The server's response>
	 *
	 *      preEnterFullscreen: Fired before entering fullscreen mode, before any layout changes occur.
	 *     postEnterFullscreen: Fired after the layout was reset for fullscreen mode.
	 *      preLeaveFullscreen: Fired before leaving fullscreen mode, before any layout changes occur.
	 *     postLeaveFullscreen: Fired after the layout was reset for non-fullscreen mode.
	 *
	 *
	 */
	function on(self, eventName, hook){
		if(self.state.eventHooks[eventName] === undefined)
			self.state.eventHooks[eventName] = [];

		self.state.eventHooks[eventName].push(hook);

	}

	/* (Public)
	 * Opens a file if it is not opened yet
	 *
	 * Parameters: fileId Integer: The id of the file
	 *             readWrite Boolean: If true document will always be writable, else it will be readOnly
	 *                                if options.readOnly or options.defaultReadOnly is set to true
	 */
	function open(self, fileId, readWrite) {
		executeHooks(self, "preOpenDoc", self, [fileId]);
		if(isReadOnly(self)){
			displayMessage(self, self.options.messages.hints.editorIsReadOnly);
			return;
		}

		for(var i=0; i<self.state.docs.length; i++){
			if(self.state.docs[i].getID() == fileId){
				selectDocument(self, self.state.docs[i]);
				return;
			}
		}
		ajax_load(self, fileId, readWrite, function(newDoc){
												insertNewDocument(self, newDoc);
												executeHooks(self, "postOpenDoc", self, [newDoc]);
		});
	}

	/* (Public)
	 * Renames the currently opened document. Shows an error message if the document is read only
	 *
	 * Parameters: newName String: the new name of the document
	 */
	function rename(self, newName) {
		if(isReadOnly(self) || self.state.curDoc.isReadOnly()){
			displayMessage(self, self.options.messages.hints.noRenameReadOnly);
			return;
		}

		var curDoc = self.state.curDoc;
		var li = curDoc.tabElem;
		curDoc.setName(newName);
		li.attr("title", curDoc.getFolder() !== null?curDoc.getFolder()+curDoc.getName():curDoc.getName()+" "+self.options.messages.noFolder);
		li.children(".tabName").text(curDoc.getName());
		markDocumentAsChanged(self, self.state.curDoc);

		updateTabText(self);
		updateCurrentDocument(self);
	}

	/* (Public)
	 * Saves the currently opened document. If it is opened read-only only displays a dialog.
	 */
	function save(self) {
		executeHooks(self, "preSaveDoc", self, []);

		if(isReadOnly(self) || self.state.curDoc.isReadOnly()){
			displayMessage(self, self.options.messages.hints.noSaveReadOnly);
			return;
		}

		updateCurrentDocument(self);

		if (self.state.doDiffBeforeSaving) {
			var additionalButtons = {
					Save: function() { ajax_update(self); executeHooks(self, "postSaveDoc", self, []); $(this).dialog("close"); },
				};
			diff(self, additionalButtons);
		} else {
			ajax_update(self);
			executeHooks(self, "postSaveDoc", self, []);
		}

	}

	/* (Public)
	 * Renames then saves the current document
	 */
	function saveas(self) {
		if(isReadOnly(self) || self.state.curDoc.isReadOnly()){
			displayMessage(self, self.options.messages.hints.noSaveReadOnly);
			return;
		}

		var name = prompt(self.options.messages.newNamePrompt, "");
		if (name == null) return;
		if (!name) name = "test";

		rename(self, getUnambiguousName(self, name));
		self.state.curDoc.setID("");

		save(self);
	}

	/* (Public)
	 * Sets whether this CMEditor should show a diff before it saves
	 */
	function setDoDiffBeforeSaving(self, value) {
		self.state.doDiffBeforeSaving = value;
	}

	/* (Public)
	 * Sets the mode (CM lingo for filetype) of the current document; triggers loading the mode
	 * first if necessary
	 *
	 * Parameters: mode (String): The name of the mode to set
	 */
	function setMode(self, mode){
		function setOverlayMode(){
		    log(self, "Setting a custom mode (overlay):", "DEBUG", mode)
		    self.codeMirror.setOption("mode", mode);
		    self.state.curDoc.setMode(mode);
		    update(self);
		}
		if(self.state.overlays && self.state.overlays.indexOf(mode) !== -1){
			var baseMode = self.options.overlayDefinitionsVar[mode]["baseMode"];
			var cmMode = CodeMirror.findModeByName(baseMode) || CodeMirror.findModeByMIME(baseMode);
			if(cmMode !== null && typeof cmMode !== "undefined"){
				loadMode(cmMode.mode, setOverlayMode);
			}else{
				setOverlayMode();
			}

			return;
		}

		var cmMode = CodeMirror.findModeByName(mode) || CodeMirror.findModeByMIME(mode);
		if(cmMode !== null && typeof cmMode !== "undefined"){
			loadMode(cmMode.mode, function(){
				log(self, "Setting a mode:", "DEBUG", mode)
				self.codeMirror.setOption("mode", cmMode.mime);
				self.state.curDoc.setMode(cmMode.mime);
				update(self);
			});
			return;
		}

		log(self, "Could not load this unknown mode: "+mode, "WARNING");
		displayMessage(self, self.options.messages.hints.noSuchMode);
	}

	/* (Public)
	 * Enters or leaves fullscreen mode
	 */
	function toggleFullscreen(self){
		if(self.state.instanceName == ""){
			return;
		}

		if(self.state.cssBeforeFullscreen == undefined){
			executeHooks(self, "preEnterFullscreen", self, []);

			self.state.cssBeforeFullscreen = {"position": self.rootElem.css("position"),
			                                  "top":  self.rootElem.css("top"),
			                                  "left":  self.rootElem.css("left"),
			                                  "height":  self.rootElem.css("height"),
			                                  "width":  self.rootElem.css("width")};
			self.state.oldDocumentOverflow = document.documentElement.style.overflow;
			document.documentElement.style.overflow = "hidden";
			self.rootElem.css({"position": "fixed", "top": "0", "left": "0", "height": "100%", "width": "100%"});
			self.rootElem.addClass("cmeditor-fullscreen");

			self.layout = self.rootElem.layout({
				east__paneSelector:   "#cmeditor-"+self.state.instanceName+"-easternpane",
				center__paneSelector: "#cmeditor-"+self.state.instanceName+"-centerpane",
				north__paneSelector:  "#cmeditor-"+self.state.instanceName+"-northernpane",
				north__size: 75,
				north__resizable:false
				});

			self.codeMirror.refresh();
			syncTabIndent(self);

			executeHooks(self, "postEnterFullscreen", self, []);
		}else{
			executeHooks(self, "preLeaveFullscreen", self, []);

			self.layout.destroy();

			self.rootElem.removeClass("cmeditor-fullscreen");
			self.rootElem.css(self.state.cssBeforeFullscreen);
			document.documentElement.style.overflow = self.state.oldDocumentOverflow;
			self.state.cssBeforeFullscreen = undefined;

			self.codeMirror.refresh();
			syncTabIndent(self);

			executeHooks(self, "postLeaverFullscreen", self, []);
		}
	}

	/* (Public)
	 * Updates mode and read-onlyness of the current document to the corresponding properties
	 * of the underlying codeMirror
	 */
	function update(self) {
		var docName = "no curDoc";
		if(self.state.curDoc){
			docName = self.state.curDoc.getName();

			getCodeMirror(self).setOption("readOnly", self.state.curDoc.isReadOnly() ? "nocursor" : "");

			if(self.state.curDoc.getMode() != self.codeMirror.getOption("mode")){
				var mode = self.codeMirror.getOption("mode");
				self.state.curDoc.setMode(mode);
				setMode(self, mode);
			}

			if(self.state.curDoc.isChanged())
				markDocumentAsChanged(self, self.state.curDoc);
			else
				markDocumentAsUnchanged(self, self.state.curDoc);

			updateCurrentDocument(self);
		}
		if(typeof self.menu !== "undefined")
			self.menu.update();
	}

	/* (Public)
	 * Serializes the currently opened document to the editor's form
	 */
	function writeCurrentDocToForm(self) {
		executeHooks(self, "preSerializeDoc", self.rootElem, [self.state.curDoc]);

		self.rootElem.find(".customBody .cmeditor-field").each(function(){
			var elem = $(this);
			var key = elem.attr("name");

			if (elem.attr("data-field-property") && self.state.curDoc.getCustomDataField(key)) {
				//if the element indicates to use the property of an object, use it
				setInputValue(self, elem, self.state.curDoc.getCustomDataField(key)[elem.attr("data-field-property")] || "");
			} else {
				setInputValue(self, elem, self.state.curDoc[key] || self.state.curDoc.getCustomDataField(key) || "");
			}
		});

		executeHooks(self, "postSerializeDoc", self.rootElem, [self.state.curDoc]);

	}



	CMEditor.prototype.constructor = CMEditor;

	//public methods
	CMEditor.prototype.closeDoc                  = function(){Array.prototype.unshift.call(arguments, this); return close.apply(this, arguments)};
	CMEditor.prototype.copyCMTheme               = function(){Array.prototype.unshift.call(arguments, this); return copyCMTheme.apply(this, arguments)};
	CMEditor.prototype.diff                      = function(){Array.prototype.unshift.call(arguments, this); return diff.apply(this, arguments)};
	CMEditor.prototype.deleteDoc                 = function(){Array.prototype.unshift.call(arguments, this); return deleteDoc.apply(this, arguments)};
	CMEditor.prototype.exportDoc                 = function(){Array.prototype.unshift.call(arguments, this); return exportDoc.apply(this, arguments)};
	CMEditor.prototype.focus                     = function(){Array.prototype.unshift.call(arguments, this); return focus.apply(this, arguments)};
	CMEditor.prototype.getUnambiguousName        = function(){Array.prototype.unshift.call(arguments, this); return getUnambiguousName.apply(this, arguments)};
	CMEditor.prototype.getCurDoc                 = function(){Array.prototype.unshift.call(arguments, this); return getCurDoc.apply(this, arguments)};
	CMEditor.prototype.getCurrentCMEditorMode    = function(){Array.prototype.unshift.call(arguments, this); return getCurrentCMEditorMode.apply(this, arguments)};
	CMEditor.prototype.getCodeMirror             = function(){Array.prototype.unshift.call(arguments, this); return getCodeMirror.apply(this, arguments)};
	CMEditor.prototype.importDoc                 = function(){Array.prototype.unshift.call(arguments, this); return importDoc.apply(this, arguments)};
	CMEditor.prototype.isReadOnly                = function(){Array.prototype.unshift.call(arguments, this); return isReadOnly.apply(this, arguments)};
	CMEditor.prototype.moveDoc                   = function(){Array.prototype.unshift.call(arguments, this); return moveDoc.apply(this, arguments)};
	CMEditor.prototype.newDoc                    = function(){Array.prototype.unshift.call(arguments, this); return newDoc.apply(this, arguments)};
	CMEditor.prototype.on                        = function(){Array.prototype.unshift.call(arguments, this); return on.apply(this, arguments)};
	CMEditor.prototype.open                      = function(){Array.prototype.unshift.call(arguments, this); return open.apply(this, arguments)};
	CMEditor.prototype.saveDoc                   = function(){Array.prototype.unshift.call(arguments, this); return save.apply(this, arguments)};
	CMEditor.prototype.saveDocAs                 = function(){Array.prototype.unshift.call(arguments, this); return saveas.apply(this, arguments)};
	CMEditor.prototype.setDoDiffBeforeSaving     = function(){Array.prototype.unshift.call(arguments, this); return setDoDiffBeforeSaving.apply(this, arguments)};
	CMEditor.prototype.setMode                   = function(){Array.prototype.unshift.call(arguments, this); return setMode.apply(this, arguments)};
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

	var Doc = CMEditor.Doc = function Doc(name, folder, mode, content, readOnly, cmDoc){
		this.content = content;
		this.folder = folder;
		this.idField = null;
		this.mode = mode;
		this.name = name;
		this.readOnly = readOnly;

		this.customData = {};
		this.tabElem = null;

		this.savedState = {
			customData: {}
		};

		if(cmDoc === undefined)
			this.codeMirrorDoc = new CodeMirror.Doc(content, mode);
		else
			this.codeMirrorDoc = cmDoc;
	}

	Doc.prototype.constructor = Doc;

	Doc.prototype.markStateAsSaved = function(){
		this.savedState.folder 	= this.folder;
		this.savedState.idField = this.idField;
		this.savedState.mode 	= this.mode;
		this.savedState.content = this.content;
		this.savedState.name    = this.name;

		for(var key in this.customData){
			this.savedState.customData[key] = this.customData[key];
		}
	}

	Doc.prototype.isChanged = function(){
		for(var key in this.customData){
			if(typeof this.savedState.customData[key] === "undefined"
				|| this.customData[key] !== this.savedState.customData[key])
				return true;
		}

		return this.folder !== this.savedState.folder
				|| this.idField !== this.savedState.idField
				|| this.mode !== this.savedState.mode
				|| this.content !== this.savedState.content
				|| this.name !== this.savedState.name;
	}

	//Getter
	Doc.prototype.getCMDoc    = function(){return this.codeMirrorDoc};
	Doc.prototype.getContent  = function(){return this.content};
	Doc.prototype.getCustomData = function(){ return this.customData};
	Doc.prototype.getCustomDataField = function(key){return this.customData[key]};
	Doc.prototype.getFolder   = function(){return this.folder};
	Doc.prototype.getID       = function(){return this.idField};
	Doc.prototype.getMode     = function(){return this.mode};
	Doc.prototype.getName     = function(){return this.name};
	Doc.prototype.getOrigContent = function(){return this.savedState.content};
	Doc.prototype.getTabElem  = function(){return this.tabElem};
	Doc.prototype.hasID       = function(){return this.idField !== undefined};
	Doc.prototype.isReadOnly  = function(){return this.readOnly};

	//Setter
	Doc.prototype.setCustomDataField = function(key, value){this.customData[key] = value};
	Doc.prototype.setContent    = function(content){this.content = content};
	Doc.prototype.setFolder     = function(folder){this.folder = folder};
	Doc.prototype.setID         = function(id){this.idField = id};
	Doc.prototype.setMode       = function(mode){this.mode = mode};
	Doc.prototype.setName       = function(name){this.name = name;};
	Doc.prototype.setReadOnly   = function(readOnly){this.readOnly = readOnly};
	Doc.prototype.setTabElem    = function(tabElem){this.tabElem = tabElem};

	return CMEditor;
})();
