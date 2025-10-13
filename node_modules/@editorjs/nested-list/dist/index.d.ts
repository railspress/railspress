import { PasteConfig, ToolboxConfig } from '@editorjs/editorjs';
import { PasteEvent } from './types';
import { BlockToolConstructorOptions, TunesMenuConfig } from '@editorjs/editorjs/types/tools';

/**
 * list style to make list as ordered or unordered
 */
type ListDataStyle = 'ordered' | 'unordered';
/**
 * Output data
 */
interface ListData {
    /**
     * list type 'ordered' or 'unordered'
     */
    style: ListDataStyle;
    /**
     * list of first-level elements
     */
    items: ListItem[];
}
/**
 * List item within the output data
 */
interface ListItem {
    /**
     * list item text content
     */
    content: string;
    /**
     * sublist items
     */
    items: ListItem[];
}
/**
 * Tool's configuration
 */
interface NestedListConfig {
    /**
     * default list style: ordered or unordered
     * default is unordered
     */
    defaultStyle?: ListDataStyle;
}
/**
 * Constructor Params for Nested List Tool, use to pass initial data and settings
 */
export type NestedListParams = BlockToolConstructorOptions<ListData, NestedListConfig>;
/**
 * CSS classes for the Nested List Tool
 */
interface NestedListCssClasses {
    baseBlock: string;
    wrapper: string;
    wrapperOrdered: string;
    wrapperUnordered: string;
    item: string;
    itemBody: string;
    itemContent: string;
    itemChildren: string;
    settingsWrapper: string;
    settingsButton: string;
    settingsButtonActive: string;
}
/**
 * NestedList Tool for EditorJS
 */
export default class NestedList {
    /**
     * Notify core that read-only mode is supported
     *
     * @returns {boolean}
     */
    static get isReadOnlySupported(): boolean;
    /**
     * Allow to use native Enter behaviour
     *
     * @returns {boolean}
     * @public
     */
    static get enableLineBreaks(): boolean;
    /**
     * Get Tool toolbox settings
     * icon - Tool icon's SVG
     * title - title to show in toolbox
     *
     * @returns {ToolboxConfig}
     */
    static get toolbox(): ToolboxConfig;
    /**
     * The Editor.js API
     */
    private api;
    /**
     * Is NestedList Tool read-only
     */
    private readOnly;
    /**
     * Tool's configuration
     */
    private config?;
    /**
     * Default list style
     */
    private defaultListStyle?;
    /**
     * Corresponds to UiNodes type from Editor.js but with wrapper being nullable
     */
    private nodes;
    /**
     * Tool's data
     */
    private data;
    /**
     * Caret helper
     */
    private caret;
    /**
     * Render plugin`s main Element and fill it with saved data
     *
     * @param {object} params - tool constructor options
     * @param {ListData} params.data - previously saved data
     * @param {object} params.config - user config for Tool
     * @param {object} params.api - Editor.js API
     * @param {boolean} params.readOnly - read-only mode flag
     */
    constructor({ data, config, api, readOnly }: NestedListParams);
    /**
     * Returns list tag with items
     *
     * @returns {Element}
     * @public
     */
    render(): Element;
    /**
     * Creates Block Tune allowing to change the list style
     *
     * @public
     * @returns {Array}
     */
    renderSettings(): TunesMenuConfig;
    /**
     * On paste sanitzation config. Allow only tags that are allowed in the Tool.
     *
     * @returns {PasteConfig} - paste config.
     */
    static get pasteConfig(): PasteConfig;
    /**
     * On paste callback that is fired from Editor.
     *
     * @param {PasteEvent} event - event with pasted data
     */
    onPaste(event: PasteEvent): void;
    /**
     * Handle UL, OL and LI tags paste and returns List data
     *
     * @param {HTMLUListElement|HTMLOListElement|HTMLLIElement} element
     * @returns {ListData}
     */
    pasteHandler(element: PasteEvent['detail']['data']): ListData;
    /**
     * Renders children list
     *
     * @param {ListItem[]} items - items data to append
     * @param {Element} parentItem - where to append
     * @returns {void}
     */
    appendItems(items: ListItem[], parentItem: Element): void;
    /**
     * Renders the single item
     *
     * @param {string} content - item content to render
     * @param {ListItem[]} [items] - children
     * @returns {Element}
     */
    createItem(content: string, items?: ListItem[]): Element;
    /**
     * Extracts tool's data from the DOM
     *
     * @returns {ListData}
     */
    save(): ListData;
    /**
     * Append children list to passed item
     *
     * @param {Element} parentItem - item that should contain passed sub-items
     * @param {ListItem[]} items - sub items to append
     */
    addChildrenList(parentItem: Element, items: ListItem[]): void;
    /**
     * Creates main <ul> or <ol> tag depended on style
     *
     * @param {string} [style] - 'ordered' or 'unordered'
     * @param {string[]} [classes] - additional classes to append
     * @returns {HTMLOListElement|HTMLUListElement}
     */
    makeListWrapper(style?: string, classes?: string[]): HTMLOListElement | HTMLUListElement;
    /**
     * Styles
     *
     * @returns {NestedListCssClasses} - CSS classes names by keys
     * @private
     */
    get CSS(): NestedListCssClasses;
    /**
     * Get list style name
     *
     * @returns {string}
     */
    get listStyle(): string;
    /**
     * Set list style
     *
     * @param {ListDataStyle} style - new style to set
     */
    set listStyle(style: ListDataStyle);
    /**
     * Returns current List item by the caret position
     *
     * @returns {Element}
     */
    get currentItem(): Element | null;
    /**
     * Handles Enter keypress
     *
     * @param {KeyboardEvent} event - keydown
     * @returns {void}
     */
    enterPressed(event: KeyboardEvent): void;
    /**
     * Decrease indentation of the current item
     *
     * @returns {void}
     */
    unshiftItem(): void;
    /**
     * Return the item content
     *
     * @param {Element} item - item wrapper (<li>)
     * @returns {string}
     */
    getItemContent(item: Element): string;
    /**
     * Sets focus to the item's content
     *
     * @param {Element} item - item (<li>) to select
     * @param {boolean} atStart - where to set focus: at the start or at the end
     * @returns {void}
     */
    focusItem(item: Element, atStart?: boolean): void;
    /**
     * Get out from List Tool by Enter on the empty last item
     *
     * @returns {void}
     */
    getOutOfList(): void;
    /**
     * Handle backspace
     *
     * @param {KeyboardEvent} event - keydown
     */
    backspace(event: KeyboardEvent): void;
    /**
     * Add indentation to current item
     *
     * @param {KeyboardEvent} event - keydown
     */
    addTab(event: KeyboardEvent): void;
    /**
     * Reduce indentation for current item
     *
     * @param {KeyboardEvent} event - keydown
     * @returns {void}
     */
    shiftTab(event: KeyboardEvent): void;
    /**
     * Convert from list to text for conversionConfig
     *
     * @param {ListData} data
     * @returns {string}
     */
    static joinRecursive(data: ListData | ListItem): string;
    /**
     * Convert from text to list with import and export list to text
     */
    static get conversionConfig(): {
        export: (data: ListData) => string;
        import: (content: string) => ListData;
    };
}
export {};
