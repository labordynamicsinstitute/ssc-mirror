{smcl}
{* *! version 1.0 31ene2017}{...}
{findalias asfradohelp}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] help" "help help"}{...}
{viewerjumpto "Syntax" "pobrezaECU##syntax"}{...}
{viewerjumpto "Description" "pobrezaECU##description"}{...}
{viewerjumpto "Options" "pobrezaECU##options"}{...}
{viewerjumpto "Remarks" "pobrezaECU##remarks"}{...}
{viewerjumpto "Examples" "pobrezaECU##examples"}{...}
{title:Title}

{phang}
{bf:pobrezaECU} {hline 2} Nonparametric forecast of the Ecuadorian poverty rate.


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:pobrezaECU} year quarter

{synoptset 20 tabbed}{...}
{synoptline}
{syntab:Arguments*}
{synopt:{opt year}}represent the year of the survey (only integers greater or equal to 2007){p_end}
{synopt:{opt quarter}}represent the quarter of the survey (only integers between 1 and 4) {p_end}
{synoptline}
{pstd}
*These arguments are {hi:strictly required}.

{marker description}{...}
{title:Description}

{pstd}
{cmd:pobrezaECU} predicts Ecuador's poverty rate from simulation of households' income conditional on the business cycle phase.
For a detailed description of the methodology and results visit: {browse "https://drive.google.com/open?id=1PZD4_QaljbuZWUqdnEG56vGeBdGRWTFn"}.


{marker options}{...}
{title:Options}

{pstd}
Options not allowed.


{marker examples}{...}
{title:Examples}

Example - Predicting poverty for the fourth quarter of 2016

{pstd} For this example you should use the ENEMDU of December 2015. It can be 
downloaded from www.ecuadorencifras.gob.ec

{phang}{cmd:. pobrezaECU 2015 4}{p_end}

{pstd} This command will show the following information:

{pstd} {hi: Pobreza 2015-4T: 23.28}

{pstd} {hi: Pobreza 2016-4T:}

         Recuperacion	         23.06	
         Crecimiento             22.06
         Dec. Sobre tendencia    21.52
         Dec. bajo tendencia     24.82
				
{pstd} This values represent the poverty prediction for 2016-4T


{marker author}{...}
{title:Authors}

      Daniel Jaramillo Calderon, jaramillocalderondc@gmail.com - daniel.jaramillo@ubc.ca

      Sergio Guerra Reyes, sergio_guerra@hks13.harvard.edu
