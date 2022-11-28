{smcl}
{* *! version 0.1.4  8 Nov 2022}{...}
{vieweralsosee "mpitb" "help mpitb"}{...}
{viewerjumpto "Syntax" "mpitb_stores##syntax"}{...}
{viewerjumpto "Description" "mpitb_stores##description"}{...}
{viewerjumpto "Options" "mpitb_stores##options"}{...}
{viewerjumpto "Remarks" "mpitb_stores##remarks"}{...}
{viewerjumpto "Examples" "mpitb_stores##examples"}{...}
{p2colset 1 17 18 2}{...}
{p2col:{bf:mpitb stores} {hline 2}}stores estimates into results frame{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd: mpitb stores, frame(}{it:name}{cmd:) loa(}{it:name}{cmd:)} 
{cmd: measure(}{it:name}{cmd:) spec(}{it:name}{cmd:)}  [{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent :* {opt fr:ame(name)}}name of results frame{p_end}
{p2coldent :* {opt l:oa(name)}}underlying level of analysis{p_end}
{p2coldent :* {opt m:easure(name)}}underlying measure{p_end}
{p2coldent :* {opt sp:ec}}underlying specification{p_end}
{synopt:{opt ct:ype(integer)}}the ctype of the estimate{p_end}
{synopt:{opt k(numlist)}}underlying poverty cutoff{p_end}
{synopt:{opt i:ndicator(name)}}underlying indicator{p_end}
{synopt:{opt w:gts(name)}}underlying weighting scheme{p_end}
{synopt:{opt tvar(varname)}}time variable{p_end}
{p2coldent :† {opt t0(value)}}time variable at begin of period of change{p_end}
{p2coldent :† {opt t1(value)}}time variable at end of period of change{p_end}
{p2coldent :† {opt yt0(year)}}year in t0{p_end}
{p2coldent :† {opt yt1(year)}}year in t1{p_end}
{p2coldent :† {opt ann(value)}}changes are annualised{p_end}
{synopt:{opt subg(numlist)}}level of subgroup variable{p_end}
{synopt:{opt add(string)}}add string as value for extra variable{p_end}
{synopt:{opt ts}}add data and estimation time stamps{p_end}
{synoptline}
{p 4 6 2}* required options; † required options if {it:ctype}=1,2.{p_end}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd: mpitb stores} may store results of an estimation into the results frame. 
Stored information includes the core of an estimate (e.g., point estimate, standard 
error, ...) and meta information describing content and context of the estimate 
(e.g., measure, indicator, level of analysis, etc). {cmd:mpitb stores} may store 
estimates of both levels and changes.{p_end}

{pstd}
{cmd:mpitb stores} is intended for advanced users and programmers who wish to add 
results of a custom estimation to their results frame. Estimates of standard quantities 
(e.g., adjusted headcount ratio, intensity, etc.) are automatically stored by 
{helpb mpitb_est:mpitb est}.{p_end}

{marker options}{...}
{title:Options}

{phang}
{opt fr:ame(name)} specifies the name of the frame where results are stored.

{phang}
{opt l:oa(name)} specifies the level of analysis to which the estimate refers. 

{phang}
{opt m:easure(name)} specifies the name of the measure to which the estimate refers. 

{phang}
{opt sp:ec(name)} specifies the name of the specification to which the estimate refers. 

{phang}
{opt ct:ype(integer)} specifies the {it:ctype} ("change type") of the estimate to store.
The {it:ctype} is 0 for "levels", 1 for "absolute changes" and 2 for "relative changes".

{phang}
{opt tvar(varname)} specifies the time variable, which identifies the different 
survey rounds in the data. This option is needed if you wish to store level
estimates over several survey rounds (harmonised over time data). In particular, 
this option is not needed to store estimates of {bf:changes} over time. 


{phang}
{opt t0(value)} specifies the initial period of a change according to the 
integer time variable.

{phang}
{opt t1(value)} specifies the final period of change according to the integer 
time variable.

{phang}
{opt yt0(year)} specifies the year in t0 and may contain decimal digits.

{phang}
{opt yt1(year)} specifies the year in t1 and may contain decimal digits.

{phang}
{opt ann(value)} specifies whether change estimate to be stored is annualised (=1) 
or not(=0).

{phang}
{opt add(string)} adds {it:string} as a value for the extra variable specified by the 
{cmd:add(}{it:name}{cmd:)} option of {helpb mpitb_rframe:mpitb rframe}.

{phang}
{opt ts} adds timestamp for the underlying data set and for estimation time.


{marker remarks}{...}
{title:Remarks}

{phang}
1. The basic usage is to (i) setup a results frame, (ii) perform the estimation and then (iii) 
store the estimate. There are two ways how to create a results frame. First, 
{helpb mpitb est} can be instructed to create a result frame, which remains 
accessible to the user after program completion. Second, {helpb mpitb rframe} is 
the underlying stand-alone tool.

{marker examples}{...}
{title:Examples}

    {hline}
{pstd}1. Storing a simple aggregate level estimate{p_end}

{pstd}Set up the results frame{p_end}

{phang2}{cmd:mpitb rframe , frame(mylevs)}

{pstd}Estimate the quantity of interest{p_end}

{phang2}{cmd:mean d_cm}

{pstd}Store estimate into results frame{p_end}

{phang2}{cmd:mpitb stores , fr(mylevs) loa(nat) m(hd) i(d_cm) spec(mympi)}

    {hline}
{pstd}2. Storing a simple level estimate for subgroups{p_end}

{phang2}{cmd:mpitb rframe , frame(mylevs)}

{phang2}{cmd:svy : mean d_nutr , over(area)}

{phang2}{cmd:mpitb stores , fr(mylevs) loa(area) meas(hd) i(d_nutr) spec(gmpi)}

    {hline}
{pstd}3. Storing an aggregate estimate for levels over time:{p_end}

{phang2}{cmd:mpitb rframe , fr(levot) t}

{phang2}{cmd:svy : mean d_cm , over(t)}

{phang2}{cmd:mpitb stores , fr(levot) loa(nat) meas(hd) i(d_cm) sp(gmpi) tvar(t)}

    {hline}
{pstd}4. Storing an estimate for levels over time for subgroups:{p_end}

{phang2}{cmd:mpitb rframe , fr(levot) t}

{phang2}{cmd:svy : mean d_cm , over(area t)}

{phang2}{cmd:mpitb stores , fr(levot) loa(area) meas(hd) i(d_cm) sp(gmpi) w(equal) tvar(t)}

    {hline}
{pstd}5. Storing proportions over time (with timestamps){p_end}

{phang2}{cmd:mpitb rframe , fr(levot) t ts}

{phang2}{cmd:svy: prop area}

{phang2}{cmd:mpitb stores , fr(level) loa(area) meas(popsh) sp(gmpi) ts}

    {hline}
{pstd}6. Storing a change estimate (raw and absolute change){p_end}

{phang2}{cmd:mpitb rframe , frame(cot) cot}

{phang2}{cmd:svy: mean d_satt if , over(t)}

{phang2}{cmd:lincom (d_satt@2.t - d_satt@1.t)}

{phang2}{cmd:mpitb stores , fr(cot) l(nat) m(hd) ct(1) sp(gmpi_cot) ann(0) yt0(2011) yt1(2014) t0(1) t1(2)}  


    {hline}
{pstd}7. Storing a change estimate and levels for a subgroup:{p_end}

{pstd}Storing changes of subgroups requires loops. Assume the time variable {it:t}
may be 1 or 2 whereas the variable {it:area} may either be 0 ("rural") or 1 ("urban")

{pstd}First we prepare two frames: one for levels, one for changes{p_end}

{phang2}{cmd:mpitb rframe , frame(level) t}

{phang2}{cmd:mpitb rframe , frame(cot) cot}

{pstd}Next we estimate levels for all subgroups at all points of time{p_end}

{phang2}{cmd:svy : mean d_nutr , over(t area)}

{pstd}Then we can store all levels{p_end}

{phang2}{cmd:mpitb stores , fr(level) l(area) m(hd) ct(0) sp(gmpi_cot) w(equal) tvar(t) ind(d_nutr)}

{pstd}Finally, we can estimate each change and store it immediately into the result frame{p_end}

{phang2}{cmd:forval s = 0/1 {c -(}}
		
{phang3}{cmd:lincom (d_nutr@`s'.area#2.t - d_nutr@`s'.area#1.t)}

{phang3}{cmd:mpitb stores , fr(cot) l(area) m(hd) ct(1) sp(gmpi_cot) ann(0) yt0(2011) yt1(2014) t0(1) t1(2)}

{phang2}{cmd:{c )-}}

    {hline}
	
