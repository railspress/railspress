/**
 * Helper for working with caret
 */
export default class Caret {
    /**
     * The <span> for caret saving/restoring
     */
    savedFakeCaret: HTMLElement | undefined;
    /**
     * Store internal properties
     */
    constructor();
    /**
     * Saves caret position using hidden <span>
     *
     * @returns {void}
     */
    save(): void;
    /**
     * Restores the caret position saved by the save() method
     *
     * @returns {void}
     */
    restore(): void;
    /**
     * Returns the first range
     *
     * @returns {Range|null}
     */
    static get range(): Range | null;
    /**
     * Extract content fragment from Caret position to the end of contenteditable element
     *
     * @returns {DocumentFragment|void}
     */
    static extractFragmentFromCaretPositionTillTheEnd(): DocumentFragment | void;
    /**
     * Set focus to contenteditable or native input element
     *
     * @param {HTMLElement} element - element where to set focus
     * @param {boolean} atStart - where to set focus: at the start or at the end
     * @returns {void}
     */
    static focus(element: HTMLElement, atStart?: boolean): void;
    /**
     * Check if the caret placed at the start of the contenteditable element
     *
     * @returns {boolean}
     */
    static isAtStart(): boolean;
    /**
     * Get all first-level (first child of [contenteditabel]) siblings from passed node
     * Then you can check it for emptiness
     *
     * @example
     * <div contenteditable>
     * <p></p>                            |
     * <p></p>                            | left first-level siblings
     * <p></p>                            |
     * <blockquote><a><b>adaddad</b><a><blockquote>       <-- passed node for example <b>
     * <p></p>                            |
     * <p></p>                            | right first-level siblings
     * <p></p>                            |
     * </div>
     * @param {HTMLElement} from - element from which siblings should be searched
     * @param {'left' | 'right'} direction - direction of search
     * @returns {HTMLElement[]}
     */
    static getHigherLevelSiblings(from: HTMLElement, direction?: 'left' | 'right'): HTMLElement[];
}
