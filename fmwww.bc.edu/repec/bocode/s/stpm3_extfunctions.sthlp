{smcl}
{* *! version 1.0.0  2023-5-23}{...}
{vieweralsosee "stpm3" "help stpm3"}{...}
{vieweralsosee "stpm3 postestimation" "help stpm3_postestimation"}{...}
{vieweralsosee "stpm3 predictions" "help stpm3_predictions"}{...}

{title:stpm3 extended functions }

{pstd}
{help stpm3} allows incorporation of factor variables for both main and time-dependent effects (using the {cmd:tvc()} option).
It also allows various functions for continous variables to be incorporated, 
for example, various types of spline functions, polynomials and fractional polynomials,
as well as more general functions.

{pstd}
Using extended functions makes many predictions much simpler. See {help stpm3_predictions} for some examples.

{pstd}
You may type a {help varlist} with factor varibles as follows,

{phang2}
{cmd:i.}{it:varname1} {cmd:i.}{it:varname1}

{pstd}
A simple example of an extended function is incorporation of a natural cubic spline function,

{phang2}
{cmd:i.}{it:varname1} {cmd:@ns(}{it:varname2}{cmd:, df(3))}

{pstd}
You can include extended functions as interactions with factor variables,

{phang2}
{cmd:i.}{it:varname1} {cmd:@ns(}{it:varname2}{cmd:, df(3))} {cmd:i.}{it:varname1}{cmd:#@ns(}{it:varname2}{cmd:, df(3))}

{pstd}
The above could also be expressed as,

{phang2}
{cmd:i.}{it:varname1}{cmd:##@ns(}{it:varname2}{cmd:, df(3))}

{pstd}
You can also have interactions between extended functions.

{phang2}
{cmd:#@ns(}{it:varname1}{cmd:, df(3))}{cmd:#@ns(}{it:varname2}{cmd:, df(4))}

{pstd}
You can add more general functions as follows,

{phang2}
{cmd:i.}{it:varname1} {cmd:@fn(}{it:expression}{cmd:),stub(}{it:name}{cmd:))}  

{pstd}
For example,

{phang2}
{cmd:i.}{it:varname1} {cmd:@fn(exp(-0.12*nodes), name(enodes)}



{pstd}
The extended functions are

{synoptset 30 tabbed}{...}
{synoptline}
{synopt :{opt @bs()}}B-splines{p_end}
{synopt :{opt @fp()}}fractional polynomials{p_end}
{synopt :{opt @fn()}}general function of vaiables(s){p_end}
{synopt :{opt @ns()}}natural cubic splines{p_end}
{synopt :{opt @poly()}}polynomials{p_end}
{synopt :{opt @rcs()}}restricted cubic splines{p_end}
{synoptline}

{pstd}
These are described in more detail below,


{dlgtab:bs() - B-splines}

{phang} 
{cmd:@bs(}{it:varname}, {it:options}{cmd:)}

{phang2} {bf:Options}

{phang3} 
{opt bknots(numlist)} - boundary knots for the B-spline function. By default these are placed
at the minimum and maximum of {it:varname}. 

{phang3}
{opt center(#)} - center the B-spline variables around a single value, 
i.e. all spline variables will be equal to zero at this value.

{phang3}
{opt degree(#)} - degree of B-spline function - default 3.

{phang3}
{opt df(#)} - degrees of freedom, i.e. number of B-splines terms. By default the knots are placed
at evenly distributed centiles of the distribution of {it:varname}. 

{phang3} 
{opt knots(numlist)} - list of internal knots for the B-splines. This is to be used when you 
do not to use the default knot placments.

{phang3} 
{opt winsor(# #, [values])} - will winsorize {it:varname} at the specified percentiles before calculating the B-spline variables.
If the {cmd:value} option is used the cutpoints are specified for the actual values of {it:varname} rather than percentiles.

{phang2}
Note that one of {cmd:df()} or {cmd:knots()} must be specified.

{dlgtab:fp() - fractional polynomial}

{phang} 
{cmd:@fp(}{it:varname}, {it:options}{cmd:)}

{phang2} {bf:Options}

{phang3}
{opt powers(numlist)} - powers of fractional polynomial, e.g. {cmd:powers(0 2)} includes {bf: ln(x)} and {bf: x^2} in the model.

{phang3}
{opt center(#)} - generate FP terms centered on #.

{phang3}
{opt center} - generate FP terms centered on the mean of {it:varname}. See {help fp}

{phang3}
{opt scale(#a #b)} - scale using ({it:varname}+{it:#a})/{it:#b}. See {help fp}

{phang3}
{opt scale} - calculate {it:#a}) and {it:#b} automatically. See {help fp}

{phang2} Note that {cmd:@fp()} fits a specific fractional function. It does not search over powers. If you want to do the latter,
then you can use the {help fp} or {help mfp} commands.

{dlgtab:fn() - general functions}

{phang} 
{cmd:@fn(}{it:expression}, {it:options}{cmd:)}

{phang2} {bf:Options}

{phang3}
{opt stub(numlist)} - a name to be added to give a more meaningful name to the function.
For example, {cmd:@fn(exp(-0.12*nodes))}, would give a default variable name of {cmd:_fn_f1}.
However, using {cmd:@fn(exp(-0.12*nodes), stub(enodes))} would give a variable name, {cmd:_fn_enodes}.

{phang3}
{opt center(#)} - center newly created variable on #. Note this centers the output of the function, not the input variable(s).

{phang3}
{opt center} - center newly created variable on its mean. Note this centers the output of the function, not the input variable(s).

{dlgtab:ns() - natural cubic splines}

{phang} 
{cmd:@ns(}{it:varname}, {it:options}{cmd:)}

{phang2} {bf:Options}

{phang3}
{opt bknots(numlist)} - boundary knots for the natural cubic spline function. 
The function will be linear before the lower boundary knots and after the upper boundary knot.
By default the boundary knots are placed at the minimum and maximum of {it:varname}. 

{phang3}
{opt center(#)} - center the natural cubic spline variables around a single value, 
i.e. all spline variables will be equal to zero at this value.

{phang3}
{opt df(#)} - degrees of freedom, i.e. number of the natural cubic splines terms

{phang3}
{opt knots(numlist)} - list of internal knots for the natural cubic spline function. 
This is to be used when you do not to use the default knot placments.

{phang3} 
{opt winsor(# #, [values])} - will winsorize {it:varname} at the specified percentiles before calculating the natural cubic spline variables.
If the {cmd:value} option is used the cutpoints are specified for the actual values of {it:varname} rather than percentiles.

{phang2}
Note that one of {cmd:df()} or {cmd:knots()} must be specified.

{dlgtab:poly() - polynomials}

{phang} 
{cmd:@poly(}{it:varname}, {it:options}{cmd:)}

{phang3}
{opt degree(#)} - degree of polynomial. This is a compulsory option.

{phang3}
{opt center(#)} - generate polynomial terms centered on #.

{phang3}
{opt center} - generate polynomial terms centered on the mean of {it:varname}. 

{phang3} 
{opt winsor(# #, [values])} - will winsorize {it:varname} at the specified percentiles before calculating the polynomial variables.
If the {cmd:value} option is used the cutpoints are specified for the actual values of {it:varname}.

{dlgtab:rcs() - restricted cubic splines}

{phang} 
{cmd:@rcs(}{it:varname}, {it:options}{cmd:)}  

{phang2} {bf:Options}

{phang3}
{opt bknots(numlist)} - boundary knots for the restricted cubic spline function. 
The function will be linear before the lower boundary knot and after the upper boundary knot.
By default the boundary knots are placed at the minimum and maximum of {it:varname}.

{phang3}
{opt center(#)} - center the restricted cubic spline variables around a single value, 
i.e. all spline variables will be equal to zero at this value.

{phang3}
{opt df(#)} - degrees of freedom, i.e. number of restricted cubic splines terms

{phang3}
{opt knots(numlist)} - list of internal knots for the restricted cubic spline function. 

{phang3} 
{opt winsor(# #, [values])} - will winsorize {it:varname} at the specified percentiles before calculating the restricted cubic spline variables.
If the {cmd:value} option is used the cutpoints are specified for the actual values of {it:varname} rather than percentiles.

{phang3}
Note that one of {cmd:df()} or {cmd:knots()} must be specified. The fitted values when using {cmd:@ns()} or {cmd:@rcs()} will be identical.
The functions differ in the way the spline variables are created.

