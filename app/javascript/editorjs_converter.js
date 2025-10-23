// HTML to EditorJS JSON Converter
// Converts clean HTML content to EditorJS block format

export function htmlToEditorJS(html) {
  if (!html || typeof html !== 'string') {
    return {
      time: Date.now(),
      blocks: [],
      version: "2.8.1"
    };
  }

  // Create a temporary DOM element to parse HTML
  const parser = new DOMParser();
  const doc = parser.parseFromString(html, 'text/html');
  const body = doc.body;

  const blocks = [];
  let blockId = 0;

  // Helper to generate unique block IDs
  function generateBlockId() {
    blockId++;
    return `block_${blockId}_${Math.random().toString(36).substr(2, 9)}`;
  }

  // Process all child nodes
  function processNode(node) {
    // Skip text nodes that are just whitespace
    if (node.nodeType === Node.TEXT_NODE) {
      const text = node.textContent.trim();
      if (text) {
        // Add as paragraph if there's actual text
        blocks.push({
          id: generateBlockId(),
          type: "paragraph",
          data: {
            text: text
          }
        });
      }
      return;
    }

    // Process element nodes
    if (node.nodeType === Node.ELEMENT_NODE) {
      const tagName = node.tagName.toLowerCase();

      switch (tagName) {
        case 'h1':
        case 'h2':
        case 'h3':
        case 'h4':
        case 'h5':
        case 'h6':
          const level = parseInt(tagName.charAt(1));
          blocks.push({
            id: generateBlockId(),
            type: "header",
            data: {
              text: node.textContent.trim(),
              level: level
            }
          });
          break;

        case 'p':
          const paragraphText = node.textContent.trim();
          if (paragraphText) {
            blocks.push({
              id: generateBlockId(),
              type: "paragraph",
              data: {
                text: paragraphText
              }
            });
          }
          break;

        case 'ul':
        case 'ol':
          const listItems = Array.from(node.querySelectorAll('li')).map(li => li.textContent.trim()).filter(text => text);
          if (listItems.length > 0) {
            blocks.push({
              id: generateBlockId(),
              type: "list",
              data: {
                style: tagName === 'ol' ? 'ordered' : 'unordered',
                items: listItems
              }
            });
          }
          break;

        case 'blockquote':
          const quoteText = node.querySelector('p')?.textContent.trim() || node.textContent.trim();
          const citation = node.querySelector('cite')?.textContent.trim();
          if (quoteText) {
            blocks.push({
              id: generateBlockId(),
              type: "quote",
              data: {
                text: quoteText,
                caption: citation || ''
              }
            });
          }
          break;

        case 'pre':
          const codeText = node.textContent.trim();
          if (codeText) {
            blocks.push({
              id: generateBlockId(),
              type: "code",
              data: {
                code: codeText
              }
            });
          }
          break;

        case 'hr':
          blocks.push({
            id: generateBlockId(),
            type: "delimiter",
            data: {}
          });
          break;

        case 'table':
          const rows = Array.from(node.querySelectorAll('tr'));
          const content = rows.map(row => 
            Array.from(row.querySelectorAll('td, th')).map(cell => cell.textContent.trim())
          );
          if (content.length > 0) {
            blocks.push({
              id: generateBlockId(),
              type: "table",
              data: {
                withHeadings: false,
                content: content
              }
            });
          }
          break;

        case 'div':
          // Check for warning-box class
          if (node.classList.contains('warning-box')) {
            const title = node.querySelector('strong')?.textContent.trim() || '';
            const message = node.querySelector('p')?.textContent.trim() || '';
            if (title || message) {
              blocks.push({
                id: generateBlockId(),
                type: "warning",
                data: {
                  title: title,
                  message: message
                }
              });
            }
          } else {
            // Recursively process children
            Array.from(node.childNodes).forEach(child => processNode(child));
          }
          break;

        case 'ul':
          // Check for checklist class
          if (node.classList.contains('checklist')) {
            const items = Array.from(node.querySelectorAll('li')).map(li => ({
              text: li.textContent.trim().replace(/^[✓✔✗✘]\s*/, ''), // Remove checkbox symbols
              checked: li.querySelector('input[type="checkbox"]')?.checked || false
            })).filter(item => item.text);
            if (items.length > 0) {
              blocks.push({
                id: generateBlockId(),
                type: "checklist",
                data: {
                  items: items
                }
              });
            }
          }
          break;

        default:
          // For other elements, recursively process children
          Array.from(node.childNodes).forEach(child => processNode(child));
          break;
      }
    }
  }

  // Process all direct children of body
  Array.from(body.childNodes).forEach(node => processNode(node));

  // If no blocks were created, create an empty paragraph
  if (blocks.length === 0) {
    blocks.push({
      id: generateBlockId(),
      type: "paragraph",
      data: {
        text: ""
      }
    });
  }

  return {
    time: Date.now(),
    blocks: blocks,
    version: "2.8.1"
  };
}


