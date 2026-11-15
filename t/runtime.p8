%import textio
%import strings
%import model
%import storage
%import geo
%zeropage floatsafe
%memtop $5c00

main {
    ubyte failures
    ubyte checks

    sub check(bool result) {
        checks++
        @($c800+checks as uword) = result as ubyte
        if not result
            failures++
    }

    sub start() {
        check(storm.valid_stamp("07 pm 09 10 1988"))
        check(storm.valid_stamp("12 am 02 29 2000"))
        check(not storm.valid_stamp("12 am 02 29 1900"))
        check(not storm.valid_stamp("00 am 09 10 1988"))
        check(not storm.valid_stamp("12 am 04 31 2026"))
        check(not storm.valid_stamp("07 xm 09 10 1988"))
        check(storage.decimal("17.00") and storage.number==170)
        check(storage.decimal("66.5") and storage.number==665)
        check(not storage.decimal("17.01"))
        check(not storage.decimal("-5"))
        check(not storage.decimal("65536"))
        check(not storage.decimal("12junk"))
        storm.clear()
        check(not storm.add("07 pm 09 10 1988",301,665,157))
        check(not storm.add("07 pm 09 10 1988",80,449,157))
        check(storm.add("07 pm 09 10 1988",80,665,157))
        check(storm.count==1 and storm.wind[0]==80 and storm.dirty)
        check(storage.load("hf.gilbert"))
        void strings.copy(storage.error,$c900)
        check(storm.count==19 and not storm.dirty)
        check(storm.longitude[0]==665 and storm.latitude[0]==157 and storm.wind[0]==80)
        check(storm.longitude[18]==964 and storm.latitude[18]==239 and storm.wind[18]==120)
        check(strings.compare(storm.timestamp(18),"11 am 09 16 1988")==0)
        check(storage.save("hf.test"))
        storm.clear()
        check(storage.load("hf.test"))
        check(storm.count==19 and storm.longitude[18]==964)
        check(not storage.save("hf.test"))
        check(not storage.load("hf.bad"))
        check(storm.count==0)
        storm.clear()
        repeat 128 {
            void storm.add("07 pm 09 10 1988",80,665,157)
        }
        check(storm.count==128)
        check(not storm.add("07 pm 09 10 1988",80,665,157))
        uword distance1=geo.nautical(665,157,29.7604,95.3698)
        pokew($c980,distance1)
        check(distance1==1800)
        uword distance2=geo.nautical(964,239,25.9017,97.4975)
        pokew($c982,distance2)
        check(distance2==134)
        uword distance3=geo.nautical(800,250,25.0,80.0)
        pokew($c984,distance3)
        check(distance3==0)
        @( $02fc )=checks
        @( $02fd )=failures
        @( $02fe )=$a5
finished:
        repeat { }
    }
}
