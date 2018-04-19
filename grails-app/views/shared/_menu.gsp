<div id="dialogContainerElement">
	<g:render template="openDialog" contextPath="/shared/" />
	<g:render template="newFileDialog" contextPath="/shared/" />
	<g:render template="gotoDialog" contextPath="/shared/" />
	<g:render template="renameDialog" contextPath="/shared/" />
	<g:render template="importDialog" contextPath="/shared/" />
</div>

<div id="cmEditorMenu_${name}" class="cmeditor-menu">


<nav class="cmeditor-menubar menunavbar navbar-expand-lg navbar-light bg-light">
<button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#cmeditorNavBarSupportedContent" aria-controls="cmeditorNavBarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">
	<span class="navbar-toggler-icon"></span>
</button>

<div class="collapse navbar-collapse" id="cmeditorNavBarSupportedContent">
	<ul class="navbar-nav mr-auto">
		<li class="nav-item dropdown">
			<a href="#" class="nav-link dropdown-toggle" id="fileMenu" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
				<g:message code="cmeditor.menu.menus.file" />
			</a>
			<div class="fileMenu dropdown-menu" aria-labelledby="fileMenu">
				<g:if test="${options.menuFile}">
				<a class="dropdown-item" href="#" value="new"><i class="far fa-fw fa-file"></i>&nbsp;<g:message code="cmeditor.menu.menus.file.new" /></a>
				<a class="dropdown-item" href="#" value="open"><i class="far fa-fw fa-folder-open"></i>&nbsp;<g:message code="cmeditor.menu.menus.file.open" /></a>
				<a class="dropdown-item" href="#" value="import"><i class="fas fa-fw fa-download"></i>&nbsp;<g:message code="cmeditor.menu.menus.file.import" /></a>
				<a class="dropdown-item" href="#" value="save" class="disabledWhenReadOnly"><i class="fas fa-fw fa-save"></i>&nbsp;<g:message code="cmeditor.menu.menus.file.save" /></a>
				<a class="dropdown-item" href="#" value="saveas" class="disabledWhenReadOnly"><i class="fas fa-fw fa-save"></i>&nbsp;<g:message code="cmeditor.menu.menus.file.saveas" /></a>
				<a class="dropdown-item" href="#" value="export"><i class="fas fa-fw fa-upload"></i>&nbsp;<g:message code="cmeditor.menu.menus.file.export" /></a>
				<a class="dropdown-item" href="#" value="rename" class="disabledWhenReadOnly"><i class="far fa-fw fa-edit"></i>&nbsp;<g:message code="cmeditor.menu.menus.file.rename" /></a>
				<a class="dropdown-item" href="#" value="delete" class="disabledWhenReadOnly"><i class="far fa-fw fa-trash-alt"></i>&nbsp;<g:message code="cmeditor.menu.menus.file.delete" /></a>
				<a class="dropdown-item" href="#" value="close"><i class="far fa-fw fa-times-circle"></i>&nbsp;<g:message code="cmeditor.menu.menus.file.close" /></a>
				</g:if>
				<a class="dropdown-item" href="#" value="quit"><i class="fas fa-fw fa-times-circle"></i>&nbsp;<g:message code="cmeditor.menu.menus.file.quit" /></a>
			</div>
		</li>
		<g:if test="${options.menuView}">
		<li class="nav-item dropdown">
			<a href="#" class="nav-link dropdown-toggle" id="viewMenu" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
				<g:message code="cmeditor.menu.menus.view" />
			</a>
			<div class="viewMenu dropdown-menu" aria-labelledby="viewMenu">
				<a class="dropdown-item" href="#" value="readOnly"><i class="fas fa-fw fa-lock"></i>&nbsp;<g:message code="cmeditor.menu.menus.view.readonly" /></a>
				<a class="dropdown-item" href="#" value="diff"><i class="fas fa-fw fa-exchange-alt"></i>&nbsp;<g:message code="cmeditor.menu.menus.view.diff" /></a>
				<a class="dropdown-item" href="#" value="goto"><i class="fas fa-fw fa-location-arrow"></i>&nbsp;<g:message code="cmeditor.menu.menus.view.goto" /></a>
				<a class="dropdown-item" href="#" value="fullscreen"><i class="fas fa-fw fa-expand-arrows-alt"></i>&nbsp;<g:message code="cmeditor.menu.menus.view.fullscreen" /> (f11)</a>
			</div>
		</li>
		</g:if>
		<li class="nav-item dropdown">
			<a href="#" class="nav-link dropdown-toggle" id="modesMenu" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
				<g:message code="cmeditor.menu.menus.view.mode" />
			</a>
			<div class="modesMenu dropdown-menu" aria-labelledby="modesMenu">
			</div>
		</li>
		<li class="nav-item dropdown">
			<a href="#" class="nav-link dropdown-toggle" id="optionsMenu" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
				<span class="'ui-button-text-icon-secondary"></span><g:message code="cmeditor.menu.menus.options" /></a>
			<div class="optionsMenu dropdown-menu" aria-labelledby="optionsMenu">
				<a class="dropdown-item" href="#" value="diffBeforeSave"><span></span><g:message code="cmeditor.menu.menus.options.diffbeforesave" /></a>

				<div class="dropdown-divider"></div>
				<a class="dropdown-item disabled" href="#"><span></span><g:message code="cmeditor.menu.menus.options.bindings" /></a>

				<a class="dropdown-item" href="#" value="bindingdefault"><span class="ui-icon ui-icon-blank"></span><g:message code="cmeditor.menu.menus.options.bindings.default" /></a><
				<a class="dropdown-item" href="#" value="bindingvim"><span></span><g:message code="cmeditor.menu.menus.options.bindings.vim" /></a>
				<a class="dropdown-item" href="#" value="bindingemacs"><span></span><g:message code="cmeditor.menu.menus.options.bindings.emacs" /></a>
				<a class="dropdown-item" href="#" value="bindingsublime"><span></span><g:message code="cmeditor.menu.menus.options.bindings.sublime" /></a>


				<div class="dropdown-divider"></div>
				<a class="dropdown-item disabled themesMenu" href="#"><span></span><g:message code="cmeditor.menu.menus.options.themes" /></a>
			</div>
		</li>
	</ul>
</div>
</nav>
</div>
