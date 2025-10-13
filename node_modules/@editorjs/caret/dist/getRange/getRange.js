"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getRange = getRange;
/**
 * Returns the first range
 * @returns range of the caret if it exists, null otherwise
 */
function getRange() {
    var selection = window.getSelection();
    return selection && selection.rangeCount ? selection.getRangeAt(0) : null;
}
