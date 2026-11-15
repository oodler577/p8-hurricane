%import strings

storm {
    const ubyte CAPACITY = 128
    ubyte count
    ubyte selected
    bool dirty
    uword[128] longitude
    uword[128] latitude
    uword[128] wind
    uword timestamps = memory("timestamps",2176,0)

    sub clear() {
        count = 0
        selected = 0
        dirty = false
    }

    sub timestamp(ubyte index) -> uword {
        return timestamps + (index as uword)*17
    }

    sub valid_stamp(str stamp) -> bool {
        if strings.length(stamp)!=16
            return false
        if stamp[2]!=' ' or stamp[5]!=' ' or stamp[8]!=' ' or stamp[11]!=' '
            return false
        if stamp[4]!='m' or (stamp[3]!='a' and stamp[3]!='p')
            return false
        ubyte i
        for i in 0 to 15 {
            if i!=2 and i!=3 and i!=4 and i!=5 and i!=8 and i!=11 {
                if stamp[i]<'0' or stamp[i]>'9'
                    return false
            }
        }
        ubyte hour = (stamp[0]-'0')*10 + stamp[1]-'0'
        ubyte month = (stamp[6]-'0')*10 + stamp[7]-'0'
        ubyte day = (stamp[9]-'0')*10 + stamp[10]-'0'
        uword year = (stamp[12]-'0' as uword)*1000 + (stamp[13]-'0' as uword)*100 + (stamp[14]-'0' as uword)*10 + stamp[15]-'0'
        if hour<1 or hour>12 or month<1 or month>12 or year<1800
            return false
        ubyte[12] days = [31,28,31,30,31,30,31,31,30,31,30,31]
        ubyte limit = days[month-1]
        if month==2 and year % 4==0 and (year % 100!=0 or year % 400==0)
            limit = 29
        return day>=1 and day<=limit
    }

    sub add(str stamp, uword mph, uword west, uword north) -> bool {
        if count==CAPACITY or mph>300 or west<450 or west>1100 or north<50 or north>450
            return false
        if not valid_stamp(stamp)
            return false
        void strings.copy(stamp, timestamp(count))
        longitude[count] = west
        latitude[count] = north
        wind[count] = mph
        selected = count
        count++
        dirty = true
        return true
    }
}
