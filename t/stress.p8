%import model
%import storage
%import geo
%import chart
%import expected
%import report
%import conv
%import strings
%zeropage floatsafe
%memtop $5c00
main {
    sub start() {
        ubyte cycle
        ubyte i
        for cycle in 0 to 7 {
            storm.clear()
            for i in 0 to 127
                report.check(storm.add("07 pm 09 10 1988",i as uword,450+(i as uword)*5,50+(i as uword)*3))
            report.check(storm.count==128)
            report.check(not storm.add("07 pm 09 10 1988",80,665,157))
            for i in 0 to 127 {
                report.check(storm.longitude[i]==450+(i as uword)*5)
                report.check(storm.latitude[i]==50+(i as uword)*3)
                report.check(lsb(storm.wind[i])==i and msb(storm.wind[i])==0)
                report.check(strings.compare(storm.timestamp(i),"07 pm 09 10 1988")==0)
            }
        }
        str stamp="12 am 02 29 1800"
        uword year
        for year in 1800 to 2400 {
            void strings.copy(conv.str_uw(year), &stamp+12)
            uword bit=year-1800
            bool leap=(expected.leap_bits[lsb(bit/8)] & (1 << lsb(bit % 8)))!=0
            report.check(storm.valid_stamp(stamp)==leap)
        }
        str decimal=" " * 12
        uword value
        for value in 450 to 1100 {
            void strings.copy(conv.str_uw(value/10),decimal)
            void strings.append(decimal,".")
            void strings.append(decimal,conv.str_ub(lsb(value % 10)))
            report.check(storage.decimal(decimal))
            report.check(storage.number==value)
        }
        for i in 0 to len(expected.miles)-1 {
            uword miles=geo.nautical(expected.west[i],expected.north[i],expected.city_lat[i],expected.city_west[i])
            report.check(abs((miles as word)-(expected.miles[i] as word))<=1)
        }
        chart.project(1100,450)
        report.check(chart.px==14 and chart.py==6 and chart.visible)
        chart.project(450,50)
        report.check(not chart.visible)
        chart.init()
        sys.memset($7f40,192,$a6)
        storm.clear()
        void storm.add("07 pm 09 10 1988",0,1100,450)
        void storm.add("07 pm 09 10 1988",300,450,450)
        void storm.add("07 pm 09 10 1988",0,450,50)
        void storm.add("07 pm 09 10 1988",300,1100,50)
        chart.draw(3)
        for i in 0 to 191
            report.check(@($7f40+i as uword)==$a6)
        graphics.disable_bitmap_mode()
        report.check((c64.SCROLY & $20)==0)
        report.finish()
finished:
        repeat { }
    }
}
