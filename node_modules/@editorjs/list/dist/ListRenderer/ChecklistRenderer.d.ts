import { ChecklistItemMeta } from '../types/ItemMeta';
import { ListConfig } from '../types/ListParams';
import { ListRendererInterface } from './ListRenderer';

/**
 * Class that is responsible for checklist rendering
 */
export declare class CheckListRenderer implements ListRendererInterface<ChecklistItemMeta> {
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
     * Renders ul wrapper for list
     * @param isRoot - boolean variable that represents level of the wrappre (root or childList)
     * @returns - created html ul element
     */
    renderWrapper(isRoot: boolean): HTMLUListElement;
    /**
     * Redners list item element
     * @param content - content used in list item rendering
     * @param meta - meta of the list item used in rendering of the checklist
     * @returns - created html list item element
     */
    renderItem(content: string, meta: ChecklistItemMeta): HTMLLIElement;
    /**
     * Return the item content
     * @param item - item wrapper (<li>)
     * @returns - item content string
     */
    getItemContent(item: Element): string;
    /**
     * Return meta object of certain element
     * @param item - will be returned meta information of this item
     * @returns Item meta object
     */
    getItemMeta(item: Element): ChecklistItemMeta;
    /**
     * Returns default item meta used on creation of the new item
     */
    composeDefaultMeta(): ChecklistItemMeta;
    /**
     * Toggle checklist item state
     * @param checkbox - checkbox element to be toggled
     */
    private toggleCheckbox;
    /**
     * Removes class responsible for special hover behavior on an item
     * @param el - item wrapper
     */
    private removeSpecialHoverBehavior;
}
