package de.rrze.cmeditor

class CmeditorTagLib {

	static namespace = "cmeditor"
	
	static encodeAsForTags = [tabs: 'raw', textArea: 'raw']
	
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
			overlayDefinitionsVar: 'overlay_definitions',
			]
		def ajax = [:]
		def mapping = [
			content: 'content',
			idField: 'id',
			mode: 'mode',
			name: 'name',
			]
		if (attrs.ajax) {
			ajax.putAll(attrs.ajax)
		}
		if (attrs.binding) {
			options.binding = attrs.binding
		}
		if (attrs.mapping) {
			mapping.putAll(attrs.mapping)
		}
		if (attrs.mode) {
			options.mode = attrs.mode
		}
		if (attrs.theme) {
			options.theme = attrs.theme
		}
		if (attrs.options) {
			options.putAll(attrs.options)
		}
		if (attrs.readOnly && attrs.readOnly.equals("true"))
			options.readOnly = true;
		out << render(template:"/shared/textArea", plugin:'cmeditor', model:[name: attrs.name, value: attrs.value, mode:attrs.mode, options:options, mapping:mapping, ajax:ajax, body: body])
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
			overlayDefinitionsVar: 'overlay_definitions',
			defaultDiffBeforeSave: true,
			]
		def ajax = [
            listURL:'ajaxList',
            getURL:'ajaxGet?label=',
			updateURL:'ajaxUpdate',
			deleteURL:'ajaxDelete',
			]
		def mapping = [
			content: 'content',
			idField: 'id',
			mode: 'mode',
			name: 'name',
			]
		if (attrs.ajax) {
			ajax.putAll(attrs.ajax)
		}
		if (attrs.binding) {
			options.binding = attrs.binding
		}
		if (attrs.mapping) {
			mapping.putAll(attrs.mapping)
		}
		if (attrs.mode) {
			options.mode = attrs.mode
		}
		if (attrs.theme) {
			options.theme = attrs.theme
		}
		if (attrs.options) {
			options.putAll(attrs.options)
		}
		out << render(template:"/shared/tabs", plugin:'cmeditor', model:[name: attrs.name, value: attrs.value, mode:attrs.mode, options:options, mapping:mapping, ajax:ajax, body: body])
	}
}
