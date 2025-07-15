export default {
   mounted() {
    console.log("✅ horizontalscroll hook mounted on", this.el.id)

    this.handleEvent("scroll_left", () => {
      console.log("⬅️ Scrolling left")
      this.el.scrollBy({ left: -150, behavior: "smooth" })
    })

    this.handleEvent("scroll_right", () => {
      console.log("➡️ Scrolling right")
      this.el.scrollBy({ left: 150, behavior: "smooth" })
    })
  }
}

 
