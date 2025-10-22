import { application } from "controllers/application"

// Import all controllers defined by importmap pins under "controllers/"
import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading"
lazyLoadControllersFrom("controllers", application)