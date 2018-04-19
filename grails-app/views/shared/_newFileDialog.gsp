<div class="modal fade newFileDialog" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">${g.message(code:'cmeditor.menu.dialogs.new')}</h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <g:message code="cmeditor.menu.dialogs.new.name" /> <input type="text" name="name"  autofocus="autofocus" /> <br />
                <g:message code="cmeditor.menu.dialogs.new.folder" /> <input type="text" name="folder" /> (<g:message code="cmeditor.menu.dialogs.new.emptytohide" />)
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                <button type="button" class="btn btn-primary mainButton">Create</button>
            </div>
        </div>
    </div>
</div>
