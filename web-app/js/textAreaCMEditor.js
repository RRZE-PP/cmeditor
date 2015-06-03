//= require jquery
//= require jquery-ui
//=require cmeditor-dependencies

this.textAreaCMEditor = function (){

    function textAreaCMEditor(rootElem, options, instanceName){
        //allow the user to omit new
        if (!(this instanceof textAreaCMEditor)) return new textAreaCMEditor(rootElem, options);
        var self = this;
        self.instanceNo = textAreaCMEditor.instanciated++;
        self.instanceName = instanceName !== undefined ? instanceName : "";

        var rootElem = self.rootElem = $(rootElem);
        self.options  = options  = options !== undefined ? options : {};

        self.eventHooks = {};
        for(hookName in options.hooks){
            on(self, hookName, options["hooks"][hookName]);
        }

        init(self, rootElem, options);

        if(options.menu){
            var menuRootElem = self.rootElem.find(".cmeditor-menu");
            executeHooks(self, "preMenuInit", menuRootElem);
            self.menu = new CMEditorMenu(self, menuRootElem, options, instanceName);
            executeHooks(self, "postMenuInit", menuRootElem, [self.menu]);
        }

        //disable some browser featues when the codeMirror has focus
        $(document).bind("keydown", function(e){
            if(e.ctrlKey && self.rootElem.find("CodeMirror-focused").size() !== 0){
                e.preventDefault();
            }
        });

        //replace code mirror's fullscreen mode addon
        CodeMirror.defineOption("fullScreen", false, function() {
            var focusElems = jQuery.grep(self.rootElem.find("*"),function(elem){return $(elem).is(":focus")});
            if(focusElems.length != 0){
                if(self.oldSizeMem == undefined){
                    self.oldSizeMem = {"position": self.rootElem.css("position"),
                                        "top":  self.rootElem.css("top"),
                                        "left":  self.rootElem.css("left"),
                                        "height":  self.rootElem.css("height"),
                                        "width":  self.rootElem.css("width"),
                                        "overflow": self.rootElem.css("overflow"),
                                        "box-sizing": self.rootElem.css("box-sizing")};
                    self.oldDocumentOverflow = document.documentElement.style.overflow;
                    document.documentElement.style.overflow = "hidden";
                    self.rootElem.css({"position": "fixed", "top": "0", "left": "0", "height": "100%", "width": "100%", "overflow-y": "scroll", "box-sizing": "border-box"});
                }else{
                    self.rootElem.css(self.oldSizeMem);
                    document.documentElement.style.overflow = self.oldDocumentOverflow;
                    self.oldSizeMem = undefined;
                }
            }
        });

        registerInstance(self.instanceName, self.instanceNo, self);
    }

    /*************************************************************************
     *                    Begin 'static' methods                             *
     *************************************************************************/
    var clazz = textAreaCMEditor;

    clazz.instanciated = 0;
    clazz.instancesNumber = {};
    clazz.instancesString = {};
    clazz.instances = [];

    /*
     * Logs to the console. If only one argument is provided prints the second argument prefixed by class name.
     * If two arguments are provided the first must be an instance of this class. Then prints the second argument
     * prefixed by class name and instance number
     */
    var log = clazz.log = function(arg0, arg1){
        if(arguments.length == 2)
            console.log(clazz.name + " #" + arg0.instanceNo + " '" + arg0.instanceName + "': " + arg1);
        else
            console.log(clazz.name + ": " + arg0);
    }

    /*
     * Registers an instance so that it can be accessed with `getInstance`
     */
    var registerInstance = clazz.registerInstance = function(instanceName, instanceNo, instance){
        clazz.instancesString[instanceName] = instance;
        clazz.instancesNumber[instanceNo]   = instance;
        clazz.instances.push(instance);
        log("registered new textAreaCMEditor instance #" + instanceNo + " '" + instanceName + "'");
    }

    /*
     * Returns an instance of this class
     *
     * Parameters: identifier (String|Number): the instance name or number
     */
     var getInstance = clazz.getInstance = function(identifier){
        if(typeof identifier == "number")
            return clazz.instancesNumber[identifier];
        else
            return clazz.instancesString[identifier];
    }

    /*
     * Returns all instances of this class
     */
     var getInstances = clazz.getInstances = function(){
        return clazz.instances;
    }

    /*************************************************************************
     *                    Begin 'private' methods                            *
     *************************************************************************/

    /*
     * Executes all hooks that were registered using `on` on `eventName`
     *
     * Parameters: eventName String: the event of which all hooks should be called
     *             context Object: the object that `this` should be set to in the hook
     *             args Array: the parameters to pass to the hook as an array
     */
    function executeHooks(self, eventName, context, args){
        for(var i=0; self.eventHooks[eventName] && i<self.eventHooks[eventName].length; i++){
            if(typeof self.eventHooks[eventName][i] == "function")
                self.eventHooks[eventName][i].apply(context, args);
        }
    }

    function init(self, rootElem, options) {
        var keyMap = {
            "Ctrl-Space": "autocomplete",
            "Ctrl-Q": function(cm){ cm.foldCode(cm.getCursor()); },
            "F11": function(cm) {
                if (!cm.getOption("readOnly")) {
                    cm.setOption("fullScreen", !cm.getOption("fullScreen"));
                }
            },
            "Alt-Up": function(cm) { cmeditorbase_moveUp(cm); },
            "Alt-Down": function(cm) { cmeditorbase_moveDown(cm); },
            "Ctrl-7": function(cm) { cmeditorbase_comment(cm); },
        };

        if (typeof self.options.overlayDefinitionsVar !== 'undefined') {
            for(var name in self.options.overlayDefinitionsVar) {
                cmeditorall_add_overlay_definition(name, self.options.overlayDefinitionsVar[name]['baseMode'], self.options.overlayDefinitionsVar[name]['definition']);
            }
            CodeMirror.commands.autocomplete = function(cm, getHints, options) { CodeMirror.showHint(cm, null, {cmeditorDefinitions: self.options.overlayDefinitionsVar}) };
        }

        var codeMirrorOptions = {
            lineNumbers: true,
            smartIndent: false,
            lineWrapping: true,
            matchBrackets: true,
            autoCloseBrackets: true,
            autoCloseTags: true,
            //cursorHeight: 1.0,
            viewportMargin: Infinity,
            foldGutter: true,
            gutters: ["CodeMirror-linenumbers", "CodeMirror-foldgutter"],
            extraKeys: keyMap,
        }

        if(options.mode)
            codeMirrorOptions.mode = options.mode;
        if(options.defaultReadOnly || options.readOnly)
            codeMirrorOptions.readOnly = 'nocursor';

        var codeMirror = self.codeMirror = CodeMirror.fromTextArea(rootElem.find("textarea")[0], codeMirrorOptions);

        if(self.options.useSession){
            if (localStorage['cmeditor-menu-binding'])
                codeMirror.setOption("keymap", localStorage['cmeditor-menu-binding']);
            else
                codeMirror.setOption("keymap", "default");

            if (localStorage['cmeditor-menu-theme'])
                codeMirror.setOption("theme", localStorage['cmeditor-menu-theme']);
            else
                codeMirror.setOption("theme", "default");
        }else{
            codeMirror.setOption("keymap", self.options.binding);
            codeMirror.setOption("theme", self.options.theme);
        }

        if (codeMirror.getOption("keymap") == 'vim') {
            codeMirror.setOption("vimMode", true);
        } else {
            codeMirror.setOption("vimMode", false);
        }
    }

    /*************************************************************************
     *                    Begin 'public' methods                             *
     *************************************************************************/

    /* (Public)
     *
     * Sets focus to the text editor
     */
    function focus(self){
        self.codeMirror.focus();
    }

    /* (Public)
     *
     * Returns the underlying codeMirror instance
     */
    function getCodeMirror(self){
        return self.codeMirror;
    }

    /* (Public)
     *
     * Can be used to register callbacks for events.
     *
     * Available Events in CMEditor:
     *
     *     preMenuInit: Fired before the menu of this CMEditor is initiated, i.e. before its constructor is called
     *                  This happens in the constructor of the CMEditor, so usually you have to set hooks to this event via
     *                  the options object
     *                  Your callback will be called in the context of the menu's root element
     *     postMenuInit: Fired after the menu of this CMEditor is initiated, i.e. after its constructor has been called
     *                  This happens in the constructor of the CMEditor, so usually you have to set hooks to this event via
     *                  the options object
     *                  Your callback will be called in the context of the menu's root element and passed the menu object as first
     *                  argument
     *
     */
    function on(self, eventName, hook){
        if(self.eventHooks[eventName] === undefined)
            self.eventHooks[eventName] = [];

        self.eventHooks[eventName].push(hook);

        log(self, "added a hook to event"+eventName);
    }

    /* (Public)
     *
     * Logs its call to the console
     */
    function update(self) {
        log(self, "update was performed.")
    }

    textAreaCMEditor.prototype.constructor = CMEditor;

    //Zugegriffen aus Menu
    textAreaCMEditor.prototype.focus         = function(){Array.prototype.unshift.call(arguments, this); return focus.apply(this, arguments)};
    textAreaCMEditor.prototype.update        = function(){Array.prototype.unshift.call(arguments, this); return update.apply(this, arguments)};
    textAreaCMEditor.prototype.getCodeMirror = function(){Array.prototype.unshift.call(arguments, this); return getCodeMirror.apply(this, arguments)};

    return textAreaCMEditor;

}();
