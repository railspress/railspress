import { InlineTool, SanitizerConfig } from '@editorjs/editorjs';
import { InlineToolConstructorOptions } from '@editorjs/editorjs/types/tools/inline-tool';

/**
 * Underline Tool for the Editor.js
 *
 * Allows to wrap inline fragment and style it somehow.
 */
export default class Underline implements InlineTool {
    /**
     * Class name for term-tag
     *
     * @type {string}
     */
    static get CSS(): string;
    /**
     * Toolbar Button
     *
     * @type {HTMLButtonElement}
     */
    private button;
    /**
     * Tag represented the term
     *
     * @type {string}
     */
    private tag;
    /**
     * API InlineToolConstructorOptions
     *
     * @type {API}
     */
    private api;
    /**
     * CSS classes
     *
     * @type {object}
     */
    private iconClasses;
    /**
     * @param options InlineToolConstructorOptions
     */
    constructor(options: InlineToolConstructorOptions);
    /**
     * Specifies Tool as Inline Toolbar Tool
     *
     * @returns {boolean}
     */
    static isInline: boolean;
    /**
     * Create button element for Toolbar
     *
     * @returns {HTMLElement}
     */
    render(): HTMLElement;
    /**
     * Wrap/Unwrap selected fragment
     *
     * @param {Range} range - selected fragment
     */
    surround(range: Range): void;
    /**
     * Wrap selection with term-tag
     *
     * @param {Range} range - selected fragment
     */
    wrap(range: Range): void;
    /**
     * Unwrap term-tag
     *
     * @param {HTMLElement} termWrapper - term wrapper tag
     */
    unwrap(termWrapper: HTMLElement): void;
    /**
     * Check and change Term's state for current selection
     */
    checkState(): boolean;
    /**
     * Get Tool icon's SVG
     *
     * @returns {string}
     */
    get toolboxIcon(): string;
    /**
     * Sanitizer rule
     *
     * @returns {{u: {class: string}}}
     */
    static get sanitize(): SanitizerConfig;
}
