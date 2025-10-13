/**
 * Returns slice of the contenteditable html element from caret position to the start or end (depending on direction)
 * @param contenteditable - The contenteditable element containing the nodes.
 * @param fromNode - The starting node to check from.
 * @param offsetInsideNode - The offset inside the starting node.
 * @param direction - The direction to check ('left' or 'right').
 * @param extract - should we remove from element extracted part
 * @returns true if adjacent content is empty, false otherwise.
 */
export declare function getContenteditableSlice(contenteditable: HTMLElement, fromNode: Node, offsetInsideNode: number, direction: 'left' | 'right', extract?: boolean): string;
