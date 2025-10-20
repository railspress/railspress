import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { name: String }

  connect() {
    console.log("Stimulus OK. Hello,", this.nameValue || "world")
  }
}
