/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js',
    './app/assets/javascripts/**/*.js'
  ],
  darkMode: 'class', // Enable class-based dark mode
  theme: {
    extend: {},
  },
  plugins: [],
}
