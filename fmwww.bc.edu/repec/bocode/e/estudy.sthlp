{smcl}
{* *! version 1.0.0  08jan2018}{...}

{title:Title}

{p2colset 5 14 0 0}{...}
{p2col :{ helpb estudy } {hline 2} Event study}{p_end}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:estudy} performs an event study with and without event date clustering on several groups of variables, by permitting to specify multiple varlists, and over different event windows (up to six). Both parametric and non-parametric diagnostic tests are allowed, while the analytical set-up as well as the output's contents and layout can be customized by means of several options. Prices can be used as inputs, as the the program will compute returns.{p_end}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{opt estudy} {it:varlist1} [({it:varlist2})... ({it:varlistN})] [{cmd:,} {it:options}]

{phang}
{it:varlist1} [({it:varlist2})... ({it:varlistN})] specify the securities returns (or prices when {opt price} option has been set) necessary to perform the event study. {cmd:estudy} treats each varlist as independent, computing portfolios and/or average CARs for each one of them.{p_end}

{synoptset 47 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Date specifications}
{p2coldent:* {opth dat:evar(varname)}}specify the date variable in the dataset. Option {opt datevar}  must be always specified and sorted in chronological order.{p_end}
{p2coldent:* {opth evd:ate(strings:string)} or {opth evd:ate(varlists:namelist datelist)}}specify {opth evd:ate(strings:string)} in case of common event/event date clustering or {opth evd:ate(varlists:namelist datelist)} in case of multiple events (i.e. when each security has its own event date). Either as {it:string} or as {it: namelist datelist}, the {opt evdate} option must be always specified.{p_end} 
{p2coldent:* {opt lb1(#)} {opt ub1(#)} [{cmd:... lb6(#) ub6(#)}]}specify lower and upper bounds of event window(s). Only the first upper ({opt lb1(#)}) and lower ({opt ub1(#)}) bounds must be always specified.{p_end}
{synopt :{opt eswlb(#)}}specify the lower bound of the estimation window; default is the first trading day available.{p_end}
{synopt :{opt eswub(#)}}specify the upper bound of the estimation window; default is {cmd:eswlb(-30)}.{p_end}

{syntab:Model}
{synopt :{opth modt:ype(strings:string)}}specify the model to compute ARs; {it:modtype} may be {opt SIM}, {opt MAM}, {opt MFM} or {opt HMM}; default is {cmd:modtype(SIM)}.{p_end}
{p2coldent:* {opth ind:exlist(varlist)}}specify the varlist used to compute (ab)normal returns. Indexlist option must be specified with all models except the Historical Mean Model (this latter specified as {cmd:modtype(HMM)}).{p_end}
{p2coldent:* {opth datef:ormat(strings:string)}}indicate the format of the event date ({opt evdate(string)} option) in case of event date clustering; {it:dateformat} may be: {cmd:MDY}, {cmd:DMY} or {cmd:YMD}.{p_end}
{synopt :{opth diagn:osticsstat(strings:string)}}specify the diagnostic test; {it:diagnosticsstat} may be {opt Norm}, {opt Patell}, {opt ADJPatell}, {opt BMP}, {opt KP}, {opt Wilcoxon} or {opt GRANK}; default is {cmd:diagn(Norm)}.{p_end}
{synopt :{opt price}}specify that prices, instead of returns, are provided in {it:varlist1 ... varlistN} as well as in {opt indexlist} option.{p_end}

{syntab:Output}
{synopt :{opth supp:ress(strings:string)}}suppress part of the output; {it:suppress} may be {opt ind} or {opt group}.{p_end}
{synopt :{opt dec:imal(#)}}set the number of decimals for the output table; default is {cmd:decimal(2)}, maximum is {cmd:7}.{p_end}
{synopt :{opt showp:values}}add a row below ARs, reporting pvalues.{p_end}
{synopt :{opt nos:tar}}hide significance stars (and the associated legend) from the output table.{p_end}
{synopt :{opth outp:utfile(strings:filename)}}store results in a .xlsx file (filename is required).{p_end}
{synopt :{opth myd:ataset(strings:datasetname)}}store results in a .dta file (filename is required).{p_end}
{synopt :{opt tex}}report the output table in {it:tex} format.{p_end}
{synopt :{opt graph}(# # [{it:, save}])}graph the cumulative ARs over the customized window as specified by means of the lower and upper bounds; suboption {opt save} stores figure in the directory in use.{p_end}
{synopt :{opt d:etails}}show a detailed output including warning messages, if any.{p_end}

{synoptline}
{p2colreset}{...}
{p 4 6 2}* These options are required{p_end}

{marker options}{...}
{title:Options}

{dlgtab:Date specifications}

{phang}
{opt datevar(varname)} specifies the name of the date variable in the dataset. The program cannot perform an event study if the time series of securities return is not linked to a date variable. If the variable reported in {cmd:datevar} is not formatted as date, the program returns an error.{p_end}

{phang}
{opt evdate(string)} or {opt evdate(namelist datelist)}, respectively, specify the event date (in case of event day clustering) or the securities and the corresponding event dates in case of multiple events. Specifically: {p_end}
{pmore}
    - {bf: With common event date}: {opt evdate(string)} specifies the {it:common event date}. It must be "{it:mmddyyyy}" "{it:ddmmyyyy}" "{it:yyyymmdd}" when the {opt dateformat} is, respectively, {bf:MDY} {bf:DMY} {bf:YMD}.{p_end}
{pmore}
    - {bf: With multiple event dates}: {opt evdate(namelist datelist)}, where {it:namelist} is a string variable and {it:datelist} is a date variable, specifies the {it:multiple event dates}. {p_end}
{pmore}
        The string variable ({it:namelist}) must include the name of all the variables specified in {it:varlist1}...{it:varlistN}. {p_end}
{pmore}
        The date variable ({it:datlist}) must include the event dates corresponding to the variables specified in {it:namelist}. {p_end}

{phang}
{opt dateformat(string)} specifies the format of the event date in case of event day clustering. {cmd:MDY}, {cmd:DMY} or {cmd:YMD}, indicate that the event date {cmd:evdate} has been specified respectively as {it:"mmddyyyy"}, {it:"ddmmyyyy"} or {it:"yyyymmdd"}. In case of multiple event dates, {cmd: estudy} ignores the {opt dateformat} option and returns a warning message. {p_end}
 
{phang}
{opt lb1(#)} {opt ub1(#)} [{cmd:... lb6(#) ub6(#)}] specify up to 6 event windows (only the first one is required), the event date being the day 0. For each event window, both lower and upper bounds must be specified. They must be indicated as integer values.{p_end}

{phang}
{opt eswlb(#)} and {opt eswub(#)} specify lower and upper bounds of the estimation window. By default, the lower bound is the first trading day available, and the upper bound is the 30th trading day before the event.{p_end}

{dlgtab:Model}

{phang}
{opt modtype(string)} specifies the model to compute ARs; {cmd:modtype} may be:{p_end}
{phang2}
i) {opt SIM} ({it:Single Index Model}), the default option, requires to specify only one variable (factor) in {cmd:indexlist}{p_end}
{phang2}
ii) {opt MAM} ({it:Market Adjusted Model}), requires to specify only one variable (factor) in {cmd:indexlist}{p_end}
{phang2}
iii) {opt MFM} ({it:Multi-Factor Model}), requires to specify more than one variable (factors) in {cmd:indexlist}{p_end}
{phang2}
iv) {opt HMM} ({it:Historical Mean Model}), ignores {cmd:indexlist}{p_end}

{phang}
{opt indexlist(varlist)} specifies the variable(s) useful to compute normal and abnormal components of securities return specified in {it: varlist1}...{it:varlistN}. Prices are allowed only if the option {opt price} has been specified. It is conditional to {cmd:modtype}:{p_end}
{pmore}
{it:Single index model} ("SIM") and {it:market adjusted model} ("MAM") require only one variable, whereas {it:multi-factor model} ("MFM") requires more than one variable.
With {it:historical mean model} ("HMM") the program ignores this option.{p_end}

{phang}
{opt diagnosticsstat(string)} allows the user to select the statistical test for the ARs significance (parametric and non-parametric tests are available). {p_end}
{pmore}
Parametric tests are: {p_end}
{phang3} 
1) {opt Norm}, the default option, is based on the Normal distribution{p_end}
{phang3}
2) {opt Patell}, following the Patell (1976) approach{p_end}
{phang3}
3) {opt ADJPatell}, performs the Patell's test with the Kolari and Pynnonen (2010) adjustment for cross-correlation of ARs{p_end}
{phang3}
4) {opt BMP}, performs the test proposed by Boehmer, Musumeci and Poulsen (1991){p_end}
{phang3}
5) {opt KP}, performs the BMP's test with the Kolari and Pynnonen (2010) adjustment for cross-correlation of ARs{p_end}
{pmore}
Non-parametric tests are {p_end}
{phang3}
1) {opt Wilcoxon}, performs the the signed-rank test, proposed by Wilcoxon (1945){p_end}
{phang3}
2) {opt GRANK}, performs the generalized RANK test, proposed by Kolari and Pynnonen (2011){p_end}

{dlgtab:Output}

{phang}
{opt suppress(string)} sets the format of the output table.{p_end}
{pmore}
{opt ind} hides single securities from the output table, while {opt group} keeps them only; by default, single securities, average and portfolio ARs are shown.
{cmd:suppress} cannot be used with only one variable specified in varlist. Option {cmd: suppress} is also valid for tables exported with {cmd: outputfile}, {cmd: mydataset} options as well as for results stored in the return list and graphs generated through the {cmd:graph} option.
{p_end}

{phang}
{opt graph}(# # [{it:, save}])} plots the cumulative ARs over the period specified by means of the two scalars, respectively indicating the lower and the upper bouds of the figure.{p_end}
{pmore}
    The suboption {it:save} stores figures in the directory in use.

{marker Remarks}{...}
{title:Remarks}

{phang}
If an event window does not contain any value, the output will show ARs (p-values) equal to 0 (".").{p_end}

{phang}
{cmd: estudy} shows messages and warnings (e.g. number of observations in the estimation windows) only if the otpion {opt details} has been specified. {p_end}

{phang}
If the event date occurs on Saturday or Sunday, {cmd:estudy} substitutes it with the first following Monday and considers it as (+1) day (the Friday is considered as -1, accordingly).
If such a date is still not available, the program terminates showing an error message. {p_end}

{phang}
Labels cannot contain the "." character. Their length is automatically cut to 45 characters (if in excess), or to 32 characters if the {cmd: outputfile} and/or {cmd: mydataset} options have been specified.{p_end}

{phang}
{cmd: estudy} shows in the output tables (and in the .xslx, .dta files and return list as well) the label of each variable indicated in the {it: varlist1}, ..., {it: varlistN}. If labels are missing, variable names are used.{p_end}

{marker example}{...}
{title:Example}

{pstd}Setup{p_end}
{phang2}{cmd:. use data_estudy.dta}{p_end}

{pstd}Performs an event study on two varlists using returns, specifying three event windows on a common event date (December 4, 2016), using the Bohemer, Musumeci and Paulsen test.{p_end}
{phang2}{bf: estudy ret_ibm ret_cocacola ret_boa ret_ford ret_boeing (ret_apple ret_netflix ret_google ret_facebook) datevar(date) evdate(12042016)}{p_end}
{pmore}
	{bf: dateformat(MDY) modt(MFM) indexlist(ret_mkt ret_smb ret_hml) diagn(BMP) lb1(-3) ub1(0) lb2(0) ub2(5) lb3(-3) ub3(3) dec(4)}{p_end}

{pstd}Performs an event study on two varlists using returns, specifying two event windows and multiple event dates, using the Adjusted Patell test.{p_end}
{phang2}{cmd:	 estudy ret_ibm-ret_boeing (ret_apple ret_netflix ret_google ret_facebook) , datevar(date) evdate(security_names event_dates) modt(SIM) indexlist(ret_sp500) diagn(ADJPatell) lb1(-3) ub1(3) lb2(-5) ub2(5) dec(4) showpv }{p_end}

{pstd}Performs an event study on two varlists using prices, specifying two event windows and multiple event dates, using the Adjusted Patell test.{p_end}
{phang2}{cmd: estudy pr_ibm-pr_boeing (pr_apple pr_netflix pr_google pr_facebook) , datevar(date) evdate(security_names event_dates) modt(SIM) indexlist(pr_sp500) pri diagn(ADJPatell) lb1(-3) ub1(3) lb2(-5) ub2(5) dec(4) showpv}{p_end}

{pstd}Performs an event study on two varlists using prices, specifying two event windows and multiple event dates, using the Bohemer, Musumeci and Paulsen test with the Kolari and Pynnonen adjustment, printing a latex formatted table.{p_end}
{phang2}{bf:estudy pr_ibm-pr_boeing (pr_apple pr_netflix pr_google pr_facebook) , datevar(date) evdate(security_names event_dates) modt(HMM) indexlist(pr_sp500) pri diagn(KP) lb1(-3) ub1(0) lb2(0) ub2(5) dec(4) tex}{p_end}

{pstd}Performs an event study on a single varlist using returns, specifying two event windows on multiple event dates, using the Bohemer, Musumeci and Paulsen test with the Kolari and Pynnonen adjustment, showing the group CAAR only and printing it over the [-20 +20] window around the event dates.{p_end}
{phang2}{cmd:estudy ret_ibm-ret_amazon , datevar(date) evdate(security_names event_dates) modt(HMM) indexlist(ret_mkt ret_smb ret_hml) diagn(KP) supp(ind) lb1(-3) ub1(0) lb2(-20) ub2(20) dec(4) graph(-20 20)}{p_end}

{marker storedres}{...}
{title:Stored results}

{phang}
{cmd: estudy} stores the following in {bf:r()}:

{phang}
Matrices {p_end}
{tab}{bf:r(car)}{tab}{tab}{tab}estimated cars
{tab}{bf:r(pv)}{tab}{tab}{tab}p-values of estimated cars
{tab}{bf:r(sd)}{tab}{tab}{tab}standard deviation of the test
{tab}{bf:r(stats)}{tab}{tab}values of the statistical tests adopted
{tab}{bf:r(ars)}{tab}{tab}{tab}time series of estimated abnormal returns

{marker references}{...}
{title:References}

{marker BMP1991}{...}
{phang}
Boehmer, E., Musumeci, J., Poulsen, A. B. (1991). {it:Event-study methodology under conditions of event-induced variance}.
Journal of Financial Economics 30, 253-272. {p_end}

{marker KP2010}{...}
{phang}
Kolari, J. W., & Pynnonen, S. (2010). {it:Event study testing with cross-sectional correlation of abnormal returns}.
Review of financial studies, 23(11), 3996-4025. {p_end}

{marker KP2011}{...}
{phang}
Kolari, J. W., & Pynnonen, S. (2011). {it:Nonparametric rank tests for event studies}.
Journal of Empirical Finance, 18(5), 953-971. {p_end}

{marker PAT1976}{...}
{phang}
Patell, J. A., (1976). {it:Corporate forecasts of earnings per share and stock price behavior: Empirical test}.
Journal of Accounting Research 14, 246-276. {p_end}

{marker WX1945}{...}
{phang}
Wilcoxon, F. (1945). {it:Individual comparisons by ranking methods}.
Biometrics Bulletin 1, 80-83. {p_end}


{marker authors}{...}
{title:Authors}

{phang}
Fausto Pacicco, LIUC Università Carlo Cattaneo - fpacicco@liuc.it
{p_end}

{phang}
Luigi Vena, LIUC Università Carlo Cattaneo - lvena@liuc.it
{p_end}

{phang}
Andrea Venegoni, LIUC Università Carlo Cattaneo - avenegoni@liuc.it
{p_end}
