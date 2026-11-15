%import graphics
%import textio
%import conv
%import model

chart {
    uword px
    ubyte py

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
        px = (1100-west)*49/100
        py = lsb((450-north)*4/10)+8
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

    sub coast() {
        ; Deliberately simplified geographic reference, in tenths of degrees.
        ; Paired polylines separated by 0,0. No original artwork is embedded.
        ubyte i
        bool previous = false
        uword lastx
        ubyte lasty
        for i in 0 to len(west)-1 {
            if west[i]==0 {
                previous = false
            } else {
                project(west[i], north[i])
                if previous
                    graphics.line(lastx,lasty,px,py)
                lastx=px
                lasty=py
                previous=true
            }
        }
        uword[] west = [1100,1080,1060,1050,1050,1060,1050,1030,1000,980,970,965,975,965,945,925,905,890,880,860,850,830,820,815,805,800,805,810,800,780,770,760,750,740,720,700,680,660,650,0,870,880,890,900,920,940,950,940,920,900,880,870,0,850,830,810,790,770,750,740,750,770,790,810,830,850,0,785,770,755,745,740,750,765,780,785,0,735,720,705,695,700,715,730,735,0,675,660,655,665,675,0,800,790,780,770,760,750,740,720,700,680,660,640,620,600,580,560,540,520,500,480,450]
        uword[] north = [310,310,310,300,280,260,240,210,180,160,170,200,250,260,285,295,290,300,300,300,295,290,270,250,250,265,285,300,320,335,350,370,390,400,410,420,440,450,450,0,210,220,220,215,210,205,190,180,180,185,195,210,0,220,230,230,225,220,215,205,200,200,205,210,215,220,0,185,185,183,180,175,175,175,180,185,0,200,200,195,185,180,180,185,200,0,185,185,180,178,185,0,90,90,95,100,110,115,115,120,120,110,105,100,100,90,80,70,60,55,50,50,50]
    }

    sub draw(ubyte index) {
        graphics.enable_bitmap_mode()
        graphics.clear_screen(1,6)
        c64.EXTCOL=6
        ; Sparse dotted latitude/longitude grid.
        uword w
        uword n
        for w in 500 to 1100 step 100 {
            for n in 50 to 450 step 10 {
                project(w,n)
                graphics.plot(px,py)
            }
        }
        for n in 100 to 400 step 100 {
            for w in 450 to 1100 step 20 {
                project(w,n)
                graphics.plot(px,py)
            }
        }
        coast()
        label(0,0,"hurricane / offline     110w-45w  5n-45n")
        label(1,2,"north america")
        label(4,14,"pacific")
        label(24,7,"atlantic")
        ubyte i
        uword lastx
        ubyte lasty
        for i in 0 to index {
            project(storm.longitude[i],storm.latitude[i])
            if i>0
                graphics.line(lastx,lasty,px,py)
            lastx=px
            lasty=py
        }
        ; Crosshair marks the currently selected observation.
        if px>=2 and px<=317 and py>=2 and py<=197 {
            graphics.line(px-2,py,px+2,py)
            graphics.line(px,py-2,px,py+2)
        }
        label(0,22,storm.timestamp(index))
        label(19,22,conv.str_uw(storm.wind[index]))
        label(23,22,"mph")
        label(28,22,conv.str_ub(index+1))
        label(32,22,"of")
        label(35,22,conv.str_ub(storm.count))
        coordinate(0,23,storm.longitude[index])
        label(6,23,"w")
        coordinate(9,23,storm.latitude[index])
        label(15,23,"n")
        label(19,23,"d: city distances")
        label(0,24,"space:next  b:back  r:restart  q:menu")
    }
}
