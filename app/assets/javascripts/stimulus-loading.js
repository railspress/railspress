// Stimulus Loading - Asset Pipeline Compatible
// This file ensures Stimulus is available for the asset pipeline

// Simple Stimulus loader for asset pipeline compatibility
window.Stimulus = window.Stimulus || {
  start: function() { return this; },
  register: function() { return this; },
  debug: false
};

// Make it globally available
if (typeof window !== 'undefined') {
  window.Stimulus = window.Stimulus;
}