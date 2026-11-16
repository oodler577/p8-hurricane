%import graphics
%import artwork
%import textio
%import conv
%import model

chart {
    uword px
    ubyte py
    bool visible

    sub init() {
        ; Copy uppercase ROM font while character ROM is visible.
        ; $c000-$c7ff is reserved exclusively for this copy.
        %asm {{
            php
            sei
            lda $01
            pha
            lda #$33
            sta $01
            ldx #0
-           .for page=0, page<8, page+=1
                lda $d000+page*$100,x
                sta $c000+page*$100,x
            .next
            inx
            bne -
            pla
            sta $01
            plp
        }}
    }

    sub project(uword west, uword north) {

        visible=west>=500 and west<=1100 and north>=100 and north<=450
        if visible {
            px=14+(1100-west)*48/100
            py=lsb((450-north)*48/100)+6
        }

    }

    sub label(ubyte col, ubyte row, str text) {
        uword destination = graphics.BITMAP_ADDRESS + (row as uword)*320 + (col as uword)*8
        ubyte i = 0
        while text[i]!=0 and col<40 {
            ubyte code = txt.petscii2scr(text[i]) & 127
            sys.memcopy($c000 + (code as uword)*8, destination, 8)
            destination += 8
            col++
            i++
        }
    }

    sub coordinate(ubyte col, ubyte row, uword value) {
        label(col, row, conv.str_uw(value/10))
        if value>=1000
            col += 3
        else if value>=100
            col += 2
        else
            col++
        label(col, row, ".")
        label(col+1, row, conv.str_ub(lsb(value % 10)))
    }

    sub large(str text, uword left, ubyte top) {
        ubyte i=0
        while text[i]!=0 {
            ubyte code=txt.petscii2scr(text[i]) & 127
            ubyte row
            for row in 0 to 7 {
                ubyte bits=@($c000+(code as uword)*8+row)
                ubyte col
                for col in 0 to 7 {
                    if (bits & (128 >> col))!=0 {
                        ubyte yy
                        ubyte xx
                        for yy in 0 to 2 {
                            for xx in 0 to 2
                                graphics.plot(left+(i as uword)*24+(col as uword)*3+xx,top+row*3+yy)
                        }
                    }
                }
            }
            i++
        }
    }

    sub title() {
        graphics.enable_bitmap_mode()
        graphics.clear_screen(3,0)
        c64.EXTCOL=8
        sys.memset(graphics.CHARS_ADDRESS+8*40,4*40,$80)
        large("skipper",76,4)
        large("jim's",100,34)
        large("hurricane",52,64)
        large("tracking",64,96)
        large("chart",100,128)
        label(13,21,"press any key")
        sys.memset(graphics.CHARS_ADDRESS+21*40,40,$10)
        label(1,23,"original by james r. brown / p8 remake")
        sys.memset(graphics.CHARS_ADDRESS+23*40,40,$10)
    }

    sub draw(ubyte index) {
        graphics.enable_bitmap_mode()
        artwork.unpack(&artwork.bitmap,graphics.BITMAP_ADDRESS,8000)
        artwork.unpack(&artwork.matrix,graphics.CHARS_ADDRESS,1000)
        c64.EXTCOL=7
        ; Recreate the original pale-yellow bulletin panel in hires text.
        sys.memset(graphics.BITMAP_ADDRESS+22*320,960,0)
        sys.memset(graphics.CHARS_ADDRESS+22*40,120,$67)
        ubyte i
        uword lastx
        ubyte lasty
        bool previous=false
        for i in 0 to index {
            project(storm.longitude[i],storm.latitude[i])
            if visible {
                if previous
                    graphics.line(lastx,lasty,px,py)
                lastx=px
                lasty=py
                previous=true
            } else {
                previous=false
            }
        }
        if visible {
            ; White current-fix marker, clear enough to distinguish from the trail.
            uword cell=(py as uword)/8*40+px/8
            @(graphics.CHARS_ADDRESS+cell)=$16
            uword destination=graphics.BITMAP_ADDRESS+cell*8
            sys.memcopy(&marker,destination,8)
        }
        label(0,22,conv.str_ub(index+1))
        label(3,22,"hurricane")
        if storm.wind[index]<39
            label(3,22,"depression")
        else if storm.wind[index]<74
            label(3,22,"storm")
        label(14,22,storm.storm_name)
        if not visible
            label(29,22,"off chart")
        label(0,23,"date")
        label(5,23,storm.timestamp(index))
        label(23,23,"wind")
        label(28,23,conv.str_uw(storm.wind[index]))
        label(32,23,"mph")
        label(0,24,"position")
        coordinate(9,24,storm.longitude[index])
        label(15,24,"west")
        coordinate(21,24,storm.latitude[index])
        label(27,24,"north")
        ubyte[] marker=[$18,$3c,$66,$5a,$5a,$66,$3c,$18]
    }
}
