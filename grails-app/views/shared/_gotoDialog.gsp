<div class="modal fade gotoDialog" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">${g.message(code:'cmeditor.menu.dialogs.goto')}</h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <g:message code="cmeditor.menu.dialogs.goto.prompt" /><p class="gotoLabel"></p><input type="number" autofocus="autofocus"/><p class="gotoError">&nbsp;</p>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                <button type="button" class="btn btn-primary mainButton">Go to</button>
            </div>
        </div>
    </div>
</div>