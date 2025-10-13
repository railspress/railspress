import { API, ToolboxConfig, BlockTool, ToolConfig, BlockToolData } from '@editorjs/editorjs';
/**
 * Warning Tool`s CSS classnames
 */
interface WarningCSS {
    baseClass: string;
    wrapper: string;
    title: string;
    input: string;
    message: string;
}
/**
 * Warning Tool's input and output data
 */
export interface WarningData extends BlockToolData {
    /**
     * Warning's title
     */
    title: string;
    /**
     * Warning's message
     */
    message: string;
}
/**
 * Warning Tool's initial configuration
 */
export interface WarningConfig extends ToolConfig {
    /**
     * Placeholder to show in warning`s title input
     */
    titlePlaceholder?: string;
    /**
     * Placeholder to show in warning`s message input
     */
    messagePlaceholder?: string;
}
/**
 * Warning Tool's constructor arguments
 */
interface WarningConstructorArgs {
    /**
     * Previously saved warning`s data
     */
    data: WarningData;
    /**
     * Warning Tool`s configuration
     */
    config?: WarningConfig;
    /**
     * Editor.js API instance
     */
    api: API;
    /**
     * Read-only mode
     */
    readOnly: boolean;
}
/**
 * @class Warning
 * @classdesc Warning Tool for Editor.js
 * @property {API} api - Editor.js API instance
 * @property {WarningData} data - Warning Tool`s input and output data
 * @property {boolean} readOnly - Read-only mode
 * @property {string} titlePlaceholder - Placeholder for title input
 * @property {string} messagePlaceholder - Placeholder for message input
 */
export default class Warning implements BlockTool {
    /**
     * Editor.js API instance
     */
    private api;
    /**
     * Warning Tool`s input and output data
     */
    private data;
    /**
     * Read-only mode is supported
     */
    private readOnly;
    /**
     * Placeholder for the title input
     */
    private titlePlaceholder;
    /**
     * Placeholder for the message input
     */
    private messagePlaceholder;
    /**
     * Notify core that read-only mode is supported
     */
    static get isReadOnlySupported(): boolean;
    /**
     * Get Toolbox settings
     *
     * @public
     * @returns {ToolboxConfig} An object containing Tool's icon and title.
     */
    static get toolbox(): ToolboxConfig;
    /**
     * Allow to press Enter inside the Warning
     *
     * @public
     * @returns {boolean}
     */
    static get enableLineBreaks(): boolean;
    /**
     * Default placeholder for warning title
     *
     * @public
     * @returns {string}
     */
    static get DEFAULT_TITLE_PLACEHOLDER(): string;
    /**
     * Default placeholder for warning message
     *
     * @public
     * @returns {string}
     */
    static get DEFAULT_MESSAGE_PLACEHOLDER(): string;
    /**
     * Warning Tool`s styles
     *
     * @returns {WarningCSS} An object containing Tool`s CSS classnames.
     */
    get CSS(): WarningCSS;
    /**
     * Render plugin`s main Element and fill it with saved data
     *
     * @param {object} params — constructor params
     * @param {WarningData} params.data — previously saved data
     * @param {WarningConfig} params.config — user config for Tool
     * @param {API} params.api - Editor.js API
     * @param {boolean} params.readOnly - read-only mode flag
     */
    constructor({ data, config, api, readOnly }: WarningConstructorArgs);
    /**
     * Create Warning Tool container with inputs
     *
     * @returns {Element} Html element of Warning Tool.
     */
    render(): HTMLElement;
    /**
     * Extract Warning data from Warning Tool element
     *
     * @param {HTMLDivElement} warningElement - element to save
     * @returns {WarningData} Warning Tool`s data.
     */
    save(warningElement: HTMLDivElement): WarningData;
    /**
     * Helper for making Elements with attributes
     *
     * @param  {string} tagName           - new Element tag name
     * @param  {Array|string} classNames  - list or name of CSS classname(s)
     * @param  {object} attributes        - any attributes
     * @returns {Element} Html element of {tagName}.
     */
    private _make;
    /**
     * Sanitizer config for Warning Tool saved data
     *
     */
    static get sanitize(): {
        title: {};
        message: {};
    };
}
export {};
