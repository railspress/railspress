/**
 * HtmlElement's attribute that can be set
 */
type HtmlElementAttributes = Partial<HTMLElement>;
/**
 * Helper for making Elements with attributes
 *
 * @param  {string} tagName           - new Element tag name
 * @param  {Array|string} classNames  - list or name of CSS classname(s)
 * @param  {object} attributes        - any attributes
 * @returns {Element}
 */
export declare function make(tagName: string, classNames?: string[] | string | null, attributes?: HtmlElementAttributes): HTMLElement;
/**
 * Returns the HTML content of passed Document Fragment
 *
 * @param {DocumentFragment} fragment - document fragment to process
 * @returns {string}
 */
export declare function fragmentToString(fragment: DocumentFragment): string;
/**
 * breadth-first search (BFS)
 * {@link https://en.wikipedia.org/wiki/Breadth-first_search}
 *
 * @description Pushes to stack all DOM leafs and checks for emptiness
 * @param {Node} node - node to check
 * @returns {boolean}
 */
export declare function isEmpty(node: Element): boolean;
export {};
