*! Source of lhaversine.mlib


*! 
*! hav_dist.mata
*! version 1.0.0, Lars Zeigermann, 21jul2025
version 10

mata:

real matrix hav_dist(real colvector lat_from, real colvector lng_from,
        real colvector lat_to, real colvector lng_to, | real scalar radius)
{
                real matrix LAT1
                real matrix LNG1
                real matrix LAT2
                real matrix LNG2
                real matrix DLAT
                real matrix DLNG
                real matrix COSLAT1
                real matrix COSLAT2
                real matrix SINDLAT
                real matrix SINDLAT_sq
                real matrix SINDLNG
                real matrix SINDLNG_sq
                real matrix DIST
                real scalar dr
                
                if (args() == 4) radius = 6371
                
                LAT1 = J(1,rows(lat_to),lat_from)
                LNG1 = J(1,rows(lng_to),lng_from)
                LAT2 = J(rows(lat_from),1,lat_to')
                LNG2 = J(rows(lng_from),1,lng_to')
                dr = pi()/180
                DLAT = (LAT2:-LAT1):*(dr:/2)
                DLNG = (LNG2:-LNG1):*(dr:/2)
                LAT1 = LAT1:*dr
                LAT2 = LAT2:*dr
                COSLAT1 = cos(LAT1)
                COSLAT2 = cos(LAT2)
                SINDLAT = sin(DLAT)
                SINDLAT_sq = SINDLAT:*SINDLAT
                SINDLNG = sin(DLNG)
                SINDLNG_sq = SINDLNG:*SINDLNG
                
                DIST = 2:*asin(sqrt(SINDLAT_sq:+COSLAT1:*COSLAT2:*SINDLNG_sq)):*radius
                
                return(DIST)
}

real matrix hav_distm(real colvector lat_from, real colvector lng_from, 
        real colvector lat_to, real colvector lng_to, | real scalar radius)
{
                if (args() == 4) radius = 3958.7559
                return(hav_dist(lat_from,lng_from,lat_to,lng_to,radius))
}

end

*! 
*! hav_inrange.mata
*! version 1.0.0, Lars Zeigermann, 21jul2025
version 10

mata:

real matrix hav_inrange(real colvector lat_from, real colvector lng_from, 
        real colvector lat_to, real colvector lng_to, real scalar range, | real scalar radius)
{
                
				if (args() == 5) radius = 6371
				
				return(hav_dist(lat_from,lng_from,lat_to,lng_to,radius) :<= range)
}


real matrix hav_inrangem(real colvector lat_from, real colvector lng_from, 
        real colvector lat_to, real colvector lng_to, real scalar range, | real scalar radius)
{
                
				if (args() == 5) radius = 3958.7559
				
				return(hav_distm(lat_from,lng_from,lat_to,lng_to,radius) :<= range)
}

real matrix hav_ninrange(real colvector lat_from, real colvector lng_from, 
        real colvector lat_to, real colvector lng_to, real scalar range, | real scalar radius)
{
                
				if (args() == 5) radius = 6371
				
				return(rowsum((hav_dist(lat_from,lng_from,lat_to,lng_to) :<= range)))
}

real matrix hav_ninrangem(real colvector lat_from, real colvector lng_from,
        real colvector lat_to, real colvector lng_to, real scalar range, | real scalar radius)
{
                if (args() == 5) radius = 3958.7559
				
				return(rowsum((hav_distm(lat_from,lng_from,lat_to,lng_to) :<= range)))
}

end