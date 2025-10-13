import { ItemChildWrapperElement, ItemElement } from '../types/Elements';

/**
 * Get child items of the passed element
 * @param element - child items would be got from this element
 * @param firstLevelChildren - if method should return all level child items or only first level ones
 */
export declare function getChildItems(element: ItemElement | ItemChildWrapperElement, firstLevelChildren?: boolean): ItemElement[];
