<div class="modal fade importDialog" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">${g.message(code:'cmeditor.menu.dialogs.import')}</h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <g:message code="cmeditor.menu.dialogs.import.file" /> <input type="file" autofocus="autofocus" multiple="multiple"/>
                <div class="cmeditor-spinner" style=""></div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                <button type="button" class="btn btn-primary mainButton">Import</button>
            </div>
        </div>
    </div>
</div>