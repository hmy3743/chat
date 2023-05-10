import infiniteScroll from "./infiniteScroll";

Hooks = {};

Hooks.InputCleanUp = {
  updated() {
    this.el.value = "";
  },
};

Hooks.InfiniteScroll = infiniteScroll;

export default Hooks;
