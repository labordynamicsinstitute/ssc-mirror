
.-
help for ^traveltime3^
.-

Retrieves distances and travel time via Google Distancematrix API V3

----------------------------------------------------------


Syntax
--------

 ^traveltime3^ , ^start^(string) ^end^(string) mode(string) units(string) avoid(string)
 

Specify ^start^ and ^end^ to retrieve travel time and road distance between two locations.

 
Description
-----------
^traveltime3^ is valid for the Google Geocoding API (V3).
Google Geocoding API (V2) ceased as of March 2013.

^traveltime3^ requires insheetjson, which in turn requires libjson.
Install both from ssc.
@ssc install insheetjson@
@ssc install libjson@

^traveltime3^ creates several variables and will overwrite existing ones. They have t_ prefixes, so there should be no problems.

^traveltime3^ creates the variables:
	t_status, which is "OK" if everything went as expected.
	t_origin, which contains the origin address interpreted from the input you specified.
	t_destination, which contains the destination address interpreted from your input.


Google Maps api has a daily query limit of 2500 per IP-address. The status code "OVER_QUERY_LIMIT"
is returned and the program stops when the limit is reached. Restart ^traveltime3^ on the next day
and it will automatically resume where it stopped. Or get a new IP.

There is a 500ms delay between queries so that Google's servers don't reject them for overflooding,
so take your time while geocoding.



Options
---------------------

required:
      
^start^(string) ^end^(string)

Can be either filled with addresses or coordinates.		


With addresses:

The address has to be coded in a single string variable similar to this:
number+street+zip+town+state
Use your regional conventional address format and you should be fine, Google is quite clever.

You can also omit certain entries (e.g. only use zip+state).

Make sure that there are no spaces or special characters that Stata cannot handle in your addresses (like ä,ö,ü,ß).
Spaces can be replaced with "+". 

Examples:

1600+Amphitheatre+Parkway,+Mountain+View,+CA
1+Friedrich-Schmidt-Platz+1010+Wien+Austria
Bahnhofstrasse+1+12555+Berlin+Deutschland
2+Rue+de+Viarmes+75001+Paris+France
4040+Austria


With coordinates:

The coordinates need to be in a single string variable with the format:

lat,lon

E.g.:
47.9948972,16.9287615


optional:

mode(string)

Can be driving, bicycling or walking; when not specified defaults to driving

units(string) 

Can be metric or imperial; when not specified defaults to metric.
Using metric units returns the distance in kilometres, while using imperial units returns the distance in miles.
Time is always returned in minutes.

avoid(string)

Can be tolls or highways; when not specified nothing is avoided
Additionally, avoid does not mean that the specified entity is avoided in all cases, they are just less prioritized by the algorithm.


Status Codes
---------------------

The "status" field within the Geocoding response object contains the status of the request, and may contain debugging information to help you track down why Geocoding is not working. The "status" field may contain the following values:

"OK" indicates that no errors occurred; the address was successfully parsed and at least one geocode was returned.
"ZERO_RESULTS" indicates that the geocode was successful but returned no results. This may occur if the geocode was passed a non-existent address or a latlng in a remote location.
"OVER_QUERY_LIMIT" indicates that you are over your quota.
"REQUEST_DENIED" indicates that your request was denied, generally because of lack of a sensor parameter.
"INVALID_REQUEST" generally indicates that the query (address or latlng) is missing.
"UNKNOWN_ERROR" indicates that the request could not be processed due to a server error. The request may succeed if you try again


--------------------
For more information see: 
@https://developers.google.com/maps/documentation/distancematrix/@

Be aware of Google's usage limits.
      Especially: Use of the Distance Matrix API must relate to the display of information on a Google Map; for example, to determine origin-destination pairs that fall within a specific driving time from one another, before requesting and displaying those destinations on a map. Use of the service in an application that doesn't display a Google map is prohibited.

Author
-------

	Stefan Bernhard
	stefanbernhard88@gmail.com

Special thanks to 
------------------

	Erik Lindsley (ssc@holocron.org) 
	for extensive support with the insheetjson command.


Thanks also to these guys for the old -^traveltime^- v2.0
-------

      Adam Ozimek
      Econsult Corporation
      ozimek@econsult.com
      
      Daniel Miles
      Econsult Corporation
      miles@econsult.com




