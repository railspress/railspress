"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.save = save;
var dom_1 = require("@editorjs/dom");
var getRange_1 = require("../getRange/getRange");
/**
 * Saves caret position using hidden <span>
 * @returns function for resoring the caret
 */
function save() {
    var range = (0, getRange_1.getRange)();
    var caret = (0, dom_1.make)('span');
    caret.id = 'cursor';
    caret.hidden = true;
    if (!range) {
        return;
    }
    range.insertNode(caret);
    /**
     * Return funciton that will restore caret and delete temporary span element
     */
    return function restore() {
        var sel = window.getSelection();
        if (!sel) {
            return;
        }
        range.setStartAfter(caret);
        range.setEndAfter(caret);
        sel.removeAllRanges();
        sel.addRange(range);
        /**
         * A little timeout uses to allow browser to set caret after element before we remove it.
         */
        setTimeout(function () {
            caret.remove();
            // eslint-disable-next-line @typescript-eslint/no-magic-numbers
        }, 150);
    };
}
