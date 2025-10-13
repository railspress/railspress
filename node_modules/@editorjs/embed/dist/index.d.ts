import { ServiceConfig, ServicesConfigType } from './serviceConfig';
import { API, PatternPasteEventDetail } from '@editorjs/editorjs';

/**
 * @description Embed Tool data
 */
export interface EmbedData {
    /** Service name */
    service: string;
    /** Source URL of embedded content */
    source: string;
    /** URL to source embed page */
    embed: string;
    /** Embedded content width */
    width?: number;
    /** Embedded content height */
    height?: number;
    /** Content caption */
    caption?: string;
}
/**
 * @description Embed tool configuration object
 */
interface EmbedConfig {
    /** Additional services provided by user */
    services?: ServicesConfigType;
}
/**
 * @description CSS object
 */
interface CSS {
    /** Base class for CSS */
    baseClass: string;
    /** CSS class for input */
    input: string;
    /** CSS class for container */
    container: string;
    /** CSS class for loading container */
    containerLoading: string;
    /** CSS class for preloader */
    preloader: string;
    /** CSS class for caption */
    caption: string;
    /** CSS class for URL */
    url: string;
    /** CSS class for content */
    content: string;
}
interface ConstructorArgs {
    data: EmbedData;
    api: API;
    readOnly: boolean;
}
/**
 * @class Embed
 * @classdesc Embed Tool for Editor.js 2.0
 *
 * @property {object} api - Editor.js API
 * @property {EmbedData} _data - private property with Embed data
 * @property {HTMLElement} element - embedded content container
 *
 * @property {object} services - static property with available services
 * @property {object} patterns - static property with patterns for paste handling configuration
 */
export default class Embed {
    /** Editor.js API */
    private api;
    /** Private property with Embed data */
    private _data;
    /** Embedded content container */
    private element;
    /** Read-only mode flag */
    private readOnly;
    /** Static property with available services */
    static services: {
        [key: string]: ServiceConfig;
    };
    /** Static property with patterns for paste handling configuration */
    static patterns: {
        [key: string]: RegExp;
    };
    /**
     * @param {{data: EmbedData, config: EmbedConfig, api: object}}
     *   data — previously saved data
     *   config - user config for Tool
     *   api - Editor.js API
     *   readOnly - read-only mode flag
     */
    constructor({ data, api, readOnly }: ConstructorArgs);
    /**
     * @param {EmbedData} data - embed data
     * @param {RegExp} [data.regex] - pattern of source URLs
     * @param {string} [data.embedUrl] - URL scheme to embedded page. Use '<%= remote_id %>' to define a place to insert resource id
     * @param {string} [data.html] - iframe which contains embedded content
     * @param {number} [data.height] - iframe height
     * @param {number} [data.width] - iframe width
     * @param {string} [data.caption] - caption
     */
    set data(data: EmbedData);
    /**
     * @returns {EmbedData}
     */
    get data(): EmbedData;
    /**
     * Get plugin styles
     *
     * @returns {object}
     */
    get CSS(): CSS;
    /**
     * Render Embed tool content
     *
     * @returns {HTMLElement}
     */
    render(): HTMLElement;
    /**
     * Creates preloader to append to container while data is loading
     *
     * @returns {HTMLElement}
     */
    createPreloader(): HTMLElement;
    /**
     * Save current content and return EmbedData object
     *
     * @returns {EmbedData}
     */
    save(): EmbedData;
    /**
     * Handle pasted url and return Service object
     *
     * @param {PasteEvent} event - event with pasted data
     */
    onPaste(event: {
        detail: PatternPasteEventDetail;
    }): void;
    /**
     * Analyze provided config and make object with services to use
     *
     * @param {EmbedConfig} config - configuration of embed block element
     */
    static prepare({ config }: {
        config: EmbedConfig;
    }): void;
    /**
     * Check if Service config is valid
     *
     * @param {Service} config - configuration of embed block element
     * @returns {boolean}
     */
    static checkServiceConfig(config: ServiceConfig): boolean;
    /**
     * Paste configuration to enable pasted URLs processing by Editor
     *
     * @returns {object} - object of patterns which contain regx for pasteConfig
     */
    static get pasteConfig(): {
        patterns: {
            [key: string]: RegExp;
        };
    };
    /**
     * Notify core that read-only mode is supported
     *
     * @returns {boolean}
     */
    static get isReadOnlySupported(): boolean;
    /**
     * Checks that mutations in DOM have finished after appending iframe content
     *
     * @param {HTMLElement} targetNode - HTML-element mutations of which to listen
     * @returns {Promise<any>} - result that all mutations have finished
     */
    embedIsReady(targetNode: HTMLElement): Promise<void>;
}
export {};
