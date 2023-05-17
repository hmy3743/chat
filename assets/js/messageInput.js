const HardCodedDelay = 1_000;
const StartTyping = "start_typing";
const EndTyping = "end_typing";

export default MessageInput = {
  mounted() {
    const that = this;

    this.el.addEventListener(
      "keyup",
      ((delay) => {
        // closure
        let throttleStarted = false;
        let throttleTimer;
        let debounceStarted = false;
        let debounceTimer;

        return (_event) => {
          // throttle - start_typing
          if (throttleTimer === undefined) that.pushEvent(StartTyping);
          if (!throttleStarted) {
            throttleStarted = true;
            that.pushEvent(StartTyping);
            throttleTimer = setTimeout(() => {
              throttleStarted = false;
            }, delay);
          }

          // debounce - stop_typing
          if (debounceStarted) clearTimeout(debounceTimer);

          debounceStarted = true;
          debounceTimer = setTimeout(() => {
            debounceStarted = false;
            that.pushEvent(EndTyping);
          }, delay);
        };

        // delay for timeouts
      })(HardCodedDelay)
    );
  }
};
