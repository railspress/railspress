"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getContenteditableSlice = getContenteditableSlice;
var dom_1 = require("@editorjs/dom");
/**
 * Returns slice of the contenteditable html element from caret position to the start or end (depending on direction)
 * @param contenteditable - The contenteditable element containing the nodes.
 * @param fromNode - The starting node to check from.
 * @param offsetInsideNode - The offset inside the starting node.
 * @param direction - The direction to check ('left' or 'right').
 * @param extract - should we remove from element extracted part
 * @returns true if adjacent content is empty, false otherwise.
 */
function getContenteditableSlice(contenteditable, fromNode, offsetInsideNode, direction, extract) {
    var _a;
    if (extract === void 0) { extract = false; }
    var range = document.createRange();
    /**
     * In case of "left":
     * Set range from the start of the contenteditable to the passed offset
     */
    if (direction === 'left') {
        range.setStart(contenteditable, 0);
        range.setEnd(fromNode, offsetInsideNode);
        /**
         * In case of "right":
         * Set range from the passed offset to the end of the contenteditable
         */
    }
    else {
        range.setStart(fromNode, offsetInsideNode);
        range.setEnd(contenteditable, contenteditable.childNodes.length);
    }
    /**
     * Check if we should extract content from the range
     */
    if (extract === true) {
        var textContent_1 = range.extractContents();
        return (0, dom_1.fragmentToString)(textContent_1);
    }
    /**
     * Clone the range's content and check its text content
     */
    var clonedContent = range.cloneContents();
    var tempDiv = document.createElement('div');
    tempDiv.appendChild(clonedContent);
    var textContent = (_a = tempDiv.textContent) !== null && _a !== void 0 ? _a : '';
    /**
     * In HTML there are two types of whitespaces:
     * - visible (&nbsp;)
     * - invisible (trailing spaces, tabs, etc.)
     *
     * If text contains only invisible whitespaces, it is considered to be empty
     */
    return textContent;
}
