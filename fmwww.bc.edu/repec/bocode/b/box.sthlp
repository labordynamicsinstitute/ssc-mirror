{smcl}
{cmd:help box}
{hline}

{title:Title}

{pstd}{cmd:box} {hline 2} Command to find and set the Box local folder as Stata's working directory{p_end}


{title:Syntax}

{pstd}{cmd:box}
[{cmd:,} {cmd:nocd}]


{title:Description}

{pstd}{cmd:box} locates a user's {browse "http://www.box.com": Box} directory and sets Stata's working directory to that location. The command is useful for running do-files saved in Box across different computers (e.g., office or home) or shared between colleagues without the need to manually amend the working directory in the do-file. {cmd:box} works only if a single Box account is installed and no other folders containing the word 'box' are in the same directory. {p_end}

{title:Option}

{pstd}{cmd:nocd} does not change the directory to Box but save the results in {cmd:r(db)}.

{title:Stored results}

{pstd}The Box directory is stored in {cmd:r(db)} and can be viewed with {cmd:return list}.{p_end} 

{title:Acknowledgment}

{pstd}This program is based on a modification of the command {helpb dropbox}. All credits to their authors, Raymond Hicks and Dustin Tingley. {cmd:dropbox} was featured in {it:Stata Journal}, volume 14, number 3: {browse "http://www.stata-journal.com/article.html?article=pr0058":pr0058}.{p_end} 

{title:Author}

{pstd}{browse "https://giacomozanello.com/":Giacomo Zanello}{p_end}
{pstd}University of Reading{p_end}
{pstd}Reading, UK{p_end}

{pstd}If you use the command, please consider citing this software as follows:

{pmore}
    Giacomo Zanello, 2025. "Box: Command to find and set the Box local folder as Stata's working directory" Statistical Software Components, Boston College Department of Economics. {p_end}
	
	
{title:Last updated}

{pstd} 23 January 2025{p_end}