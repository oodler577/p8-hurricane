%import floats
geo {
    sub nautical(uword storm_west, uword storm_north, float city_lat, float city_west) -> uword {
        ; Great-circle distance on a mean-radius sphere (3440.065 nautical miles).
        float slat=floats.rad(storm_north as float / 10.0)
        float clat=floats.rad(city_lat)
        float dlat=(clat-slat)/2.0
        float dlon=floats.rad(city_west-(storm_west as float) / 10.0)/2.0
        float a=floats.sin(dlat)*floats.sin(dlat) + floats.cos(slat)*floats.cos(clat)*floats.sin(dlon)*floats.sin(dlon)
        a=floats.clampf(a,0.0,1.0)
        float miles=6880.13*floats.atan2(sqrt(a),sqrt(1.0-a))
        return (miles+0.5) as uword
    }
}
