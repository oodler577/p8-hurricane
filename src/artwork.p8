; Adapted original HUR1 map artwork; see CREDITS.md and data/artwork/provenance.json.
artwork {
    sub unpack(uword source, uword target, uword size) {
        uword end=target+size
        while target<end {
            ubyte token=@(source)
            source++
            if token<128 {
                ubyte count=token+1
                repeat count {
                    @(target)=@(source)
                    target++
                    source++
                }
            } else if token>128 {
                ubyte repeats=lsb(257-(token as uword))
                ubyte value=@(source)
                source++
                repeat repeats {
                    @(target)=value
                    target++
                }
            }
        }
    }

    asmsub bitmap() {
        %asm {{
            .binary "../data/artwork/map-bitmap.rle"
            ; !notreached!
        }}
    }

    asmsub matrix() {
        %asm {{
            .binary "../data/artwork/map-matrix.rle"
            ; !notreached!
        }}
    }
}
