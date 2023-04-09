{smcl}
{* 29Mar2023}{...}
{hi:help chatgpt}
{hline}

{title:Title}

{p 4 18 2}
{hi:chatgpt} {hline 2} Provides an interface that allows users to interact with ChatGPT within Stata software and receive advice about Stata.
{p_end}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:chatgpt}
{cmd:,} 
{opt openai_api_key(string)}
{opt command(string)}
[ {it: options} ]

{title:Special notice}
{pstd}
Currently, this command is only available for Windows users. We will update the command as soon as possible to make it available for more users.
{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:chatgpt} uses the API Key({browse "https://platform.openai.com/account/api-keys"}) provided by OpenAI to create an interface that allows users to have a conversation with ChatGPT within Stata software. 
{cmd:chatgpt} can not only provide quick responses to Stata-related content, but it also supports in-context learning, just like when users use ChatGPT on the official website({browse "https://chat.openai.com/chat"}). This makes it easier to have a continuous and in-depth discussion about a Stata technical issue.
{p_end}


{title:Requirements}

{pstd}
1. Before using this command, a API key is needed. 
You can get a secret key from Open AI platform({browse "https://platform.openai.com/account/api-keys"}). 
{p_end}

{pstd}
2. {cmd:chatgpt} requires Stata version 14 or higher.
{p_end}

{pstd}
3. Windows Users need to install cURL first({browse "https://curl.se/download.html"}), a command-line tool and a library used for transferring data over various protocols, and set the path of cURL as an environment variable.
{p_end}

{pstd}
Windows users also need to use curl to download jq, a command-line utility that can slice, filter, and transform the components of a JSON file.
Specifically, they need to launch cmd in administrator mode and enter the following command:
{p_end}

{pstd}
curl -L -o jq.exe https://github.com/stedolan/jq/releases/latest/download/jq-win64.exe
{p_end}

{pstd}
Once the version number of jq is displayed when "jq -V" is entered in cmd, the installation is complete.
{p_end}





{marker options}{...}
{title:options for chatgpt}

{dlgtab:Main (required)}

{phang}{opt openai_api_key(string)} provides the credentials of the Open AI's platform to be used. 
Users can get a secret key from Open AI's platform ({browse "https://platform.openai.com/account/api-keys"}). 
{p_end}

{phang}
{opt command(string)} specifies the prompt for GPT, and GPT will respond based on the prompt as well as the context of the preceding text.
{p_end}

{dlgtab:Supplementary options}

{phang}{opt chatmode("short"|"long")} specifies the talk mode with GPT.
The default is {opt chatmode("short")}.
{opt chatmode("long")} provides in-context learning mode, where the entire conversation history is uploaded along with the prompt, allowing GPT to generate more intelligent responses.
This makes it easier to have a continuous and in-depth discussion about a Stata technical issue.
{opt chatmode("short")} provides quick response mode, which makes responses more prompt.
{p_end}


{marker example}{...}
{title:Example}

{pstd}
Quick response mode

{phang}
{stata `"clear"'}
{p_end}
{phang}
{stata `"global OPENAI_API_KEY "YOUR OPENAN API KEY""'}
{p_end}
{phang}
{stata `"chatgpt, openai_api_key($OPENAI_API_KEY) command("how to clearing the dataset?")"'}
{p_end}

{pstd}
Longchat mode

{phang}
{stata `"clear"'}
{p_end}
{phang}
{stata `"global OPENAI_API_KEY "YOUR OPENAN API KEY""'}
{p_end}
{phang}
{stata `"chatgpt, openai_api_key($OPENAI_API_KEY) command("how to clearing the dataset?") chatmode("long")"'}
{p_end}

{phang}
{stata `"chatgpt, openai_api_key($OPENAI_API_KEY) command("how to new a variable?") chatmode("long")"'}
{p_end}

{phang}
{stata `"chatgpt, openai_api_key($OPENAI_API_KEY) command("Summarizing the first two commands.") chatmode("long")"'}
{p_end}


{title:Author}

{pstd}Chuntao LI{p_end}
{pstd}China Stata Club(爬虫俱乐部){p_end}
{pstd}Wuhan, China{p_end}
{pstd}chtl@henu.edu.cn{p_end}

{pstd}Xueren Zhang{p_end}
{pstd}China Stata Club(爬虫俱乐部){p_end}
{pstd}Wuhan, China{p_end}
{pstd}snowmanzhang@whu.edu.cn{p_end}

