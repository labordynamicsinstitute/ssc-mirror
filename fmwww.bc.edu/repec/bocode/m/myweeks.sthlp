{smcl}
{* 10jun2024}{...}
{hline}
help for {hi:myweeks}
{hline}

{title:Numbered weeks from daily dates}

{p 8 17 2}
{cmd:myweeks}
{it:dailydatevar}
{ifin}
{cmd:,}
{cmdab:gen:erate(}{it:newvar}{cmd:)}
[
{cmdab:dow:start(}{it:#}{cmd:)}
{cmdab:daily:date} 
{cmd:format(}{it:format}{cmd:)} 
]


{title:Description}

{p 4 4 2}
{cmd:myweeks} takes a numeric daily date variable assumed to follow Stata's
rule that daily dates are integers counted from 0 at 1 January 1960 and
generates a new variable numbering the distinct weeks in which they occur 
with distinct integers. 

{p 4 4 2}
{cmd:myweeks} uses the following rules. 

{p 8 8 2}
1. Each week starts on a particular day of the week, one of Sunday to
Saturday. 

{p 8 8 2}
2. By default weeks start on Sundays, for which the Stata function 
{help dow()} returns 0. You may choose a different day to start the
week by specifying {cmd:dowstart()} with an integer between 1 (meaning
Monday) and 6 (meaning Saturday). 

{p 8 8 2}
3. By default {cmd:myweeks} uses a rule broadly similar to those used in
official Stata: the first complete week within 1960 using the rules so
far is numbered 0. This is best explained by example. 1 January 1960,
daily date 0, was a Friday for which {cmd:dow()} returns 5. So 2 January
1960 was a Saturday and 3 January 1960 was a Sunday. Hence week 0 starts
on 3 January 1960 if weeks start on day of the week 0, meaning Sunday.
Similarly week 0 starts on 4, 5, 6, 7 January if weeks start on days of
the week 1, 2, 3, 4, but on 1, 2 January if weeks start in days of the
week 5, 6. Any previous weeks in the data are indexed with negative
integers. Any later weeks are indexed with positive integers. 

{p 8 8 2}
4. Optionally you may specify using the {cmd:dailydate} option that
weeks as defined here are indexed by the daily dates that start them.
Such week indexes differ by multiples of 7. Users proceeding to 
{help tsset} or {help xtset} will often find it essential in due course to
specify the option {cmd:delta(7)}. 


{title:Remarks} 

{p 4 4 2}
Dates in Stata are complicated because dates are complicated.  You may
have been familiar long since with many of the rules governing the
calendar, but that should not lead you to suppose that working with
dates will always be simple. There are many different date
conventions and Stata may need to be told about yours.  Weeks are
especially complicated because several definitions are in use,
implying different code both for identifying weeks and for working with
weekly data for weekly dates or for any other dates. 

{p 4 4 2}
Stata's official functionality for weeks hinges on an idiosyncratic
definition: week 1 of any year always starts on 1 January in that
year and subsequent weeks in the same year start at multiples of 7 days
later, except that week 52 is always 8 or 9 days long. No week 53 is 
ever observed. This definition is documented, but many users have not 
read the documentation or failed to think through its consequences. 
Stata's definition ensures that weeks always nest within years, but it 
is not consistent with any other definition of week.  See, for example, 
Cox (2010, 2012a, 2012b, 2019, 2022a, 2022b) on a variety of related 
challenges. That is more references than you may want to be given. 
Cox (2010) is most relevant, but not essential, for understanding 
the main idea here. 

{p 4 4 2} 
Warning: The whole point of {cmd:myweeks} is to step outside
Stata's official functionality for weeks and to offer an alternative. It
is consistent only with Stata's {help dow()} function and whatever is
consistent with that. It neither assumes nor can be used successfully in
conjunction with Stata's own weekly dates; nor with functions such as
{help yw()}, 
{help weekly()}, 
{help week()}, 
{help dofw()} or 
{help wofd()}; nor with Stata's display formats for weekly dates. 
Weeks as numbered by {cmd:myweeks} will often span years, starting in
one year and ending in the next.  

{p 4 4 2}
{cmd:myweeks} is often redundant. Quite commonly, weekly data arrive
indexed by a daily date variable with values 7 days apart. Such dates 
may be simply understood and used without needing to be converted to any
other form. In particular, they lend themselves to easily understood 
graphics or tabulations. Crucially, however, the time step of 7 days 
may need to be explained, as already mentioned. 

{p 4 4 2}
{cmd:myweeks} does not assume completeness of dates in any sense. You
may have daily dates only for certain days of the week, say weekdays
Mondays to Fridays. You may lack data for public holidays.  You may have
gaps in your dataset in which certain weeks are absent and not
represented by any daily dates. The command will not be fazed by such
incomplete data.

{p 4 4 2}
A preference for defining a week by the day of the week on which it ends can 
be met with two simple twists. For example, weeks defined to end on Fridays 
necessarily start on Saturdays and each ending Friday is 6 days later than the 
starting Saturday. Otherwise see Cox (2010). This point is developed 
in the code examples. 

{p 4 4 2}
You may seek a numbering scheme that differs from what is provided by
{cmd:myweeks}.  Other than writing your own code, that is best achieved
by following this command with {cmd:summarize} and adjusting your
numbering using the minimum shown, accessible as {cmd:r(min)}. No such
option is provided here to emphasize that any such variation is your
responsibility. At the risk of stating the obvious: If you are using
different datasets that you will eventually {help append} or 
{help merge}, it is best to change to your own numbering scheme only when all
datasets have been combined. If you use {cmd:myweeks} consistently,
datasets can be combined confidently. In addition, be wary of 
{help egen}'s {cmd:group()} function: although it helpfully maps a sequence 
of increasing values to integers 1 up, it will ignore gaps in any sequence. 

{p 4 4 2}
Users sometimes want to combine weeks into longer periods, lasting say 2,
3 or 4 weeks. For such aggregation, my best advice is to use 
{help floor()} or {help ceil()}, say as discussed in Cox (2018).  

{p 4 4 2}
Once you have classified daily dates into weeks, you may wish to proceed
with some kind of reduction using that framework, either with or without
some other classification, say into panel or longitudinal data. In
addition to official commands such as {help collapse}, {help contract},
and {help table}, {help rangestat} and {help rangerun} from SSC address
certain fairly common needs.


{title:Options}

{p 4 8 2}
{cmd:generate()} specifies a new variable name to hold week numbers. 
This is a required option. 

{p 4 8 2}
{cmd:dowstart()} specifies a day of the week on which weeks are deemed
to start.  The syntax is consistent with that of official function 
{help dow()} and may specify any integer between 0 for Sunday and 6 for
Saturday. The defult is 0. 

{p 4 8 2} 
{cmd:dailydate} specifies that weeks should be specified by the daily 
date of the first day of the week. It is not a problem if such a daily
date is not represented in the data. 

{p 4 8 2}
{cmd:format()} specifies a format for the daily date variable requested 
with the previous option. The default is {cmd:%td}. The only check on any
format specified is that it works with integers. You are warned against the
fallacy that specifying a date format other than a daily date format is
a way to convert one kind of date to another: see Cox (2012c).
 

{title:Examples}

{p 4 8 2}{cmd:. clear}{p_end}
{p 4 8 2}{cmd:. set obs 42}{p_end}

{p 4 8 2}{cmd: . * sandbox: first 21 days of 1960; 21 days centred on current date}{p_end}
{p 4 8 2}{cmd:. gen date = mdy(1, _n, 1960) in 1/21}{p_end}
{p 4 8 2}{cmd:. replace date = daily("$S_DATE", "DMY") + (_n - 32) in 22/42}{p_end}
{p 4 8 2}{cmd:. format date %td}{p_end}
{p 4 8 2}{cmd:. gen dow = dow(date)}{p_end}
{p 4 8 2}{cmd:. gen which = _n > 21}{p_end}

{p 4 8 2}{cmd:. * week numbers starting each day of the week}{p_end}
{p 4 8 2}{cmd:. forval d=0/6 {c -(}}{p_end}
{p 4 8 2}{cmd:. {space 4}myweeks date, gen(w`d') dowstart(`d')}{p_end}
{p 4 8 2}{cmd:. {space 4}myweeks date, gen(W`d') dowstart(`d') daily}{p_end}
{p 4 8 2}{cmd:. {space 4}local show `show' w`d' W`d'}{p_end}
{p 4 8 2}{cmd:. {c )-}}{p_end}

{p 4 8 2}{cmd:. list date dow `show', sepby(which w0)}{p_end}

{p 4 8 2}{cmd:. * weeks ending Friday}{p_end}
{p 4 8 2}{cmd:. myweeks date, gen(wef) dowstart(6)}{p_end}
{p 4 8 2}{cmd:. myweeks date, gen(WEF) dowstart(6) dailydate}{p_end}
{p 4 8 2}{cmd:. replace WEF = WEF + 6}{p_end}

{p 4 8 2}{cmd:. list date dow wef WEF, sepby(which wef)}{p_end}


{title:Author}

{p 4 4 2}Nicholas J. Cox, Durham University{break} 
         n.j.cox@durham.ac.uk


{title:References} 

{p 4 8 2}
Cox, N.J. 2010. Stata tip 68: Week assumptions.
{it:Stata Journal} 10(4): 682{c -}685. 

{p 4 8 2}    
Cox, N.J. 2012a. Stata tip 111: More on working with weeks.
{it:Stata Journal} 12(3): 565{c -}569. 
		
{p 4 8 2}
Cox, N.J. 2012b. Stata tip 111: More on working with weeks, erratum.
{it:Stata Journal} 12(4): 765. 

{p 4 8 2}
Cox, N.J. 2012c. Stata tip 113: Changing a variable's format: 
What it does and does not mean. 
{it:Stata Journal} 12(4): 761{c -}764.            

{p 4 8 2}		
Cox, N.J. 2018. Speaking Stata: From rounding to binning. 
{it:Stata Journal} 18(3): 741{c -}754. 
        
{p 4 8 2}
Cox, N.J. 2019. Speaking Stata: The last day of the month. 
{it:Stata Journal} 19(3): 719{c -}728. 

{p 4 8 2}
Cox, N.J. 2022a. Stata tip 145: Numbering weeks within months.
{it:Stata Journal} 22(1): 224{c -}230. 

{p 4 8 2}
Cox, N.J. 2022b. Erratum: Stata tip 145: Numbering weeks within months.
{it:Stata Journal} 22(2): 465{c -}466. 


{title:Also see}

{p 4 4 2}
Online:  help for {help datetime},{break}
{help datetime functions},{break}
{help datetime display formats},{break}
{help tsset},{break}
{help xtset}
{p_end}
