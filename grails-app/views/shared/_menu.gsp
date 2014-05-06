<r:require modules="cmeditor-menu" />
<div id="cmeditor-menu-${name}-container" class="cmeditor-menu">
	<div id="cmeditor-menu-${name}-donation" class="dialog" title="Donation" style="display: none;">
		<p>You want the incredible addon?</p>
		<p>Donate via Coffee?</p>
	</div>
	<div id="cmeditor-menu-${name}-open" class="dialog" title="Open" style="display: none;">
	</div>
	<ul id="cmeditor-menu-${name}" class="cmeditor-menubar">
		<li><a href="#">File</a>
			<ul id="cmeditor-menu-${name}-file">
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
			<ul id="cmeditor-menu-${name}-view">
				<li><a href="#" value="readOnly"><span></span>readOnly</a></li>
				<li><a href="#" value="diff"><span></span>diff</a></li>
				<li><a href="#" value="addonfullscreen"><span></span>full-screen (f11)</a></li>
				<li><a href="#"><span></span>Mode</a>
					<ul id="cmeditor-menu-${name}-modes">
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
			<ul id="cmeditor-menu-${name}-options">
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
			<ul id="cmeditor-menu-${name}-addons">
				<li><a href="#" value="addondonation"><span class="ui-icon ui-icon-blank"></span>incredible</a></li>
			</ul>
		</li>
	</ul>
</div>
<r:script disposition="head">
	var cmeditor_menu_${name}_file = {
		new: function(cm) { cmeditor_${name}_new(cm); },
		open: function(cm) {
			var s = $("<select id=\"cmeditor-menu-${name}-open-select\" name=\"cmeditor-menu-${name}-open-select\" multiple=\"true\" />");
			$('#cmeditor-menu-${name}-open-no-files').remove();
			$('#cmeditor-menu-${name}-open-select').remove();
			$('#cmeditor-menu-${name}-open .chosen-container').remove();
			<g:if test="${ajax.listURL}">
			$.get("${ajax.listURL}", function(data){
				if (data.success) {
					var available = false
					var myButtons = {
						Cancel: function() { $( this ).dialog( "close" ); },
					};
					for(var i=0; i < data.result.length; ++i) {
						//cmeditor_${name}_load_by_name(data.result[i]);
						if (cmeditor_${name}_doc_id(data.result[i]) == undefined) {
							$("<option />", {value: data.result[i], text: data.result[i]}).appendTo(s);
							available = true;
						}
					}
					if (available == true) {
						s.appendTo("#cmeditor-menu-${name}-open");
						$('#cmeditor-menu-${name}-open-select').chosen({width:'95%'});
						myButtons.Open = function() {
							var vals = $('#cmeditor-menu-${name}-open-select').val();
							for (var i in vals) {
								cmeditor_${name}_ajax_load(vals[i]);
							}
							$( this ).dialog( "close" );
						};
					} else {
						s = $("<p id=\"cmeditor-menu-${name}-open-no-files\" name=\"cmeditor-menu-${name}-open-no-files\">No files available.</p>");
						s.appendTo("#cmeditor-menu-${name}-open");
					}
					$('#cmeditor-menu-${name}-open').dialog({
						height: 300,
						buttons: myButtons,
					});
				} else {
					cmeditor_${name}_update_message(data.message);
				}
			});
			</g:if>
		},
		save: function(cm) { cmeditor_${name}_save(cm); },
		saveas: function(cm) { cmeditor_${name}_saveas(cm); },
		rename: function(cm) {
			var name = prompt("Name of the new buffer", "");
			if (name == null) return;
			if (!name) name = "test";
			cmeditor_${name}_rename_doc(cmeditor_${name}_get_name(name));
		},
		delete: function(cm) { cmeditor_${name}_ajax_delete(); },
		close: function(cm) { cmeditor_${name}_close(cm); },
		quit: function(cm) {
			if (typeof cm.toTextArea == 'function') {
				cm.toTextArea();
				$('#cmeditor-menu-${name}-container').remove();
			} else {
				$('#cmeditor-tabs-${name}-update').remove();
				$('#cmeditor-tabs-${name}').remove();
			}
		},
		};
	var cmeditor_menu_${name}_view = {
		readOnly: function(cm) {
			if (!cm.getOption('readOnly')) {
				cm.setOption('readOnly', 'nocursor');
				$("#cmeditor-menu-${name}-view a[value='addonfullscreen']").parent().addClass('ui-state-disabled');
			} else {
				cm.setOption('readOnly', false);
				$("#cmeditor-menu-${name}-view a[value='addonfullscreen']").parent().removeClass('ui-state-disabled');
			}
		},
		diff: function(cm) { if(typeof cmeditor_${name}_diff == 'function') cmeditor_${name}_diff(cm); },
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
	var cmeditor_menu_${name}_options = {
		diffBeforeSave: function(cm) { if(typeof cmeditor_${name}_set_diff_before_save == 'function') cmeditor_${name}_set_diff_before_save($("#cmeditor-menu-${name}-options a[value='diffBeforeSave']").children('span').hasClass('ui-icon-check')); },
		bindingdefault: function(cm) { cm.setOption("keymap", "default"); cm.setOption("vimMode", false); },
		bindingvim: function(cm) { cm.setOption("keymap", "vim"); cm.setOption("vimMode", true); },
		bindingemacs: function(cm) { cm.setOption("keymap", "emacs"); cm.setOption("vimMode", false); },
		bindingsublime: function(cm) { cm.setOption("keymap", "sublime"); cm.setOption("vimMode", false); },
		themedefault: function(cm) { cm.setOption("theme", "default"); },
		themeeclipse: function(cm) { cm.setOption("theme", "eclipse"); },
		'themelesser-dark': function(cm) { cm.setOption("theme", "lesser-dark"); },
		thememonokai: function(cm) { cm.setOption("theme", "monokai"); },
		themenight: function(cm) { cm.setOption("theme", "night"); },
		'themethe-matrix': function(cm) { cm.setOption("theme", "the-matrix"); },
		themetwilight: function(cm) { cm.setOption("theme", "twilight"); },
		//theme: function(cm) { cm.setOption("theme", ""); },
	};
	var cmeditor_menu_${name}_addons = {
		addondonation: function(cm) {
			$('#cmeditor-menu-${name}-donation').dialog({
				height: 300,
				buttons: {
					Yes: function() { $( this ).dialog( "close" ); },
					No: function() { $( this ).dialog( "close" ); },
				},
			});
		},
	};
	function cmeditor_menu_${name}_init() {
		<g:if test="${options.addModes}">
			<g:each in="${options.addModes}" var="mode">
				var s = $("<li><a href=\"#\" value=\"mode${mode}\"><span></span>${mode}</a></li>");
				s.appendTo("#cmeditor-menu-${name}-modes");
				cmeditor_menu_${name}_view['mode${mode}'] = function(name) {
					return function(cm) { cm.setOption("mode", name); };
					}('${mode}');
			</g:each>
		</g:if>
		if (typeof ${options.overlayDefinitionsVar} !== 'undefined') {
			for(var name in ${options.overlayDefinitionsVar}) {
				var s = $("<li><a href=\"#\" value=\"mode"+name+"\"><span></span>"+name+"</a></li>");
				s.appendTo("#cmeditor-menu-${name}-modes");
				cmeditor_menu_${name}_view["mode"+name] = function(name) {
					return function(cm) { cm.setOption("mode", name); };
					}(name);
			}
		}
		//cmeditor_menu_${name}_options['mode'+'dammit'] = function(cm) { cm.setOption("mode", 'dammit'); };
		$('#cmeditor-menu-${name}').menubar({
			position: {
				within: $("#demo-frame").add(window).first()
			}
		});
		$('#cmeditor-menu-${name}-file a').click(function(event) {
			var found = cmeditor_menu_${name}_file[$(this).attr('value')];
		    cmeditor_${name}.focus();
		    if (found) found(cmeditor_${name});
		    else console.log("CALLED MISSING FILE: "+$(this).attr('value'));
			event.preventDefault();
		});
		$('#cmeditor-menu-${name}-view a').click(function(event) {
			var found = cmeditor_menu_${name}_view[$(this).attr('value')];
		    cmeditor_${name}.focus();
		    if (found) found(cmeditor_${name});
		    else console.log("CALLED MISSING VIEW: "+$(this).attr('value'));
		    if ($(this).attr('value').indexOf('mode') == 0) {
		    	cmeditor_${name}_update();
				$(this).parent().parent().find('span').removeClass('ui-icon ui-icon-check');
				$(this).children('span').addClass('ui-icon ui-icon-check');
		    }
		    if ($(this).attr('value').indexOf('readOnly') == 0) {
		    	if (cmeditor_${name}.getOption('readOnly')) {
		    		$(this).children('span').addClass('ui-icon ui-icon-check');
		    	} else {
		    		$(this).children('span').removeClass('ui-icon ui-icon-check');
		    	}
		    	cmeditor_${name}_update();
		    }
			event.preventDefault();
		});
		$('#cmeditor-menu-${name}-options a').click(function(event) {
			if ($(this).attr('value').indexOf('diffBeforeSave') == 0) {
				if ($(this).children('span').hasClass('ui-icon-check')) {
					$(this).children('span').removeClass('ui-icon ui-icon-check');
				} else {
					$(this).children('span').addClass('ui-icon ui-icon-check');
				}
			} else {
				$(this).parent().parent().find('span').removeClass('ui-icon ui-icon-check');
				$(this).children('span').addClass('ui-icon ui-icon-check');
			}
			var found = cmeditor_menu_${name}_options[$(this).attr('value')];
		    cmeditor_${name}.focus();
		    if (found) found(cmeditor_${name})
		    else console.log("CALLED MISSING OPTIONS: "+$(this).attr('value'));
		    <g:if test="${options.useSession}">if ($(this).attr('value').indexOf('binding') == 0) {localStorage['cmeditor-menu-binding'] = $(this).attr('value').substring(7);}</g:if>
		    <g:if test="${options.useSession}">if ($(this).attr('value').indexOf('theme') == 0) {localStorage['cmeditor-menu-theme'] = $(this).attr('value').substring(5);}</g:if>
		    <g:if test="${options.useSession}">if ($(this).attr('value').indexOf('diffBeforeSave') == 0) {localStorage['cmeditor-menu-diffBeforeSave'] = $(this).children('span').hasClass('ui-icon-check');}</g:if>
		    //return false;
		    event.preventDefault();
		});
		$('#cmeditor-menu-${name}-addons a').click(function(event) {
			var found = cmeditor_menu_${name}_addons[$(this).attr('value')];
		    cmeditor_${name}.focus();
		    if (found) found(cmeditor_${name});
		    else console.log("CALLED MISSING FILE: "+$(this).attr('value'));
			event.preventDefault();
		});
		
		$("#cmeditor-menu-${name}-modes a[value='mode${options.mode}']").children('span').addClass('ui-icon ui-icon-check');
		<g:if test="${options.useSession}">
		if (localStorage['cmeditor-menu-binding']) $("#cmeditor-menu-${name}-options a[value='binding"+localStorage['cmeditor-menu-binding']+"']").children('span').addClass('ui-icon ui-icon-check');
		else $("#cmeditor-menu-${name}-options a[value='bindingdefault']").children('span').addClass('ui-icon ui-icon-check'); 
		if (localStorage['cmeditor-menu-theme']) $("#cmeditor-menu-${name}-options a[value='theme"+localStorage['cmeditor-menu-theme']+"']").children('span').addClass('ui-icon ui-icon-check');
		else $("#cmeditor-menu-${name}-options a[value='themedefault']").children('span').addClass('ui-icon ui-icon-check'); 
		if (localStorage['cmeditor-menu-diffBeforeSave']) $("#cmeditor-menu-${name}-options a[value='diffBeforeSave']").children('span').addClass('ui-icon ui-icon-check');
		<g:if test="${options.defaultDiffBeforeSave}">
		else $("#cmeditor-menu-${name}-options a[value='diffBeforeSave']").children('span').addClass('ui-icon ui-icon-check');
		</g:if>
		</g:if>
		<g:else>
		$("#cmeditor-menu-${name}-options a[value='binding${options.binding}']").children('span').addClass('ui-icon ui-icon-check');
		$("#cmeditor-menu-${name}-options a[value='theme${options.theme}']").children('span').addClass('ui-icon ui-icon-check');
		<g:if test="${options.defaultDiffBeforeSave}">
		$("#cmeditor-menu-${name}-options a[value='diffBeforeSave']").children('span').addClass('ui-icon ui-icon-check');
		</g:if>
		</g:else>
		
		<g:if test="${options.defaultReadOnly}">
			$("#cmeditor-menu-${name}-view a[value='readOnly']").children('span').addClass('ui-icon ui-icon-check');
		</g:if>
		<g:if test="${options.readOnly}">
			$("#cmeditor-menu-${name}-view a[value='readOnly']").children('span').addClass('ui-icon ui-icon-check');
			$("#cmeditor-menu-${name}-view a[value='readOnly']").parent().addClass('ui-state-disabled');
			$("#cmeditor-menu-${name}-file a[value='new']").parent().addClass('ui-state-disabled');
			$("#cmeditor-menu-${name}-file a[value='save']").parent().addClass('ui-state-disabled');
			$("#cmeditor-menu-${name}-file a[value='saveas']").parent().addClass('ui-state-disabled');
			$("#cmeditor-menu-${name}-file a[value='rename']").parent().addClass('ui-state-disabled');
			$("#cmeditor-menu-${name}-file a[value='delete']").parent().addClass('ui-state-disabled');
		</g:if>
		
		if(typeof cmeditor_${name}_diff != 'function') {
			$("#cmeditor-menu-${name}-view a[value='diff']").parent().remove();
			$("#cmeditor-menu-${name}-options a[value='diffBeforeSave']").parent().remove();
		}
		
		cmeditor_${name}.focus();
		console.log("cmeditor_${name}_menu loaded.")
	};
	function cmeditor_menu_${name}_update() {
		$('#cmeditor-menu-${name}-modes').find('span').removeClass('ui-icon ui-icon-check');
		$("#cmeditor-menu-${name}-modes a[value='mode"+cmeditor_${name}_get_mode()+"']").children('span').addClass('ui-icon ui-icon-check');
		if (cmeditor_${name}.getOption('readOnly')) {
			console.log("RO");
			$("#cmeditor-menu-${name}-view a[value='readOnly'] span").addClass('ui-icon ui-icon-check');
			$("#cmeditor-menu-${name}-view a[value='addonfullscreen']").parent().addClass('ui-state-disabled');
		} else {
			console.log("RW");
			$("#cmeditor-menu-${name}-view a[value='readOnly'] span").removeClass('ui-icon ui-icon-check');
			$("#cmeditor-menu-${name}-view a[value='addonfullscreen']").parent().removeClass('ui-state-disabled');
		}
		console.log("cmeditor_menu_${name}_update was performed.")
	};
</r:script>