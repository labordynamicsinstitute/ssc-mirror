{smcl}
{* 7Sep2021}{...}
{hline}

{title:Title}

{p2colset 5 14 14 2}{...}
{p2col:{hi:hhelp} {hline 2}} Open the online HTML version of help document for specific command{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:hhelp} {cmd:}{it:command_name} [{cmd:,}
{opt m:arkdown}
{opt txt}
{opt ms}
{opt tex:full}
{opt l:atex}
{opt f:ormat}{cmd:(}#{cmd:)}
{opt c:lipoff}]

{synoptset 17 tabbed}{...}
{synopthdr}
{synoptline}
{col 5}{cmd:Format}{col 19}provide web link to online help document and automatically copy to the clipboard
{synopt:{opt m:arkdown}} in markdown format{p_end}
{synopt:{opt txt}}   in plain text format, which can be pasted into the dialog box of Facebook or WeChat for Chinese users.{p_end}
{synopt:{opt ms}}  copy rich text punctuated with links to clipboard, which can be pasted into MicroSoft documents.{p_end}
{synopt:{opt tex:full}}  in LaTeX full syntax format{p_end}
{synopt:{opt l:atex}}    in LaTeX compact format{p_end}
{synopt:{opt f:ormat(#)}} in preset formats, including three modes{p_end}
{synopt:{opt c:lipoff}}  do not copy the link to the clipboard{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}


{title:Description}

{pstd}
{cmd:hhelp} can quickly open the online HTML version of official Stata help files. As a simplification of {help wwwhelp:wwwhelp}, it allows faster access to the HTML version without any options.

{pstd}
For example, {it:wwwhelp xtreg, web} is equivalent with {it:hhelp xtreg}.


{title:Options}

{pstd}
provide web links to the HTML version of online help files, which can be put into specific format and automatically copied to the clipboard{p_end}

{phang2}{opt markdown} displaying the web link in Markdown format. For example, {ul:hhelp regress, markdown} displays the text in the following format:{p_end}

{pmore3} [**[R]** regress](https://www.stata.com/help.cgi?regress) {p_end}

{phang3}It can be copied to a Markdown file and displayed as a clickable link: {browse `"https://www.stata.com/help.cgi?regress"':[R] regress}{p_end}

{phang2}{opt txt} displaying the web link in text (command:URL) format. For example, {ul:hhelp regress, txt} displays the text in the following format:{p_end}

{pmore3}[R] regress: https://www.stata.com/help.cgi?regress {p_end}

{phang3}It can be copied to the dialog box of Facebook or WeChat for Chinese users.{p_end}

{phang2}{opt ms} sends a rich text punctuated with links to the clipboard, which can be pasted easily to the MicroSoft Word. For example, {ul:hhelp regress, ms}, When pressing ’Command+V’ in the MicroSoft Word, the text will appear as a clickable
link.  {browse `"https://www.stata.com/help.cgi?regress"':[R] regress}{p_end}

{phang3} However, this option has some limitations. It requires Stata 16 or newer versions of Stata to be installed as well as python, because the commands call the Windows API through Stata's interaction with Python; and it is currently only available for Windows systems. Otherwise, it will automatically switch to the {opt txt} option, which displays a plain text with links. (command:URL) {p_end}

{phang2}{opt texfull} displaying the web link in full TeX text format. For example, {ul:hhelp regress, texfull} displays the text in the following format:{p_end}

{pmore3} \href{https://www.stata.com/help.cgi?regress}{\bfseries{[\MakeUppercase{r}] regress}}  {p_end}

{phang3} It can be inserted into a .tex document, which will displayed as a clickable link in the PDF file when compiled using a TeX editor: {browse `"https://www.stata.com/help.cgi?regress"':[R] regress}{p_end}

{phang2}{opt latex} displaying the web link in Latex format. For example, {ul:hhelp regress, latex} displays the text in the following format:{p_end}

{pmore3}\stwwwhelp[r]{regress} {p_end}

{phang3} It can be inserted into a .tex document, which will displayed as a clickable link in the PDF file when compiled using a TeX editor: {browse `"https://www.stata.com/help.cgi?regress"':[R] regress}{p_end}

{pmore3}Note: Since {it:\stwwwhelp} is a new user-defined command, it needs to be defined by adding the following to the introductory section of the .tex document.{p_end}
{pmore3} \newcommand{\stwwwhelp}[2][r]{  {p_end}
{pmore3}{space 4}	 \href{https://www.stata.com/manuals/#1#2.pdf}{\bfseries{[\MakeUppercase{#1}] #2}}  {p_end}
{pmore3} }  {p_end}

{phang2}{cmd:format(#)} displaying web links in three supporting Markdown preset formats.

{phang3}format(1) is rendered in Markdown as {browse `"https://www.stata.com/help.cgi?regress"':[R] regress}. The text displayed is formatted as follows:{p_end}

{pmore3}[**[R]** regress](https://www.stata.com/help.cgi?regress)

{phang3}format(2) is rendered in Markdown as {browse `"https://www.stata.com/help.cgi?regress"':regress}. The text displayed is formatted as follows:{p_end}

{pmore3}[regress](https://www.stata.com/help.cgi?regress)

{phang3}format(3) is rendered in Markdown as {browse `"https://www.stata.com/help.cgi?regress"':help regress}. The text displayed is formatted as follows:{p_end}

{pmore3}[help regress](https://www.stata.com/help.cgi?regress)

{phang2}{cmd:clipoff} deselect copying to the clipboard


{title:Examples}

{phang}* {ul:Basic use}: open help document

{phang2}{inp:.} {stata "hhelp pwcorr":hhelp pwcorr}{p_end}
{phang2}{inp:.} {stata "hhelp mata function":hhelp mata function}{p_end}
{phang2}{inp:.} {stata "hhelp sum":hhelp sum}{p_end}

{phang}* {ul:Auxiliary use}: provide web link

{phang2}{inp:.} {stata "hhelp twoway scatter, m":hhelp twoway scatter, m}{p_end}
{phang2}{inp:.} {stata "hhelp import excel, w web":hhelp import excel, w web}{p_end}
{phang2}{inp:.} {stata "hhelp xtreg, latex":hhelp xtreg, latex}{p_end}
{phang2}{inp:.} {stata "hhelp xtreg, tex":hhelp xtreg, tex}{p_end}
{phang2}{inp:.} {stata "hhelp xtreg, f(2)":hhelp xtreg, f(2)}{p_end}
{phang2}{inp:.} {stata "hhelp xtreg, f(3) clipoff":hhelp xtreg, f(3) clipoff}{p_end}


{title:Stored results}

{pstd}
You can view the stored results through {stata "return list": return list} (see {help return}) after using {cmd:hhelp}:

{synoptset 15 tabbed}{...}
{synopt:{cmd:. r(link)}}web links (URLs) to PDF help documents{p_end}
{synopt:{cmd:. r(link_web)}}web links (URLs) to web versions of help documents{p_end}
{synopt:{cmd:. r(link_m)}}markdown formatted web link text{p_end}
{synopt:{cmd:. r(link_txt)}}command:URL formatted web link text{p_end}
{synopt:{cmd:. r(link_l1)}}LaTeX raw formatted web link text{p_end}
{synopt:{cmd:. r(link_l2)}}LaTeX custom-formatted web link text{p_end}
{synopt:{cmd:. r(link_f1)}}first pre-formatted web link text{p_end}
{synopt:{cmd:. r(link_f2)}}second pre-formatted web link text{p_end}
{synopt:{cmd:. r(link_f3)}}third pre-formatted web link text{p_end}


{title:Author}

{pstd} {cmd:Yujun,Lian* (连玉君)}{p_end}
{pstd} . Lingnan College, Sun Yat-Sen University, China. {p_end}
{pstd} . E-mail: {browse "mailto:arlionn@163.com":arlionn@163.com} {p_end}
{pstd} . Blog: {browse "lianxh.cn":https://www.lianxh.cn}.{p_end}

{pstd} Yongli,Chen (陈勇吏) {p_end}
{pstd} . Antai College of Economics and Management, Shanghai Jiao Tong University, China.{p_end}
{pstd} . E-mail: {browse "mailto:yongli_chan@163.com":yongli_chan@163.com}{p_end}


{title:Also see}

{pstd} Online: {helpb help}, {helpb wwwhelp}{p_end}

