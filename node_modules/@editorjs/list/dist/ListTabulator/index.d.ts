import { ListData } from '../types/ListParams';
import { ItemChildWrapperElement } from '../types/Elements';
import { PasteEvent } from '../types';
import { PasteConfig } from '@editorjs/editorjs';
import { ListParams } from '..';
import { ListRenderer } from '../types/ListRenderer';
import { OlCounterType } from '../types/OlCounterType';

/**
 * Class that is responsible for list tabulation
 */
export default class ListTabulator<Renderer extends ListRenderer> {
    /**
     * The Editor.js API
     */
    private api;
    /**
     * Is Editorjs List Tool read-only option
     */
    private readOnly;
    /**
     * Tool's configuration
     */
    private config?;
    /**
     * Full content of the list
     */
    private data;
    /**
     * Editor block api
     */
    private block;
    /**
     * Rendered list of items
     */
    private renderer;
    /**
     * Wrapper of the whole list
     */
    private listWrapper;
    /**
     * Getter method to get current item
     * @returns current list item or null if caret position is not undefined
     */
    private get currentItem();
    /**
     * Method that returns nesting level of the current item, null if there is no selection
     */
    private get currentItemLevel();
    /**
     * Assign all passed params and renderer to relevant class properties
     * @param params - tool constructor options
     * @param params.data - previously saved data
     * @param params.config - user config for Tool
     * @param params.api - Editor.js API
     * @param params.readOnly - read-only mode flag
     * @param renderer - renderer instance initialized in tool class
     */
    constructor({ data, config, api, readOnly, block }: ListParams, renderer: Renderer);
    /**
     * Function that is responsible for rendering list with contents
     * @returns Filled with content wrapper element of the list
     */
    render(): ItemChildWrapperElement;
    /**
     * Function that is responsible for list content saving
     * @param wrapper - optional argument wrapper
     * @returns whole list saved data if wrapper not passes, otherwise will return data of the passed wrapper
     */
    save(wrapper?: ItemChildWrapperElement): ListData;
    /**
     * On paste sanitzation config. Allow only tags that are allowed in the Tool.
     * @returns - config that determines tags supposted by paste handler
     * @todo - refactor and move to list instance
     */
    static get pasteConfig(): PasteConfig;
    /**
     * Method that specified hot to merge two List blocks.
     * Called by Editor.js by backspace at the beginning of the Block
     *
     * Content of the first item of the next List would be merged with deepest item in current list
     * Other items of the next List would be appended to the current list without any changes in nesting levels
     * @param data - data of the second list to be merged with current
     */
    merge(data: ListData): void;
    /**
     * On paste callback that is fired from Editor.
     * @param event - event with pasted data
     * @todo - refactor and move to list instance
     */
    onPaste(event: PasteEvent): void;
    /**
     * Handle UL, OL and LI tags paste and returns List data
     * @param element - html element that contains whole list
     * @todo - refactor and move to list instance
     */
    pasteHandler(element: PasteEvent['detail']['data']): ListData;
    /**
     * Changes ordered list start property value
     * @param index - new value of the start property
     */
    changeStartWith(index: number): void;
    /**
     * Changes ordered list counterType property value
     * @param counterType - new value of the counterType value
     */
    changeCounters(counterType: OlCounterType): void;
    /**
     * Handles Enter keypress
     * @param event - keydown
     */
    private enterPressed;
    /**
     * Handle backspace
     * @param event - keydown
     */
    private backspace;
    /**
     * Reduce indentation for current item
     * @param event - keydown
     */
    private shiftTab;
    /**
     * Decrease indentation of the passed item
     * @param item - list item to be unshifted
     */
    private unshiftItem;
    /**
     * Method that is used for list splitting and moving trailing items to the new separated list
     * @param item - current item html element
     */
    private splitList;
    /**
     * Method that is used for splitting item content and moving trailing content to the new sibling item
     * @param currentItem - current item html element
     */
    private splitItem;
    /**
     * Method that is used for merging current item with previous one
     * Content of the current item would be appended to the previous item
     * Current item children would not change nesting level
     * @param item - current item html element
     */
    private mergeItemWithPrevious;
    /**
     * Add indentation to current item
     * @param event - keydown
     */
    private addTab;
    /**
     * Convert current item to default block with passed index
     * @param newBloxkIndex - optional parameter represents index, where would be inseted default block
     * @param removeList - optional parameter, that represents condition, if List should be removed
     */
    private convertItemToDefaultBlock;
    /**
     * Convert first item of the list to default block
     * This method could be called when backspace button pressed at start of the first item of the list
     * First item of the list would be converted to the paragraph and first item children would be unshifted
     */
    private convertFirstItemToDefaultBlock;
    /**
     * Method that calls render function of the renderer with a necessary item meta cast
     * @param itemContent - content to be rendered in new item
     * @param meta - meta used in list item rendering
     * @returns html element of the rendered item
     */
    private renderItem;
    /**
     * Renders children list
     * @param items - list data used in item rendering
     * @param parentElement - where to append passed items
     */
    private appendItems;
}
