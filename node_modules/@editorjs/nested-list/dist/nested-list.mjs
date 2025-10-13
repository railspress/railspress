(function(){"use strict";try{if(typeof document<"u"){var e=document.createElement("style");e.appendChild(document.createTextNode('.cdx-nested-list{margin:0;padding:0;outline:none;counter-reset:item;list-style:none}.cdx-nested-list__item{line-height:1.6em;display:flex;margin:2px 0}.cdx-nested-list__item [contenteditable]{outline:none}.cdx-nested-list__item-body{flex-grow:2}.cdx-nested-list__item-content,.cdx-nested-list__item-children{flex-basis:100%}.cdx-nested-list__item-content{word-break:break-word;white-space:pre-wrap}.cdx-nested-list__item:before{counter-increment:item;margin-right:5px;white-space:nowrap}.cdx-nested-list--ordered>.cdx-nested-list__item:before{content:counters(item,".") ". "}.cdx-nested-list--unordered>.cdx-nested-list__item:before{content:"•"}.cdx-nested-list__settings{display:flex}.cdx-nested-list__settings .cdx-settings-button{width:50%}')),document.head.appendChild(e)}}catch(t){console.error("vite-plugin-css-injected-by-js",t)}})();
function c(d) {
  return d.nodeType === Node.ELEMENT_NODE;
}
function p(d, e = null, t) {
  const r = document.createElement(d);
  Array.isArray(e) ? r.classList.add(...e) : e && r.classList.add(e);
  for (const n in t)
    r[n] = t[n];
  return r;
}
function g(d) {
  const e = p("div");
  return e.appendChild(d), e.innerHTML;
}
function C(d) {
  let e;
  return d.nodeType !== Node.ELEMENT_NODE ? e = d.textContent : (e = d.innerHTML, e = e.replaceAll("<br>", "")), (e == null ? void 0 : e.trim().length) === 0;
}
class u {
  /**
   * Store internal properties
   */
  constructor() {
    this.savedFakeCaret = void 0;
  }
  /**
   * Saves caret position using hidden <span>
   *
   * @returns {void}
   */
  save() {
    const e = u.range, t = p("span");
    t.hidden = !0, e && (e.insertNode(t), this.savedFakeCaret = t);
  }
  /**
   * Restores the caret position saved by the save() method
   *
   * @returns {void}
   */
  restore() {
    if (!this.savedFakeCaret)
      return;
    const e = window.getSelection();
    if (!e)
      return;
    const t = new Range();
    t.setStartAfter(this.savedFakeCaret), t.setEndAfter(this.savedFakeCaret), e.removeAllRanges(), e.addRange(t), setTimeout(() => {
      var r;
      (r = this.savedFakeCaret) == null || r.remove();
    }, 150);
  }
  /**
   * Returns the first range
   *
   * @returns {Range|null}
   */
  static get range() {
    const e = window.getSelection();
    return e && e.rangeCount ? e.getRangeAt(0) : null;
  }
  /**
   * Extract content fragment from Caret position to the end of contenteditable element
   *
   * @returns {DocumentFragment|void}
   */
  static extractFragmentFromCaretPositionTillTheEnd() {
    const e = window.getSelection();
    if (!e || !e.rangeCount)
      return;
    const t = e.getRangeAt(0);
    let r = t.startContainer;
    if (r.nodeType !== Node.ELEMENT_NODE) {
      if (!r.parentNode)
        return;
      r = r.parentNode;
    }
    if (!c(r))
      return;
    const n = r.closest("[contenteditable]");
    if (!n)
      return;
    t.deleteContents();
    const s = t.cloneRange();
    return s.selectNodeContents(n), s.setStart(t.endContainer, t.endOffset), s.extractContents();
  }
  /**
   * Set focus to contenteditable or native input element
   *
   * @param {HTMLElement} element - element where to set focus
   * @param {boolean} atStart - where to set focus: at the start or at the end
   * @returns {void}
   */
  static focus(e, t = !0) {
    const r = document.createRange(), n = window.getSelection();
    n && (r.selectNodeContents(e), r.collapse(t), n.removeAllRanges(), n.addRange(r));
  }
  /**
   * Check if the caret placed at the start of the contenteditable element
   *
   * @returns {boolean}
   */
  static isAtStart() {
    const e = window.getSelection();
    if (!e || e.focusOffset > 0)
      return !1;
    const t = e.focusNode;
    return !t || !c(t) ? !1 : u.getHigherLevelSiblings(t, "left").every((s) => C(s));
  }
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
  static getHigherLevelSiblings(e, t = "left") {
    let r = e;
    const n = [];
    for (; r.parentNode && r.parentNode.contentEditable !== "true"; )
      r = r.parentNode;
    const s = t === "left" ? "previousSibling" : "nextSibling";
    for (; r[s]; )
      r = r[s], n.push(r);
    return n;
  }
}
const w = '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="none" viewBox="0 0 24 24"><line x1="9" x2="19" y1="7" y2="7" stroke="currentColor" stroke-linecap="round" stroke-width="2"/><line x1="9" x2="19" y1="12" y2="12" stroke="currentColor" stroke-linecap="round" stroke-width="2"/><line x1="9" x2="19" y1="17" y2="17" stroke="currentColor" stroke-linecap="round" stroke-width="2"/><path stroke="currentColor" stroke-linecap="round" stroke-width="2" d="M5.00001 17H4.99002"/><path stroke="currentColor" stroke-linecap="round" stroke-width="2" d="M5.00001 12H4.99002"/><path stroke="currentColor" stroke-linecap="round" stroke-width="2" d="M5.00001 7H4.99002"/></svg>', S = '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="none" viewBox="0 0 24 24"><line x1="12" x2="19" y1="7" y2="7" stroke="currentColor" stroke-linecap="round" stroke-width="2"/><line x1="12" x2="19" y1="12" y2="12" stroke="currentColor" stroke-linecap="round" stroke-width="2"/><line x1="12" x2="19" y1="17" y2="17" stroke="currentColor" stroke-linecap="round" stroke-width="2"/><path stroke="currentColor" stroke-linecap="round" stroke-width="2" d="M7.79999 14L7.79999 7.2135C7.79999 7.12872 7.7011 7.0824 7.63597 7.13668L4.79999 9.5"/></svg>';
class f {
  /**
   * Notify core that read-only mode is supported
   *
   * @returns {boolean}
   */
  static get isReadOnlySupported() {
    return !0;
  }
  /**
   * Allow to use native Enter behaviour
   *
   * @returns {boolean}
   * @public
   */
  static get enableLineBreaks() {
    return !0;
  }
  /**
   * Get Tool toolbox settings
   * icon - Tool icon's SVG
   * title - title to show in toolbox
   *
   * @returns {ToolboxConfig}
   */
  static get toolbox() {
    return {
      icon: S,
      title: "List"
    };
  }
  /**
   * Render plugin`s main Element and fill it with saved data
   *
   * @param {object} params - tool constructor options
   * @param {ListData} params.data - previously saved data
   * @param {object} params.config - user config for Tool
   * @param {object} params.api - Editor.js API
   * @param {boolean} params.readOnly - read-only mode flag
   */
  constructor({ data: e, config: t, api: r, readOnly: n }) {
    var i;
    this.nodes = {
      wrapper: null
    }, this.api = r, this.readOnly = n, this.config = t, this.defaultListStyle = ((i = this.config) == null ? void 0 : i.defaultStyle) === "ordered" ? "ordered" : "unordered";
    const s = {
      style: this.defaultListStyle,
      items: []
    };
    this.data = e && Object.keys(e).length ? e : s, this.caret = new u();
  }
  /**
   * Returns list tag with items
   *
   * @returns {Element}
   * @public
   */
  render() {
    return this.nodes.wrapper = this.makeListWrapper(this.data.style, [
      this.CSS.baseBlock
    ]), this.data.items.length ? this.appendItems(this.data.items, this.nodes.wrapper) : this.appendItems(
      [
        {
          content: "",
          items: []
        }
      ],
      this.nodes.wrapper
    ), this.readOnly || this.nodes.wrapper.addEventListener(
      "keydown",
      (e) => {
        switch (e.key) {
          case "Enter":
            this.enterPressed(e);
            break;
          case "Backspace":
            this.backspace(e);
            break;
          case "Tab":
            e.shiftKey ? this.shiftTab(e) : this.addTab(e);
            break;
        }
      },
      !1
    ), this.nodes.wrapper;
  }
  /**
   * Creates Block Tune allowing to change the list style
   *
   * @public
   * @returns {Array}
   */
  renderSettings() {
    return [
      {
        name: "unordered",
        label: this.api.i18n.t("Unordered"),
        icon: w
      },
      {
        name: "ordered",
        label: this.api.i18n.t("Ordered"),
        icon: S
      }
    ].map((t) => ({
      name: t.name,
      icon: t.icon,
      label: t.label,
      isActive: this.data.style === t.name,
      closeOnActivate: !0,
      onActivate: () => {
        this.listStyle = t.name;
      }
    }));
  }
  /**
   * On paste sanitzation config. Allow only tags that are allowed in the Tool.
   *
   * @returns {PasteConfig} - paste config.
   */
  static get pasteConfig() {
    return {
      tags: ["OL", "UL", "LI"]
    };
  }
  /**
   * On paste callback that is fired from Editor.
   *
   * @param {PasteEvent} event - event with pasted data
   */
  onPaste(e) {
    const t = e.detail.data;
    this.data = this.pasteHandler(t);
    const r = this.nodes.wrapper;
    r && r.parentNode && r.parentNode.replaceChild(this.render(), r);
  }
  /**
   * Handle UL, OL and LI tags paste and returns List data
   *
   * @param {HTMLUListElement|HTMLOListElement|HTMLLIElement} element
   * @returns {ListData}
   */
  pasteHandler(e) {
    const { tagName: t } = e;
    let r = "unordered", n;
    switch (t) {
      case "OL":
        r = "ordered", n = "ol";
        break;
      case "UL":
      case "LI":
        r = "unordered", n = "ul";
    }
    const s = {
      style: r,
      items: []
    }, i = (l) => Array.from(l.querySelectorAll(":scope > li")).map((o) => {
      var m;
      const a = o.querySelector(`:scope > ${n}`), y = a ? i(a) : [];
      return {
        content: ((m = o == null ? void 0 : o.firstChild) == null ? void 0 : m.textContent) || "",
        items: y
      };
    });
    return s.items = i(e), s;
  }
  /**
   * Renders children list
   *
   * @param {ListItem[]} items - items data to append
   * @param {Element} parentItem - where to append
   * @returns {void}
   */
  appendItems(e, t) {
    e.forEach((r) => {
      const n = this.createItem(r.content, r.items);
      t.appendChild(n);
    });
  }
  /**
   * Renders the single item
   *
   * @param {string} content - item content to render
   * @param {ListItem[]} [items] - children
   * @returns {Element}
   */
  createItem(e, t = []) {
    const r = p("li", this.CSS.item), n = p("div", this.CSS.itemBody), s = p("div", this.CSS.itemContent, {
      innerHTML: e,
      contentEditable: (!this.readOnly).toString()
    });
    return n.appendChild(s), r.appendChild(n), t && t.length > 0 && this.addChildrenList(r, t), r;
  }
  /**
   * Extracts tool's data from the DOM
   *
   * @returns {ListData}
   */
  save() {
    const e = (t) => Array.from(
      t.querySelectorAll(`:scope > .${this.CSS.item}`)
    ).map((n) => {
      const s = n.querySelector(`.${this.CSS.itemChildren}`), i = this.getItemContent(n), l = s ? e(s) : [];
      return {
        content: i,
        items: l
      };
    });
    return {
      style: this.data.style,
      items: this.nodes.wrapper ? e(this.nodes.wrapper) : []
    };
  }
  /**
   * Append children list to passed item
   *
   * @param {Element} parentItem - item that should contain passed sub-items
   * @param {ListItem[]} items - sub items to append
   */
  addChildrenList(e, t) {
    const r = e.querySelector(`.${this.CSS.itemBody}`), n = this.makeListWrapper(void 0, [
      this.CSS.itemChildren
    ]);
    this.appendItems(t, n), r && r.appendChild(n);
  }
  /**
   * Creates main <ul> or <ol> tag depended on style
   *
   * @param {string} [style] - 'ordered' or 'unordered'
   * @param {string[]} [classes] - additional classes to append
   * @returns {HTMLOListElement|HTMLUListElement}
   */
  makeListWrapper(e = this.listStyle, t = []) {
    const r = e === "ordered" ? "ol" : "ul", n = e === "ordered" ? this.CSS.wrapperOrdered : this.CSS.wrapperUnordered;
    return t.push(n), p(r, [this.CSS.wrapper, ...t]);
  }
  /**
   * Styles
   *
   * @returns {NestedListCssClasses} - CSS classes names by keys
   * @private
   */
  get CSS() {
    return {
      baseBlock: this.api.styles.block,
      wrapper: "cdx-nested-list",
      wrapperOrdered: "cdx-nested-list--ordered",
      wrapperUnordered: "cdx-nested-list--unordered",
      item: "cdx-nested-list__item",
      itemBody: "cdx-nested-list__item-body",
      itemContent: "cdx-nested-list__item-content",
      itemChildren: "cdx-nested-list__item-children",
      settingsWrapper: "cdx-nested-list__settings",
      settingsButton: this.api.styles.settingsButton,
      settingsButtonActive: this.api.styles.settingsButtonActive
    };
  }
  /**
   * Get list style name
   *
   * @returns {string}
   */
  get listStyle() {
    return this.data.style || this.defaultListStyle;
  }
  /**
   * Set list style
   *
   * @param {ListDataStyle} style - new style to set
   */
  set listStyle(e) {
    if (!this.nodes || !this.nodes.wrapper)
      return;
    const t = Array.from(
      this.nodes.wrapper.querySelectorAll(`.${this.CSS.wrapper}`)
    );
    t.push(this.nodes.wrapper), t.forEach((r) => {
      r.classList.toggle(this.CSS.wrapperUnordered, e === "unordered"), r.classList.toggle(this.CSS.wrapperOrdered, e === "ordered");
    }), this.data.style = e;
  }
  /**
   * Returns current List item by the caret position
   *
   * @returns {Element}
   */
  get currentItem() {
    const e = window.getSelection();
    if (!e)
      return null;
    let t = e.anchorNode;
    return !t || (c(t) || (t = t.parentNode), !t) || !c(t) ? null : t.closest(`.${this.CSS.item}`);
  }
  /**
   * Handles Enter keypress
   *
   * @param {KeyboardEvent} event - keydown
   * @returns {void}
   */
  enterPressed(e) {
    const t = this.currentItem;
    if (e.stopPropagation(), e.preventDefault(), e.isComposing)
      return;
    const r = t ? this.getItemContent(t).trim().length === 0 : !0, n = (t == null ? void 0 : t.parentNode) === this.nodes.wrapper, s = (t == null ? void 0 : t.nextElementSibling) === null;
    if (n && s && r) {
      this.getOutOfList();
      return;
    } else if (s && r) {
      this.unshiftItem();
      return;
    }
    const i = u.extractFragmentFromCaretPositionTillTheEnd();
    if (!i)
      return;
    const l = g(i), h = t == null ? void 0 : t.querySelector(
      `.${this.CSS.itemChildren}`
    ), o = this.createItem(l, void 0);
    h && Array.from(h.querySelectorAll(`.${this.CSS.item}`)).length > 0 ? h.prepend(o) : t == null || t.after(o), this.focusItem(o);
  }
  /**
   * Decrease indentation of the current item
   *
   * @returns {void}
   */
  unshiftItem() {
    const e = this.currentItem;
    if (!e || !e.parentNode || !c(e.parentNode))
      return;
    const t = e.parentNode.closest(`.${this.CSS.item}`);
    if (!t)
      return;
    this.caret.save(), t.after(e), this.caret.restore();
    const r = t.querySelector(
      `.${this.CSS.itemChildren}`
    );
    if (!r)
      return;
    r.children.length === 0 && r.remove();
  }
  /**
   * Return the item content
   *
   * @param {Element} item - item wrapper (<li>)
   * @returns {string}
   */
  getItemContent(e) {
    const t = e.querySelector(`.${this.CSS.itemContent}`);
    return !t || C(t) ? "" : t.innerHTML;
  }
  /**
   * Sets focus to the item's content
   *
   * @param {Element} item - item (<li>) to select
   * @param {boolean} atStart - where to set focus: at the start or at the end
   * @returns {void}
   */
  focusItem(e, t = !0) {
    const r = e.querySelector(
      `.${this.CSS.itemContent}`
    );
    r && u.focus(r, t);
  }
  /**
   * Get out from List Tool by Enter on the empty last item
   *
   * @returns {void}
   */
  getOutOfList() {
    var e;
    (e = this.currentItem) == null || e.remove(), this.api.blocks.insert(), this.api.caret.setToBlock(this.api.blocks.getCurrentBlockIndex());
  }
  /**
   * Handle backspace
   *
   * @param {KeyboardEvent} event - keydown
   */
  backspace(e) {
    if (!u.isAtStart())
      return;
    e.preventDefault();
    const t = this.currentItem;
    if (!t)
      return;
    const r = t.previousSibling;
    if (!t.parentNode || !c(t.parentNode))
      return;
    const n = t.parentNode.closest(`.${this.CSS.item}`);
    if (!r && !n || r && !c(r))
      return;
    e.stopPropagation();
    let s;
    if (r) {
      const a = r.querySelectorAll(
        `.${this.CSS.item}`
      );
      s = Array.from(a).pop() || r;
    } else
      s = n;
    const i = u.extractFragmentFromCaretPositionTillTheEnd();
    if (!i)
      return;
    const l = g(i);
    if (!s)
      return;
    const h = s.querySelector(
      `.${this.CSS.itemContent}`
    );
    if (!h)
      return;
    u.focus(h, !1), this.caret.save(), h.insertAdjacentHTML("beforeend", l);
    let o = t.querySelectorAll(
      `.${this.CSS.itemChildren} > .${this.CSS.item}`
    );
    o = Array.from(o), o = o.filter((a) => !a.parentNode || !c(a.parentNode) ? !1 : a.parentNode.closest(`.${this.CSS.item}`) === t), o.reverse().forEach((a) => {
      r ? s.after(a) : t.after(a);
    }), t.remove(), this.caret.restore();
  }
  /**
   * Add indentation to current item
   *
   * @param {KeyboardEvent} event - keydown
   */
  addTab(e) {
    e.stopPropagation(), e.preventDefault();
    const t = this.currentItem;
    if (!t)
      return;
    const r = t.previousSibling;
    if (!r || !c(r) || !r)
      return;
    const s = r.querySelector(
      `.${this.CSS.itemChildren}`
    );
    if (this.caret.save(), s)
      s.appendChild(t);
    else {
      const i = this.makeListWrapper(void 0, [
        this.CSS.itemChildren
      ]), l = r.querySelector(`.${this.CSS.itemBody}`);
      i.appendChild(t), l == null || l.appendChild(i);
    }
    this.caret.restore();
  }
  /**
   * Reduce indentation for current item
   *
   * @param {KeyboardEvent} event - keydown
   * @returns {void}
   */
  shiftTab(e) {
    e.stopPropagation(), e.preventDefault(), this.unshiftItem();
  }
  /**
   * Convert from list to text for conversionConfig
   *
   * @param {ListData} data
   * @returns {string}
   */
  static joinRecursive(e) {
    return e.items.map((t) => `${t.content} ${f.joinRecursive(t)}`).join("");
  }
  /**
   * Convert from text to list with import and export list to text
   */
  static get conversionConfig() {
    return {
      export: (e) => f.joinRecursive(e),
      import: (e) => ({
        items: [
          {
            content: e,
            items: []
          }
        ],
        style: "unordered"
      })
    };
  }
}
export {
  f as default
};
