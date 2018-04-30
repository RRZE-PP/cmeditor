<div class="modal fade diffDialog" tabindex="-1" role="dialog">
    <div class="modal-dialog modal-lg" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">${g.message(code:'cmeditor.dialogs.diff')}</h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <p class="noChanges"><g:message code="cmeditor.dialogs.diff.noChanges" /></p>
                <div class="diffoutput"></div>
                <p><strong><g:message code="cmeditor.dialogs.diff.contextSize" /></strong><input name="contextSize" value="1" type="number" autofocus="autofocus"/></p>
                <p><input type="radio" value="0" name="_viewType" id="sidebyside" checked="checked"/>
                    <label for="sidebyside"><g:message code="cmeditor.dialogs.diff.sideBySide" /></label>
                    &nbsp; &nbsp; <input type="radio" value="1" name="_viewType" id="inline" />
                    <label for="inline"><g:message code="cmeditor.dialogs.diff.inline" /></label> </p>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                <button type="button" class="btn btn-primary mainButton">OK</button>
            </div>
        </div>
    </div>
</div>