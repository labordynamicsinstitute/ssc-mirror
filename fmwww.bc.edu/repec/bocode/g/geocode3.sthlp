
.-
help for ^geocode3^
.-

Retrieves coordinates via Google Geocoding API V3 (geocoding)
or
retrieves addresses via Google Geocoding API V3 (reverse geocoding)
----------------------------------------------------------


Syntax
--------

 ^geocode3^, ^address^(varname) ^fulladdress^ ^quality^ ^zip^ ^state^ ^number^ ^street^ ^ad1^ ^ad2^ ^ad3^ ^sub^ | ^reverse^ ^coord^(varname)
 

Specify ^address^(varname) to retrieve coordinates from addresses provided in ^address^(varname), or
specify ^coord^(varname) to retrieve addresses from coordinates provided in ^coord^(varname).
The other options are available for both normal and reverse geocoding.

e.g.
^geocode3^, ^address^(varname) ^zip^ ^state^
^geocode3^, ^coord^(varname) ^zip^ ^state^ ^number^ ^street^ ^ad2^
 
Description
-----------
^geocode3^ is valid for the Google Geocoding API (V3).
Google Geocoding API (V2) ceased as of March 2013.

^geocode3^ requires insheetjson, which in turn requires libjson.
Install both from ssc.
@ssc install insheetjson@
@ssc install libjson@

^geocode3^ creates several variables and will overwrite existing ones. They have g_ and r_ prefixes, so there should be no problems.

^geocode3^ creates a variable g_/r_status, which is "OK" if
everything went as expected.

Google Maps api has a daily query limit of 2500 per IP-address. The status code "OVER_QUERY_LIMIT"
is returned and the program stops when the limit is reached. Restart ^geocode^ on the next day
and it will automatically resume where it stopped. Or get a new IP.

There is a 500ms delay between queries so that Google's servers don't reject them for overflooding,
so take your time while geocoding.



Options for Geocoding
---------------------

required:
      
^address^(varname)			

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


optional:

^fulladdress^ ^quality^ ^zip^ ^state^ ^number^ ^street^ ^ad1^ ^ad2^ ^ad3^ ^sub^

Generates a new variable g_* that contains the * that Google returned from your input.

^fulladdress^ contains the full address in a single variable. The other each provide an additional
variable containing only the postal code, country, street number, street name, politival administrative area of levels 1 to 3, and subpolitical area.
Not all of these are available for every request and the variable contains not_found if no information was returned.

^quality^ creates two variables: g_quality, which gives the degree of accuracy of the output, 
and g_partial, which is 1 if the output was generated only from a partial match of you input (e.g. the postcode matched but the street was not found in that area).


Options for reverse Geocoding
---------------------

required:
      
^coord^(varname)			

The coords need to be in a single string variable with the format:

lat,lon

E.g.:
47.9948972,16.9287615


optional:

^fulladdress^ ^quality^ ^zip^ ^state^ ^number^ ^street^ ^ad1^ ^ad2^ ^ad3^ ^sub^

^fulladdress^ is automatically specified when reverse geocoding; rest like above.

Status Codes
---------------------

The "status" field within the Geocoding response object contains the status of the request, and may contain debugging information to help you track down why Geocoding is not working. The "status" field may contain the following values:

"OK" indicates that no errors occurred; the address was successfully parsed and at least one geocode was returned.
"ZERO_RESULTS" indicates that the geocode was successful but returned no results. This may occur if the geocode was passed a non-existent address or a latlng in a remote location.
"OVER_QUERY_LIMIT" indicates that you are over your quota.
"REQUEST_DENIED" indicates that your request was denied, generally because of lack of a sensor parameter.
"INVALID_REQUEST" generally indicates that the query (address or latlng) is missing.
"UNKNOWN_ERROR" indicates that the request could not be processed due to a server error. The request may succeed if you try again


location_type stores additional data about the specified location. The following values are currently supported:

"ROOFTOP" indicates that the returned result is a precise geocode for which we have location information accurate down to street address precision.
"RANGE_INTERPOLATED" indicates that the returned result reflects an approximation (usually on a road) interpolated between two precise points (such as intersections). Interpolated results are generally returned when rooftop geocodes are unavailable for a street address.
"GEOMETRIC_CENTER" indicates that the returned result is the geometric center of a result such as a polyline (for example, a street) or polygon (region).
"APPROXIMATE" indicates that the returned result is approximate.

--------------------
For more information see: 
@https://developers.google.com/maps/documentation/geocoding/@

Be aware of Google's usage limits.
	Especially:  The Geocoding API may only be used in conjunction with a Google map; geocoding results without displaying them on a map is prohibited. For complete details on allowed usage, consult the Maps API Terms of Service License Restrictions.
      

Author
-------

	Stefan Bernhard
	stefanbernhard88@gmail.com


Special thanks to 
------------------

	Erik Lindsley (ssc@holocron.org) 
	for extensive support with the insheetjson command.



Thanks also to these guys for the old -^geocode^- v2.0
-------

      Adam Ozimek
      Econsult Corporation
      ozimek@econsult.com
      
      Daniel Miles
      Econsult Corporation
      miles@econsult.com




