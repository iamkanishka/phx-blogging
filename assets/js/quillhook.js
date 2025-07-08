

export default {
  mounted() {
    const toolbarOptions = [
      ["bold", "italic", "underline", "strike"],
      ["blockquote", "code-block"],
      [{ header: 1 }, { header: 2 }],
      [{ list: "ordered" }, { list: "bullet" }],
      [{ script: "sub" }, { script: "super" }],
      [{ indent: "-1" }, { indent: "+1" }],
      [{ direction: "rtl" }],
      [{ size: ["small", false, "large", "huge"] }],
      [{ header: [1, 2, 3, 4, 5, 6, false] }],
      [{ color: [] }, { background: [] }],
      [{ font: [] }],
      [{ align: [] }],
      ["clean"],
      ["link", "image", "video"],
    ];

    this.quill = new Quill(this.el, {
      theme: "snow",
      modules: {
        toolbar: toolbarOptions,
      },
      placeholder: "Write your post content here...",
    });

    // Set initial content
    const initialContent = this.el.dataset.content;
    if (initialContent) {
      this.quill.root.innerHTML = initialContent;
    }

    // Sync changes to hidden input and LiveView
    this.quill.on("text-change", () => {
      const html = this.quill.root.innerHTML;
      const text = this.quill.getText();

      // Update hidden input (for form submission)
      const hiddenInput = document.getElementById("quill_html_content");
      if (hiddenInput) {
        hiddenInput.value = html;
      }

      // Push to LiveView (optional)
      this.pushEventTo("#quill-editor", "quill-change", { html: html, text: text });
    });
  },

  updated() {
    const content = this.el.dataset.content;
    if (content && this.quill.root.innerHTML !== content) {
      this.quill.root.innerHTML = content;
    }
  }
};
