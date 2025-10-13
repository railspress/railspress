"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.isCaretAtStartOfInput = isCaretAtStartOfInput;
var dom_1 = require("@editorjs/dom");
var getCaretNodeAndOffset_1 = require("../getCaretNodeAndOffset/getCaretNodeAndOffset");
var checkContenteditableSliceForEmptiness_1 = require("../checkContenteditableSliceForEmptiness/checkContenteditableSliceForEmptiness");
/**
 * Checks if caret is at the start of the passed input
 *
 * Cases:
 * Native input:
 * - if offset is 0, caret is at the start
 * Contenteditable:
 * - caret at the first text node and offset is 0 — caret is at the start
 * - caret not at the first text node — we need to check left siblings for emptiness
 * - caret offset > 0, but all left part is visible (nbsp) — caret is not at the start
 * - caret offset > 0, but all left part is invisible (whitespaces) — caret is at the start
 * @param input - input where caret should be checked
 */
function isCaretAtStartOfInput(input) {
    var firstNode = (0, dom_1.getDeepestNode)(input);
    if (firstNode === null || (0, dom_1.isEmpty)(input)) {
        return true;
    }
    /**
     * In case of native input, we simply check if offset is 0
     */
    if ((0, dom_1.isNativeInput)(firstNode)) {
        return firstNode.selectionEnd === 0;
    }
    if ((0, dom_1.isEmpty)(input)) {
        return true;
    }
    var _a = (0, getCaretNodeAndOffset_1.getCaretNodeAndOffset)(), caretNode = _a[0], caretOffset = _a[1];
    /**
     * If there is no selection, caret is not at the start
     */
    if (caretNode === null) {
        return false;
    }
    /**
     * If there is nothing visible to the left of the caret, it is considered to be at the start
     */
    return (0, checkContenteditableSliceForEmptiness_1.checkContenteditableSliceForEmptiness)(input, caretNode, caretOffset, 'left');
}
