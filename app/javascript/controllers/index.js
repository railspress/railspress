import { application } from "controllers/application"

// Import all controllers defined by importmap pins under "controllers/"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)