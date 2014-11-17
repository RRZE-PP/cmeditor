modules = {
	
	'cmeditor-min' {
		defaultBundle false
		
		dependsOn 'jquery'
		
		resource url: 'codemirror-4.0/lib/codemirror.css', disposition:'head'
		resource url: 'codemirror-4.0/lib/codemirror.js', disposition:'head'
	}
	
	'cmeditor-main' {
		defaultBundle false
		
		dependsOn 'cmeditor-min'
		
		// modes
		resource url: 'codemirror-4.0/mode/htmlmixed/htmlmixed.js', disposition:'head'
		resource url: 'codemirror-4.0/mode/htmlembedded/htmlembedded.js', disposition:'head'
		resource url: 'codemirror-4.0/mode/css/css.js', disposition:'head'
		resource url: 'codemirror-4.0/mode/xml/xml.js', disposition:'head'
		resource url: 'codemirror-4.0/mode/javascript/javascript.js', disposition:'head'
		resource url: 'codemirror-4.0/mode/groovy/groovy.js', disposition:'head'
		resource url: 'codemirror-4.0/mode/clike/clike.js', disposition:'head'
		resource url: 'codemirror-4.0/mode/properties/properties.js', disposition:'head'
		
		// themes
		resource url: 'codemirror-4.0/theme/eclipse.css', disposition:'head'
		resource url: 'codemirror-4.0/theme/lesser-dark.css', disposition:'head'
		resource url: 'codemirror-4.0/theme/monokai.css', disposition:'head'
		resource url: 'codemirror-4.0/theme/night.css', disposition:'head'
		resource url: 'codemirror-4.0/theme/the-matrix.css', disposition:'head'
		resource url: 'codemirror-4.0/theme/twilight.css', disposition:'head'
//		resource url: 'css/codemirror-4.0/theme/.css', disposition:'head'
		
		// keymaps
		resource url: 'codemirror-4.0/keymap/vim.js', disposition:'head'
		resource url: 'codemirror-4.0/keymap/sublime.js', disposition:'head'
		resource url: 'codemirror-4.0/keymap/emacs.js', disposition:'head'
		
		// addon
		resource url: 'codemirror-4.0/addon/dialog/dialog.js', disposition:'head'
		resource url: 'codemirror-4.0/addon/dialog/dialog.css', disposition:'head'
		resource url: 'codemirror-4.0/addon/edit/matchbrackets.js', disposition:'head'
		resource url: 'codemirror-4.0/addon/edit/closebrackets.js', disposition:'head'
		resource url: 'codemirror-4.0/addon/edit/closetag.js', disposition:'head'
		resource url: 'codemirror-4.0/addon/search/search.js', disposition:'head'
		resource url: 'codemirror-4.0/addon/search/searchcursor.js', disposition:'head'
		resource url: 'codemirror-4.0/addon/mode/overlay.js', disposition:'head'
		// hint
		resource url: 'codemirror-4.0/addon/hint/show-hint.css', disposition:'head'
		resource url: 'codemirror-4.0/addon/hint/show-hint.js', disposition:'head'
		resource url: 'codemirror-4.0/addon/hint/anyword-hint.js', disposition:'head'
		resource url: 'codemirror-4.0/addon/hint/css-hint.js', disposition:'head'
		resource url: 'codemirror-4.0/addon/hint/html-hint.js', disposition:'head'
		resource url: 'codemirror-4.0/addon/hint/javascript-hint.js', disposition:'head'
		resource url: 'codemirror-4.0/addon/hint/sql-hint.js', disposition:'head'
		resource url: 'codemirror-4.0/addon/hint/xml-hint.js', disposition:'head'
		//resource url: 'codemirror-4.0/addon/hint/python-hint.js', disposition:'head'
		
		resource url: 'codemirror-4.0/addon/comment/comment.js', disposition:'head'
		resource url: 'codemirror-4.0/addon/comment/continuecomment.js', disposition:'head'
		
		resource url: 'codemirror-4.0/addon/fold/foldcode.js', disposition:'head'
		resource url: 'codemirror-4.0/addon/fold/foldgutter.css', disposition:'head'
		resource url: 'codemirror-4.0/addon/fold/foldgutter.js', disposition:'head'
		resource url: 'codemirror-4.0/addon/fold/brace-fold.js', disposition:'head'
		resource url: 'codemirror-4.0/addon/fold/comment-fold.js', disposition:'head'
		resource url: 'codemirror-4.0/addon/fold/indent-fold.js', disposition:'head'
		resource url: 'codemirror-4.0/addon/fold/markdown-fold.js', disposition:'head'
		resource url: 'codemirror-4.0/addon/fold/xml-fold.js', disposition:'head'
		
		resource url: 'codemirror-4.0/addon/selection/active-line.js', disposition:'head'
		
		resource url: 'codemirror-4.0/addon/display/fullscreen.css', disposition:'head'
		resource url: 'codemirror-4.0/addon/display/fullscreen.js', disposition:'head'
		
		resource url:'/css/cmeditor-base.css', disposition:'head'
		resource url:'/js/cmeditor-base.js', disposition:'head'
		resource url:'/js/cmeditor-overlay.js', disposition:'head'
		resource url:'/js/cmeditor-hint.js', disposition:'head'
	}
	
	'cmeditor-menu' {
		dependsOn 'cmeditor-main, jquery-ui'
		
		resource url:'/css/jquery/jquery.ui.menubar.css', disposition:'head'
		resource url:'/js/jquery/jquery.ui.menubar.js', disposition:'head'
		resource url:'/css/jquery/chosen.css', disposition:'head'
		resource url:'/js/jquery/chosen.jquery.js', disposition:'head'
	}
	
	'cmeditor-tabs' {
		dependsOn 'cmeditor-main, jquery-ui, jsdifflib'
		
		resource url:'/js/cmeditor-tabs.js', disposition:'head'
	}
	
	'cmeditor' {
		dependsOn 'cmeditor-main, cmeditor-menu, cmeditor-tabs'
	}
	
	'jsdifflib' {
		resource url:'/jsdifflib/difflib.js', disposition:'head'
		resource url:'/jsdifflib/diffview.css', disposition:'head'
		resource url:'/jsdifflib/diffview.js', disposition:'head'
	}
}