import { PasteConfig, ToolboxConfig } from '@editorjs/editorjs';
import { BlockToolConstructorOptions, MenuConfigItem, ToolConfig } from '@editorjs/editorjs/types/tools';
import { ListConfig, ListData, OldListData } from './types/ListParams';
import { PasteEvent } from './types';

/**
 * Constructor Params for Editorjs List Tool, use to pass initial data and settings
 */
export type ListParams = BlockToolConstructorOptions<ListData | OldListData, ListConfig>;
/**
 * Default class of the component used in editor
 */
export default class EditorjsList {
    /**
     * Notify core that read-only mode is supported
     */
    static get isReadOnlySupported(): boolean;
    /**
     * Allow to use native Enter behaviour
     */
    static get enableLineBreaks(): boolean;
    /**
     * Get Tool toolbox settings
     * icon - Tool icon's SVG
     * title - title to show in toolbox
     */
    static get toolbox(): ToolboxConfig;
    /**
     * On paste sanitzation config. Allow only tags that are allowed in the Tool.
     * @returns - paste config object used in editor
     */
    static get pasteConfig(): PasteConfig;
    /**
     * Convert from text to list with import and export list to text
     */
    static get conversionConfig(): {
        /**
         * Method that is responsible for conversion from data to string
         * @param data - current list data
         * @returns - contents string formed from list data
         */
        export: (data: ListData) => string;
        /**
         * Method that is responsible for conversion from string to data
         * @param content - contents string
         * @returns - list data formed from contents string
         */
        import: (content: string, config: ToolConfig<ListConfig>) => ListData;
    };
    /**
     * Get list style name
     */
    private get listStyle();
    /**
     * Set list style
     * @param style - new style to set
     */
    private set listStyle(value);
    /**
     * The Editor.js API
     */
    private api;
    /**
     * Is Ediotrjs List Tool read-only
     */
    private readOnly;
    /**
     * Tool's configuration
     */
    private config;
    /**
     * Default list style formes as passed default list style from config or 'ordered' as default
     */
    private defaultListStyle?;
    /**
     * Default Counter type of the ordered list
     */
    private defaultCounterTypes;
    /**
     * Tool's data
     */
    private data;
    /**
     * Editor block api
     */
    private block;
    /**
     * Class that is responsible for complete list rendering and saving
     */
    private list;
    /**
     * Main constant wrapper of the whole list
     */
    private listElement;
    /**
     * Render plugin`s main Element and fill it with saved data
     * @param params - tool constructor options
     * @param params.data - previously saved data
     * @param params.config - user config for Tool
     * @param params.api - Editor.js API
     * @param params.readOnly - read-only mode flag
     */
    constructor({ data, config, api, readOnly, block }: ListParams);
    /**
     * Convert from list to text for conversionConfig
     * @param data - current data of the list
     * @returns - string of the recursively merged contents of the items of the list
     */
    private static joinRecursive;
    /**
     * Function that is responsible for content rendering
     * @returns rendered list wrapper with all contents
     */
    render(): HTMLElement;
    /**
     * Function that is responsible for content saving
     * @returns formatted content used in editor
     */
    save(): ListData;
    /**
     * Function that is responsible for mergind two lists into one
     * @param data - data of the next standing list, that should be merged with current
     */
    merge(data: ListData): void;
    /**
     * Creates Block Tune allowing to change the list style
     * @returns array of tune configs
     */
    renderSettings(): MenuConfigItem[];
    /**
     * On paste callback that is fired from Editor.
     * @param event - event with pasted data
     */
    onPaste(event: PasteEvent): void;
    /**
     * Handle UL, OL and LI tags paste and returns List data
     * @param element - html element that contains whole list
     */
    pasteHandler(element: PasteEvent['detail']['data']): ListData;
    /**
     * Changes ordered list counterType property value
     * @param counterType - new value of the counterType value
     */
    private changeCounters;
    /**
     * Changes ordered list start property value
     * @param index - new value of the start property
     */
    private changeStartWith;
    /**
     * This method allows changing tabulator respectfully to passed style
     */
    private changeTabulatorByStyle;
}
