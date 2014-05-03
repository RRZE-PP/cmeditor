package de.rrze.cmeditor

class CMEditorTagLib {

	static namespace = "cmeditor"
	
	def textArea = { attrs, body ->
		def options = [
			menu: true,
			menuFile: false,
			menuView: true,
			useSession: true,
			readOnly: false,
			mode: 'htmlmixed',
			binding: 'default',
			theme: 'default',
			defaultReadOnly: false,
			]
		if (attrs.mode) {
			options.mode = attrs.mode
		}
		if (attrs.binding) {
			options.binding = attrs.binding
		}
		if (attrs.theme) {
			options.theme = attrs.theme
		}
		if (attrs.options) {
			options.putAll(attrs.options)
		}
		def mapping = [
			name:'name',
			content:'content',
			mode:'mode',
			]
		if (attrs.mapping) {
			mapping.putAll(attrs.mapping)
		}
		def ajax = [:]
		if (attrs.ajax) {
			ajax.putAll(attrs.ajax)
		}
		out << render(template:"/shared/textArea", plugin:'cm-editor', model:[name: attrs.name, value: attrs.value, mode:attrs.mode, options:options, mapping:mapping, ajax:ajax, body: body])
	}
	
	def tabs = { attrs, body ->
		def options = [
			menu: true,
			menuFile: true,
			menuView: true,
			useSession: true,
			readOnly: false,
			mode: 'htmlmixed',
			binding: 'default',
			theme: 'default',
			defaultContent: '',
			defaultMode: 'htmlmixed',
			defaultReadOnly: false,
			defaultDiffBeforeSave: true,
			idField: 'id',
			]
		def mapping = [:]
		def ajax = [
            listURL:'',
            getURL:'',
			updateURL:'',
			deleteURL:'',
			]
		if (attrs.mode) {
			options.mode = attrs.mode
		}
		if (attrs.binding) {
			options.binding = attrs.binding
		}
		if (attrs.theme) {
			options.theme = attrs.theme
		}
		if (attrs.options) {
			options.putAll(attrs.options)
		}
		if (attrs.mapping) {
			mapping.putAll(attrs.mapping)
		}
		if (attrs.ajax) {
			ajax.putAll(attrs.ajax)
		}
		out << render(template:"/shared/tabs", plugin:'cm-editor', model:[name: attrs.name, value: attrs.value, mode:attrs.mode, options:options, mapping:mapping, ajax:ajax, body: body])
	}
}
