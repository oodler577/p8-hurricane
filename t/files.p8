%import floats
%import model
%import storage
%import expected
%import report
%zeropage floatsafe
%memtop $5c00
main {
    sub start() {
        str name="hf.c00"
        ubyte i
        for i in 0 to len(expected.valid)-1 {
            name[4]='0'+i/10
            name[5]='0'+i % 10
            storm.clear()
            @($7fff)=$a6
            bool result=storage.load(name)
            @($ca00+i as uword)=result as ubyte
            report.check(result==(expected.valid[i]!=0))
            report.check(@($7fff)==$a6)
            if result
                report.check(storm.count==expected.counts[i] and not storm.dirty)
        }
        report.finish()
finished:
        repeat { }
    }
}
