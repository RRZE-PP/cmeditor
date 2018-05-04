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
					<cmeditor:menuItem value="new" code="file.new" icon="fa-file" iconFamily="far"/>
					<cmeditor:menuItem value="open" code="file.open" icon="fa-folder-open" iconFamily="far"/>
					<cmeditor:menuItem value="import" code="file.import" icon="fa-download" iconFamily="fas"/>
					<cmeditor:menuItem value="save" code="file.save" icon="fa-save" iconFamily="fas"/>
					<cmeditor:menuItem value="saveas" code="file.saveas" icon="fa-save" iconFamily="fas"/>
					<cmeditor:menuItem value="export" code="file.export" icon="fa-upload" iconFamily="fas"/>
					<cmeditor:menuItem value="rename" code="file.rename" icon="fa-edit" iconFamily="far"/>
					<cmeditor:menuItem value="delete" code="file.delete" icon="fa-trash-alt" iconFamily="far"/>
					<cmeditor:menuItem value="close" code="file.close" icon="fa-times-circle" iconFamily="far"/>
				</g:if>
				<cmeditor:menuItem value="quit" code="file.quit" icon="fa-times-circle" iconFamily="fas"/>
			</div>
		</li>
		<g:if test="${options.menuView}">
		<li class="nav-item dropdown">
			<a href="#" class="nav-link dropdown-toggle" id="viewMenu" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
				<g:message code="cmeditor.menu.menus.view" />
			</a>
			<div class="viewMenu dropdown-menu" aria-labelledby="viewMenu">
				<cmeditor:menuItem value="readOnly" code="view.readonly" icon="fa-lock" iconFamily="fas"/>
				<cmeditor:menuItem value="diff" code="view.diff" icon="fa-exchange-alt" iconFamily="fas"/>
				<cmeditor:menuItem value="goto" code="view.goto" icon="fa-location-arrow" iconFamily="fas"/>
				<cmeditor:menuItem value="showLog" code="view.log" icon="fa-list" iconFamily="fas"/>
				<cmeditor:menuItem value="fullscreen" code="view.fullscreen" icon="fa-expand-arrows-alt" iconFamily="fas"/>
			</div>
		</li>
		</g:if>
		<li class="nav-item dropdown">
			<a href="#" class="nav-link dropdown-toggle" id="modesMenu" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
				<g:message code="cmeditor.menu.menus.view.mode" />
			</a>
			<div class="modesMenu dropdown-menu" aria-labelledby="modesMenu"></div>
		</li>
		<li class="nav-item dropdown">
			<a href="#" class="nav-link dropdown-toggle" id="optionsMenu" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
				<span class="'ui-button-text-icon-secondary"></span><g:message code="cmeditor.menu.menus.options" /></a>
			<div class="optionsMenu dropdown-menu" aria-labelledby="optionsMenu">
				<cmeditor:menuItem value="diffBeforeSave" code="options.diffbeforesave" active="true" />
				<cmeditor:menuDivider />

				<cmeditor:menuItem value="dummyBindings" code="options.bindings" disabled="true" />
				<cmeditor:menuItem value="bindingdefault" code="options.bindings.default" group="bindings" />
				<cmeditor:menuItem value="bindingemacs" code="options.bindings.emacs" group="bindings" />
				<cmeditor:menuItem value="bindingsublime" code="options.bindings.sublime" group="bindings" />
				<cmeditor:menuItem value="bindingvim" code="options.bindings.vim" group="bindings" />

				<cmeditor:menuDivider />
				<a class="dropdown-item disabled themesMenu" href="#"><span></span><g:message code="cmeditor.menu.menus.options.themes" /></a>
			</div>
		</li>
	</ul>
</div>
</nav>
</div>
