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