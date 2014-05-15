<r:require modules="cmeditor-tabs" />

<div id="cmeditor-tabs-${name}" class="cmeditor">
	<div id="cmeditor-tabs-${name}-diff" class="dialog" title="diff" style="display: none;">
		<div id="cmeditor-tabs-${name}-diffoutput"> </div>
		<p>
		<strong>Context size (optional):</strong> <input type="text" onKeyUp="if($(this).val()) cmeditor_${name}_diffUsingJS(0);" id="cmeditor-tabs-${name}-diffoutput-contextSize" value="1" />
		</p>
		<p>
		<input type="radio" name="_viewtype" id="sidebyside" onclick="cmeditor_${name}_diffUsingJS(0);" /> <label for="sidebyside">Side by Side Diff</label>
		&nbsp; &nbsp;
		<input type="radio" name="_viewtype" id="inline" onclick="cmeditor_${name}_diffUsingJS(1);" /> <label for="inline">Inline Diff</label>
		</p>
		<form>
		</form>
	</div>
	<div id="cmeditor-tabs-${name}-readOnly" class="dialog" title="readOnly" style="display: none;">
		<form>
		</form>
	</div>
	<div id="cmeditor-tabs-${name}-warning" class="dialog" title="warning" style="display: none;">
		<form>
		</form>
	</div>
	<div id="cmeditor-tabs-${name}-update" class="cmeditor-tab-message" style="display:none;"></div>
	<g:if test="${options.menu}">
		<g:render template="/shared/menu" plugin="cm-editor" model="[name:name, options:options]"></g:render>
	</g:if>
	<div class="cmeditor-settings"></div>
	<div class="cmeditor-main">
		<form id="cmeditor-tabs-${name}-form" method="post" onsubmit="cmeditor_${name}_ajax_update($(this).serialize());return false">
			<g:hiddenField name="_cmeditorName" class="cmeditor-field" value="" />
			<g:hiddenField name="_cmeditorMode" class="cmeditor-field" value="" />
			<g:hiddenField name="_cmeditorStatus" class="cmeditor-field" value="" />
			<g:hiddenField name="_cmeditorReadOnly" class="cmeditor-field" value="" />
			<g:hiddenField name="_cmeditorOrigContent" class="cmeditor-field" value="" />
			<g:hiddenField name="_cmeditorContent" class="cmeditor-field" value="" />
			${body()}
			<ul id="cmeditor-tabs-${name}-docs" class="tabs"></ul>
		</form>
	</div>
</div>
<r:script>
	function cmeditor_${name}_diffUsingJS(viewType) {
		"use strict";
		var byId = function (id) { return document.getElementById(id); },
			base = difflib.stringAsLines(byId("_cmeditorOrigContent").value),
			newtxt = difflib.stringAsLines(byId("_cmeditorContent").value),
			sm = new difflib.SequenceMatcher(base, newtxt),
			opcodes = sm.get_opcodes(),
			diffoutputdiv = byId("cmeditor-tabs-${name}-diffoutput"),
			contextSize = byId("cmeditor-tabs-${name}-diffoutput-contextSize").value;
	
		diffoutputdiv.innerHTML = "";
		contextSize = contextSize || null;
		
		if (opcodes && opcodes.length == 1) {
			$("#cmeditor-tabs-${name}-diffoutput").html("<p>No changes!</p>");
		} else {
			diffoutputdiv.appendChild(diffview.buildView({
				baseTextLines: base,
				newTextLines: newtxt,
				opcodes: opcodes,
				baseTextName: "Base Text",
				newTextName: "New Text",
				contextSize: contextSize,
				viewType: viewType
			}));
		}
	}

	var cmeditor_${name};
	
	var cmeditor_docs_${name} = [], cmeditor_curDoc_${name}, cmeditor_unregDocName_${name};
	
	var cmeditor_diffBeforeSave_${name};
	
	function cmeditor_${name}_find_doc(name) { return cmeditor_docs_${name}[cmeditor_${name}_doc_id(name)]; }
	function cmeditor_${name}_doc_id(name) { for (var i = 0; i < cmeditor_docs_${name}.length; ++i) if (cmeditor_docs_${name}[i]._cmeditorName == name) return i; }
	
	function cmeditor_${name}_update_message(data,textStatus) {
		$('#cmeditor-tabs-${name}-update').html(data);
		$("#cmeditor-tabs-${name}-update").toggle('slide', {'direction':'up'}).delay(3000).toggle('slide', {'direction':'up'});
	}
	
	function cmeditor_${name}_ajax_update(data) {
		if (cmeditor_curDoc_${name}) {
			$.ajax({
				type:'POST',
				data:data,
				url:'${ajax.updateURL}',
				success:function(data,textStatus){
					if (data.status == 'success') {
						cmeditor_${name}_ajax_reload();
					}
					cmeditor_${name}_update_message(data.msg, textStatus);
					},
				error:function(XMLHttpRequest,textStatus,errorThrown){
					},
			});
			return false;
		}
	}
	
	function cmeditor_${name}_ajax_reload() {
		if (cmeditor_curDoc_${name}) {
			var name = cmeditor_curDoc_${name}._cmeditorName;
			cmeditor_${name}_unregister_doc(cmeditor_curDoc_${name});
			cmeditor_${name}_ajax_load(name, true);
		}
	}
	
	function cmeditor_${name}_ajax_load(name, readWrite) {
		$.ajax({
			type:'GET',
			url: "${ajax.getURL}"+name,
			success: function(data){
				if (data.status == 'success' && data.result) {
					data.result._cmeditorName = data.result.${mapping.name};
					data.result._cmeditorMode = data.result.${mapping.mode} || '${options.defaultMode}';
					if (readWrite) {
						data.result._cmeditorReadOnly = '';
					} else {
						data.result._cmeditorReadOnly = '${options.readOnly||options.defaultReadOnly?'nocursor':''}';
					}
					data.result._cmeditorContent = data.result.${mapping.content};
					data.result._cmeditorOrigContent = data.result.${mapping.content};
					data.result._cmeditorStatus = 'unchanged';
					data.result._cmeditorDoc = new CodeMirror.Doc(data.result._cmeditorContent, data.result._cmeditorMode);
					cmeditor_${name}_register_doc_data(data.result);
					console.log("cmeditor_${name}_ajax_load '"+name+"' was performed.");
					console.log(data.result.version)
				} else {
					cmeditor_${name}_update_message(data.msg);
				}
			},
			error:function(XMLHttpRequest,textStatus,errorThrown){
				cmeditor_${name}_update_message(textStatus + ": " + errorThrown);
			},
		});
	}
	
	function cmeditor_${name}_ajax_delete() {
		<g:if test="${options.readOnly}">
		$('#cmeditor-tabs-${name}-readOnly').dialog({ height: 300, buttons: {Cancel: function() { $( this ).dialog( "close" ); },},});
		</g:if><g:else>
		if (cmeditor_curDoc_${name}["${options.idField}"]) {
			$.ajax({
				type:'GET',
				data:{id:cmeditor_curDoc_${name}["${options.idField}"]},
				url:'${ajax.deleteURL}',
				success:function(data,textStatus){
					if (data.status == 'success') {
						// do sth
					}
					cmeditor_${name}_update_message(data,textStatus);
					//cmeditor_${name}_ajax_reload();
				},
				error:function(XMLHttpRequest,textStatus,errorThrown){
				}});
		}
		cmeditor_${name}_unregister_doc(cmeditor_curDoc_${name});
		return false;
		</g:else>
	}
	
	function cmeditor_${name}_get_name(name) {
		var data = [];
		<g:if test="${ajax.listURL}">
		$.ajax({
    		url: "${ajax.listURL}",
    		success: function(json) {
    			if (json.status == 'success' && json.result) {
      				data = json.result;
      			}
    		},
    		async:false
  		});
  		</g:if>
  		var i = 0;
  		while (cmeditor_${name}_find_doc(name + (i || "")) || cmeditortabs_is_in_list(data, name + (i || ""))) ++i;
		return name + (i || "");
	}
	
	function cmeditor_${name}_register_doc_data(data) {
		cmeditor_docs_${name}.push(data);
		var docTabs = document.getElementById("cmeditor-tabs-${name}-docs");
		var li = docTabs.appendChild(document.createElement("li"));
		li.appendChild(document.createTextNode(data._cmeditorName));
		if (cmeditor_${name}.getDoc() == data._cmeditorDoc) {
			cmeditor_${name}_set_selected_doc(cmeditor_docs_${name}.length - 1);
			cmeditor_curDoc_${name} = data;
		}
		cmeditor_${name}_select_doc(cmeditor_docs_${name}.length - 1);
		cmeditor_${name}_unregister_untitled_doc();
		console.log("cmeditor_${name}_register_doc_data '"+data._cmeditorName+"' was performed. Current doc: "+cmeditor_curDoc_${name})
	}
	
	function cmeditor_${name}_register_doc(name, doc) {
		var data = {_cmeditorName: name, _cmeditorContent:'', _cmeditorStatus:'new'};
		data._cmeditorDoc = doc;
		cmeditor_docs_${name}.push(data);
		var docTabs = document.getElementById("cmeditor-tabs-${name}-docs");
		var li = docTabs.appendChild(document.createElement("li"));
		li.appendChild(document.createTextNode(name));
		if (cmeditor_${name}.getDoc() == doc) {
			setSelectedDoc(cmeditor_docs_${name}.length - 1);
			cmeditor_curDoc_${name} = data;
		}
		cmeditor_${name}_select_doc(cmeditor_docs_${name}.length - 1);
		cmeditor_${name}_unregister_untitled_doc();
		console.log("cmeditor_${name}_register_doc '"+name+"' was performed. Current doc: "+cmeditor_curDoc_${name})
	}
	
	function cmeditor_${name}_unregister_doc(doc) {
		for (var i = 0; i < cmeditor_docs_${name}.length && doc != cmeditor_docs_${name}[i]; ++i) {}
		cmeditor_docs_${name}.splice(i, 1);
		var docList = document.getElementById("cmeditor-tabs-${name}-docs");
		docList.removeChild(docList.childNodes[i]);
		cmeditor_${name}_register_untitled_doc();
		cmeditor_${name}_select_doc(Math.max(0, i - 1));
		console.log("cmeditor_${name}_unregister_doc "+doc._cmeditorName+" was performed.");
	}
	
	function cmeditor_${name}_register_untitled_doc() {
		if (cmeditor_docs_${name}.length < 1) {
			cmeditor_unregDocName_${name} = cmeditor_${name}_get_name('Untitled Document');
			var data = {_cmeditorName:cmeditor_unregDocName_${name}, _cmeditorReadOnly:'${options.readOnly||options.defaultReadOnly?'nocursor':''}', _cmeditorOrigContent:'${options.defaultContent}', _cmeditorContent:'${options.defaultContent}', _cmeditorMode:'${options.defaultMode}', _cmeditorStatus:'new'};
			data._cmeditorDoc = new CodeMirror.Doc(data._cmeditorContent, "${options.defaultMode}")
			cmeditor_${name}_register_doc_data(data);
		}
		console.log("cmeditor_${name}_register_untitled_doc "+cmeditor_curDoc_${name}._cmeditorName+" was performed.");
	}
	
	function cmeditor_${name}_unregister_untitled_doc() {
		if (cmeditor_docs_${name}.length > 1) {
			var doc = cmeditor_${name}_find_doc(cmeditor_unregDocName_${name})
			if (doc && doc._cmeditorStatus == 'new') {
				cmeditor_${name}_unregister_doc(doc);
			}
		}
		console.log("cmeditor_${name}_unregister_untitled_doc was performed.");
	}
	
	function cmeditor_${name}_rename_doc(newName) {
		<g:if test="${options.readOnly}">
		$('#cmeditor-tabs-${name}-readOnly').dialog({ height: 300, buttons: {Cancel: function() { $( this ).dialog( "close" ); },},});
		</g:if><g:else>
		var docId = cmeditor_${name}_doc_id(cmeditor_curDoc_${name}._cmeditorName);
		var oldName = cmeditor_docs_${name}[docId]._cmeditorName;
		cmeditor_docs_${name}[docId]._cmeditorName = newName;
		cmeditor_${name}_set_changed_doc(docId);
		cmeditor_${name}_update_doc();
		console.log("cmeditor_${name}_rename_doc '"+oldName+"', '"+newName+"' was performed.")
		</g:else>
	}
	
	function cmeditor_${name}_set_changed_doc(pos, cmChangeObjects) {
		var docTab = $( "#cmeditor-tabs-${name}-docs li:nth-child("+(pos+1)+")" )
		console.log("changed " + cmeditor_docs_${name}[pos]._cmeditorName);
		docTab.text("*"+cmeditor_docs_${name}[pos]._cmeditorName);
		console.log("cmeditor_${name}_set_changed_doc '"+pos+"' was performed.")
	}

	function cmeditor_${name}_unset_changed_doc(pos) {
		var docTab = $( "#cmeditor-tabs-${name}-docs li:nth-child("+(pos+1)+")" )
		console.log("unchanged " + cmeditor_docs_${name}[pos]._cmeditorName);
		docTab.text(cmeditor_docs_${name}[pos]._cmeditorName);
		console.log("cmeditor_${name}_unset_changed_doc '"+pos+"' was performed.")
	}
	
	function cmeditor_${name}_set_selected_doc(pos) {
		var docTabs = document.getElementById("cmeditor-tabs-${name}-docs");
		for (var i = 0; i < docTabs.childNodes.length; ++i)
			docTabs.childNodes[i].className = pos == i ? "selected" : "";
		console.log("cmeditor_${name}_set_selected_doc "+pos+" was performed.")
	}
	
	function cmeditor_${name}_select_doc(pos) {
		cmeditor_${name}_set_selected_doc(pos);
		cmeditor_curDoc_${name} = cmeditor_docs_${name}[pos];
		cmeditor_${name}.swapDoc(cmeditor_curDoc_${name}._cmeditorDoc);
		cmeditor_${name}_update_doc();
		<g:if test="${options.menu}">cmeditor_menu_${name}_update();</g:if>
		console.log("cmeditor_${name}_select_doc "+cmeditor_curDoc_${name}._cmeditorName+" "+pos+" was performed.")
	}
	
	function cmeditor_${name}_update() {
		var docName = 'no curDoc';
		if (cmeditor_curDoc_${name}) {
			docName = cmeditor_curDoc_${name}._cmeditorName;
			var pos = cmeditor_${name}_doc_id(cmeditor_curDoc_${name}._cmeditorName);
			if (cmeditor_curDoc_${name}._cmeditorReadOnly != cmeditor_${name}.getOption('readOnly')) {
				cmeditor_curDoc_${name}._cmeditorReadOnly = cmeditor_${name}.getOption('readOnly');
			}
			if (cmeditor_curDoc_${name}._cmeditorMode != cmeditor_${name}.getOption('mode')) {
				cmeditor_curDoc_${name}._cmeditorMode = cmeditor_${name}.getOption('mode');
				var pos = cmeditor_${name}_doc_id(cmeditor_curDoc_${name}._cmeditorName);
				cmeditor_${name}_set_changed_doc(pos);
				if (cmeditor_curDoc_${name}._cmeditorStatus == 'new') {
					cmeditor_curDoc_${name}._cmeditorStatus = 'unsaved';
				} else if (cmeditor_curDoc_${name}._cmeditorStatus == 'unchanged') {
					cmeditor_curDoc_${name}._cmeditorStatus = 'changed';
				}
			}
			cmeditor_${name}_update_doc();
		}
		console.log("cmeditor_${name}_update "+docName+" was performed.")
	}
	
	function cmeditor_${name}_update_doc(cmChangeObjects) {
		var docName = 'no curDoc';
		var changed = false;
		if (cmeditor_curDoc_${name}) {
			var pos = cmeditor_${name}_doc_id(cmeditor_curDoc_${name}._cmeditorName);
			docName = cmeditor_curDoc_${name}._cmeditorName;
			if (cmeditor_curDoc_${name}._cmeditorMode != cmeditor_${name}.getOption("mode")) {
				cmeditor_${name}.setOption("mode", cmeditor_curDoc_${name}._cmeditorMode);
				changed = true;
				console.log("mode changed");
			}
			if (cmChangeObjects && !cmChangeObjects.propertyIsEnumerable('cmeditor_custom_field')) {// && cmeditor_curDoc_${name}._cmeditorContent != cmeditor_curDoc_${name}._cmeditorDoc.getValue()) {
			//console.log(cmeditor_curDoc_${name}._cmeditorContent);
			//console.log(cmeditor_curDoc_${name}._cmeditorDoc.getValue());
				cmeditor_curDoc_${name}._cmeditorContent = cmeditor_curDoc_${name}._cmeditorDoc.getValue();
				changed = true;
				console.log("content changed" + cmChangeObjects);
			}
			if (cmeditor_curDoc_${name}._cmeditorReadOnly != cmeditor_${name}.getOption('readOnly')) {
				if (cmeditor_curDoc_${name}._cmeditorReadOnly) {
					cmeditor_${name}.setOption('readOnly', cmeditor_curDoc_${name}._cmeditorReadOnly);
				} else {
					cmeditor_${name}.setOption('readOnly', false);
				}
			}
			if (cmChangeObjects && cmChangeObjects.propertyIsEnumerable('cmeditor_custom_field')) {
				changed = true;
				console.log("custom field changed")
			}
			if (changed || cmChangeObjects) {
				cmeditor_${name}_set_changed_doc(pos, cmChangeObjects);
				if (cmeditor_curDoc_${name}._cmeditorStatus == 'new') {
					cmeditor_curDoc_${name}._cmeditorStatus = 'unsaved';
				} else if (cmeditor_curDoc_${name}._cmeditorStatus == 'unchanged') {
					cmeditor_curDoc_${name}._cmeditorStatus = 'changed';
				}
			}
			cmeditor_${name}_set_form_doc();
		}
		console.log("cmeditor_${name}_update_doc "+docName+" was performed.")
		return changed;
	}
	
	function cmeditor_${name}_set_form_doc_field(elem, val) {
		if (elem.attr('type') == 'checkbox') {
			if (val) {
				elem.prop('checked', true);
				//elem.attr('value',true);
			} else {
				elem.prop('checked', false);
				//elem.removeAttr('value');
			}
		} else {
			elem.val(val);
		}
	}
	
	function cmeditor_${name}_set_form_doc() {
		if (typeof cmeditor_${name}_set_form_doc_before == 'function') cmeditor_${name}_set_form_doc_before();
		$("#cmeditor-tabs-${name}-form .cmeditor-field").each(function(){
			var key = $(this).attr('id');
			if ($(this).attr('data-field-property') && cmeditor_curDoc_${name}[key]) {
			console.log("BOOOOO " + key);
				cmeditor_${name}_set_form_doc_field($(this), cmeditor_curDoc_${name}[key][$(this).attr('data-field-property')]||'')
			} else {
				cmeditor_${name}_set_form_doc_field($(this), cmeditor_curDoc_${name}[key]||'');
			}
		});
		$("#cmeditor-tabs-${name}-form #${mapping.name}.cmeditor-field").val(cmeditor_curDoc_${name}._cmeditorName||'');
		$("#cmeditor-tabs-${name}-form #${mapping.mode}.cmeditor-field").val(cmeditor_curDoc_${name}._cmeditorMode||'');
		$("#cmeditor-tabs-${name}-form #${mapping.content}.cmeditor-field").val(cmeditor_curDoc_${name}._cmeditorContent||'');
		if (typeof cmeditor_${name}_set_form_doc_after == 'function') cmeditor_${name}_set_form_doc_after();
		console.log("cmeditor_${name}_set_form_doc "+cmeditor_curDoc_${name}._cmeditorName+" was performed.")
	}
	
	function cmeditor_${name}_set_diff_before_save(value) {
		cmeditor_diffBeforeSave_${name} = value;
		console.log("cmeditor_${name}_set_diff_before_save "+value+" was performed.")
	}
	
	function cmeditor_${name}_save(cm) {
		<g:if test="${options.readOnly}">
		$('#cmeditor-tabs-${name}-readOnly').dialog({ height: 300, buttons: {Cancel: function() { $( this ).dialog( "close" ); },},});
		</g:if><g:else>
		var pos = cmeditor_${name}_doc_id(cmeditor_curDoc_${name}._cmeditorName)
		cmeditor_${name}_update_doc();
		
		if (cmeditor_diffBeforeSave_${name}) {
		var addButtons = {
				Save: function() { $('#cmeditor-tabs-${name}-form').submit(); $( this ).dialog( "close" );},
			};
		cmeditor_${name}_diff(cmeditor_${name}, addButtons)
		} else {
			$('#cmeditor-tabs-${name}-form').submit();
		}
		
		//cmeditor_${name}_unset_changed_doc(pos);
		console.log("cmeditor_${name}_save "+cmeditor_curDoc_${name}._cmeditorName+" ("+pos+") was performed.");
		</g:else>
	}
	
	function cmeditor_${name}_saveas(cm) {
		<g:if test="${options.readOnly}">
		$('#cmeditor-tabs-${name}-readOnly').dialog({ height: 300, buttons: {Cancel: function() { $( this ).dialog( "close" ); },},});
		</g:if><g:else>
		var name = prompt("Name of the new buffer", "");
		if (name == null) return;
		if (!name) name = "test";
		cmeditor_${name}_rename_doc(cmeditor_${name}_get_name(name));
		cmeditor_curDoc_${name}["${options.idField}"] = '';
		cmeditor_${name}_save(cm);
		console.log("cmeditor_${name}_saveas "+cmeditor_curDoc_${name}._cmeditorName+" was performed.");
		</g:else>
	}
	
	function cmeditor_${name}_new(cm) {
		<g:if test="${options.readOnly}">
		$('#cmeditor-tabs-${name}-readOnly').dialog({ height: 300, buttons: {Cancel: function() { $( this ).dialog( "close" ); },},});
		</g:if><g:else>
		var name = prompt("Name of the new buffer", "");
		if (name == null) return;
		if (!name) name = "test";
		var data = {_cmeditorName: cmeditor_${name}_get_name(name), _cmeditorMode:"${options.defaultMode}", _cmeditorStatus:'new', _cmeditorContent: '${options.defaultContent}'};
		data._cmeditorDoc = new CodeMirror.Doc(data._cmeditorContent, data._cmeditorMode);
		cmeditor_${name}_register_doc_data(data);
		cmeditor_${name}_select_doc(cmeditor_docs_${name}.length - 1);
		</g:else>
	}
	
	function cmeditor_${name}_close(cm) {
		var status = cmeditor_curDoc_${name}._cmeditorStatus;
		if (status == 'changed' || status == 'unsaved') {
			$('#cmeditor-tabs-${name}-warning').dialog({
				height: 300,
				buttons: {
					Cancel: function() { $( this ).dialog( "close" ); },
					Close: function() { cmeditor_${name}_unregister_doc(cmeditor_curDoc_${name}); $( this ).dialog( "close" );},
				},
			});
		} else {
			cmeditor_${name}_unregister_doc(cmeditor_curDoc_${name});
		}
	}
	
	function cmeditor_${name}_diff(cm, addButtons) {
		var buttons = {
				Cancel: function() { $( this ).dialog( "close" ); },
				//Close: function() { cmeditor_${name}_unregister_doc(cmeditor_curDoc_${name}); $( this ).dialog( "close" );},
			};
		if (addButtons) {
			for (var name in addButtons) {
				buttons[name] = addButtons[name];
			}
		}
		cmeditor_${name}_diffUsingJS(2);
		$('#cmeditor-tabs-${name}-diff').dialog({
			resize:'auto',
			width: 'auto',
			height: 'auto',
			buttons: buttons,
		});
	}
	
	function cmeditor_${name}_get_mode() {
		return cmeditor_curDoc_${name}._cmeditorMode;
	}
	
	function cmeditor_${name}_init() {
		var keyMap = {
			"Ctrl-Space": "autocomplete",
			"Ctrl-S": function(cm) { cmeditor_${name}_save(cm); },
			"Ctrl-Q": function(cm){ cm.foldCode(cm.getCursor()); },
			"F11": function(cm) {
				if (!cm.getOption("readOnly")) {
		          cm.setOption("fullScreen", !cm.getOption("fullScreen"));
		        }
		    },
		    "Alt-Up": function(cm) { cmeditorbase_moveUp(cm); },
            "Alt-Down": function(cm) { cmeditorbase_moveDown(cm); },
		    "Ctrl-7": function(cm) { cmeditorbase_comment(cm); },
			//"Ctrl-I": function(cm) { server.showType(cm); },
			//"Ctrl-Space": function(cm) { server.complete(cm); },
			//"Alt-.": function(cm) { server.jumpToDef(cm); },
			//"Alt-,": function(cm) { server.jumpBack(cm); },
			//"Ctrl-Q": function(cm) { server.rename(cm); }
	  	};
		if (typeof ${options.overlayDefinitionsVar} !== 'undefined') {
	  		//console.log(Object.keys(${options.overlayDefinitionsVar}));
			for(var name in ${options.overlayDefinitionsVar}) {
				//console.log(name+" baseMode: "+ ${options.overlayDefinitionsVar}[name]['baseMode']);
				//console.log(name+" definition: "+ ${options.overlayDefinitionsVar}[name]['definition']);
				cmeditorall_add_overlay_definition(name, ${options.overlayDefinitionsVar}[name]['baseMode'], ${options.overlayDefinitionsVar}[name]['definition']);
			}
			CodeMirror.commands.autocomplete = function(cm, getHints, options) { CodeMirror.showHint(cm, null, {cmeditorDefinitions: ${options.overlayDefinitionsVar}}) };
		}
		cmeditor_${name} = CodeMirror(document.getElementById("cmeditor-tabs-${name}-form"), {
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
		if (localStorage['cmeditor-menu-diffBeforeSave'] === null) cmeditor_${name}_set_diff_before_save(localStorage['cmeditor-menu-diffBeforeSave']);
		else cmeditor_${name}_set_diff_before_save(${options.defaultDiffBeforeSave});
		</g:if><g:else>
		cmeditor_${name}.setOption("keymap", "${options.binding}");
		cmeditor_${name}.setOption("theme", "${options.theme}");
		cmeditor_${name}_set_diff_before_save(${options.defaultDiffBeforeSave});
		</g:else>
		if (cmeditor_${name}.getOption("keymap") == 'vim') {
			cmeditor_${name}.setOption("vimMode", true);
		} else {
			cmeditor_${name}.setOption("vimMode", false);
		}
	  
	  cmeditor_${name}.on("changes", function(cm, cmChangeObjects) {
	  	cmeditor_${name}_update_doc(cmChangeObjects);
	  });
	}
	CodeMirror.on(document.getElementById("cmeditor-tabs-${name}-docs"), "click", function(e) {
		var target = e.target || e.srcElement;
		if (target.nodeName.toLowerCase() != "li") return;
		for (var i = 0, c = target.parentNode.firstChild; ; ++i, (c = c.nextSibling)) {
			if (c == target) return cmeditor_${name}_select_doc(i);
		}
	});
	
	$(document).ready(function() {
		cmeditor_${name}_init();
		
		function cmeditor_${name}_get_custom_field(elem) {
			if (elem.attr('type') == 'checkbox') {
				return elem.is(":checked");
			} else {
				return elem.val();
			}
		}
		
		function cmeditor_${name}_custom_change(elem) {
			var key = elem.attr('id');
			
			if (cmeditor_curDoc_${name}) {
				var old = null;
				var doUpdate = true;
				if (key == '${mapping.name}') {
					cmeditor_${name}_rename_doc(cmeditor_${name}_get_custom_field(elem));
					doUpdate = false;
				} else if (key == '${mapping.mode}') {
					old = cmeditor_curDoc_${name}._cmeditorMode;
					cmeditor_curDoc_${name}._cmeditorMode = cmeditor_${name}_get_custom_field(elem);
					<g:if test="${options.menu}">cmeditor_menu_${name}_update();</g:if>
				} else if (key == '${mapping.content}') {
					old = cmeditor_curDoc_${name}._cmeditorContent;
					cmeditor_curDoc_${name}._cmeditorContent = cmeditor_${name}_get_custom_field(elem);
				} else {
					if (elem.attr('data-field-property') && cmeditor_curDoc_${name}[key] !== 'undefined') {
						if (cmeditor_curDoc_${name}[key]) {
							old = cmeditor_curDoc_${name}[key][elem.attr('data-field-property')];
						} else {
							cmeditor_curDoc_${name}[key] = {};
						}
						cmeditor_curDoc_${name}[key][elem.attr('data-field-property')] = cmeditor_${name}_get_custom_field(elem);
					} else {
						old = cmeditor_curDoc_${name}[key];
						cmeditor_curDoc_${name}[key] = cmeditor_${name}_get_custom_field(elem);
					}
				}
				if (doUpdate) {
					cmeditor_${name}_update_doc({cmeditor_custom_field: true, old:old, new:cmeditor_${name}_get_custom_field(elem)});
				}
			}
		}
		
		<g:if test="${options.menu}">cmeditor_menu_${name}_init();</g:if>
		cmeditor_${name}_register_untitled_doc();
		$("#cmeditor-tabs-${name}-form .cmeditor-field").keyup(function() {cmeditor_${name}_custom_change($(this));});
		$("#cmeditor-tabs-${name}-form select.cmeditor-field").change(function() {cmeditor_${name}_custom_change($(this));});
		$("#cmeditor-tabs-${name}-form input[type='checkbox'].cmeditor-field").change(function() {cmeditor_${name}_custom_change($(this));});
		console.log("cmeditor_${name} loaded.")
	});
</r:script>