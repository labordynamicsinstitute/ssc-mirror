{smcl}
{* *! version 0.12  2021-04-21}{...}

{viewerjumpto "Syntax" "sf12##syntax"}{...}
{viewerjumpto "Description" "sf12##description"}{...}
{viewerjumpto "Examples" "sf12##examples"}{...}
{viewerjumpto "Acknowledgements" "sf12##acknowledgements"}{...}
{viewerjumpto "References" "sf12##references"}{...}
{viewerjumpto "Author" "sf12##author"}{...}

{title:Title}
{phang}
{bf:sf12} {hline 2} Validate sf12 input and calculate sf12 version 2 t scores

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:sf12} {it:varlist(min=12 max=12)}[{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt w:eights}} Choose between the (default) US general population 1990 
{it:us1990}  where the weights etc are the ones from {browse "https://labs.dgsom.ucla.edu/hays/pages/programs_utilities":Ronald D Hays webpage}
or {it:dk2018} for the danish 2018 weights, see
{browse "https://www.defactum.dk/siteassets/defactum/3-projektsite/hvordan-har-du-det/hhdd-2017/konference-marts-2018/bind-1/bilag.pdf":Hvordan har du det? 2017 – Sundhedsprofil for region og kommuner (Bind 1).}
{p_end}
{synopt:{opt noq:uietly}} Show output from code in log{p_end}
{synopt:{opt c:lear}} Delete existing sf12 variables before generating new variables{p_end}
{synopt:{opt p:refix}} Add string argument as prefix to the generated new variables{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}
{cmd:sf12} takes 12 variables in correct order (i1 i2a i2b i3a i3b i4a i4b i5 
i6a i6b i6c i7), validate the variables with respect to sf12 requirements.
Only rows that are correct are used for calculating the sf12 t scores.{break}
The default underlying z-scores are based on US general population 1990 means 
and sd's (They are not age/gender based).
{p_end}
{pstd}{red:It is important} for users to understand that the scaling should be 
the exact same as indicated by the sf12 version 2 questionaire.{break}
Also it is important to know that answers for i1, i5, i6a, and i6b will be 
reversed when using the command.
{p_end}
{pstd}The code is based on {browse "https://labs.dgsom.ucla.edu/hays/pages/programs_utilities":Ronald D Hays webpage},
especially the {browse "https://labs.dgsom.ucla.edu/hays/files/view/docs/programs-utilities/sf12v2-1.sas.rtf":SAS code version}.
{p_end}

{marker examples}{...}
{title:Examples}

Input example data by copying the following:

{cmd:. clear}
{cmd:. input} id i1 i2a i2b i3a i3b i4a i4b i5 i6a i6b i6c i7
1 1 1 1 1 1 1 1 1 1 1 1 1
2 1 1 3 3 3 3 3 3 3 3 3 3 
3 1 1 . 3 3 3 3 3 3 3 3 3
4 5 5 1 1 1 . . . . . . .
end


Check that input data are loaded:

{cmd:. list}, noobs
  +-------------------------------------------------------------------------+
  | id   i1   i2a   i2b   i3a   i3b   i4a   i4b   i5   i6a   i6b   i6c   i7 |
  |-------------------------------------------------------------------------|
  |  1    1     1     1     1     1     1     1    1     1     1     1    1 |
  |  2    2     1     1     3     3     3     3    3     3     3     3    3 |
  |  3    3     1     1     .     3     3     3    3     3     3     3    3 |
  |  4    4     5     5     1     1     1     .    .     .     .     .    . |
  +-------------------------------------------------------------------------+

 
Run {cmd:sf12} on example data:
  
{cmd:. sf12} i1 i2a i2b i3a i3b i4a i4b i5 i6a i6b i6c i7


List the generated variables:

{cmd:. list} id pf rp bp gh vt sf re mh agg_phys agg_ment, noobs
  +------------------------------------------------------------------------------------------+
  | id      pf      rp      bp      gh      vt      sf      re      mh   agg_phys   agg_ment |
  |------------------------------------------------------------------------------------------|
  |  1   22.11   20.32   57.44   61.99   67.88   16.18   11.35   40.16      43.47      32.72 |
  |  2   39.29   38.75   37.06   61.99   47.75   36.37   33.71   40.16      45.73      38.88 |
  |  3       .   38.75   37.06   61.99   47.75   36.37   33.71   40.16          .          . |
  |  4       .   20.32       .   18.87       .       .       .       .          .          . |
  +------------------------------------------------------------------------------------------+

 
To eg see generated variables and their labels:
 
{cmd:. ds i*, not detail}

              storage   display    value
variable name   type    format     label      variable label
---------------------------------------------------------------------------------------------
pf              double  %10.0g              * NEMC (US 1990) physical functioning t-score
rp              double  %10.0g              * NEMC (US 1990) role limitation physical t-score
bp              double  %10.0g              * NEMC (US 1990) pain t-score
gh              double  %10.0g              * NEMC (US 1990) general health t-score
vt              double  %10.0g              * NEMC (US 1990) vitality t-score
sf              double  %10.0g              * NEMC (US 1990) social functioning t-score
re              double  %10.0g              * NEMC (US 1990) role limitation emotional t-score
mh              double  %10.0g              * NEMC (US 1990) mental health t-score
agg_phys        double  %10.0g              * NEMC (US 1990) physical health t-score - sf12
agg_ment        double  %10.0g              * NEMC (US 1990) mental health t-score - sf12


There are documenting comments in {cmd:notes}:

{cmd:. notes pf bp}

pf:
  1.  Based on i2a (i2a) and i2b (i2b)

bp:
  1.  Based on reversed i5 (i5)


  
To get the DEFACTUM weights

{cmd:. sf12 i1 i2a i2b i3a i3b i4a i4b i5 i6a i6b i6c i7, weights(dk2018) clear}
{cmd:. format pf-agg_ment %6.2f}
{cmd:. list id pf-agg_ment, noobs}

  +------------------------------------------------------------------------------------------+
  | id      pf      rp      bp      gh      vt      sf      re      mh   agg_phys   agg_ment |
  |------------------------------------------------------------------------------------------|
  |  1   20.39   20.79   57.78   62.94   67.79   14.49   17.98   40.28      34.99      36.10 |
  |  2   38.23   39.22   39.57   62.94   48.54   35.34   37.80   40.28      42.13      41.43 |
  |  3       .   39.22   39.57   62.94   48.54   35.34   37.80   40.28          .          . |
  |  4       .   20.79       .   22.42       .       .       .       .          .          . |
  +------------------------------------------------------------------------------------------+


{marker acknowledgements}{...}
{title:Acknowledgements}
{pstd}A special thanks to Finn Breinholt Larsen at DEFACTUM for helping with 
the DEFACTUM scores and weights.
{p_end}


{marker references}{...}
{title:References}

{phang}
	Hays RD, Sherbourne CD, Spritzer KL, & Dixon W J. (1996){break}
	A Microcomputer Program (sf36.exe) that Generates SAS Code for Scoring the SF-36 Health Survey.{break}  
	Proceedings of the 22nd Annual SAS Users Group International Conference, 1128-1132.
{p_end}
{phang}
	Ron D. Hays, Leo S. Morales (2001){break}
	{browse "http://www.rand.org/content/dam/rand/pubs/reprints/2005/RAND_RP971.pdf":The RAND-36 Measure of Health-Related Quality of Life}{break}
	Annals of Medicine, v. 33, 2001, pp. 350-357
{p_end}
{phang}
    Larsen FB, Pedersen MH, Lasgaard M, Sørensen JB, Christiansen J, Lundberg A, Pedersen SE, Friis K. 
    {browse "https://www.defactum.dk/siteassets/defactum/3-projektsite/hvordan-har-du-det/hhdd-2017/konference-marts-2018/bind-1/bilag.pdf":Hvordan har du det? 2017 – Sundhedsprofil for region og kommuner (Bind 1).} 
    Aarhus: DEFACTUM, Region Midtjylland;
2018.
{p_end}
{phang}
	Sepideh S Farivar, William E Cunningham and Ron D Hays (2007)
	{browse "http://www.rand.org/content/dam/rand/pubs/reprints/2008/RAND_RP1309.pdf":Correlated physical and mental health summary scores for the SF-36 and SF-12 Health Survey, V.1}
	Health and Quality of Life Outcomes 2007, 5:54
{p_end}
	
{marker author}{...}
{title:Author}
{p}

Niels Henrik Bruun,{break}Research data and statistics{break}Aalborg University Hospital.

Email {browse "mailto:niels.henrik.bruun@gmail.com":niels.henrik.bruun@gmail.com}
