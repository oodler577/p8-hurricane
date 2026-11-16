%import textio
%import chart
%import storage
%zeropage basicsafe
%memtop $5c00
main {
    sub start() {
        chart.init()
        if storage.load("hf.gilbert") {
            chart.draw(1)
            @($02fe)=$a5
        }
finished:
        repeat { }
    }
}
