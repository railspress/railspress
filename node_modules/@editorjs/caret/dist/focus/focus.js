"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.focus = focus;
var dom_1 = require("@editorjs/dom");
/**
 * Set focus to contenteditable or native input element
 * @param element - element where to set focus
 * @param atStart - where to set focus: at the start or at the end
 */
function focus(element, atStart) {
    var _a, _b;
    if (atStart === void 0) { atStart = true; }
    /** If element is native input */
    if ((0, dom_1.isNativeInput)(element)) {
        element.focus();
        var position = atStart ? 0 : element.value.length;
        element.setSelectionRange(position, position);
    }
    else {
        var range_1 = document.createRange();
        var selection = window.getSelection();
        if (!selection) {
            return;
        }
        /**
         * Helper function to create a new text node and set the caret
         * @param parent - parent element to append the text node
         * @param prepend - should the text node be prepended or appended
         */
        var createAndFocusTextNode = function (parent, prepend) {
            if (prepend === void 0) { prepend = false; }
            var textNode = document.createTextNode('');
            if (prepend) {
                parent.insertBefore(textNode, parent.firstChild);
            }
            else {
                parent.appendChild(textNode);
            }
            range_1.setStart(textNode, 0);
            range_1.setEnd(textNode, 0);
        };
        /**
         * Helper for checking for null and undefined
         * @param v - value to check
         */
        var isDefinedAndNotNull = function (v) { return v !== undefined && v !== null; };
        /**
         * We need to set focus at start/end to the text node inside an element
         */
        var childNodes = element.childNodes;
        var nodeToFocus = atStart ? childNodes[0] : childNodes[childNodes.length - 1];
        if (isDefinedAndNotNull(nodeToFocus)) {
            /**
             * Ensure the nodeToFocus is a text node,
             * if it's not, drill down to find a text node
             */
            while (isDefinedAndNotNull(nodeToFocus) && nodeToFocus.nodeType !== Node.TEXT_NODE) {
                nodeToFocus = atStart ? nodeToFocus.firstChild : nodeToFocus.lastChild;
            }
            /**
             * If a text node is found, place the caret
             */
            if (isDefinedAndNotNull(nodeToFocus) && nodeToFocus.nodeType === Node.TEXT_NODE) {
                var length_1 = (_b = (_a = nodeToFocus.textContent) === null || _a === void 0 ? void 0 : _a.length) !== null && _b !== void 0 ? _b : 0;
                var position = atStart ? 0 : length_1;
                range_1.setStart(nodeToFocus, position);
                range_1.setEnd(nodeToFocus, position);
            }
            else {
                /**
                 * If no text node is found, create one and set focus
                 */
                createAndFocusTextNode(element, atStart);
            }
        }
        else {
            /**
             * If the element is empty, create a text node and place the caret at the start
             */
            createAndFocusTextNode(element);
        }
        selection.removeAllRanges();
        selection.addRange(range_1);
    }
}
