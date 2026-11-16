%import textio

; Shared credit for every platform's title/menu screen.
credits {
    str original_title = "skipper jim's hurricane tracking chart"
    str original_author = "james r. brown"

    sub show() {
        txt.print("based on the original c64 program:\n")
        txt.print(original_title)
        txt.print("\nby ")
        txt.print(original_author)
        txt.print("\n\n")
    }
}
