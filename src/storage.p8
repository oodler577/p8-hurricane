%import diskio
%import strings
%import conv
%import model

storage {
    ; Bounded scratch area, separate from program, bitmap, ROM and font copy.
    const uword BUFFER = $8000
    const uword LIMIT = 8192
    uword position
    uword line_start
    uword size
    str line = " " * 40
    str stamp = " " * 16
    bool okay
    uword number
    str error = " " * 40
    str filename = " " * 24

    sub next_line() -> bool {
        line_start = position
        ubyte n = 0
        if position>=size
            return false
        while position<size {
            ubyte c = @(BUFFER+position)
            position++
            if c==13 or c==10 {
                ; Accept CR, LF and CRLF without introducing empty lines.
                if c==13 and position<size and @(BUFFER+position)==10
                    position++
                line[n] = 0
                return true
            }
            if c<32 or c>126 or n==40 {
                line[0] = 0
                return false
            }
            line[n] = c
            n++
        }
        line[n] = 0
        return n!=0
    }

    sub decimal(str text) -> bool {
        ; Strict decimal -> tenths. Extra fractional digits must be zero.
        number = 0
        ubyte i = 0
        bool digit = false
        while text[i]>='0' and text[i]<='9' {
            if number>3000
                return false
            number = number*10 + text[i]-'0'
            i++
            digit = true
        }
        if not digit or number>3000
            return false
        number *= 10
        if text[i]=='.' {
            i++
            if text[i]<'0' or text[i]>'9'
                return false
            number += text[i]-'0'
            i++
            while text[i]=='0'
                i++
        }
        return text[i]==0
    }

    sub load(str name) -> bool {
        void strings.copy("cannot open storm file", error)
        if not diskio.f_open(name)
            return false
        size = diskio.f_read(BUFFER, LIMIT)
        diskio.f_close()
        if size==0 or size==LIMIT {
            void strings.copy("file empty, too large or i/o error", error)
            return false
        }
        storm.clear()
        position = 0
        void strings.copy("invalid or incomplete storm file", error)
        while next_line() {
            if line=="end" {
                ; Permit only whitespace after the sentinel.
                while position<size {
                    ubyte c = @(BUFFER+position)
                    position++
                    if c!=13 and c!=10 and c!=32
                        goto bad_file
                }
                if storm.count==0
                    goto bad_file
                storm.dirty = false
                storm.selected = 0
                void strings.copy("loaded", error)
                return true
            }
            if not storm.valid_stamp(line)
                goto bad_file
            void strings.copy(line, stamp)
            if not next_line() or not decimal(line) or number % 10!=0
                goto bad_file
            uword mph = number/10
            if not next_line() or not decimal(line)
                goto bad_file
            uword west = number
            if not next_line() or not decimal(line)
                goto bad_file
            if not storm.add(stamp, mph, west, number)
                goto bad_file
            ; The original last record can end directly with END.
            if not next_line()
                goto bad_file
            if line=="end" {
                position = line_start
            } else if line!="0" {
                goto bad_file
            }
        }
bad_file:
        storm.clear()
        return false
    }

    sub write_line(str value) {
        ubyte cr = 13
        okay = diskio.f_write(value, strings.length(value)) and okay
        okay = diskio.f_write(&cr, 1) and okay
    }

    sub write_decimal(uword value) {
        ; All disk coordinates have exactly one fractional digit.
        diskio.reset_write_channel()
        txt.print_uw(value/10)
        txt.chrout('.')
        txt.chrout(lsb(value % 10)+'0')
        txt.chrout(13)
        ubyte status = cbm.READST()
        cbm.CLRCHN()
        okay = status==0 and okay
    }

    str dos_status = " " * 40

    sub read_dos_status() -> bool {
        ; Keep channel 15 open until all data channels are closed:
        ; closing it on a 1541 closes every open file on that drive.
        cbm.CLRCHN()
        void cbm.CHKIN(15)
        if_cs {
            cbm.CLRCHN()
            return false
        }
        ubyte i=0
        repeat {
            ubyte c=cbm.CHRIN()
            ubyte st=cbm.READST()
            if (st & $bf)!=0 {
                cbm.CLRCHN()
                return false
            }
            if c==13 or c==10 {
                dos_status[i]=0
                cbm.CLRCHN()
                return i>=2 and dos_status[0]=='0' and dos_status[1]=='0'
            }
            if i==40 {
                cbm.CLRCHN()
                return false
            }
            dos_status[i]=c
            i++
        }
    }

    sub save(str name) -> bool {
        void strings.copy("no observations to save",error)
        if storm.count==0
            return false
        void strings.copy("cannot create storm file",error)
        cbm.SETNAM(0,filename)
        cbm.SETLFS(15,diskio.drivenumber,15)
        void cbm.OPEN()
        if_cs {
            cbm.CLOSE(15)
            return false
        }
        void strings.copy(name,filename)
        void strings.append(filename,",s,w")
        if not diskio.f_open_w(filename) {
            cbm.CLOSE(15)
            return false
        }
        if not read_dos_status() {
            diskio.f_close_w()
            cbm.CLOSE(15)
            return false
        }
        ; Clear EOF left by reading the status line before beginning output.
        @($90)=0
        okay=true
        ubyte i
        for i in 0 to storm.count-1 {
            write_line(storm.timestamp(i))
            write_line(conv.str_uw(storm.wind[i]))
            write_decimal(storm.longitude[i])
            write_decimal(storm.latitude[i])
            write_line("0")
        }
        write_line("end")
        diskio.f_close_w()
        bool dos_ok=read_dos_status()
        cbm.CLOSE(15)
        if not okay or not dos_ok {
            void strings.copy("disk write failed; check drive status",error)
            return false
        }
        storm.dirty=false
        void strings.copy("saved",error)
        return true
    }
}
