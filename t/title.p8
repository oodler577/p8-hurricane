%import chart
%zeropage basicsafe
%memtop $5c00
main {
    sub start() {
        chart.init()
        chart.title()
        @($02fe)=$a5
finished:
        repeat { }
    }
}
