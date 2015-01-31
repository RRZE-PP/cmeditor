<div id="cmEditorMenu_${name}" class="cmeditor-menu">
	<div class="dialog donationDialog" title="Donation" style="display: none;">
		<p>You want the incredible addon?</p>
		<p>Donate via Coffee?</p>
	</div>
	<div class="dialog openMenu" title="Open" style="display: none;">
	</div>
	<ul class="cmeditor-menubar menu">
		<li><a href="#">File</a>
			<ul class="fileMenu">
				<g:if test="${options.menuFile}">
				<li><a href="#" value="new"><span class="ui-icon ui-icon-newwin"></span>New</a></li>
				<li><a href="#" value="open"><span class="ui-icon ui-icon-newwin"></span>Open</a></li>
				<li><a href="#" value="save"><span class="ui-icon ui-icon-disk"></span>Save</a></li>
				<li><a href="#" value="saveas"><span class="ui-icon ui-icon-disk"></span>Save As</a></li>
				<li><a href="#" value="rename"><span></span>Rename</a></li>
				<li><a href="#" value="delete"><span class="ui-icon ui-icon-trash"></span>Delete</a></li>
				<li><a href="#" value="close"><span class="ui-icon ui-icon-close"></span>Close</a></li>
				</g:if>
				<li><a href="#" value="quit"><span></span>Quit</a></li>
			</ul>
		</li>
		<g:if test="${options.menuView}">
		<li><a href="#">View</a>
			<ul class="viewMenu">
				<li><a href="#" value="readOnly"><span></span>readOnly</a></li>
				<li><a href="#" value="diff"><span></span>diff</a></li>
				<li><a href="#" value="goto"><span></span>goto</a></li>
				<li><a href="#" value="addonfullscreen"><span></span>full-screen (f11)</a></li>
				<li><a href="#"><span></span>Mode</a>
					<ul class="modesMenu">
						<li><a href="#" value="modehtmlmixed"><span class="ui-icon ui-icon-blank"></span>htmlmixed</a></li>
						<li><a href="#" value="modehtmlembedded"><span></span>htmlembedded</a></li>
						<li><a href="#" value="modejavascript"><span></span>javascript</a></li>
						<li><a href="#" value="modexml"><span></span>xml</a></li>
						<li><a href="#" value="modecss"><span></span>css</a></li>
						<li><a href="#" value="modegroovy"><span></span>groovy</a></li>
						<li><a href="#" value="modejava"><span></span>java</a></li>
						<li><a href="#" value="modeproperties"><span></span>properties</a></li>
					</ul></li>
			</ul>
		</li>
		</g:if>
		<li><a href="#"><span class="'ui-button-text-icon-secondary"></span>Options</a>
			<ul class="optionsMenu">
				<li><a href="#" value="diffBeforeSave"><span></span>diffBeforeSave</a></li>
				<li><a href="#"><span></span>Binding</a>
					<ul id="cmeditor-menu-${name}-bindings">
						<li><a href="#" value="bindingdefault"><span class="ui-icon ui-icon-blank"></span>default</a></li>
						<li><a href="#" value="bindingvim"><span></span>vim</a></li>
						<li><a href="#" value="bindingemacs"><span></span>emacs</a></li>
						<li><a href="#" value="bindingsublime"><span></span>sublime</a></li>
					</ul></li>
				<li><a href="#"><span></span>Theme</a>
					<ul id="cmeditor-menu-${name}-themes">
						<li><a href="#" value="themedefault"><span class="ui-icon ui-icon-blank"></span>default</a></li>
						<li><a href="#" value="themeeclipse"><span></span>eclipse</a></li>
						<li><a href="#" value="themelesser-dark"><span></span>lesser-dark</a></li>
						<li><a href="#" value="thememonokai"><span></span>monokai</a></li>
						<li><a href="#" value="themenight"><span></span>night</a></li>
						<li><a href="#" value="themethe-matrix"><span></span>the-matrix</a></li>
						<li><a href="#" value="themetwilight"><span></span>twilight</a></li>
					</ul></li>
			</ul>
		</li>
		<li><a href="#"><span></span>Addons</a>
			<ul class="addonsMenu">
				<li><a href="#" value="addondonation"><span class="ui-icon ui-icon-blank"></span>incredible</a></li>
			</ul>
		</li>
	</ul>
</div>
<script type="text/javascript">
	this.CMEditorMenu = (function(){

		function CMEditorMenu(cmeditor, rootElem, options){
			var self = this;
			self.instanceNo = CMEditorMenu.instanciated++;

			self.cmeditor = cmeditor;
			self.rootElem = rootElem = $(rootElem);
			self.options  = options  = options !== undefined ? options : {};

			if (typeof self.init_before == "function") self.init_before();
			initMenus(self);
			addUserDefinedItems(self);
			registerMenuCallbacks(self);
			decorateMenuItems(self);
			initDialogs(self);


			self.rootElem.find(".menu").menubar({
				position: {
					within: $("#demo-frame").add(window).first()
				}
			});

			self.cmeditor.focus();
			log(self, "cmeditor_menu loaded.");
		}

		CMEditorMenu.instanciated = 0;
		function log(self, msg){console.log("CMEditorMenu #"+self.instanceNo+": "+msg);}

		/*
		 * Initialises menu objects where the keys are the menu items' anchor's names and the values are callbacks
		 */
		function initMenus(self){
			self.viewMenu = {
				readOnly: function(cm) {
					if (!cm.getOption("readOnly")) {
						cm.setOption("readOnly", "nocursor");
						self.find("a[value='addonfullscreen']").parent().addClass("ui-state-disabled");
					} else {
						cm.setOption("readOnly", false);
						self.find("a[value='addonfullscreen']").parent().removeClass("ui-state-disabled");
					}
				},
				diff: function(cm) { if(typeof self.cmeditor.diff == "function") self.cmeditor.diff(); },
				addonfullscreen: function(cm) {
					if (!cm.getOption("readOnly")) {
						cm.setOption("fullScreen", !cm.getOption("fullScreen"));
			        }
			    },
				modehtmlmixed: function(cm) { cm.setOption("mode", "htmlmixed"); },
				modehtmlembedded: function(cm) { cm.setOption("mode", "htmlembedded"); },
				modexml: function(cm) { cm.setOption("mode", "xml"); },
				modecss: function(cm) { cm.setOption("mode", "css"); },
				modejavascript: function(cm) { cm.setOption("mode", "javascript"); },
				modegroovy: function(cm) { cm.setOption("mode", "groovy"); },
				modejava: function(cm) { cm.setOption("mode", "text/x-java"); },
				modeproperties: function(cm) { cm.setOption("mode", "properties"); },
			}

			self.fileMenu = {
				new: function(cm) { self.cmeditor.new(); },
				open: function(cm) {

					var s = $("<select class=\"fileSelect\" name=\"cmeditor-menu-open-select\" multiple=\"true\" />");
					self.openDialog.find(".noFiles").remove();
					self.openDialog.find(".fileSelect").remove();
					self.openDialog.find(".chosen-container").remove();

					if(self.options.ajax.listURL){
						$.get(self.options.ajax.listURL, function(data){
							if (data.status == "success") {
								var available = false
								var myButtons = {
									Cancel: function() { $(this).dialog( "close" ); },
								};
								for(var i=0; i < data.result.length; ++i) {
									if (self.cmeditor.doc_id(data.result[i]) == undefined) {
										$("<option />", {value: data.result[i], text: data.result[i]}).appendTo(s);
										available = true;
									}
								}
								if (available == true) {
									s.appendTo(self.openDialog);
									self.openDialog.find(".fileSelect").chosen({width:"95%"});
									myButtons.Open = function() {
										var vals = self.openDialog.find(".fileSelect").val();
										for (var i in vals) {
											self.cmeditor.ajax_load(vals[i]);
										}
										$(this).dialog( "close" );
									};
								} else {
									s = $("<p class=\"noFiles\" name=\"cmeditor-menu-open-no-files\">No files available.</p>");
									s.appendTo(self.openDialog);
								}

								self.openDialog.dialog("option", "buttons", myButtons);
								self.openDialog.dialog("open");
								log(self, "opened");
							} else {
								self.cmeditor.update_message(data.msg);
							}
						});
					}
				},
				save: function(cm) { self.cmeditor.save(); },
				saveas: function(cm) { self.cmeditor.saveas(); },
				rename: function(cm) {
					var name = prompt("Name of the new buffer", "");
					log(self, name);
					if (name == null) return;
					if (!name) name = "test";
					log(self, self.cmeditor.get_name(name));
					self.cmeditor.rename_doc(self.cmeditor.get_name(name));
				},
				delete: function(cm) { self.cmeditor.delete(); },
				close: function(cm) { self.cmeditor.close(); },
				quit: function(cm) {
					if (typeof cm.toTextArea == "function") {
						cm.toTextArea();
						self.rootElem.find(".container").remove();
					} else {
						self.cmeditor.rootElem.remove();
					}
				},
			};

			self.viewMenu = {
				readOnly: function(cm) {
					if (!cm.getOption("readOnly")) {
						cm.setOption("readOnly", "nocursor");
						self.rootElem.find(".viewMenu a[value='addonfullscreen']").parent().addClass("ui-state-disabled");
					} else {
						cm.setOption("readOnly", false);
						self.rootElem.find(".viewMenu a[value='addonfullscreen']").parent().removeClass("ui-state-disabled");
					}
				},
				diff: function(cm) { if(typeof self.cmeditor.diff == "function") self.cmeditor.diff(); },
				goto: function(cm) { self.cmeditor.goto() },
				addonfullscreen: function(cm) {
					if (!cm.getOption("readOnly")) {
						cm.setOption("fullScreen", !cm.getOption("fullScreen"));
			        }
			    },
				modehtmlmixed: function(cm) { cm.setOption("mode", "htmlmixed"); },
				modehtmlembedded: function(cm) { cm.setOption("mode", "htmlembedded"); },
				modexml: function(cm) { cm.setOption("mode", "xml"); },
				modecss: function(cm) { cm.setOption("mode", "css"); },
				modejavascript: function(cm) { cm.setOption("mode", "javascript"); },
				modegroovy: function(cm) { cm.setOption("mode", "groovy"); },
				modejava: function(cm) { cm.setOption("mode", "text/x-java"); },
				modeproperties: function(cm) { cm.setOption("mode", "properties"); },
			}
			self.optionsMenu = {
				diffBeforeSave: function(cm) {
					if(typeof self.cmeditor.set_diff_before_save == "function")
						self.cmeditor.set_diff_before_save(self.rootElem.find(".optionsMenu a[value='diffBeforeSave']").children("span").hasClass("ui-icon-check")); },
				bindingdefault: function(cm) { cm.setOption("keymap", "default"); cm.setOption("vimMode", false); },
				bindingvim: function(cm) { cm.setOption("keymap", "vim"); cm.setOption("vimMode", true); },
				bindingemacs: function(cm) { cm.setOption("keymap", "emacs"); cm.setOption("vimMode", false); },
				bindingsublime: function(cm) { cm.setOption("keymap", "sublime"); cm.setOption("vimMode", false); },
				themedefault: function(cm) { cm.setOption("theme", "default"); },
				themeeclipse: function(cm) { cm.setOption("theme", "eclipse"); },
				"themelesser-dark": function(cm) { cm.setOption("theme", "lesser-dark"); },
				thememonokai: function(cm) { cm.setOption("theme", "monokai"); },
				themenight: function(cm) { cm.setOption("theme", "night"); },
				"themethe-matrix": function(cm) { cm.setOption("theme", "the-matrix"); },
				themetwilight: function(cm) { cm.setOption("theme", "twilight"); },
				//theme: function(cm) { cm.setOption("theme", ""); },
			};
			self.addonsMenu = {
				addondonation: function(cm) {
					self.donationDialog.dialog("open");
				},
			};
		}

		/*
		 * Initialises the modal dialogs
		 */
		function initDialogs(self){
			self.donationDialog = self.rootElem.find(".donationDialog").dialog({
						autoOpen: false,
						height: 300,
						buttons: {
							Yes: function() { $( this ).dialog( "close" ); },
							No: function() { $( this ).dialog( "close" ); },
						},
					});

			self.openDialog = self.rootElem.find(".openMenu").dialog({
						autoOpen: false,
						height: 300
					});

		}

		/*
		 * Adds items to the menu which the user defined via options
		 */
		function addUserDefinedItems(self) {
			if(self.options.addModes){
				for (var i = self.options.addModes.length - 1; i >= 0; i--) {
					var mode = self.options.addModes[i];

					var s = $("<li><a href=\"#\" value=\"mode"+mode+"\"><span></span>"+mode+"</a></li>");
					s.appendTo(self.rootElem.find(".modesMenu"));
					self.viewMenu["mode"+mode] = function(name) {
						return function(cm) { cm.setOption("mode", name); };
					}(mode);
				}
			}

			if (typeof self.options.overlayDefinitionsVar !== "undefined") {
				for(var name in self.options.overlayDefinitionsVar) {
					var s = $("<li><a href=\"#\" value=\"mode"+name+"\"><span></span>"+name+"</a></li>");
					s.appendTo(self.rootElem.find(".modesMenu"));
					self.viewMenu["mode"+name] = function(name) {
						return function(cm) { cm.setOption("mode", name); };
					}(name);
				}
			}
		}

		/*
		 * Marks or grays out some menu items depending on their values
		 */
		function decorateMenuItems(self){
			self.rootElem.find(".modesMenu a[value='mode"+self.options.mode+"']").children("span").addClass("ui-icon ui-icon-check");

			if(self.options.useSession){
				if (localStorage["cmeditor-menu-binding"])
					self.rootElem.find(".optionsMenu a[value='binding"+localStorage["cmeditor-menu-binding"]+"']").children("span").addClass("ui-icon ui-icon-check");
				else
					self.rootElem.find(".optionsMenu a[value='bindingdefault']").children("span").addClass("ui-icon ui-icon-check");

				if (localStorage['cmeditor-menu-theme'])
					self.rootElem.find(".optionsMenu a[value='theme"+localStorage['cmeditor-menu-theme']+"']").children("span").addClass("ui-icon ui-icon-check");
				else
					self.rootElem.find(".optionsMenu a[value='themedefault']").children("span").addClass("ui-icon ui-icon-check");

				if (localStorage['cmeditor-menu-diffBeforeSave'] === true)
					self.rootElem.find(".optionsMenu a[value='diffBeforeSave']").children("span").addClass("ui-icon ui-icon-check");
				else if (self.options.defaultDiffBeforeSave)
					self.rootElem.find(".optionsMenu a[value='diffBeforeSave']").children("span").addClass("ui-icon ui-icon-check");

			}else{
				self.rootElem.find(".optionsMenu a[value='binding"+self.options.binding+"']").children("span").addClass("ui-icon ui-icon-check");
				self.rootElem.find(".optionsMenu a[value='theme"+self.options.theme+"']").children("span").addClass("ui-icon ui-icon-check");

				if(self.options.defaultDiffBeforeSave){
					self.rootElem.find(".optionsMenu a[value='diffBeforeSave']").children("span").addClass("ui-icon ui-icon-check");
				}
			}

			if(self.options.defaultReadOnly){
				self.rootElem.find(".viewMenu a[value='readOnly']").children("span").addClass("ui-icon ui-icon-check");
			}
			if(self.options.readOnly){
				self.rootElem.find(".viewMenu a[value='readOnly']").children("span").addClass("ui-icon ui-icon-check");
				self.rootElem.find(".viewMenu a[value='readOnly']").parent().addClass("ui-state-disabled");
				self.rootElem.find(".fileMenu a[value='new']").parent().addClass("ui-state-disabled");
				self.rootElem.find(".fileMenu a[value='save']").parent().addClass("ui-state-disabled");
				self.rootElem.find(".fileMenu a[value='saveas']").parent().addClass("ui-state-disabled");
				self.rootElem.find(".fileMenu a[value='rename']").parent().addClass("ui-state-disabled");
				self.rootElem.find(".fileMenu a[value='delete']").parent().addClass("ui-state-disabled");
			}

			if(typeof self.cmeditor.diff != "function") {
				self.rootElem.find(".viewMenu a[value='diff']").parent().remove();
				self.rootElem.find(".optionsMenu a[value='diffBeforeSave']").parent().remove();
			}
		}

		/*
		 *	Registers click callbacks on anchors in menu items
		 */
		function registerMenuCallbacks(self){
			self.rootElem.find(".fileMenu a").click(function(event) {
				log(self, "file menu entry clicked");
				var found = self.fileMenu[$(this).attr("value")];
			    self.cmeditor.focus();

			    if (found) found(self.cmeditor.getCodeMirror());
			    else log(self, "CALLED MISSING FILE: "+$(this).attr("value"));

				event.preventDefault();
			});

			self.rootElem.find(".viewMenu a").click(function(event) {
				var found = self.viewMenu[$(this).attr("value")];
			    self.cmeditor.focus();

			    if (found) found(self.cmeditor.getCodeMirror());
			    else log(self, "CALLED MISSING VIEW: "+$(this).attr("value"));

			    if ($(this).attr("value").indexOf("mode") == 0) {
			    	self.cmeditor.update();
					$(this).parent().parent().find("span").removeClass("ui-icon ui-icon-check");
					$(this).children("span").addClass("ui-icon ui-icon-check");
			    }
			    if ($(this).attr("value").indexOf("readOnly") == 0) {
			    	if (self.cmeditor.getCodeMirror().getOption("readOnly")) {
			    		$(this).children("span").addClass("ui-icon ui-icon-check");
			    	} else {
			    		$(this).children("span").removeClass("ui-icon ui-icon-check");
			    	}
			    	self.cmeditor.update();
			    }
				event.preventDefault();
			});

			self.rootElem.find(".optionsMenu a").click(function(event) {
				if ($(this).attr("value").indexOf("diffBeforeSave") == 0) {
					if ($(this).children("span").hasClass("ui-icon-check")) {
						$(this).children("span").removeClass("ui-icon ui-icon-check");
					} else {
						$(this).children("span").addClass("ui-icon ui-icon-check");
					}
				} else {
					$(this).parent().parent().find("span").removeClass("ui-icon ui-icon-check");
					$(this).children("span").addClass("ui-icon ui-icon-check");
				}

				var found = self.optionsMenu[$(this).attr("value")];
			    self.cmeditor.focus();

			    if (found) found(self.cmeditor.getCodeMirror())
			    else log(self, "CALLED MISSING OPTIONS: "+$(this).attr("value"));

				if(self.options.useSession){
				    if ($(this).attr("value").indexOf("binding") == 0) {localStorage["cmeditor-menu-binding"] = $(this).attr("value").substring(7);}
				    if ($(this).attr("value").indexOf("theme") == 0) {localStorage["cmeditor-menu-theme"] = $(this).attr("value").substring(5);}
				    if ($(this).attr("value").indexOf("diffBeforeSave") == 0) {localStorage["cmeditor-menu-diffBeforeSave"] = $(this).children("span").hasClass("ui-icon-check");}
				}
			    //return false;
			    event.preventDefault();
			});

			self.rootElem.find(".addonsMenu a").click(function(event) {
				var found = self.addonsMenu[$(this).attr("value")];
			    self.cmeditor.focus();
			    if (found) found(self.cmeditor.getCodeMirror());
			    else log(self, "CALLED MISSING FILE: "+$(this).attr("value"));
				event.preventDefault();
			});
		}

		function update(self) {
			self.rootElem.find(".modesMenu").find("span").removeClass("ui-icon ui-icon-check");
			self.rootElem.find(".modesMenu a[value='mode"+self.cmeditor.get_mode()+"']").children("span").addClass("ui-icon ui-icon-check");

			if (self.cmeditor.getCodeMirror().getOption("readOnly")) {
				log(self, "RO");
				self.rootElem.find(".view a[value='readOnly'] span").addClass("ui-icon ui-icon-check");
				self.rootElem.find(".view a[value='addonfullscreen']").parent().addClass("ui-state-disabled");
			} else {
				log(self, "RW");
				self.rootElem.find(".view a[value='readOnly'] span").removeClass("ui-icon ui-icon-check");
				self.rootElem.find(".view a[value='addonfullscreen']").parent().removeClass("ui-state-disabled");
			}

			log(self, "cmeditor_menu_update was performed.")
		}

		CMEditorMenu.prototype.constructor = CMEditorMenu;
		CMEditorMenu.prototype.update = function(){update(this)};

		return CMEditorMenu;
	})();
</script>
