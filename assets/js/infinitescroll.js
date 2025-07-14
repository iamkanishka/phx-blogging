export default {
  mounted() {
    const page = parseInt(this.el.dataset.loadedPage)
    const total = parseInt(this.el.dataset.totalPages)

    if (page >= total) return // Already on last page

    const observer = new IntersectionObserver((entries, obs) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          this.pushEvent("load-more", {})
          obs.unobserve(this.el) // Remove the hook temporarily
        }
      })
    }, { threshold: 1.0 })

    observer.observe(this.el)
  }
};
