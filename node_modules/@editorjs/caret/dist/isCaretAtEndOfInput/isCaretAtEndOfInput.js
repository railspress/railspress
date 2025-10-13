"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.isCaretAtEndOfInput = isCaretAtEndOfInput;
var dom_1 = require("@editorjs/dom");
var getCaretNodeAndOffset_1 = require("../getCaretNodeAndOffset");
var checkContenteditableSliceForEmptiness_1 = require("../checkContenteditableSliceForEmptiness");
/**
 * Checks if caret is at the end of the passed input
 *
 * Cases:
 * Native input:
 * - if offset is equal to value length, caret is at the end
 * Contenteditable:
 * - caret at the last text node and offset is equal to text length — caret is at the end
 * - caret not at the last text node — we need to check right siblings for emptiness
 * - caret offset < text length, but all right part is visible (nbsp) — caret is at the end
 * - caret offset < text length, but all right part is invisible (whitespaces) — caret is at the end
 * @param input - input where caret should be checked
 */
function isCaretAtEndOfInput(input) {
    var lastNode = (0, dom_1.getDeepestNode)(input, true);
    if (lastNode === null) {
        return true;
    }
    /**
     * In case of native input, we simply check if offset is equal to value length
     */
    if ((0, dom_1.isNativeInput)(lastNode)) {
        return lastNode.selectionEnd === lastNode.value.length;
    }
    var _a = (0, getCaretNodeAndOffset_1.getCaretNodeAndOffset)(), caretNode = _a[0], caretOffset = _a[1];
    /**
     * If there is no selection, caret is not at the end
     */
    if (caretNode === null) {
        return false;
    }
    /**
     * If there is nothing visible to the right of the caret, it is considered to be at the end
     */
    return (0, checkContenteditableSliceForEmptiness_1.checkContenteditableSliceForEmptiness)(input, caretNode, caretOffset, 'right');
}
