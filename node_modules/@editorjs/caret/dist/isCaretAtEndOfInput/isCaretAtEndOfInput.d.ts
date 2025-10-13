/**
 * Checks if caret is at the end of the passed input
 *
 * Cases:
 * Native input:
 * - if offset is equal to value length, caret is at the end
 * Contenteditable:
 * - caret at the last text node and offset is equal to text length — caret is at the end
 * - caret not at the last text node — we need to check right siblings for emptiness
 * - caret offset < text length, but all right part is visible (nbsp) — caret is at the end
 * - caret offset < text length, but all right part is invisible (whitespaces) — caret is at the end
 * @param input - input where caret should be checked
 */
export declare function isCaretAtEndOfInput(input: HTMLElement): boolean;
