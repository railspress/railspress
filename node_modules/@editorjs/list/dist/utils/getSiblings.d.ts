/**
 * Get all siblings before passed element, or after it
 * @param element - html element whose siblings would be returned
 * @param direction - wherever siblings would be returned, after element of before it
 */
export declare function getSiblings(element: HTMLElement, direction?: 'after' | 'before'): Element[] | null;
