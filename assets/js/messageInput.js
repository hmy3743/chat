const HardCodedDelay = 1_000;
const StartTyping = 'start_typing';
const EndTyping = 'end_typing';

const makeDebounceFunction = (handler, delay = 1000, binder = null) => {
  let timer = setTimeout(() => {}, 0);
  const bound = binder ? handler.bind(binder) : handler;
  return (event) =>
    clearTimeout(timer) ||
    ((timer = setTimeout(() => bound(event), delay)) && undefined);
};

const makeThrottleFunction = (handler, delay = 1000, binder = null) => {
  let ticking = false;
  const bound = binder ? handler : handler.bind(binder);
  return (event) =>
    ticking
      ? undefined
      : (ticking = true) &&
        setTimeout(() => (ticking = false) || bound(event), delay) &&
        undefined;
};

export default MessageInput = {
  mounted() {
    const that = this;

    const debounceHandler = makeDebounceFunction(
      (_event) => this.pushEvent(EndTyping),
      HardCodedDelay,
      that,
    );
    const throttleHandler = makeThrottleFunction(
      (_event) => this.pushEvent(StartTyping),
      HardCodedDelay,
      that,
    );

    this.el.addEventListener('input', throttleHandler);
    this.el.addEventListener('input', debounceHandler);
  },
};
