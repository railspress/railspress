import { OrderedListItemMeta } from '../types/ItemMeta';
import { ListConfig } from '../types/ListParams';
import { ListRendererInterface } from './ListRenderer';

/**
 * Class that is responsible for ordered list rendering
 */
export declare class OrderedListRenderer implements ListRendererInterface<OrderedListItemMeta> {
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
     * @returns - created html ol element
     */
    renderWrapper(isRoot: boolean): HTMLOListElement;
    /**
     * Redners list item element
     * @param content - content used in list item rendering
     * @param _meta - meta of the list item unused in rendering of the ordered list
     * @returns - created html list item element
     */
    renderItem(content: string, _meta: OrderedListItemMeta): HTMLLIElement;
    /**
     * Return the item content
     * @param item - item wrapper (<li>)
     * @returns - item content string
     */
    getItemContent(item: Element): string;
    /**
     * Returns item meta, for ordered list
     * @returns item meta object
     */
    getItemMeta(): OrderedListItemMeta;
    /**
     * Returns default item meta used on creation of the new item
     */
    composeDefaultMeta(): OrderedListItemMeta;
}
