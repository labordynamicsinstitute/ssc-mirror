{smcl}
{* 21jul2025}{...}
{cmd:help lhaversine}
{hline}

{title:Title}

{p 4}
{bf:lhaversine -- Mata library for distance functions}


{title:Syntax}


{p 8 12}
{it:real matrix}{bind:   }
{cmd:hav_dist(}{it:lat_a, lng_a, lat_b, lng_b }[{it:, rd}]{cmd:)}

{p 8 12}
{it:real matrix}{bind:   }
{cmd:hav_distm(}{it:lat_a, lng_a, lat_b, lng_b }[{it:, rd}]{cmd:)}

{p 8 12}
{it:real matrix}{bind:   }
{cmd:hav_inrange(}{it:lat_a, lng_a, lat_b, lng_b, rn }[{it:, rd}]{cmd:)}

{p 8 12}
{it:real matrix}{bind:   }
{cmd:hav_inrangem(}{it:lat_a, lng_a, lat_b, lng_b, rn }[{it:, rd}]{cmd:)}

{p 8 12}
{it:real matrix}{bind:   }
{cmd:hav_ninrange(}{it:lat_a, lng_a, lat_b, lng_b, rn }[{it:, rd}]{cmd:)}

{p 8 12}
{it:real matrix}{bind:   }
{cmd:hav_ninrangem(}{it:lat_a, lng_a, lat_b, lng_b, rn }[{it:, rd}]{cmd:)}

{p 4 4 2}
where

{p 8}
{it:lat_a is a real colvector}

{p 8}
{it:lng_a is a real colvector}

{p 8}
{it:lat_b is real colvector}

{p 8}
{it:lng_b is a real colvector}

{p 8}
{it:rd is a real scalar}

{p 8}
{it:rn is a real scalar}

{title:Description}

{pstd} 
All functions in {cmd:lhaversine} use the haversine formula for great-circle distances, {browse "https://en.wikipedia.org/wiki/Haversine_formula"}. The geographical coordinates must be in signed decimal degress. 
Latitudes range from -90 to 90. Longitudes range from -180 to 180. To convert radians into degress, multiply by pi/180.

{pstd}
{cmd:hav_dist()}
returns a matrix of distances between A locations and B locations. The results are in kilometres. {cmd:hav_dist()} takes the latitudes (column vector {it:lat_a}) and 
longitudes (column vector {it:lng_a}) of the A locations and the latitudes (column vector {it:lat_b}) and longitudes (column vector {it:lng_b}) of the B locations as inputs. The optional argument ({it:rd}) allows the
user to specifiy the earth radius. The default is 6,371 kilometres.

{pstd}
{cmd:hav_distm()}
returns a distance matrix in miles. The default radius is 3,958.76 miles.

{pstd}
{cmd:hav_inrange()}
returns a matrix of ones and zeros, indicating if a B location is within a given range of an A location. The range ({it:rn}) needs to be specified by the user and is in kilometers. The  {cmd:hav_dist()} takes the latitudes {it:lat_a} and longitudes {it:lng_b} of the A locations and the latitudes
{it:lat_b} and longitudes {it:lng_b} as inputs. The optional argument ({it:rd}) allows the user to specifiy the earth radius. The default is 6,371 kilometres.

{pstd}
{cmd:hav_inrangem()}
returns a matrix of ones and zeros, indicating if a B location is within a range of ({it:rn}) miles of an a location. The optional argument ({it:rd}) allows the user to specifiy the earth radius. The default is 3,958.76 miles.

{pstd}
{cmd:hav_inrange()}
returns a column vector containing the number of B locations that are within a given range of an A location. The range ({it:rn}) needs to be specified by the user and is in kilometers. The optional argument ({it:rd}) allows the user to specifiy the earth radius. The default is 6,371 kilometres.

{pstd}
{cmd:hav_ninrangem()}
returns a column vector with the number of B locations that are within a range of ({it:rn}) miles of an A location. The optional argument ({it:rd}) allows the user to specifiy the earth radius. The default is 3,958.76 miles.


{title:Examples}

{p 4}
Define the latitudes and longitudes of two A und three B locations:

        {cmd::} lat_a = 53.1205306\53.2056589
	{cmd::} lng_a = 8.101857\8.2530387
	{cmd::} lat_b = 53.1479943\53.2450662\51.2082624
	{cmd::} lng_b = 7.8664467\6.8423613\8.2001266

{p 4}
Obtain distances between A und B locations in kilometres using {cmd:hav_dist()}:

        {cmd::} hav_dist(lat_a, lng_a, lat_b, lng_b)
        {res}    {txt}            1             2             3          
            {c TLC}{hline 43}{c TRC}
          1 {c |}  {res} 15.99849446   229.3229587   15.31791198 {c |}
	  2 {c |}  {res} 26.55005308   241.9975468   5.622063328 {c |}
            {c BLC}{hline 43}{c BRC}
	

{p 4}
Obtain distances in miles with user-specified radius of 3960 miles using {cmd:hav_distm()}:

	{cmd::} rd = 3960
        
        {cmd::} hav_distm(lat_a, lng_a, lat_b, lng_b, rd)
        {res}      {txt}            1             2             3             
            {c TLC}{hline 43}{c TRC}
          1 {c |}  {res} 9.944127774   142.5394627   9.521100523 {c |}
	  2 {c |}  {res} 16.50262285   150.4175617   3.494486074 {c |}
            {c BLC}{hline 43}{c BRC}

{p 4}
Generate a matrix indicating which B locations are within a 25km range of the A locations using {cmd:hav_inrange()}:

	{cmd::} rn = 25

	{cmd::} hav_inrange(lat_a, lng_a, lat_b, lng_b, rn)
         {res}     {txt}  1   2   3          
            {c TLC}{hline 15}{c TRC}
          1 {c |}  {res} 1   0   1   {c |}
	  2 {c |}  {res} 0   0   1   {c |}
            {c BLC}{hline 15}{c BRC}

{p 4}
Generate a column vector containing the number of B locations that are within a 25km range of the A locations using {cmd:hav_ninrange()}:

	{cmd::} hav_mindist(lat_a, lng_a, lat_b, lng_b, rn)
        {res}      {txt}  1 
            {c TLC}{hline 7}{c TRC}
          1 {c |}  {res} 2   {c |}
	  2 {c |}  {res} 1   {c |}
            {c BLC}{hline 7}{c BRC}

{title:Conformability}

	{cmd:hav_dist(}{it:lat_a}{cmd:,} {it:lng_a}{cmd:,} {cmd:lat_b}{cmd:,} {cmd:lng_b} [{cmd:,} {cmd:rd}]{cmd:)}:
       	  {it:lat_a}:  {it:n x} 1
	  {it:lng_a}:  {it:n x} 1
 	  {it:lat_b}:  {it:k x} 1
	  {it:lng_b}:  {it:k x} 1
	     {it:rd}:  1 {it:x} 1
	 {it:result}:  {it:n x k}.

	{cmd:hav_distm()} is analogue


	{cmd:hav_inrange(}{it:lat_a}{cmd:,} {it:lng_a}{cmd:,} {cmd:lat_b}{cmd:,} {cmd:lng_b}{cmd:,} {cmd:rn} [{cmd:,} {cmd:rd}]{cmd:)}:
       	  {it:lat_a}:  {it:n x} 1
	  {it:lng_a}:  {it:n x} 1
 	  {it:lat_b}:  {it:k x} 1
	  {it:lng_b}:  {it:k x} 1
	     {it:rn}:  1 {it:x} 1
	     {it:rd}:  1 {it:x} 1
	 {it:result}:  {it:n x k}.

        {cmd:hav_inrangem()} is analogue


	{cmd:hav_ninrange(}{it:lat_a}{cmd:,} {it:lng_a}{cmd:,} {cmd:lat_b}{cmd:,} {cmd:lng_b}{cmd:,} {cmd:rn} [{cmd:,} {cmd:rd}]{cmd:)}:
       	  {it:lat_a}:  {it:n x} 1
	  {it:lng_a}:  {it:n x} 1
 	  {it:lat_a}:  {it:k x} 1
	  {it:lng_a}:  {it:k x} 1
	     {it:rn}:  1 {it:x} 1
	     {it:rd}:  1 {it:x} 1
	 {it:result}:  {it:n x} 1.

	{cmd:hav_ninrangem()} is analogue



{title:Author}

{pstd}
Lars Zeigermann, {browse "mailto:lars.zeigermann@posteo.de":lars.zeigermann@posteo.de}

{title:Acknowledgment}

{pstd}
{cmd:lhaversine} is based on {cmd:geodist} written bei Robert Picard und reuses some of its code.

{pstd}