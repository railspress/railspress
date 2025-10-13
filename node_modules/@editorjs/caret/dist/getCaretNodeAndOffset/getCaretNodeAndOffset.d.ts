/**
 * Returns TextNode containing a caret and a caret offset in it
 * Returns null if there is no caret set
 *
 * Handles a case when focusNode is an ElementNode and focusOffset is a child index,
 * returns child node with focusOffset index as a new focusNode
 */
export declare function getCaretNodeAndOffset(): [Node | null, number];
