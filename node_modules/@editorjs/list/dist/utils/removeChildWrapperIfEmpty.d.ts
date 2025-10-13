import { ItemChildWrapperElement, ItemElement } from '../types/Elements';

/**
 * Method that will remove passed child wrapper if it has no child items
 * @param element - child wrapper or actual item, from where we get child wrapper
 */
export declare function removeChildWrapperIfEmpty(element: ItemChildWrapperElement | ItemElement): void;
