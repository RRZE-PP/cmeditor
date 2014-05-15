function cmeditorbase_lst(arr) { return arr[arr.length-1]; }

function cmeditorbase_comment(cm) {
  var minLine = Infinity, ranges = cm.listSelections(), mode = null;
  for (var i = ranges.length - 1; i >= 0; i--) {
    var from = ranges[i].from(), to = ranges[i].to();
    if (from.line >= minLine) continue;
    if (to.line >= minLine) to = Pos(minLine, 0);
    minLine = from.line;
    if (mode == null) {
      if (cm.uncomment(from, to, {lineComment: "//"})) mode = "un";
      else { cm.lineComment(from, to, {lineComment: "//"}); mode = "line"; }
    } else if (mode == "un") {
      cm.uncomment(from, to, {lineComment: "//"});
    } else {
      cm.lineComment(from, to, {lineComment: "//"});
    }
  }
}

function cmeditorbase_moveDown(cm) {
	cmeditorbase_moveDownSelection(cm, function(range) {
	return {from: CodeMirror.Pos(range.from().line, 0),
		to: CodeMirror.Pos(range.to().line + 1, 0)};
	});
}

function cmeditorbase_moveUp(cm) {
	cmeditorbase_moveUpSelection(cm, function(range) {
		return {from: CodeMirror.Pos(range.from().line - 1, 0),
			to: CodeMirror.Pos(range.to().line, 0)};
	});
}

function cmeditorbase_moveDownSelection(cm, compute) {
	var ranges = cm.doc.sel.ranges, move = [];
	// Build up a set of ranges to move first, merging overlapping
	// ranges.
	for (var i = 0; i < ranges.length; i++) {
		var toMove = compute(ranges[i]);
		while (move.length
				&& CodeMirror.cmpPos(toMove.from, cmeditorbase_lst(move).to) <= 0) {
			var replaced = move.pop();
			if (CodeMirror.cmpPos(replaced.from, toMove.from) < 0) {
				toMove.from = replaced.from;
				break;
			}
		}
		move.push(toMove);
	}
	var sels = cm.doc.listSelections();
	for (var i = 0; i < sels.length; i++) {
		sels[i].anchor = CodeMirror.Pos(sels[i].anchor.line + 1,
				sels[i].anchor.ch)
		sels[i].head = CodeMirror.Pos(sels[i].head.line + 1, sels[i].head.ch)
	}
	// Next, move those actual ranges.
	cm.operation(function() {
		for (var i = move.length - 1; i >= 0; i--) {
			var replacement = cm.getLine(move[i].to.line) + "\n";
			for (var j = move[i].from.line; j < move[i].to.line; j++)
				replacement = replacement + cm.getLine(j) + "\n";
			cm.doc.replaceRange(replacement, move[i].from, CodeMirror.Pos(
					move[i].to.line + 1, 0), "+move");
		}
	});
	cm.doc.setSelections(sels);
}

function cmeditorbase_moveUpSelection(cm, compute) {
	var doMove = true;
	var ranges = cm.doc.sel.ranges, move = [];
	// Build up a set of ranges to move first, merging overlapping
	// ranges.
	for (var i = 0; i < ranges.length; i++) {
		if (ranges[i].from().line == 0) {
			doMove = false;
			break;
		}
		var toMove = compute(ranges[i]);
		while (move.length
				&& CodeMirror.cmpPos(toMove.from, cmeditorbase_lst(move).to) <= 0) {
			var replaced = move.pop();
			if (CodeMirror.cmpPos(replaced.from, toMove.from) < 0) {
				toMove.from = replaced.from;
				break;
			}
		}

		move.push(toMove);
	}
	if (doMove) {
		var sels = cm.doc.listSelections();
		for (var i = 0; i < sels.length; i++) {
			sels[i].anchor = CodeMirror.Pos(sels[i].anchor.line - 1,
					sels[i].anchor.ch)
			sels[i].head = CodeMirror.Pos(sels[i].head.line - 1,
					sels[i].head.ch)
		}
		// Next, move those actual ranges.
		cm.operation(function() {
			for (var i = move.length - 1; i >= 0; i--) {
				var replacement = "";
				for (var j = move[i].from.line + 1; j < move[i].to.line + 1; j++)
					replacement = replacement + cm.getLine(j) + "\n";
				replacement = replacement
						+ cm.getLine(move[i].from.line) + "\n";
				cm.doc.replaceRange(replacement, move[i].from,
						CodeMirror.Pos(move[i].to.line + 1, 0),
						"+move");
			}
		});
		cm.doc.setSelections(sels);
	}
}