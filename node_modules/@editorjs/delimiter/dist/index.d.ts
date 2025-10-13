import { BlockTool, BlockToolConstructorOptions, BlockToolData, ToolboxConfig, PasteConfig, PasteEvent } from '@editorjs/editorjs';
/**
 * Delimiter Block for the Editor.js.
 *
 * @author CodeX (team@ifmo.su)
 * @copyright CodeX 2018
 * @license The MIT License (MIT)
 * @version 2.0.0
 */
/**
 * @typedef {Object} DelimiterData
 * @description Tool's input and output data format
 */
export default class Delimiter implements BlockTool {
    /**
     * Notify core that read-only mode is supported
     * @return {boolean}
     */
    static get isReadOnlySupported(): boolean;
    /**
     * Allow Tool to have no content
     * @return {boolean}
     */
    static get contentless(): boolean;
    private api;
    private _CSS;
    private data;
    private _element;
    /**
     * Render plugin`s main Element and fill it with saved data
     *
     * @param {{data: DelimiterData, config: object, api: object}}
     *   data — previously saved data
     *   config - user config for Tool
     *   api - Editor.js API
     */
    constructor({ data, config, api }: BlockToolConstructorOptions);
    /**
     * Create Tool's view
     * @return {HTMLDivElement}
     * @private
     */
    drawView(): HTMLDivElement;
    /**
     * Return Tool's view
     * @returns {HTMLDivElement}
     * @public
     */
    render(): HTMLDivElement;
    /**
     * Extract Tool's data from the view
     * @param {HTMLDivElement} toolsContent - Paragraph tools rendered view
     * @returns {DelimiterData} - saved data
     * @public
     */
    save(toolsContent: HTMLElement): BlockToolData;
    /**
     * Get Tool toolbox settings
     * icon - Tool icon's SVG
     * title - title to show in toolbox
     *
     * @return {{icon: string, title: string}}
     */
    static get toolbox(): ToolboxConfig;
    /**
     * Delimiter onPaste configuration
     *
     * @public
     */
    static get pasteConfig(): PasteConfig;
    /**
     * On paste callback that is fired from Editor
     *
     * @param {PasteEvent} event - event with pasted data
     */
    onPaste(event: PasteEvent): void;
}
