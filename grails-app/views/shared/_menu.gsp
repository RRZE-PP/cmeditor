<div id="cmEditorMenu_${name}" class="cmeditor-menu">
	<div class="dialog donationDialog" title="${g.message(code:'cmeditor.addons.incredible')}" style="display: none;">
		<p><g:message code="cmeditor.addons.incredible.question1" /></p>
		<p><g:message code="cmeditor.addons.incredible.question2" /></p>
	</div>
	<div class="dialog openMenu" title="${g.message(code:'cmeditor.menu.dialogs.open')}" style="display: none;">
		<p class="noFiles" name="cmeditor-menu-open-no-files"><g:message code="cmeditor.menu.dialogs.open.nofile" /></p>
	</div>
	<div class="dialog renameDialog" title="${g.message(code:'cmeditor.menu.dialogs.rename')}" style="display: none;">
		<g:message code="cmeditor.menu.dialogs.rename.newname" /><input type="text" name="newName"  autofocus="autofocus" /> <br />
		<g:message code="cmeditor.menu.dialogs.rename.newfolder" /> <input type="text" name="newFolder" /> (<g:message code="cmeditor.menu.dialogs.rename.emptytohide" />)
	</div>
	<div class="dialog newFileDialog" title="${g.message(code:'cmeditor.menu.dialogs.new')}" style="display: none;">
		<g:message code="cmeditor.menu.dialogs.new.name" /> <input type="text" name="name"  autofocus="autofocus" /> <br />
		<g:message code="cmeditor.menu.dialogs.new.folder" /> <input type="text" name="folder" /> (<g:message code="cmeditor.menu.dialogs.new.emptytohide" />)
	</div>
	<div class="dialog gotoDialog" title="${g.message(code:'cmeditor.menu.dialogs.goto')}" style="display: none;">
		<g:message code="cmeditor.menu.dialogs.goto.prompt" /><p class="gotoLabel"></p><input type="number" autofocus="autofocus"/><p class="gotoError">&nbsp;</p>
	</div>
	<div class="dialog importDialog" title="${g.message(code:'cmeditor.menu.dialogs.import')}" style="display: none;">
		<g:message code="cmeditor.menu.dialogs.import.file" /> <input type="file" autofocus="autofocus" multiple="multiple"/>
		<div class="cmeditor-spinner" style=""></div>
	</div>
	<ul class="cmeditor-menubar menu">
		<li><a href="#"><g:message code="cmeditor.menu.menus.file" /></a>
			<ul class="fileMenu">
				<g:if test="${options.menuFile}">
				<li><a href="#" value="new"><span class="ui-icon ui-icon-newwin"></span><g:message code="cmeditor.menu.menus.file.new" /></a></li>
				<li><a href="#" value="open"><span class="ui-icon ui-icon-newwin"></span><g:message code="cmeditor.menu.menus.file.open" /></a></li>
				<li><a href="#" value="import"><span></span><g:message code="cmeditor.menu.menus.file.import" /></a></li>
				<li><a href="#" value="save"><span class="ui-icon ui-icon-disk"></span><g:message code="cmeditor.menu.menus.file.save" /></a></li>
				<li><a href="#" value="saveas"><span class="ui-icon ui-icon-disk"></span><g:message code="cmeditor.menu.menus.file.saveas" /></a></li>
				<li><a href="#" value="export"><span></span><g:message code="cmeditor.menu.menus.file.export" /></a></li>
				<li><a href="#" value="rename"><span></span><g:message code="cmeditor.menu.menus.file.rename" /></a></li>
				<li><a href="#" value="delete"><span class="ui-icon ui-icon-trash"></span><g:message code="cmeditor.menu.menus.file.delete" /></a></li>
				<li><a href="#" value="close"><span class="ui-icon ui-icon-close"></span><g:message code="cmeditor.menu.menus.file.close" /></a></li>
				</g:if>
				<li><a href="#" value="quit"><span></span><g:message code="cmeditor.menu.menus.file.quit" /></a></li>
			</ul>
		</li>
		<g:if test="${options.menuView}">
		<li><a href="#"><g:message code="cmeditor.menu.menus.view" /></a>
			<ul class="viewMenu">
				<li><a href="#" value="readOnly"><span class="ui-icon ui-icon-blank"></span><g:message code="cmeditor.menu.menus.view.readonly" /></a></li>
				<li><a href="#" value="diff"><span class="ui-icon ui-icon-transferthick-e-w"></span><g:message code="cmeditor.menu.menus.view.diff" /></a></li>
				<li><a href="#" value="goto"><span class="ui-icon ui-icon-arrowreturnthick-1-e"></span><g:message code="cmeditor.menu.menus.view.goto" /></a></li>
				<li><a href="#" value="addonfullscreen"><span class="ui-icon ui-icon-arrow-4-diag"></span><g:message code="cmeditor.menu.menus.view.fullscreen" /> (f11)</a></li>
				<li><a href="#"><span></span><g:message code="cmeditor.menu.menus.view.mode" /> (f11)</a>
					<ul class="modesMenu ui-menu-icons">
					</ul>
				</li>
			</ul>
		</li>
		</g:if>
		<li><a href="#"><span class="'ui-button-text-icon-secondary"></span><g:message code="cmeditor.menu.menus.options" /></a>
			<ul class="optionsMenu">
				<li><a href="#" value="diffBeforeSave"><span></span><g:message code="cmeditor.menu.menus.options.diffbeforesave" /></a></li>
				<li><a href="#"><span></span><g:message code="cmeditor.menu.menus.options.bindings" /></a>
					<ul id="cmeditor-menu-${name}-bindings">
						<li><a href="#" value="bindingdefault"><span class="ui-icon ui-icon-blank"></span><g:message code="cmeditor.menu.menus.options.bindings.default" /></a></li>
						<li><a href="#" value="bindingvim"><span></span><g:message code="cmeditor.menu.menus.options.bindings.vim" /></a></li>
						<li><a href="#" value="bindingemacs"><span></span><g:message code="cmeditor.menu.menus.options.bindings.emacs" /></a></li>
						<li><a href="#" value="bindingsublime"><span></span><g:message code="cmeditor.menu.menus.options.bindings.sublime" /></a></li>
					</ul></li>
				<li><a href="#"><span></span><g:message code="cmeditor.menu.menus.options.themes" /></a>
					<ul class="themesMenu" id="cmeditor-menu-${name}-themes">
					</ul>
				</li>
			</ul>
		</li>
		<li><a href="#"><span></span><g:message code="cmeditor.menu.menus.addons" /></a>
			<ul class="addonsMenu">
				<li><a href="#" value="addondonation"><span class="ui-icon ui-icon-blank"></span><g:message code="cmeditor.menu.menus.addons.incredible" /></a></li>
			</ul>
		</li>
	</ul>
</div>
