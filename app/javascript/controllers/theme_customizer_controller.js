import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "templateSelect", "gjsContainer"
  ]

  connect() {
    console.log('Theme Customizer Controller connected')
    
    // Check if global data exists
    if (window.themeCustomizerData) {
      console.log('Global data found:', window.themeCustomizerData)
      this.themeSections = window.themeCustomizerData.themeSections || {}
      this.themeSettings = window.themeCustomizerData.themeSettings || []
      this.templateData = window.themeCustomizerData.templateData || {}
    } else {
      console.warn('No global themeCustomizerData found')
      // Set some default sections for testing
      this.themeSections = {
        'hero': { 'type': 'hero', 'name': 'Hero', 'schema': {} },
        'rich-text': { 'type': 'rich-text', 'name': 'Rich Text', 'schema': {} },
        'post-list': { 'type': 'post-list', 'name': 'Post List', 'schema': {} }
      }
      this.themeSettings = []
      this.templateData = {}
    }
    
    console.log('Theme sections:', this.themeSections)
    console.log('Theme settings:', this.themeSettings)
    console.log('Template data:', this.templateData)
    
    this.currentTemplateType = 'index'
    this.editor = null
    
    // Initialize with a small delay to ensure DOM is ready
    setTimeout(() => {
      this.initializeGrapesJS()
      this.loadTemplateContent(this.currentTemplateType)
    }, 100)
  }

  disconnect() {
    if (this.editor) {
      this.editor.destroy()
    }
  }


  // Template selection
  templateChanged(event) {
    this.currentTemplateType = event.target.value
    this.loadTemplateContent(this.currentTemplateType)
  }



  // Preview template
  previewTemplate() {
    if (this.editor) {
      const html = this.editor.getHtml()
      const css = this.editor.getCss()
      
      // Open preview in new window
      const previewWindow = window.open('', '_blank')
      previewWindow.document.write(`
        <!DOCTYPE html>
        <html>
        <head>
          <title>Preview</title>
          <style>${css}</style>
        </head>
        <body>${html}</body>
        </html>
      `)
      previewWindow.document.close()
    }
  }

  // Save customization
  async saveCustomization() {
    if (!this.editor) return
    
    const components = this.editor.getComponents()
    const styles = this.editor.getCss()
    
    try {
      const response = await fetch('/admin/template_customizer/save', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({
          template_data: this.templateData,
          components: components,
          styles: styles,
          template_type: this.currentTemplateType
        })
      })
      
      const result = await response.json()
      if (result.success) {
        alert('Preview saved successfully!')
      } else {
        alert('Error saving preview: ' + result.errors.join(', '))
      }
    } catch (error) {
      console.error('Error saving customization:', error)
      alert('Error saving customization')
    }
  }

  // Publish customization
  async publishCustomization() {
    if (!this.editor) return
    
    const components = this.editor.getComponents()
    const styles = this.editor.getCss()
    
    try {
      const response = await fetch('/admin/template_customizer/publish', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({
          template_data: this.templateData,
          components: components,
          styles: styles,
          template_type: this.currentTemplateType
        })
      })
      
      const result = await response.json()
      if (result.success) {
        alert('Theme published successfully!')
      } else {
        alert('Error publishing theme: ' + result.errors.join(', '))
      }
    } catch (error) {
      console.error('Error publishing customization:', error)
      alert('Error publishing customization')
    }
  }

  // Go back to admin
  goBackToAdmin() {
    window.location.href = '/admin'
  }

  // Initialize GrapesJS
  initializeGrapesJS() {
    console.log('Starting GrapesJS initialization...')
    console.log('Container element:', this.gjsContainerTarget)
    
    // Check if GrapesJS is already loaded
    if (window.grapesjs) {
      console.log('GrapesJS already loaded, initializing...')
      this.initGrapesJSEditor()
    } else {
      console.log('Loading GrapesJS from CDN...')
      // Load GrapesJS from CDN
      const script = document.createElement('script')
      script.src = 'https://unpkg.com/grapesjs@0.21.8/dist/grapes.min.js'
      script.onload = () => {
        console.log('GrapesJS loaded from CDN')
        this.initGrapesJSEditor()
      }
      script.onerror = (error) => {
        console.error('Failed to load GrapesJS:', error)
      }
      document.head.appendChild(script)
    }
  }
  
  initGrapesJSEditor() {
    console.log('Initializing GrapesJS editor...')
    console.log('grapesjs object:', typeof grapesjs)
      
      this.editor = grapesjs.init({
        container: this.gjsContainerTarget,
        height: '100%',
        width: 'auto',
        storageManager: false,
        
        // Admin Onyx theme
        colorPrimary: '#6366f1',
        colorSecondary: '#000000',
        colorTertiary: '#111111',
        colorQuaternary: '#1a1a1a',
        
        // Canvas
        canvas: {
          styles: [
            'https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css'
          ],
          scripts: []
        },
        
        // Layer Manager - shows current page structure
        layerManager: {
          label: 'Layers'
        },
        
        // Style Manager - for CSS editing
        styleManager: {
          label: 'Styles'
        },
        
        // Trait Manager - for component settings
        traitManager: {
          label: 'Settings'
        },
        
        // Block Manager - for available theme sections
        blockManager: {
          label: 'Blocks'
        },
        
        // Device Manager
        deviceManager: {
          devices: [
            {
              name: 'Desktop',
              width: ''
            },
            {
              name: 'Tablet',
              width: '768px',
              widthMedia: '992px'
            },
            {
              name: 'Mobile',
              width: '320px',
              widthMedia: '768px'
            }
          ]
        },
        
        // Panels
        panels: {
          defaults: [
            {
              id: 'basic-actions',
              el: '.panel__basic-actions',
              buttons: [
                {
                  id: 'visibility',
                  active: true,
                  className: 'btn-toggle-borders',
                  label: '<svg style="width:16px;height:16px" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>',
                  command: 'sw-visibility'
                },
                {
                  id: 'export',
                  className: 'btn-open-export',
                  label: '<svg style="width:16px;height:16px" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>',
                  command: 'export-template',
                  context: 'export-template'
                },
                {
                  id: 'show-json',
                  className: 'btn-show-json',
                  label: '<svg style="width:16px;height:16px" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>',
                  context: 'show-json',
                  command(editor) {
                    editor.Modal.setTitle('Components JSON')
                      .setContent(`<textarea style="width:100%; height: 250px;">${JSON.stringify(editor.getComponents(), null, 2)}</textarea>`)
                      .open()
                  }
                }
              ]
            }
          ]
        }
      })
      
      // Add custom commands
      this.editor.Commands.add('export-template', {
        run(editor) {
          const html = editor.getHtml()
          const css = editor.getCss()
          const template = `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Exported Template</title>
  <style>${css}</style>
</head>
<body>${html}</body>
</html>`
          
          const blob = new Blob([template], { type: 'text/html' })
          const url = URL.createObjectURL(blob)
          const a = document.createElement('a')
          a.href = url
          a.download = 'template.html'
          a.click()
          URL.revokeObjectURL(url)
        }
      })

      // Populate Block Manager with available theme sections
      this.populateBlockManager()
      
      // Listen for component changes to update Layer Manager
      this.editor.on('component:update', () => {
        this.updateLayerManager()
      })
      
    console.log('GrapesJS initialized successfully!')
    console.log('Editor object:', this.editor)
    
    // Debug: Check if panels are loaded
    setTimeout(() => {
      console.log('Checking GrapesJS panels...')
      console.log('Block Manager:', this.editor.BlockManager)
      console.log('Layer Manager:', this.editor.LayerManager)
      console.log('Panels:', this.editor.Panels)
      console.log('Editor DOM:', this.editor.getContainer())
    }, 1000)
  }

  // Populate Block Manager with available theme sections
  populateBlockManager() {
    if (!this.editor) return

    const blockManager = this.editor.BlockManager
    
    console.log('Populating block manager with sections:', this.themeSections)
    
    // Check if themeSections is valid
    if (this.themeSections && typeof this.themeSections === 'object' && !Array.isArray(this.themeSections)) {
      try {
        // Add theme sections as blocks
        Object.keys(this.themeSections).forEach(sectionType => {
          const section = this.themeSections[sectionType]
          
          if (section && typeof section === 'object') {
            blockManager.add(sectionType, {
              label: section.name || sectionType.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase()),
              category: 'Theme Sections',
              content: this.generateSectionHTML(sectionType, section),
              attributes: {
                'data-section-type': sectionType,
                'data-section-id': sectionType + '_' + Date.now()
              }
            })
          }
        })
      } catch (error) {
        console.error('Error adding theme sections to block manager:', error)
      }
    } else {
      console.warn('Invalid themeSections:', this.themeSections)
    }
    
    // Add some basic blocks
    blockManager.add('text-block', {
      label: 'Text Block',
      category: 'Basic',
      content: '<div class="text-block"><p>Add your text here</p></div>',
      attributes: { class: 'gjs-block' }
    })
    
    blockManager.add('image-block', {
      label: 'Image',
      category: 'Basic', 
      content: '<div class="image-block"><img src="https://via.placeholder.com/300x200" alt="Image" /></div>',
      attributes: { class: 'gjs-block' }
    })
    
    blockManager.add('button-block', {
      label: 'Button',
      category: 'Basic',
      content: '<div class="button-block"><button class="btn">Click me</button></div>',
      attributes: { class: 'gjs-block' }
    })
    
    blockManager.add('hero-section', {
      label: 'Hero Section',
      category: 'Layout',
      content: `
        <section class="hero-section bg-gray-900 text-white py-20">
          <div class="container mx-auto px-4 text-center">
            <h1 class="text-4xl font-bold mb-4">Hero Title</h1>
            <p class="text-xl mb-8">Hero description goes here</p>
            <button class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
              Call to Action
            </button>
          </div>
        </section>
      `,
      attributes: { class: 'gjs-block' }
    })
  }

  // Generate HTML for a theme section
  generateSectionHTML(sectionType, section) {
    // Create a more realistic section structure based on common section types
    const sectionName = section.name || sectionType.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())
    
    switch(sectionType.toLowerCase()) {
      case 'hero':
        return `
          <section class="hero-section bg-gradient-to-r from-blue-600 to-purple-600 text-white py-20" data-section-type="${sectionType}">
            <div class="container mx-auto px-4 text-center">
              <h1 class="text-5xl font-bold mb-6">${sectionName}</h1>
              <p class="text-xl mb-8 max-w-2xl mx-auto">Add your hero content here</p>
              <button class="bg-white text-blue-600 font-bold py-3 px-8 rounded-lg hover:bg-gray-100 transition">
                Get Started
              </button>
            </div>
          </section>
        `
      case 'features':
        return `
          <section class="features-section py-16 bg-gray-50" data-section-type="${sectionType}">
            <div class="container mx-auto px-4">
              <h2 class="text-3xl font-bold text-center mb-12">${sectionName}</h2>
              <div class="grid md:grid-cols-3 gap-8">
                <div class="text-center">
                  <div class="w-16 h-16 bg-blue-600 rounded-full mx-auto mb-4"></div>
                  <h3 class="text-xl font-semibold mb-2">Feature 1</h3>
                  <p class="text-gray-600">Feature description goes here</p>
                </div>
                <div class="text-center">
                  <div class="w-16 h-16 bg-green-600 rounded-full mx-auto mb-4"></div>
                  <h3 class="text-xl font-semibold mb-2">Feature 2</h3>
                  <p class="text-gray-600">Feature description goes here</p>
                </div>
                <div class="text-center">
                  <div class="w-16 h-16 bg-purple-600 rounded-full mx-auto mb-4"></div>
                  <h3 class="text-xl font-semibold mb-2">Feature 3</h3>
                  <p class="text-gray-600">Feature description goes here</p>
                </div>
              </div>
            </div>
          </section>
        `
      case 'testimonials':
        return `
          <section class="testimonials-section py-16" data-section-type="${sectionType}">
            <div class="container mx-auto px-4">
              <h2 class="text-3xl font-bold text-center mb-12">${sectionName}</h2>
              <div class="max-w-3xl mx-auto text-center">
                <blockquote class="text-xl italic mb-6">
                  "This is a testimonial quote that will be replaced with real content."
                </blockquote>
                <cite class="text-gray-600">- Customer Name</cite>
              </div>
            </div>
          </section>
        `
      default:
        return `
          <section class="generic-section py-12" data-section-type="${sectionType}">
            <div class="container mx-auto px-4">
              <h2 class="text-2xl font-bold mb-4">${sectionName}</h2>
              <div class="prose max-w-none">
                <p>This is a ${sectionName.toLowerCase()} section. Content will be loaded from theme files.</p>
              </div>
            </div>
          </section>
        `
    }
  }

  // Update Layer Manager when components change
  updateLayerManager() {
    // The Layer Manager automatically updates when components change
    // We just need to make sure it's properly configured
    const layerManager = this.editor.LayerManager
    if (layerManager) {
      layerManager.render()
    }
  }

  // Load template content and update both managers
  async loadTemplateContent(templateType) {
    try {
      const response = await fetch(`/admin/template_customizer/load_content?template_type=${templateType}`)
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      
      const data = await response.json()
      
      console.log('Template data loaded:', data)
      
      // Update GrapesJS with new content
      if (this.editor) {
        this.editor.setComponents(data.html || '')
        this.editor.setStyle('')
        
        // Update Block Manager with available sections
        if (data.sections && typeof data.sections === 'object') {
          this.themeSections = data.sections
          this.populateBlockManager()
        } else {
          console.warn('Invalid sections data:', data.sections)
        }
      }
      
      // Store template data for saving
      this.templateData = data.template_data || {}
      this.themeSettings = data.settings || {}
      
    } catch (error) {
      console.error('Error loading template content:', error)
      console.error('Error details:', error.message)
    }
  }
}
