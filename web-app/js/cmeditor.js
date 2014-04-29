function cmeditorall_keyword_overlay(name, baseMode, keywords) {
	CodeMirror.defineMode(name, function(config, parserConfig) {
		var keywordOverlay = {
				token: function(stream, state) {
					var ch;
					for (keyword of keywords) {
						if (stream.match(keyword) && (stream.eol() || /\W/.test(stream.peek()))) {
							stream.eat(keyword);
							return name;
						}
					}
					while (!stream.match(/\W/, false) && stream.next() != null) {}
					stream.next();
					return null;
				}
		};
		return CodeMirror.overlayMode(CodeMirror.getMode(config, parserConfig.backdrop || baseMode), keywordOverlay);
	});
}