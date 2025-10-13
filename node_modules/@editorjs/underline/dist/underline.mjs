(function(){"use strict";try{if(typeof document<"u"){var e=document.createElement("style");e.appendChild(document.createTextNode(".cdx-underline{text-decoration:underline}")),document.head.appendChild(e)}}catch(n){console.error("vite-plugin-css-injected-by-js",n)}})();
const r = '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="none" viewBox="0 0 24 24"><path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 7.5V11.5C9 12.2956 9.31607 13.0587 9.87868 13.6213C10.4413 14.1839 11.2044 14.5 12 14.5C12.7956 14.5 13.5587 14.1839 14.1213 13.6213C14.6839 13.0587 15 12.2956 15 11.5V7.5"/><path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7.71429 18H16.2857"/></svg>', s = class s {
  /**
   * @param options InlineToolConstructorOptions
   */
  constructor(e) {
    this.tag = "U", this.api = e.api, this.iconClasses = {
      base: this.api.styles.inlineToolButton,
      active: this.api.styles.inlineToolButtonActive
    };
  }
  /**
   * Class name for term-tag
   *
   * @type {string}
   */
  static get CSS() {
    return "cdx-underline";
  }
  /**
   * Create button element for Toolbar
   *
   * @returns {HTMLElement}
   */
  render() {
    return this.button = document.createElement("button"), this.button.type = "button", this.button.classList.add(this.iconClasses.base), this.button.innerHTML = this.toolboxIcon, this.button;
  }
  /**
   * Wrap/Unwrap selected fragment
   *
   * @param {Range} range - selected fragment
   */
  surround(e) {
    if (!e)
      return;
    const t = this.api.selection.findParentTag(this.tag, s.CSS);
    t ? this.unwrap(t) : this.wrap(e);
  }
  /**
   * Wrap selection with term-tag
   *
   * @param {Range} range - selected fragment
   */
  wrap(e) {
    const t = document.createElement(this.tag);
    t.classList.add(s.CSS), t.appendChild(e.extractContents()), e.insertNode(t), this.api.selection.expandToTag(t);
  }
  /**
   * Unwrap term-tag
   *
   * @param {HTMLElement} termWrapper - term wrapper tag
   */
  unwrap(e) {
    var o;
    this.api.selection.expandToTag(e);
    const t = window.getSelection();
    if (!t)
      return;
    const n = t.getRangeAt(0);
    if (!n)
      return;
    const i = n.extractContents();
    i && ((o = e.parentNode) == null || o.removeChild(e), n.insertNode(i), t.removeAllRanges(), t.addRange(n));
  }
  /**
   * Check and change Term's state for current selection
   */
  checkState() {
    var t;
    const e = this.api.selection.findParentTag(this.tag, s.CSS);
    return (t = this.button) == null || t.classList.toggle(this.iconClasses.active, !!e), !!e;
  }
  /**
   * Get Tool icon's SVG
   *
   * @returns {string}
   */
  get toolboxIcon() {
    return r;
  }
  /**
   * Sanitizer rule
   *
   * @returns {{u: {class: string}}}
   */
  static get sanitize() {
    return {
      u: {
        class: s.CSS
      }
    };
  }
};
s.isInline = !0;
let a = s;
export {
  a as default
};
