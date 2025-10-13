import { InlineTool, InlineToolConstructorOptions, SanitizerConfig } from '@editorjs/editorjs';

/**
 * Inline Code Tool for the Editor.js
 *
 * Allows to wrap inline fragment and style it somehow.
 */
export default class InlineCode implements InlineTool {
    /**
     * Editor.js API
     */
    private api;
    /**
     * Button element for the toolbar
     */
    private button;
    /**
     * Tag representing the term
     */
    private tag;
    /**
     * CSS classes for the icon
     */
    private iconClasses;
    /**
     * Class name for term-tag
     *
     * @type {string}
     */
    static get CSS(): string;
    constructor({ api }: InlineToolConstructorOptions);
    /**
     * Specifies Tool as Inline Toolbar Tool
     *
     * @return {boolean}
     */
    static get isInline(): boolean;
    /**
     * Create button element for Toolbar
     *
     * @return {HTMLElement}
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
     *
     * @return {boolean}
     */
    checkState(): boolean;
    /**
     * Get Tool icon's SVG
     * @return {string}
     */
    get toolboxIcon(): string;
    /**
     * Sanitizer rule
     * @return {SanitizerConfig}
     */
    static get sanitize(): SanitizerConfig;
}
