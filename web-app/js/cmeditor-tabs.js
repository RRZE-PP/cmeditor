//= require cmeditor-main
//= require jquery-ui
//= require jsdifflib
//= require_self
function cmeditortabs_is_in_list(data, name) {
	for (var i = 0; i < data.length; ++i)
		if (data[i] == name)
			return true;
}