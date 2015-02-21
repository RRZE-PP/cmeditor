function cmeditorbase_is_int(value){
  if((parseFloat(value) == parseInt(value)) && !isNaN(value)){
      return true;
  } else {
      return false;
  }
}

function cmeditorbase_enableDialogButton(dialog_selector, button_name) {
	var button = cmeditorbase_getDialogButton( dialog_selector, button_name );
	if (button) {
		button.attr('disabled', 'disabled' ).addClass( 'ui-state-disabled' );
	}
}

function cmeditorbase_getDialogButton( dialog_selector, button_name )
{
  var buttons = $( dialog_selector + ' .ui-dialog-buttonpane button' );
  for ( var i = 0; i < buttons.length; ++i )
  {
     var jButton = $( buttons[i] );
     if ( jButton.text() == button_name )
     {
         return jButton;
     }
  }

  return null;
}

function cmeditorbase_lst(arr) { return arr[arr.length-1]; }

function cmeditorbase_comment(cm) {
  var minLine = Infinity, ranges = cm.listSelections(), mode = null;
  for (var i = ranges.length - 1; i >= 0; i--) {
    var from = ranges[i].from(), to = ranges[i].to();
    if (from.line >= minLine) continue;
    if (to.line >= minLine) to = Pos(minLine, 0);
    minLine = from.line;
    if (mode == null) {
      if (cm.uncomment(from, to, {lineComment: "//"})) mode = "un";
      else { cm.lineComment(from, to, {lineComment: "//"}); mode = "line"; }
    } else if (mode == "un") {
      cm.uncomment(from, to, {lineComment: "//"});
    } else {
      cm.lineComment(from, to, {lineComment: "//"});
    }
  }
}

function cmeditorbase_moveDown(cm) {
	cmeditorbase_moveDownSelection(cm, function(range) {
	return {from: CodeMirror.Pos(range.from().line, 0),
		to: CodeMirror.Pos(range.to().line + 1, 0)};
	});
}

function cmeditorbase_moveUp(cm) {
	cmeditorbase_moveUpSelection(cm, function(range) {
		return {from: CodeMirror.Pos(range.from().line - 1, 0),
			to: CodeMirror.Pos(range.to().line, 0)};
	});
}

function cmeditorbase_moveDownSelection(cm, compute) {
	var ranges = cm.doc.sel.ranges, move = [];
	// Build up a set of ranges to move first, merging overlapping
	// ranges.
	for (var i = 0; i < ranges.length; i++) {
		var toMove = compute(ranges[i]);
		while (move.length
				&& CodeMirror.cmpPos(toMove.from, cmeditorbase_lst(move).to) <= 0) {
			var replaced = move.pop();
			if (CodeMirror.cmpPos(replaced.from, toMove.from) < 0) {
				toMove.from = replaced.from;
				break;
			}
		}
		move.push(toMove);
	}
	var sels = cm.doc.listSelections();
	for (var i = 0; i < sels.length; i++) {
		sels[i].anchor = CodeMirror.Pos(sels[i].anchor.line + 1,
				sels[i].anchor.ch)
		sels[i].head = CodeMirror.Pos(sels[i].head.line + 1, sels[i].head.ch)
	}
	// Next, move those actual ranges.
	cm.operation(function() {
		for (var i = move.length - 1; i >= 0; i--) {
			var replacement = cm.getLine(move[i].to.line) + "\n";
			for (var j = move[i].from.line; j < move[i].to.line; j++)
				replacement = replacement + cm.getLine(j) + "\n";
			cm.doc.replaceRange(replacement, move[i].from, CodeMirror.Pos(
					move[i].to.line + 1, 0), "+move");
		}
	});
	cm.doc.setSelections(sels);
}

function cmeditorbase_moveUpSelection(cm, compute) {
	var doMove = true;
	var ranges = cm.doc.sel.ranges, move = [];
	// Build up a set of ranges to move first, merging overlapping
	// ranges.
	for (var i = 0; i < ranges.length; i++) {
		if (ranges[i].from().line == 0) {
			doMove = false;
			break;
		}
		var toMove = compute(ranges[i]);
		while (move.length
				&& CodeMirror.cmpPos(toMove.from, cmeditorbase_lst(move).to) <= 0) {
			var replaced = move.pop();
			if (CodeMirror.cmpPos(replaced.from, toMove.from) < 0) {
				toMove.from = replaced.from;
				break;
			}
		}

		move.push(toMove);
	}
	if (doMove) {
		var sels = cm.doc.listSelections();
		for (var i = 0; i < sels.length; i++) {
			sels[i].anchor = CodeMirror.Pos(sels[i].anchor.line - 1,
					sels[i].anchor.ch)
			sels[i].head = CodeMirror.Pos(sels[i].head.line - 1,
					sels[i].head.ch)
		}
		// Next, move those actual ranges.
		cm.operation(function() {
			for (var i = move.length - 1; i >= 0; i--) {
				var replacement = "";
				for (var j = move[i].from.line + 1; j < move[i].to.line + 1; j++)
					replacement = replacement + cm.getLine(j) + "\n";
				replacement = replacement
						+ cm.getLine(move[i].from.line) + "\n";
				cm.doc.replaceRange(replacement, move[i].from,
						CodeMirror.Pos(move[i].to.line + 1, 0),
						"+move");
			}
		});
		cm.doc.setSelections(sels);
	}
}

function cmeditorall_add_overlay_definition(name, baseMode, definition) {
	var words = definition.words;
	CodeMirror.defineMode(name, function(config, parserConfig) {
		var wordOverlay = {
				hint: 'cmeditor',
				startState: function() {return {inObject: false, inBlockComment: false, words:words};},
				token: function(stream, state) {
					if (state.inBlockComment) {
						var maybeEnd = false, ch;
					    while (ch = stream.next()) {
					      if (ch == "/" && maybeEnd) {
					    	state.inBlockComment = false;
					        break;
					      }
					      maybeEnd = (ch == "*");
					    }
					    return;
					}

					if (stream.match("/*")) {
				    	state.inBlockComment = true;
				    	state.inObject = false;
						state.words = words;
				        return;
				    }
				    if (stream.match("//")) {
				        stream.skipToEnd();
				        return;
				    }
					if (state.inObject) {
						if (stream.eat('.')) {
							if (stream.eol()) {
								state.inObject = false;
								state.words = words;
							}
							return;				// skip dot
						}
					}
					for (var word in state.words) {
						if (stream.match(word) && (stream.eol() || /\W/.test(stream.peek()))) {
							stream.eat(word);
							if (stream.peek() == '.') {
								if (typeof state.words[word] == 'object' && typeof state.words[word].words == 'object') {
									state.inObject = true;	// update state
									state.words = state.words[word].words;
								} else {
									return null;
								}
							}
							if (stream.eol()) {
								state.inObject = false;
								state.words = words;
							}
							return name;
						}
					}
					state.inObject = false;
					state.words = words;
					// skip to next word character
					while (!stream.match(/\W/, false) && stream.next() != null) {}
					stream.next();
					return null;
				}
		};
		return CodeMirror.overlayMode(CodeMirror.getMode(config, parserConfig.backdrop || baseMode), wordOverlay);
	});
}


(function(mod) {
  if (typeof exports == "object" && typeof module == "object") // CommonJS
    mod(require("../../lib/codemirror"));
  else if (typeof define == "function" && define.amd) // AMD
    define(["../../lib/codemirror"], mod);
  else // Plain browser env
    mod(CodeMirror);
})(function(CodeMirror) {
	"use strict";

  	var WORD = /[\w\.]+/, RANGE = 500;

	CodeMirror.registerGlobalHelper("hint", "cmeditor", function(mode, editor){return true}, function(editor, options) {
		// only provide completions for definitions
		if (!(options.cmeditorDefinitions && options.cmeditorDefinitions.propertyIsEnumerable(editor.getOption('mode')))) return;
		var definition = options.cmeditorDefinitions[editor.getOption('mode')].definition
		var word = options && options.word || WORD;
		var range = options && options.range || RANGE;
		var cur = editor.getCursor(), curLine = editor.getLine(cur.line);
		var start = cur.ch, end = start;
		while (end < curLine.length && word.test(curLine.charAt(end))) ++end;
		while (start && word.test(curLine.charAt(start - 1))) --start;
		var curWord = start != end && curLine.slice(start, end);

		var list = [];
		var words = definition.words;

		if (!curWord) {
			for(var word in words) {
		    	list.push({text:word, className:'cmeditor-completion '+(words[word].className||'')})
		    }
			return {list: list, from: CodeMirror.Pos(cur.line, start), to: CodeMirror.Pos(cur.line, end)};
		}

	    for(var word in words) {
	    	if (word.indexOf(curWord) == 0) list.push({text:word, displayText: words[word].displayText||'', className:'cmeditor-completion '+(words[word].className||'')});
	    }
	    if (curWord.indexOf('.') > -1) {
	    	var parts = curWord.split('.');
	    	var partOfWord = parts.shift()
	    	var parent = '';
	    	var notFound = false;
	    	while (partOfWord && parts.length>0) {
	    		if (words.propertyIsEnumerable(partOfWord) && words[partOfWord].propertyIsEnumerable('words')) {
		    		var words = words[partOfWord].words;
		    	} else {
		    		notFound = true;
		    	}
	    		parent = parent+partOfWord+'.'
	    		partOfWord = parts.shift()
	    	}
	    	if (!notFound) {
		    	for (var word in words) {
		    		if (word.indexOf(partOfWord) == 0) list.push({text:parent+word, displayText: words[word].displayText||'', className:'cmeditor-completion '+(words[word].className||'')});
		    	}
	    	}
	    }
	    return {list: list, from: CodeMirror.Pos(cur.line, start), to: CodeMirror.Pos(cur.line, end)};
	  });
});
