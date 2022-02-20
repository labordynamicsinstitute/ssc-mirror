{smcl}
{* *! version 2.0.0 16feb2022}{...}
{viewerjumpto "Syntax" "wordy##syntax"}{...}
{viewerjumpto "Description" "wordy##description"}{...}

{title:Title}

{phang}
{bf:wordy} {hline 2} plays a silly word game and shows your guesses on a Stata graph

{marker syntax}{title:Syntax}

{p 8 17 2}
{cmdab:w:ordy} [{it:pattern}]
[{cmd:,} {cmdab:use:indx(}{it:integer}{cmd:)} {cmdab:sup:presscheck} ] 

{marker description}{...}
{title:Description}

{pstd}
{cmd:wordy} with no argument picks a new word every day from a list of 8,938 five-letter words legal in a popular crossword game in 1998.
You then have six guesses at the word, and every time you type a guess, a Stata graph appears showing green squares
for letters in the right position and yellow squares for a letter that appears in the word but in the wrong position.
This may remind you of a different game using colored pegs on an oblong brown plastic board.
{p_end}

{pstd}
{cmd:wordy} with an optional argument {it:pattern} looks up legal five-letter words matching a pattern with letters specified and ? used as a wildcard meaning any letter. 
For example {stata "wordy bo??e":wordy bo??e} returns 13 legal words matching that pattern.
{p_end}

{pstd}
The option {cmdab:useindx} can be used to specify a different day (measured as elapsed days from 1 Jan 1960) to use
when picking the word, thereby giving you the chance to play many distinct games on one calendar day, and waste even more time.
{p_end}

{pstd}
The option  {cmdab:sup:presscheck} suppresses a check that the guess is a real word, thereby giving you the chance to 
guess random strings of letter and further optimize your guesses.
{p_end}

{marker author}{...}
{title:Authors}

{pstd}Austin Nichols{p_end}
{pstd}austinnichols@gmail.com{p_end}

{marker citation}{...}
{title:Citation of {cmd:wordy}}

{p}{cmd:wordy} is not an official Stata command. It is a free contribution
to the Stata community, like a paper you might deposit in the recycling bin. Please cite it as such: {p_end}

{phang}Austin Nichols. 2022. 
wordy: Stata module for playing word games and wasting time.
{browse "http://ideas.repec.org/c/boc/bocode/s456890.html":http://ideas.repec.org/c/boc/bocode/s456890.html}{p_end}

{title:Contact for support}

    Austin Nichols
    Washington, DC, USA
    {browse "mailto:austinnichols@gmail.com":austinnichols@gmail.com}

{marker seealso}{...}
{title:Also see}

{p 1 14}Manual:  {hi:[U] Chapter 3.2  Stata on the Internet {help stata_on_internet}} {hi:[U]  Chapter 29   Using the Internet to keep up to date {help whatsnew}}
{p_end}
