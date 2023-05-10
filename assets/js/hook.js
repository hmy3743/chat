Hooks = {}

Hooks.InputCleanUp = {
    updated() {
        this.el.value = ""
    }
}

export default Hooks
