export default InfiniteScroll = {
  mounted() {
    this.observer = new IntersectionObserver(
      (entries) => {
        console.log("zz");
        const target = entries[0];
        if (target.isIntersecting) {
          this.pushEvent("load-more", {});
        }
      },
      {
        root: null, // window by default
        rootMargin: "100px",
        threshold: 0.1,
      }
    );
    this.observer.observe(this.el);
  },
  destroyed() {
    this.observer.unobserve(this.el);
  },
};
