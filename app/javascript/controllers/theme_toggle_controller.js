import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="theme-toggle"
export default class extends Controller {
  static targets = ["moonIcon", "sunIcon"]

  connect() {
    // Initialize theme: default to dark unless user saved a preference
    const savedTheme = localStorage.getItem('theme')
    const shouldUseDark = savedTheme ? savedTheme === 'dark' : true

    document.documentElement.classList.toggle('dark', shouldUseDark)
    if (shouldUseDark) this.showDark(); else this.showLight()
    console.log('[theme-toggle] connected', { savedTheme, shouldUseDark, hasDarkClass: document.documentElement.classList.contains('dark') })
  }

  toggle() {
    const isDark = document.documentElement.classList.contains('dark')
    
    if (isDark) {
      // Switch to light mode
      document.documentElement.classList.remove('dark')
      localStorage.setItem('theme', 'light')
      this.showLight()
      console.log('[theme-toggle] toggled -> light', { saved: localStorage.getItem('theme'), hasDarkClass: document.documentElement.classList.contains('dark') })
    } else {
      // Switch to dark mode
      document.documentElement.classList.add('dark')
      localStorage.setItem('theme', 'dark')
      this.showDark()
      console.log('[theme-toggle] toggled -> dark', { saved: localStorage.getItem('theme'), hasDarkClass: document.documentElement.classList.contains('dark') })
    }
  }

  showLight() {
    const moon = this.element.querySelector('.theme-icon-moon')
    const sun = this.element.querySelector('.theme-icon-sun')
    if (moon) moon.style.display = 'block'
    if (sun) sun.style.display = 'none'
  }

  showDark() {
    const moon = this.element.querySelector('.theme-icon-moon')
    const sun = this.element.querySelector('.theme-icon-sun')
    if (moon) moon.style.display = 'none'
    if (sun) sun.style.display = 'block'
  }
}
