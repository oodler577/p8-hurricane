%import textio
%import credits
%import strings
%import conv
%import floats
%import geo
%import diskio
%import model
%import storage
%import chart
%zeropage floatsafe
%memtop $5c00

main {
    str input = " " * 40
    str stamp = " " * 16
    str name = " " * 16
    ubyte key

    sub start() {
        chart.init()
        chart.title()
        void txt.waitkey()
        graphics.disable_bitmap_mode()
        void strings.copy("hf.gilbert",name)
        void strings.copy("ready",storage.error)
        repeat {
            menu()
            key = txt.waitkey()
            when key {
                'l' -> load()
                'n' -> {
                    if discard() {
                        storm.clear()
                        void strings.copy("new storm", name)
                    }
                }
                'a' -> add()
                's' -> save()
                'v' -> view()
                'f' -> {
                    txt.cls()
                    void diskio.directory()
                    pause()
                }
                'q' -> {
                    if discard() {
                        txt.cls()
                        return
                    }
                }
            }
        }
    }

    sub menu() {
        txt.cls()
        c64.EXTCOL=6
        c64.BGCOL0=6
        txt.color(1)
        txt.print("p8-hurricane / prog8 c64\n")
        credits.show()
        txt.print("storm: ")
        txt.print(name)
        txt.print("\nobservations: ")
        txt.print_ub(storm.count)
        if storm.dirty
            txt.print("  (unsaved)")
        txt.print("\n\nl  load storm file\nn  new storm\na  add observation\ns  save as new file\nv  view / replay track\nf  disk directory\nq  quit\n\n")
        txt.print("chart: 110w-50w, 10n-45n\ncapacity: 128 observations\n\n")
        txt.print(storage.error)
    }

    sub pause() {
        txt.print("\npress a key")
        void txt.waitkey()
    }

    sub discard() -> bool {
        if not storm.dirty
            return true
        txt.print("\ndiscard unsaved observations? y/n ")
        return txt.waitkey()=='y'
    }

    sub ask(str prompt, ubyte maximum) {
        ; Bounded GETIN editor; avoids the unbounded KERNAL line editor.
        txt.print(prompt)
        ubyte n=0
        repeat {
            ubyte c=txt.waitkey()
            if c==13 {
                input[n]=0
                txt.nl()
                return
            }
            if c==20 {
                if n>0 {
                    n--
                    txt.chrout(20)
                }
            } else if c>=32 and c<=95 and n<maximum {
                input[n]=c
                n++
                txt.chrout(c)
            }
        }
    }

    sub file_prompt() -> bool {
        ask("filename (up to 16 chars): ",16)
        if input[0]==0
            return false
        ubyte i
        for i in 0 to strings.length(input)-1 {
            ubyte c=input[i]
            if not ((c>='a' and c<='z') or (c>='0' and c<='9') or c=='.' or c=='-' or c=='_') {
                void strings.copy("use letters, digits, dot or hyphen",storage.error)
                return false
            }
        }
        return true
    }

    sub load() {
        if not discard()
            return
        txt.cls()
        if not file_prompt()
            return
        void strings.copy(input, storage.filename)
        if storage.load(input)
            void strings.copy(storage.filename, name)
    }

    sub save() {
        txt.cls()
        txt.print("save to a new filename; no overwrite\n")
        if not file_prompt()
            return
        if storage.save(input)
            void strings.copy(input, name)
    }

    sub read_number(str prompt, uword minimum, uword maximum) -> uword {
        repeat {
            ask(prompt,8)
            if storage.decimal(input) and storage.number>=minimum and storage.number<=maximum
                return storage.number
            txt.print("invalid / out of range\n")
        }
    }

    sub add() {
        if storm.count==storm.CAPACITY {
            void strings.copy("observation capacity reached",storage.error)
            return
        }
        txt.cls()
        txt.print("add observation (winds in mph)\n\n")
        repeat {
            ask("time: 07 pm 09 10 1988\n> ",16)
            if storm.valid_stamp(input)
                break
            txt.print("invalid time/date\n")
        }
        void strings.copy(input,stamp)
        uword mph=read_number("wind mph (0-300): ",0,3000)
        if mph % 10!=0 {
            void strings.copy("wind must be whole mph; entry cancelled",storage.error)
            return
        }
        uword west=read_number("west degrees (45-110): ",450,1100)
        uword north=read_number("north degrees (5-45): ",50,450)
        txt.print("add this observation? y/n ")
        if txt.waitkey()=='y' {
            void storm.add(stamp,mph/10,west,north)
            void strings.copy("observation added",storage.error)
        }
    }

    sub view() {
        if storm.count==0 {
            void strings.copy("load or add observations first",storage.error)
            return
        }
        repeat {
            chart.draw(storm.selected)
            key=txt.waitkey()
            if key=='q'
                break
            if key==' ' and storm.selected<storm.count-1
                storm.selected++
            if key=='b' and storm.selected>0
                storm.selected--
            if key=='r'
                storm.selected=0
            if key=='d' {
                graphics.disable_bitmap_mode()
                distances()
            }
        }
        graphics.disable_bitmap_mode()
    }

    sub distances() {
        ; Great-circle distance using the haversine formula; fixed city centres.
        txt.cls()
        txt.print("distance from selected observation\n\n")
        txt.print(storm.timestamp(storm.selected))
        txt.print("\n\n")
        distance("houston",29.7604,95.3698)
        distance("brownsville",25.9017,97.4975)
        distance("new orleans",29.9511,90.0715)
        distance("miami",25.7617,80.1918)
        txt.print("\nnautical miles to city centres\n")
        pause()
    }

    sub distance(str city, float lat, float west) {
        txt.print(city)
        txt.print(": ")
        txt.print_uw(geo.nautical(storm.longitude[storm.selected],storm.latitude[storm.selected],lat,west))
        txt.nl()
    }
}
