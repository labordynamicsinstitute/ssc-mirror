{smcl}
{cmd:help onedrive}
{hline}

{title:Title}

{pstd}{cmd:onedrive} {hline 2} Command to find and set Microsoft OneDrive local folder as Stata's working directory{p_end}


{title:Syntax}

{pstd}{cmd:onedrive}
[{cmd:,} {cmd:nocd}]


{title:Description}

{pstd}{cmd:onedrive} locates a user's {browse "http://www.onedrive.com":Microsoft OneDrive} directory and sets Stata's working directory to that location. The command is useful for running do-files saved in OneDrive across different computers (e.g., office or home) or shared between colleagues without the need to manually amend the working directory in the do-file. {cmd:onedrive} works only if a single OneDrive account is installed (either a personal, work, or school account) and no other folders containing the word 'onedrive' are in the same directory. {p_end}

{title:Option}

{pstd}{cmd:nocd} does not change the directory to OneDrive but save the results in {cmd:r(db)}.

{title:Stored results}

{pstd}The OneDrive directory is stored in {cmd:r(db)} and can be viewed with {cmd:return list}.{p_end} 

{title:Acknowledgment}

{pstd}This program is based on a modification of the command {helpb dropbox}. All credits to their authors, Raymond Hicks and Dustin Tingley. {cmd:dropbox} was featured in {it:Stata Journal}, volume 14, number 3: {browse "http://www.stata-journal.com/article.html?article=pr0058":pr0058}.{p_end} 

{title:Author}

{pstd}{browse "https://giacomozanello.com/":Giacomo Zanello}{p_end}
{pstd}University of Reading{p_end}
{pstd}Reading, UK{p_end}

{pstd}If you use the command, please consider citing this software as follows:

{pmore}
    Giacomo Zanello, 2024. "ONEDRIVE: Command to find and set Microsoft OneDrive local folder as Stata's working directory" Statistical Software Components S459284, Boston College Department of Economics. {p_end}
	
	
{title:Last updated}

{pstd} 1 February 2024{p_end}