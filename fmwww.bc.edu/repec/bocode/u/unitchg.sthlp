{smcl}
{* April 3, 2025 @ 17:08:48 UK}{...}
{hi:help unitchg} 
{hline}

{title:Title}

{phang}
{cmd:egen-unitchg()} and {cmd:unitchg} Conversion of units
{p_end}

{title:Syntax}
{p 8 17 2} {cmd: unitchg} [ # | [{it:converter}s] [{it:search-term} ] ] [ , options]{p_end}
{p 8 17 2} {cmd: egen} [type] newvar = unitchg(varname)  , {it:converter}({it:unit})  [options] {p_end}

{pstd} {cmd:#} is a number, {it:converter} is one of the converters
specified below und {it:unit} is a name, or a short name of a unit of
measurement. {it:search-term} is a string to search for availabel
units in a converter. {p_end}

{synoptset 20 tabbed}
{synopthdr}
{synoptline}
{syntab:converter}
{synopt:{opt an:gle(unig)}} conversion between units of angles, e.g. radian, gon, sextant, ...{p_end}
{synopt:{opt ar:ea(unit)}} conversion between units of areas, e.g. acre, are, m^2, ...{p_end}
{synopt:{opt c:urrency(unit)}} conversion between currencies, e.g. EUR, NZD, USD, ...{p_end}
{synopt:{opt datas:torage(unit)}} conversion between units of data storages, e.g. byte, floppy, nibble, ...{p_end}
{synopt:{opt datat:ransfer(unit)}} conversion between units of data transfers, e.g. byte/s, ethernet, USB, ...{p_end}
{synopt:{opt l:ength(unit)}} conversion between units of length, e.g. meter, inch, furlong, span ...{p_end}
{synopt:{opt m:ass(unit)}} conversion between units of masses, e.g. gram, ounce, carat, livre ...{p_end}
{synopt:{opt mil:eage(unit)}} conversion between units of mileages, e.g. miles per gallon, liter per km ...{p_end}
{synopt:{opt s:peed(unit)}} conversion between units of speed, e.g. miles per hour, km/100 km, knots, ...{p_end}
{synopt:{opt temp:erature(unit)}} conversion between units of temperatures, e.g. kelvin, fahrenheit, rankine, ...{p_end}
{synopt:{opt ti:me(unit)}} conversion between units of time, e.g. hour, moment, lunar year, ...{p_end}
{synopt:{opt v:olume(unit)}} conversion between units of volumes, e.g. liter, teaspoon, stere ...{p_end}

{syntab:common option}
{synopt:{opt to(unit)}} any unit available for the converter{p_end}

{syntab:currency option}
{synopt:{opt d:ate(date)}} mandatory date or range of dates for the currency conversion{p_end}

{syntab:option for some converters}
{synopt:{opt decimal(type)}} meaning of decimal numbers in some conveters{p_end}

{pstd}{bf:Note:} The converter-name is specified as option in the
egen-function and when specifying {cmd:unitchg} with a number. It can
be also specified in plural as program arguemt (without parentheses) for
{cmd:unitchg} to list all availble units.
 
{title:Description}

{pstd} Both, the command {cmd:unitchg} and the egen-function
{cmd:unitchg()} convert units of measurement into many other units of
measurements. {cmd:unitchg} displays the number {cmd:#} converted to
the other unit. The egen-function {cmd:unitchg()} creates the new
variable {it:newvar} holding the numbers {it:varname} converted to
the other unit. {p_end}

{pstd} {cmd:unitchg} and {cmd:unitchg()} allow conversion between many units,
including historical units that have been forgotten, or no longer in
use. An alphabetic list of the available units for each converter is
shown with {cmd:unitchg {it:converter}}. The list of available units
can be searched by issuing {cmd:unitchg {it:converter}} with a
case-insensitve {it:search-term}.{p_end} 

{title:Options}

{phang}{opt angle(unit)} is used to convert units of angles into other
units of angles. Unit is any of the short or long names listed in the
output of {stata unitchg angles}. By default, units are converted to
radians (rad). {p_end}

{phang}{opt area(unit)} is used to convert units of areas into other
units of area. Unit is any of the short or long names listed in the
output of {stata unitchg areas}. By default, units are converted to
square meters. Note that any of the lengths available for the
{cmd:length()} converter can be also used for {cmd:area()}. If used,
they are interpreted as square-lengths (i.e. specifying
{cmd:unit(inch)} converts square-inches to square meters.{p_end}

{phang}{opt currency(unit)} is used to convert currencies into other
currencies. Unit can be any of the short names listed in the
output of {stata unitchg currencies}.{p_end}

{pmore}Units are converted to EUR using the exchange rate
of the day, yearly average, or
average of an arbitrary periods specified in the mandatroy option {cmd:date()}
{p_end}

{pmore}The currency-conversion is done by means of the
{it:Frankfurter} API (https://frankfurter.dev/) which tracks exchange
rates published by institutional and non-commercial sources like the
European Central Bank. Since the exchange rates are taken from the
Internet, an Internet connection is required for the conversion of
currencies.{p_end}

{phang}{opt datastorage(unit)} is used to convert units to measure
data storage into other units of data storage. Unit is any of the short or
long names listed in the output of {stata unitchg datastorages}. By
default, units are converted to bytes. {p_end}

{phang}{opt datatransfer(unit)} is used to convert units to measure
the speed of data transfer into other units of data transfer. Unit is
any of the short or long names listed in the output of {stata unitchg
datatransfer}. By default, units are converted to bytes per second. {p_end}

{phang}{opt date(date-string)} is a mandatory option for the conversion of
currencies. It is used to specify the date or period
for the conversion. It allows the key-words "today" and "yesterday", as well as
any other date specified in the format day, month, year
(e.g. "7/4/2025", or "7 apr 2025", etc.). Morover,
a year (e.g. "2020") can be used to apply the conversion on the
average exchange rate for the specified year. Any other period can be
specified with the syntax {cmd:{it:start}:[{it:end}]}, whereby both,
{cmd:{it:start}} and {cmd:{it:start}} can be either a year or a date
in the format day, month year. If a year is specified for {it:start}
the period starts at January 1st of the given year. If a year is
specified for {it:end}, the period ends at December 31th of the given
year. If {it:end} is left unspecified, the end of the period is set to
the current date. {p_end}

{phang}{opt decimal(string)} is used to specify the meaning of the
numbers behind the decimal point in some units of time and length. By
default the als converters interprets numbers behind the decimal point
as decimals, e.g. the converter for time interprets 4.5 hours as 4
hours and 30 minutes, and the converter length interprets 4.5 feet as
4 and a half feet. The option decimal can be used to specify that 4.5
should be interpreted as 4 hours and 50 minutes, or 4 feet and 5
inches, respectively.  The option allows the following
settings:{p_end}

{p2colset 10 17 20 40}
{p2line}
{p2col:doy} days of year; x.42 is interpreted as 42/365.25{p_end}
{p2col:dom} days of month; x.24 is interpreted as 24/30{p_end}
{p2col:dow} days of week; x.4 is interpreted as 4/7{p_end}
{p2col:hour} hour of day; x.23 is interpreted as 23/24{p_end}
{p2col:minute} minute of hour; x.42 is interpreted as 42/60{p_end}
{p2col:second} second of minute; x.42 is interpreted as 42/60{p_end}
{p2col:inch} inch within feet; x.11 is interpreted as 11/12{p_end}
{p2line}
{p2colreset}

{phang}{opt length(unit)} is used to convert units of length into
other units of length. Unit is any of the short or long names listed
in the output of {stata unitchg lenthts}. By default, units are
converted to meters. Note that any of the lengths can be also used for
the converters {cmd:area()} and {cmd:volumes()}. In this cases they
are taken as square-lengths, or cubic-lengths, respectively.{p_end}

{phang}{opt mass(unit)} is used to convert units of masses into
other units of masses. Unit is any of the short or long names listed
in the output of {stata unitchg masses}. By default, units are
converted to grams.{p_end}

{phang}{opt mileage(unit)} is used to convert units of mileage into
other units of mileage. Unit can be any combination of the lengths and
capacities listed in the output of {stata unitchg lengths} and
{stata unitchg volumes}. Use "/" to define the nominator and the denominator
of the unit in the normal way. By default, units are converted to meters per cubic
meter.{p_end}

{phang}{opt speed(unit)} is used to convert units of speed into other
units of speed. Unit can be any combination of the lengths and times
listed in the output of {stata unitchg lengths} and {stata unitchg
times}. Use "/" to define the nominator and the denominator of the
unit in the normal way. By default, units are converted to meters per
second.{p_end}

{pmore}If speed is expressed in terms of time per length, the meaning
of the decimal point of the number to be converted can be changed with 
{cmd:decimal()}.{p_end}

{phang}{opt temperature(unit)} is used to convert units of
temperatures into other units of temperatures. Unit is any of the
short or long names listed in the output of {stata unitchg temperatures}. By
default, units are converted to °Kelvin.{p_end}

{phang}{opt time(unit)} is used to convert units of time into other
units of temperatures. Unit is any of the short or long names listed
in the output of {stata unitchg time}. By default, units are converted
to seconds.{p_end}

{pmore} By default, numbers behind the decimal point are
interpreted as decimals, i.e. 4.5 hours is 4 hours and 30 minutes. The
meaning of the numbers behind the decimal point can be changed with
option {cmd:decimal()}.{p_end}

{phang}{opt to(unit)} is used to specify the name of the unit to which
the number {cmd:#} or the contents of {cmd:{it:varname}} is converted
to. Any of the units allowed for the converter can be used here. See
the description of the respective converter for the default unit in
case {cmd:to()} is left unspecified.{p_end}

{phang}{opt volume(unit)} is used to convert units of
volumes into other units of volumes. Unit is any of the
short or long names listed in the output of {stata unitchg volumes}. By
default, units are converted to cubic meters.{p_end}


{title:Precision}

{pstd} Conversion is done in two steps throughout: On the first step,
units are converted to the base unit, on the second step the unit is
converted from the base unit into the unit given by the option
to(). The process may lead to precision problems for units that are
very different from the base unit. As a consequence, {cmd:unitchg}
only allows conversions to units convertable using a rescale factor
that can be expressed in float precision. This pretty much limits the
units to those that measure quantities on earth. {p_end}

{pstd}Any converter is tested by cycling through all available units
and than test whether the original number can be reproduced within
float precision. This procedure should guarentee a reasonable degree
of precision for all units provided. Nevertheless it is not
necessarily a good idea to express nano-meters in, say, lightminutes,
or terraliters in teaspoons. Both are possible, though:
{p_end}

{phang}. {stata unitchg 1, length(nm) to(light-minute)}{p_end}
{phang}. {stata unitchg 1, volume(Tl) to(tsp)}{p_end}


{title:Example(s) for unitchg}

{phang}Typing {cmd:unitchg} without options shows a list of available
converters:

{phang}. {stata unitchg}{p_end}

{phang}Lists of units available for a specific converters can be
requested with variants of the following: 

{phang}. {stata unitchg lengths}{p_end}
{phang}. {stata unitchg currencies}{p_end}

{phang}The following searches for units of lengths that are related to
the United Kingdom:

{phang}. {stata unitchg lengths UK}{p_end}

{phang}The following examples show variants of the command to display
the number 1 in a given unit converted to the base unit of the specified converter:

{phang}. {stata unitchg 1, length(in)}{p_end}
{phang}. {stata unitchg 1, length(UK nauticmile)}{p_end}
{phang}. {stata unitchg 1, temperature(Rømer)}{p_end}
{phang}. {stata unitchg 1, currency(TRY) date(today)}{p_end}

{phang}The following examples show variants of the command to display
various quantities in a given unit converted to some other unit:{p_end}

{phang}. {stata unitchg 42.195, length(km) to(mile)}{p_end}
{phang}. {stata unitchg 42.195, length(km) to(mile(Roman))}{p_end}

{phang}. {stata unitchg 0.75, volume(l) to(vodka bottle (RU))}{p_end}
{phang}. {stata unitchg 1, volume(US teaspoon) to(UK teaspoon)}{p_end}

{phang}German Stata users may be relieved to realize that they can
express areas into units of Saarland. For example, the United States
is 3,809,525 square miles which is as big as around 3840
Saarland's:{p_end}

{phang}. {stata unitchg 3809525, area(mi^2) to(saarland)}

{title:More example(s) for currencies}

{phang}By default, currencies are converted using the exchange rate of
the current day. This can be changed by means of the option
{cmd:date()}. The following converts 42 Turkish Lira into Euro based
on the exchange rate of April 7th 2000:

{phang}. {stata unitchg 42, currency(TRY) date(7 April 2010)}{p_end}

{phang}You can also request conversion using the average exchange rate
of a period. Here is an example that uses year's 2010 average exchange
rate to convert 42 Turkish Lira into Polish Złoty:

{phang}. {stata unitchg 42, currency(TRY) to(PLN) date(2010)}{p_end}

{phang}Use the syntax ({it:start}:{it:end}) to fine tune the period
for calculating the average exchange rate for the conversion. The
following uses the average exchange rate of the period from April 7
2010 to the last day of 2011:

{phang}. {stata "unitchg 42, currency(TRY) to(PLN) date(7 April 2010:2011)"}{p_end}

{phang}Specifiying a period without end requests a conversion based on
the average exchange for the period from the starting day to the
current day. Thus, the following uses the average exchange rate of the
first day of 2025 until the day you issue the command: 

{phang}. {stata "unitchg 42, currency(TRY) to(PLN) date(2025:)"}{p_end}

{title:Example(s) for egen-unitchg()}

The egen-function {cmd:unitchg()} works similar to {cmd:unitchg} on
numbers. The difference is that the input stems from a variable in the
dataset and the output is written to a new command. The following
shows how to convert the vthe auto data into a
more European version:

{phang}. {stata sysuse auto}{p_end}
{phang}. {stata egen mileageEU = unitchg(mpg), mileage(mi/gal_US) to(l/100 km)}{p_end}
{phang}. {stata egen headroomEU = unitchg(headroom), length(in) to(cm)}{p_end}
{phang}. {stata egen trunkEU = unitchg(trunk), volume(ft^3) to(l)}{p_end}
{phang}. {stata egen weightEU = unitchg(weight), mass(lb) to(kg)}{p_end}
{phang}. {stata egen lengthEU = unitchg(length), length(in) to(m)}{p_end}
{phang}. {stata egen displacementEU = unitchg(displacement), volume(in^3) to(cm^3)}{p_end}
{phang}. {stata list make *EU in 1/10}{p_end}


{title:Author}

Ulrich Kohler
{browse "mailto:ulrich.kohler@uni-potsdam.de"}

{title:Acknowledgement}

{phang}The converters for areas, datastorages, datatransfers, lengths,
masses, and volumes are based on conversion factors taken from 
{browse "https://www.translatorscafe.com/unit-converter/en-US/"}
{p_end}

{phang}The converter for angles is based on conversion factors taken from
{browse "https://www.calculatorsoup.com/calculators/conversions/angle.php"}
{p_end}

{phang}The converter for temperatures is based on conversion formulas
taken from {browse "https://en.wikipedia.org/wiki/Conversion_of_scales_of_temperature"}
{p_end}

{phang}The converter for time is based on factors taken from taken
from {browse "https://en.wikipedia.org/wiki/Unit_of_time"}. The Hindu
units of time are based on the table "Sidereal Units" on
{browse "https://en.wikipedia.org/wiki/Hindu_units_of_time"}
{p_end}

{phang}I do not automatically update the above sources in case of
corrections. I am solely responsible for any errors in the conversion
of these converters.
{p_end}

{phang}The converter for currencies is a call to the Frankfurter API
at {browse "https://api.frankfurter.dev"}.
{p_end}

{phang}I thank the maintainers, contributers and developers of all the
above web-pages. I also thank the particpants of the 22nd German Stata
Conference in Hamburg for comments and suggestions.{p_end}

{title:Also see}

{psee}
Online: help for {help cm2in}, {help msq2ftsq}, {help g2oz} (if installed)
{p_end}

 
