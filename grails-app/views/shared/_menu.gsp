<div id="cmEditorMenu_${name}" class="cmeditor-menu">
	<div class="dialog donationDialog" title="Donation" style="display: none;">
		<p>You want the incredible addon?</p>
		<p>Donate via Coffee?</p>
	</div>
	<div class="dialog openMenu" title="Open" style="display: none;">
	</div>
	<ul class="cmeditor-menubar menu">
		<li><a href="#">File</a>
			<ul class="fileMenu">
				<g:if test="${options.menuFile}">
				<li><a href="#" value="new"><span class="ui-icon ui-icon-newwin"></span>New</a></li>
				<li><a href="#" value="open"><span class="ui-icon ui-icon-newwin"></span>Open</a></li>
				<li><a href="#" value="save"><span class="ui-icon ui-icon-disk"></span>Save</a></li>
				<li><a href="#" value="saveas"><span class="ui-icon ui-icon-disk"></span>Save As</a></li>
				<li><a href="#" value="rename"><span></span>Rename</a></li>
				<li><a href="#" value="delete"><span class="ui-icon ui-icon-trash"></span>Delete</a></li>
				<li><a href="#" value="close"><span class="ui-icon ui-icon-close"></span>Close</a></li>
				</g:if>
				<li><a href="#" value="quit"><span></span>Quit</a></li>
			</ul>
		</li>
		<g:if test="${options.menuView}">
		<li><a href="#">View</a>
			<ul class="viewMenu">
				<li><a href="#" value="readOnly"><span></span>readOnly</a></li>
				<li><a href="#" value="diff"><span></span>diff</a></li>
				<li><a href="#" value="goto"><span></span>goto</a></li>
				<li><a href="#" value="addonfullscreen"><span></span>full-screen (f11)</a></li>
				<li><a href="#"><span></span>Mode</a>
					<ul class="modesMenu">
						<li><a href="#" value="modehtmlmixed"><span class="ui-icon ui-icon-blank"></span>htmlmixed</a></li>
						<li><a href="#" value="modehtmlembedded"><span></span>htmlembedded</a></li>
						<li><a href="#" value="modejavascript"><span></span>javascript</a></li>
						<li><a href="#" value="modexml"><span></span>xml</a></li>
						<li><a href="#" value="modecss"><span></span>css</a></li>
						<li><a href="#" value="modegroovy"><span></span>groovy</a></li>
						<li><a href="#" value="modejava"><span></span>java</a></li>
						<li><a href="#" value="modeproperties"><span></span>properties</a></li>
					</ul></li>
			</ul>
		</li>
		</g:if>
		<li><a href="#"><span class="'ui-button-text-icon-secondary"></span>Options</a>
			<ul class="optionsMenu">
				<li><a href="#" value="diffBeforeSave"><span></span>diffBeforeSave</a></li>
				<li><a href="#"><span></span>Binding</a>
					<ul id="cmeditor-menu-${name}-bindings">
						<li><a href="#" value="bindingdefault"><span class="ui-icon ui-icon-blank"></span>default</a></li>
						<li><a href="#" value="bindingvim"><span></span>vim</a></li>
						<li><a href="#" value="bindingemacs"><span></span>emacs</a></li>
						<li><a href="#" value="bindingsublime"><span></span>sublime</a></li>
					</ul></li>
				<li><a href="#"><span></span>Theme</a>
					<ul id="cmeditor-menu-${name}-themes">
						<li><a href="#" value="themedefault"><span class="ui-icon ui-icon-blank"></span>default</a></li>
						<li><a href="#" value="themeeclipse"><span></span>eclipse</a></li>
						<li><a href="#" value="themelesser-dark"><span></span>lesser-dark</a></li>
						<li><a href="#" value="thememonokai"><span></span>monokai</a></li>
						<li><a href="#" value="themenight"><span></span>night</a></li>
						<li><a href="#" value="themethe-matrix"><span></span>the-matrix</a></li>
						<li><a href="#" value="themetwilight"><span></span>twilight</a></li>
					</ul></li>
			</ul>
		</li>
		<li><a href="#"><span></span>Addons</a>
			<ul class="addonsMenu">
				<li><a href="#" value="addondonation"><span class="ui-icon ui-icon-blank"></span>incredible</a></li>
			</ul>
		</li>
	</ul>
</div>
