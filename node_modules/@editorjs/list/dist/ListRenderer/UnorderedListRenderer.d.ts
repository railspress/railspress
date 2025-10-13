import { UnorderedListItemMeta } from '../types/ItemMeta';
import { ListConfig } from '../types/ListParams';
import { ListRendererInterface } from './ListRenderer';

/**
 * Class that is responsible for unordered list rendering
 */
export declare class UnorderedListRenderer implements ListRendererInterface<UnorderedListItemMeta> {
    /**
     * Tool's configuration
     */
    protected config?: ListConfig;
    /**
     * Is Editorjs List Tool read-only option
     */
    private readOnly;
    /**
     * Getter for all CSS classes used in unordered list rendering
     */
    private static get CSS();
    /**
     * Assign passed readonly mode and config to relevant class properties
     * @param readonly - read-only mode flag
     * @param config - user config for Tool
     */
    constructor(readonly: boolean, config?: ListConfig);
    /**
     * Renders ol wrapper for list
     * @param isRoot - boolean variable that represents level of the wrappre (root or childList)
     * @returns - created html ul element
     */
    renderWrapper(isRoot: boolean): HTMLUListElement;
    /**
     * Redners list item element
     * @param content - content used in list item rendering
     * @param _meta - meta of the list item unused in rendering of the unordered list
     * @returns - created html list item element
     */
    renderItem(content: string, _meta: UnorderedListItemMeta): HTMLLIElement;
    /**
     * Return the item content
     * @param item - item wrapper (<li>)
     * @returns - item content string
     */
    getItemContent(item: Element): string;
    /**
     * Returns item meta, for unordered list
     * @returns Item meta object
     */
    getItemMeta(): UnorderedListItemMeta;
    /**
     * Returns default item meta used on creation of the new item
     */
    composeDefaultMeta(): UnorderedListItemMeta;
}
