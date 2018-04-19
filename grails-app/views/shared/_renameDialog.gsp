<div class="modal fade renameDialog" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">${g.message(code:'cmeditor.menu.dialogs.rename')}</h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <g:message code="cmeditor.menu.dialogs.rename.newname" /><input type="text" name="newName"  autofocus="autofocus" /> <br />
                <g:message code="cmeditor.menu.dialogs.rename.newfolder" /> <input type="text" name="newFolder" /> (<g:message code="cmeditor.menu.dialogs.rename.emptytohide" />)
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                <button type="button" class="btn btn-primary mainButton">Rename</button>
            </div>
        </div>
    </div>
</div>