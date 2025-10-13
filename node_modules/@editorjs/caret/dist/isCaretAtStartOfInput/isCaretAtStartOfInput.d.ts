/**
 * Checks if caret is at the start of the passed input
 *
 * Cases:
 * Native input:
 * - if offset is 0, caret is at the start
 * Contenteditable:
 * - caret at the first text node and offset is 0 — caret is at the start
 * - caret not at the first text node — we need to check left siblings for emptiness
 * - caret offset > 0, but all left part is visible (nbsp) — caret is not at the start
 * - caret offset > 0, but all left part is invisible (whitespaces) — caret is at the start
 * @param input - input where caret should be checked
 */
export declare function isCaretAtStartOfInput(input: HTMLElement): boolean;
