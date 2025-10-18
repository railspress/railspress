import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="theme-toggle"
export default class extends Controller {
  connect() {
    // Check for saved theme preference or default to dark mode
    const savedTheme = localStorage.getItem('theme')
    if (savedTheme === 'light') {
      document.documentElement.classList.remove('dark')
    } else {
      // Default to dark mode (full black)
      document.documentElement.classList.add('dark')
    }
  }

  toggle() {
    const isDark = document.documentElement.classList.contains('dark')
    
    if (isDark) {
      // Switch to light mode
      document.documentElement.classList.remove('dark')
      localStorage.setItem('theme', 'light')
    } else {
      // Switch to dark mode
      document.documentElement.classList.add('dark')
      localStorage.setItem('theme', 'dark')
    }
  }
}
