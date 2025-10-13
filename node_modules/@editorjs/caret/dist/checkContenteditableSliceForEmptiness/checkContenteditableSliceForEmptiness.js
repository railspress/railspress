"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.checkContenteditableSliceForEmptiness = checkContenteditableSliceForEmptiness;
var dom_1 = require("@editorjs/dom");
var getContenteditableSlice_1 = require("../getContenteditableSlice/getContenteditableSlice");
/**
 * Checks content at left or right of the passed node for emptiness.
 * @param contenteditable - The contenteditable element containing the nodes.
 * @param fromNode - The starting node to check from.
 * @param offsetInsideNode - The offset inside the starting node.
 * @param direction - The direction to check ('left' or 'right').
 * @returns true if adjacent content is empty, false otherwise.
 */
function checkContenteditableSliceForEmptiness(contenteditable, fromNode, offsetInsideNode, direction) {
    /**
     * Get content editable slice
     */
    var textContent = (0, getContenteditableSlice_1.getContenteditableSlice)(contenteditable, fromNode, offsetInsideNode, direction);
    /**
     * Check extracted slice for emptiness
     */
    return (0, dom_1.isCollapsedWhitespaces)(textContent);
}
