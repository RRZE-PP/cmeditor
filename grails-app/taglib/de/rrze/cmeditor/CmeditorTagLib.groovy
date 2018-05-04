package de.rrze.cmeditor

import org.apache.commons.lang.RandomStringUtils

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
			mode: 'application/x-ejs',
			binding: 'default',
			theme: 'default',
			defaultReadOnly: false,
			overlayDefinitionsVar: 'overlay_definitions',
			preloadModules: false
		]
		def ajax = [:]
		def mapping = [
			content: 'content',
			folder: 'folder',
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
		if (attrs.readOnly)
			options.readOnly = true;

		if (attrs.options) {
			options.putAll(attrs.options)
		}

		def availableThemes = [
			"default",
			"eclipse",
			"idea",
			"lesser-dark",
			"monokai",
			"night",
			"the-matrix",
			"twilight"
		]
		def availableModes = [
			"HTML",
			"Embedded Javascript",
			"CSS",
			"XML",
			"Javascript",
			"Groovy",
			"Java",
			"Properties"
		]
		if(attrs.availableThemes)
			availableThemes = attrs.availableThemes
		if(attrs.availableModes)
			availableModes = attrs.availableModes

		out << render(template:"/shared/textArea", plugin:'cmeditor',
						model:
							[name: attrs.name ? attrs.name : RandomStringUtils.randomAlphanumeric(125),
							 value: attrs.value,
							 mode: attrs.mode,
							 options: options,
							 mapping: mapping,
							 ajax: ajax,
							 body: body,
							 availableModes: availableModes,
							 availableThemes: availableThemes])
	}

	def tabs = { attrs, body ->
		def options = [
			menu: true,
			menuFile: true,
			menuView: true,
			useSession: true,
			readOnly: false,
			binding: 'default',
			theme: 'default',
			defaultContent: '',
			defaultMode: 'application/x-ejs',
			defaultReadOnly: false,
			overlayDefinitionsVar: 'overlay_definitions',
			defaultDiffBeforeSave: true,
			preloadModules: false
		]
		def ajax = [
			listURL:'ajaxList',
			getURL:'ajaxGet',
			updateURL:'ajaxUpdate',
			deleteURL:'ajaxDelete',
		]
		def mapping = [
			content: 'content',
			folder: 'folder',
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
		if (attrs.theme) {
			options.theme = attrs.theme
		}
		if (attrs.readOnly)
			options.readOnly = true;


		if (attrs.options) {
			options.putAll(attrs.options)
		}

		def availableThemes = [
			"default",
			"eclipse",
			"idea",
			"lesser-dark",
			"monokai",
			"night",
			"the-matrix",
			"twilight"
		]
		def availableModes = [
			"HTML",
			"Embedded Javascript",
			"CSS",
			"XML",
			"Javascript",
			"Groovy",
			"Java",
			"Properties"
		]
		if(attrs.availableThemes)
			availableThemes = attrs.availableThemes
		if(attrs.availableModes)
			availableModes = attrs.availableModes

		def bodyContent = raw(body())
		out << render(template:"/shared/tabs", plugin:'cmeditor',
						model:
							[name: attrs.name ? attrs.name : RandomStringUtils.randomAlphanumeric(125),
							 value: attrs.value,
							 mode: attrs.mode,
							 options: options,
							 mapping: mapping,
							 ajax: ajax,
							 bodyContent: bodyContent,
							 availableModes: availableModes,
							 availableThemes: availableThemes])
	}
	
	def menuItem = { attrs, body ->
		def value = attrs.value
		def codePrefix = attrs.codePrefix ?: 'cmeditor.menu.menus.'
		def msg = attrs.code ? g.message(code:(codePrefix + attrs.code)) : (attrs.msg ?: 'TITLE?!')
		
		def classes = ["dropdown-item"]
		if (attrs.disabled) {
			classes << "disabled"
		}
		
		if (attrs.active) {
			classes << "active"
		}
		
		def dataAttrs = ""
		dataAttrs += " data-group='${attrs.group ?: 'default'}'"
		
		out << "<a class='${classes.join(' ')}' href='#' value='${value}' $dataAttrs>"
		
		def icon = attrs.icon
		if (icon) {
			def iconFamily = attrs.iconFamily ?: 'fas'
			out << "<i class='$iconFamily fa-fw $icon'></i>&nbsp;"
		} else {
			out << "<i class='fa-fw'></i>&nbsp;"
		}
		
		out << "${msg}</a>"
	}
	
	def menuDivider = { attrs, body ->
		out << '<div class="dropdown-divider"></div>'
	}
	
}
