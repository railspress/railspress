import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="ckeditor"
export default class extends Controller {
  static targets = ["editor", "input"]

  connect() {
    console.log("CKEditor connecting...")
    
    if (!window.ClassicEditor) {
      this.loadCKEditor().then(() => {
        this.initializeEditor()
      })
    } else {
      this.initializeEditor()
    }
  }

  disconnect() {
    if (this.editor) {
      this.editor.destroy().catch(error => {
        console.error("Error destroying CKEditor:", error)
      })
    }
  }

  async loadCKEditor() {
    return new Promise((resolve, reject) => {
      if (window.ClassicEditor) {
        resolve()
        return
      }
      
      const script = document.createElement('script')
      script.src = 'https://cdn.ckeditor.com/ckeditor5/40.1.0/classic/ckeditor.js'
      script.onload = resolve
      script.onerror = reject
      document.head.appendChild(script)
    })
  }

  async initializeEditor() {
    try {
      const initialData = this.inputTarget.value || '<p>Start writing...</p>'
      
      this.editor = await ClassicEditor.create(this.editorTarget, {
        initialData: initialData,
        toolbar: {
          items: [
            'heading', '|',
            'bold', 'italic', 'underline', 'strikethrough', '|',
            'link', 'bulletedList', 'numberedList', '|',
            'blockQuote', 'insertTable', '|',
            'undo', 'redo'
          ]
        },
        heading: {
          options: [
            { model: 'paragraph', title: 'Paragraph', class: 'ck-heading_paragraph' },
            { model: 'heading1', view: 'h1', title: 'Heading 1', class: 'ck-heading_heading1' },
            { model: 'heading2', view: 'h2', title: 'Heading 2', class: 'ck-heading_heading2' },
            { model: 'heading3', view: 'h3', title: 'Heading 3', class: 'ck-heading_heading3' }
          ]
        }
      })

      // Update hidden input when content changes
      this.editor.model.document.on('change:data', () => {
        this.inputTarget.value = this.editor.getData()
      })

      console.log("CKEditor initialized successfully")
    } catch (error) {
      console.error("Error initializing CKEditor:", error)
      // Fallback to contenteditable
      this.editorTarget.contentEditable = true
      this.editorTarget.className = 'min-h-[400px] p-4 border rounded focus:outline-none'
      this.editorTarget.innerHTML = this.inputTarget.value || '<p>Start writing...</p>'
      
      this.editorTarget.addEventListener('input', () => {
        this.inputTarget.value = this.editorTarget.innerHTML
      })
    }
  }
}








