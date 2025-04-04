{smcl}
{* *! version 1.3  3apr2025}{...}
{cmd:help peermean}
{hline}

{title:Title}

{p2colset 5 22 24 2}{...}
{p2col :{bf:peermean} {hline 2}} Mean of Peer firms {p_end}
{p2colreset}{...}


{title:Syntax}

{p 4 19 2}
{cmdab:peermean} {varlist} {ifin}, {cmd:by(groupvar)} 
[{cmdab:s:uffix:(str)} {cmdab:SINGLE:zero}]

{title:Options}

{phang}
{opth by:(varlist:groupvar)} specifies the {it:groupvar} that defines the peers. 

{phang}
{opt suffix(str)} specify the suffix of the new variables to be generated. The default is {bf:_peer}.

{phang}
{opt singlezero} specifies how to handle cases where there is only one observation in a group. By default, when a group contains only one observation, Peer Mean cannot be calculated and will be set to missing (.). If this option is specified, Peer Mean will be set to zero (0) instead of missing for such groups.

{title:Description}

{pstd}
Suppose there are 4 firms in an industry with output y {1, 2, 3, 4}. They are peers of each other. 
When we consider firm A, its peers include firm B, firm C and firm D. The mean of output of firm A's peers equals
y_mean{-A} = (2+3+4)/3.

{pstd}
In general, the peer mean can be calculated by the following formula:

{phang}
--------------------------------------------------------------------
    
                   1
      y[peerx] = -----(y1+y2+...+y[i-1]+       +y[i+1]+...+y[N])
                  N-1
    
                   1
               = -----(y1+y2+...+y[i-1] + y[i] +y[i+1]+...+y[N] - y[i])
                  N-1	
    			  
                   N               1  
               = -----(y_mean) - ----- y[i]
                  N-1             N-1 
    			  
               = w1*y_mean - w2*y_i	 
    		   
{phang}			   
--------------------------------------------------------------------

{phang}
where, w1 = N/(N-1) and w2 = 1/(N-1)

{pstd}
If a group contains only one observation, the Peer Mean cannot be calculated, and it will be set to a missing value (.) by default. However, if the {opt SINGLEzero} option is specified, Peer Mean will be set to zero (0) instead of missing for such groups.

{title:Examples 1: Usage}

{p 4 10 6}{stata sysuse "nlsw88.dta", clear}{p_end}
{p 4 10 6}{stata peermean wage, by(industry)}{p_end}

{title:Examples 2: Check the results}

{p 4 10 6}{cmd:*-Data setup}{p_end}
{p 4 10 6}{stata sysuse "nlsw88.dta", clear}{p_end}

{p 4 10 6}// Data processing for demonstrating the calculation principle of peermean.ado{p_end}
{p 4 10 6}// This step is not necessary for actual applications{p_end}
{p 4 10 6}{stata keep if industry<=3}{p_end}
{p 4 10 6}{stata keep wage hours industry}{p_end}
{p 4 10 6}{stata `"bysort industry: gen Ni = _n"'}{p_end}
{p 4 10 6}{stata keep if Ni<=industry}{p_end}
{p 4 10 6}{stata replace wage = int(wage)}{p_end}
{p 4 10 6}{stata list, sepby(industry) clean}{p_end}

{p 4 10 6}{cmd:*-peer mean}{p_end}
{p 4 10 6}{stata peermean wage, by(industry)}{p_end}

{p 4 10 6}{cmd:*-Results}{p_end}
{p 4 10 6}{stata list indust wage Ni wage_peer, sepby(industry) abb(15)}{p_end}

     +-----------------------------------------------+
     |              industry   wage   Ni   wage_peer |
     |-----------------------------------------------|
  1. | Ag/Forestry/Fisheries     11    1           . |
     |-----------------------------------------------|
  2. |                Mining      5    1          40 |
  3. |                Mining     40    2           5 |
     |-----------------------------------------------|
  4. |          Construction     11    1         8.5 |
  5. |          Construction     11    2         8.5 |
  6. |          Construction      6    3          11 |
     +-----------------------------------------------+

{title:Author}

{phang}
{cmd:Yujun Lian (连玉君)} Lingnan College, Sun Yat-Sen University, China.{break}
E-mail: {browse "mailto:arlionn@163.com":arlionn@163.com} {break}
Blog: {browse "https://www.lianxh.cn":lianxh.cn} {break}
{p_end}


{title:Also see}

{psee} 
Online:  
{help _gpeers} (if installed)


