import { application } from "controllers/application"

// Auto-load everything under controllers/
// Using import.meta.glob with proper error handling
try {
  const modules = import.meta.glob("./**/*_controller.js", { eager: true })
  for (const path in modules) {
    const controller = modules[path].default
    if (controller && controller.identifier) {
      application.register(controller.identifier, controller)
    }
  }
} catch (error) {
  console.warn("import.meta.glob not supported, controllers will be loaded individually")
}
