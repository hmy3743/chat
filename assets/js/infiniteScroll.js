export default InfiniteScroll = {
  mounted() {
    this.skeleton = document.getElementById("skeleton-card");
    this.observer = new IntersectionObserver(
      (entries) => {
        const target = entries[0];
        if (target.isIntersecting) {
          this.pushEvent("load-more", {});
        }
      },
      {
        root: null, // window by default
        rootMargin: "200px",
        threshold: 0.1,
      }
    );
    this.observer.observe(this.el);
  },
  updated() {
    this.skeleton.className = "";
  },
  destroyed() {
    this.observer.unobserve(this.el);
  },
};
