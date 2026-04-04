{smcl}
{* *! version 1.0.0  03apr2026}{...}
{vieweralsosee "[R] help" "help help"}{...}
{viewerjumpto "Syntax" "telegram##syntax"}{...}
{viewerjumpto "Description" "telegram##description"}{...}
{viewerjumpto "Options" "telegram##options"}{...}
{viewerjumpto "Examples" "telegram##examples"}{...}
{viewerjumpto "Stored results" "telegram##results"}{...}
{title:Title}

{phang}
{bf:telegram} {hline 2} Send free push notifications (mobile alerts) and 
exported figures from Stata to Telegram


{marker syntax}{...}
{title:Syntax}

{pstd}Initial configuration:{p_end}
{p 8 17 2}
{cmdab:telegram} {cmd:setup}

{pstd}Send a message or figure:{p_end}
{p 8 17 2}
{cmdab:telegram}
[{it:"message text or caption"}]
[{cmd:,} {it:options}]

{pstd}Alias:{p_end}
{p 8 17 2}
{cmdab:tg} can be used interchangeably as a drop-in shortcut for {cmdab:telegram}.

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt token(string)}}Telegram Bot API token{p_end}
{synopt:{opt chatid(string)}}Telegram Chat ID (numeric or @channel){p_end}
{synopt:{opt fig:ure(filepath)}}Path to a local image file to send (e.g., .png, .jpg){p_end}

{syntab:Advanced}
{synopt:{opt notrimpipe}}Do not trim spaces around the {bf:||} line-break operator{p_end}
{synopt:{opt connectt:imeout(#)}}curl connection timeout in seconds; default is {bf:10}{p_end}
{synopt:{opt maxt:ime(#)}}curl total execution timeout in seconds; default is {bf:60}{p_end}
{synopt:{opt retry(#)}}curl maximum retry attempts; default is {bf:0}{p_end}
{synopt:{opt curlcmd(string)}}path to curl executable; default is {bf:"curl"}{p_end}
{synopt:{opt debug}}display redacted curl command and API responses{p_end}
{synopt:{opt quiet}}suppress success output{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
Let's be honest: staring at Stata while a massive script runs is nobody's idea 
of a good time. {cmd:telegram} lets you walk away. It sends free push 
notifications (mobile alerts) and exported graphs from Stata directly to your 
smartphone (iPhone or Android) or desktop via the Telegram messenger.

{pstd}
Whether you are monitoring remote batch jobs or waiting for a bootstrap to 
finish so you can finally pour a glass of wine (or grab another coffee), this 
package is a hassle-free alternative to wrestling with SMTP email servers or 
paying for premium third-party push notification apps. 

{pstd}
{bf:Setup and Credentials:} Nobody wants to paste their Bot Token and Chat ID 
into every single command. Run {cmd:telegram setup} once. It walks you through 
the setup and quietly saves your credentials in a {cmd:telegram_config.txt} 
file inside your Stata {cmd:PERSONAL} directory. (Pro-tip: If you are on a 
virtual desktop, ensure your {cmd:PERSONAL} sysdir points to a persistent 
network drive).

{pstd}
{bf:Line Breaks:} Because walls of text are terrible to read on a phone, use 
the double-pipe operator {bf:||} to drop in a line break. Spaces around the 
pipes are automatically trimmed (unless you use the {opt notrimpipe} option).

{pstd}
{bf:Message Chunking:} Telegram cuts off standard messages at 4,096 characters. 
{cmd:telegram} is Unicode-aware and will automatically split longer output into 
sequential chunks of 4,000 characters. This conservative limit ensures that 
multi-byte characters (like complex emojis) don't cause API rejection errors 
at the boundary.

{pstd}
{bf:Figure Captions:} Use the {opt figure()} option to push charts right to 
your screen so you can review results from the couch. The message text 
automatically becomes the image caption (though Telegram limits captions to a 
strict 1,024 characters).


{marker options}{...}
{title:Options}

{phang}
{opt token(string)} specifies the authentication token provided by the BotFather. 
It must contain a colon. (Note: This is optional if you have completed the 
{cmd:telegram setup} configuration).

{phang}
{opt chatid(string)} specifies the recipient. This can be a personal chat ID 
(e.g., {it:12345678}), a negative group chat ID (e.g., {it:-12345678}), or a 
public channel username (e.g., {it:@my_stata_channel}). (Note: This is optional 
if you have completed the {cmd:telegram setup} configuration).

{phang}
{opt figure(filepath)} specifies a local image file to upload. Supported 
formats include .png, .jpg, .jpeg, .gif, .bmp, and .webp. Stata formats like 
.gph or vector formats like .eps are not supported by Telegram.

{phang}
{opt notrimpipe} instructs the program to preserve spaces immediately before 
and after the {bf:||} operator when converting it to a line break.

{phang}
{opt debug} prints the exact (but redacted) curl command being sent to the OS 
shell. Highly recommended for troubleshooting when firewalls or proxy servers 
decide to ruin your day.


{marker examples}{...}
{title:Examples}

{pstd}First-time configuration:{p_end}
{phang2}{cmd:. telegram setup}{p_end}

{pstd}Standard plain-text message:{p_end}
{phang2}{cmd:. telegram "Data cleaning finished. I deserve a coffee."}{p_end}

{pstd}Using the shorter alias:{p_end}
{phang2}{cmd:. tg "Simulation completed."}{p_end}

{pstd}Using line breaks to format a mobile alert:{p_end}
{phang2}{cmd:. tg "Model 1 Converged || R-squared: 0.85 || Let's pretend that's causal..."}{p_end}

{pstd}Using compound quotes to include double quotes and evaluate a macro:{p_end}
{phang2}{cmd:. local pval = 0.042}{p_end}
{phang2}{cmd:. tg `"The "causal" effect has a p-value of `pval'"'}{p_end}

{pstd}Sending an exported Stata graph to your phone (fully executable):{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. scatter price mpg}{p_end}
{phang2}{cmd:. graph export "results.png", as(png) replace}{p_end}
{phang2}{cmd:. tg "Scatter plot of Price vs. MPG", figure("results.png")}{p_end}

{pstd}Overriding stored credentials for a specific alert:{p_end}
{phang2}{cmd:. tg "Monte Carlo loop 1,000 complete. Pouring wine.", chatid("@lab_channel") token("987:XYZ")}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:telegram} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(curl_rc)}}0 if successful; standard Stata error code otherwise{p_end}
{synopt:{cmd:r(chunks)}}number of message chunks or files sent{p_end}
{synopt:{cmd:r(split_msg)}}1 if a text message was split into chunks, 0 otherwise{p_end}
{synopt:{cmd:r(orig_len)}}character length of the original message/caption{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(type)}}{cmd:"text"} or {cmd:"figure"}{p_end}
{synopt:{cmd:r(chatid)}}the resolved Chat ID used for the transmission{p_end}
{p2colreset}{...}