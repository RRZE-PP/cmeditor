# CMEditor
CMEditor is a simple way to easily use the popular CodeMirror web editor in grails applications. You can use it to edit pretty much anything that can be mapped to a file-like object. I.e. something with a filename and text-content.
If your model requires additional fields this is supported, too.

For example managing your library could be done by mapping filename to "$author - $title". The tabbed editor then could manage everything: Author, title, publication year and - of course - the books content in a nice-to-use CodeMirror editor. You could even edit multiple books simultaneously.

##Cloning and checking out
After cloning this repo you'll have to run `grails upgrade` to regenerate some files in the web-app/WEB-INF folder.

##Usage
Add cmeditor as a plugin to your grails project's conf/BuildConfig.groovy:
```
    plugins {
        compile 'cmeditor:latest.release'
    }
```

Include the plugin's resources using either the resources or assets plugin:
```

	<r:require modules="cmeditor" />
	<!-- or -->
	<asset:javascript src="cmeditor.js"/>
	<asset:stylesheet href="cmeditor.css"/>

```

When adding a textarea or tabbed editor you have to supply a `name`-attribute. After document initialization you can access the corresponding javascript CMEditor-object by calling `CMEditor.getInstance("<nameAttributeValue>)"`. For an API of the class see the CMEditor.js file in grails-app/js/web-app/js/.
### Textareas
You can substitute a `<g:textArea name=""/>` with `<cmeditor:textArea name=""/>`.

Available options here are:
  * _ajax_: ajax locations (not yet supported)
  * _binding_: the initial key-binding of the editor (e.g. vim)
  * _mapping_: a collection defining the mapping for your document model (respectively the generated json):
    * _content_: the file content's variable name
    * _idField_: String, the variable name of the mapped document to use as id; _default_: id
    * _mode_: the content's mode's variable name
    * _name_: the filename's variable name
  * _mode_:    the default mode for the editor to use (e.g. htmlmixed)
  * _readOnly_: Boolean, whether to make the textArea readOnly; _default_: false
  * _options_: a collection defining additional options:
    * _binding_: String, overrides the _binding_-attribute
    * _menu_: Boolean, whether to display a menu bar or not; _default_: true
    * _menuFile_: Boolean, whether to display a file menu or not; _default_: false
    * _menuView_: Boolean, whether to display a view menu or not; _default_: true
    * _mode_: String, overrides the _mode_-attribute (not yet supported)
    * _overlayDefinitionsVar_: String, a js-variable name in which you can define additional CodeMirror overlays
    * _readOnly_: Boolean, overrides the _readOnly_-attribute
    * _theme_: String, overrides the _theme_-attribute
    * _useSession_: Boolean, whether to save editor state in the user's browser; _default_: true (not yet supported) _default_: true
  * _theme_:   the initial theme to use
  * _value_: The initial value to put in the text area

So for example use: `<g:textArea name="foobar" binding="vim" options="[readOnly: true"] />`

### Tabbed Editor
The tabbed editor is useful to edit more than one file at once. They are loaded and stored seamlessly using ajax to a controller of your choice.

Available options are:
  * _ajax_: paths for the editor to communicate with your controller; all information has to be json encoded
    * listURL: GET, list of available filenames; _default_: 'ajaxList',
    * getURL: GET, object representing the mapped document: _default_: 'ajaxGet?label=',
    * updateURL: POST, location to call to save a document; it's passed the document's id; _default_: 'ajaxUpdate',
    * deleteURL: POST, location to call to delete a document; it's passed the document's id; _default_: 'ajaxDelete',
  * _binding_: the initial key-binding of the editor (e.g. vim)
  * _mapping_: a collection defining the mapping for your document model (respectively the generated json):
    * _content_: the file content's variable name
    * _idField_: String, the variable name of the mapped document to use as id; _default_: id
    * _mode_: the content's mode's variable name
    * _name_: the filename's variable name
  * _mode_:    the default mode for the editor to use (e.g. htmlmixed) (not yet supported)
  * _options_: a collection defining additional options:
    * _binding_: String, overrides the _binding_-attribute
    * _defaultContent_: String, the default content of a new file; _default_: '' (empty string)
    * _defaultDiffBeforeSave_: Boolean, whether to display a diff before saving; _default_: true
    * _defaultMode_: the default mode for the editor to use (e.g. htmlmixed)
    * _defaultReadOnly_: Boolean, whether to open files read only; _default_: false
    * _menu_: Boolean, whether to display a menu bar or not; _default_: true
    * _menuFile_: Boolean, whether to display a file menu or not; _default_: false
    * _menuView_: Boolean, whether to display a view menu or not; _default_: true
    * _mode_: String, overrides the _mode_-attribute (not yet supported)
    * _overlayDefinitionsVar_: String, a js-variable name in which you can define additional CodeMirror overlays
    * _readOnly_: Boolean, whether to make the whole editor readOnly; _default_: false
    * _theme_: String, overrides the _theme_-attribute
    * _useSession_: Boolean, whether to save editor state in the user's browser; _default_: true (not yet supported) _default_: true
  * _theme_:   the initial theme to use

If you need additional input fields, you can provide them in the body of the tag. All elements with the class `cmeditor-field` there will be serialized using their name as key and sent along with the document's content.

So for example:
```gsp
    <cmeditor:tabs name="book" options="[defaultContent:'Lorem ipsum sit dolor']" ajax="[getURL:createLink(action: 'ajaxGet')+'?name=']">
      <label for="author"> <g:message code="myLibrary.author.label" default="Author" /></label>
      <g:textField name="author" class="cmeditor-field" /> <br />

      <label for="mode"><g:message code="myLibrary.title.label" default="Title" /></label>
      <g:textField name="mode" class="cmeditor-field" />
  </cmeditor:tabs>
```
