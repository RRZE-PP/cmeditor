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