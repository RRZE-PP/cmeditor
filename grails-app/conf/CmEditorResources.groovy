modules = {
	
	'cmeditor-min' {
		defaultBundle false
		
		dependsOn 'jquery'
		
		resource url: 'codemirror-4.0/lib/codemirror.css', disposition:'head'
		resource url: 'codemirror-4.0/lib/codemirror.js', disposition:'head'
	}
	
	'cmeditor' {
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
		
		resource url:'/css/cmeditor.css', disposition:'head'
		resource url:'/js/cmeditor.js', disposition:'head'
		
		resource url: 'codemirror-4.0/addon/display/fullscreen.css', disposition:'head'
		resource url: 'codemirror-4.0/addon/display/fullscreen.js', disposition:'head'
		
	}
	
	'cmeditor-menu' {
		dependsOn 'cmeditor, jquery-ui'
		
		resource url:'/css/jquery/jquery.ui.menubar.css', disposition:'head'
		resource url:'/js/jquery/jquery.ui.menubar.js', disposition:'head'
		resource url:'/css/jquery/chosen.css', disposition:'head'
		resource url:'/js/jquery/chosen.jquery.js', disposition:'head'
	}
	
	'cmeditor-tabs' {
		dependsOn 'cmeditor, jquery-ui, jsdifflib'
		
		resource url:'/js/cmeditor-tabs.js', disposition:'head'
	}
	
	'cmeditorbbx' {
		defaultBundle false
		
		dependsOn 'cmeditor'
		
		// custom
		resource url:'/css/cmeditor.css', disposition:'head'
		resource url:'/js/cmeditor.js', disposition:'head'
	}
	
	'jsdifflib' {
		resource url:'/jsdifflib/difflib.js', disposition:'head'
		resource url:'/jsdifflib/diffview.css', disposition:'head'
		resource url:'/jsdifflib/diffview.js', disposition:'head'
	}
}