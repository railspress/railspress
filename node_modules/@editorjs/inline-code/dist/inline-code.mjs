(function(){"use strict";try{if(typeof document<"u"){var e=document.createElement("style");e.appendChild(document.createTextNode(".inline-code{background:rgba(250,239,240,.78);color:#b44437;padding:3px 4px;border-radius:5px;margin:0 1px;font-family:inherit;font-size:.86em;font-weight:500;letter-spacing:.3px}")),document.head.appendChild(e)}}catch(n){console.error("vite-plugin-css-injected-by-js",n)}})();
const a = '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="none" viewBox="0 0 24 24"><path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 8L5 12L9 16"/><path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 8L19 12L15 16"/></svg>';
class s {
  constructor({ api: t }) {
    this.tag = "CODE", this.api = t, this.button = null, this.iconClasses = {
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
    return "inline-code";
  }
  /**
   * Specifies Tool as Inline Toolbar Tool
   *
   * @return {boolean}
   */
  static get isInline() {
    return !0;
  }
  /**
   * Create button element for Toolbar
   *
   * @return {HTMLElement}
   */
  render() {
    return this.button = document.createElement("button"), this.button.type = "button", this.button.classList.add(this.iconClasses.base), this.button.innerHTML = this.toolboxIcon, this.button;
  }
  /**
   * Wrap/Unwrap selected fragment
   *
   * @param {Range} range - selected fragment
   */
  surround(t) {
    var n;
    if (!t)
      return;
    let e = this.api.selection.findParentTag(this.tag, s.CSS);
    e ? this.unwrap(e) : (n = t.commonAncestorContainer.parentElement) != null && n.querySelector(this.tag) || this.wrap(t);
  }
  /**
  * Wrap selection with term-tag
  *
  * @param {Range} range - selected fragment
  */
  wrap(t) {
    let e = document.createElement(this.tag);
    e.classList.add(s.CSS), e.appendChild(t.extractContents()), t.insertNode(e), this.api.selection.expandToTag(e);
  }
  /**
   * Unwrap term-tag
   *
   * @param {HTMLElement} termWrapper - term wrapper tag
   */
  unwrap(t) {
    var o;
    this.api.selection.expandToTag(t);
    const e = window.getSelection();
    if (!e)
      return;
    const n = e.getRangeAt(0), i = n.extractContents();
    (o = t.parentNode) == null || o.removeChild(t), n.insertNode(i), e.removeAllRanges(), e.addRange(n);
  }
  /**
   * Check and change Term's state for current selection
   * 
   * @return {boolean}
   */
  checkState() {
    const t = this.api.selection.findParentTag(this.tag, s.CSS);
    return this.button && this.button.classList.toggle(this.iconClasses.active, !!t), !!t;
  }
  /**
   * Get Tool icon's SVG
   * @return {string}
   */
  get toolboxIcon() {
    return a;
  }
  /**
   * Sanitizer rule
   * @return {SanitizerConfig}
   */
  static get sanitize() {
    return {
      code: {
        class: s.CSS
      }
    };
  }
}
export {
  s as default
};
