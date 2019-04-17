<div id="cmEditorOpenDialog" class="modal fade openMenu" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">${g.message(code:'cmeditor.menu.dialogs.open')}</h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <p class="noFiles" name="cmeditor-menu-open-no-files"><g:message code="cmeditor.menu.dialogs.open.nofile" /></p>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                <button type="button" class="btn btn-primary mainButton">Open</button>
            </div>
        </div>
    </div>
</div>

<script>
    $('#cmEditorOpenDialog').on('shown.bs.modal', function () {
        $('.fileSelect').select2('open').select2('close');
    })
</script>