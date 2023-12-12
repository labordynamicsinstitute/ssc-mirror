{smcl}
{* 23Jun2023}{...}
{hi:help chatgpt}
{hline}

{title:Title}

{p 4 18 2}
{hi:chatgpt} {hline 2} Provides an interface that allows users to interact with GPT(Generative Pre-trained Transformer) within Stata software and receive responses about Stata.
{p_end}


{title:Syntax}

{p 8 17 2}
{bf:chatgpt} [ {it: subcommand} ] [, {it:options} ]

{p 4 4 2}
where the subcommands can be:

{col 5} subcommand {col 19} Description
{space 4}{hline}
{col 5} {bf: talk}{col 19} talk with GPT and receive responses.
{col 5} {bf: read}{col 19} submit text files or data to GPT in order to gain a better understanding.
{col 5} {bf: session}{col 19} create or modify the configuration information of a session.
{col 5} {bf: test}{col 19} test if the commands can run, no options
{space 4}{hline}



{title:Early Access}

{p 4 4 2}
This command is currently undergoing continuous development, and the features presented in this sthlp file will be further updated as the command program is refined. We welcome you to try out this command in advance and provide valuable suggestions for the next phase of command development.


{title:Description}

{p 4 4 2}
{cmd:chatgpt} uses the API Key provided by OpenAI to create sessions, enabling users to communicate with GPT within the Stata software. To be more specific, {cmd:chatgpt} not only enables GPT to read technical documents related to Stata (such as ado/do/sthlp file), but it also allows users to directly chat with GPT in the Stata, with GPT's responses displayed on the Stata screen.

{p 4 4 2}
Addition, {cmd:chatgpt} also supports in-context learning, just like when users use ChatGPT on the official website({browse "https://chat.openai.com/chat"}). This makes it easier to have a continuous and in-depth discussion about a Stata technical issue.


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
4. Python is required for both Windows and MacOS users.
{p_end}


{title:Options for chatgpt}


{dlgtab:chatgpt base options}

{p 4 4 2}
These options can be used in various sub-commands to configure basic settings.

{col 5}{it:option}{col 27}{it:Description}
{space 4}{hline}
{col 5}stata{col 27} this session is dedicated to discussing Stata topics.
{col 5}openai_api_key({it:string}){col 27}provides the credentials of the Open AI's platform to be used. 
{col 5}engine({it:string}){col 27} specifies the language engine used for the session.
{col 5}systemprompt({it:string}){col 27} specifies the system prompt for the session. Appropriate system prompts help GPT better understand and answer questions.
{space 4}{hline}


{dlgtab:chatgpt session options}

{p 4 4 2}
The options of {cmd:chatgpt session} are used to create a session. 
We recommend that you specifically use {cmd: chatgpt session} with base options to configure session information when you want to have multi-turn conversations with GPT, to prevent the confusion that may arise from the misuse of options.

{p 4 4 2}
{opt set_session(string)} creates a new session, with the parameter being the session id.

{p 4 4 2}
{opt replace} clears all records of the current session and creates a new session.


{dlgtab:chatgpt talk options}

{p 4 4 2}
{opt command(string)} specifies the prompt for GPT, and GPT will response based on the prompt.

{p 4 4 2}
{opt session(string)} specifies the session id to which the command belongs. If this id has not been created by {cmd: chatgpt session}, the command will result in an error. 
When this option is used, the {opt openai_api_key(str)} option does not need to be added, as it is already bound to the session id.

{p 4 4 2}
{opt proxy(string)} specifies the proxy port used by the command when submitting data through the API. 
This option is used when users need to access the services provided by OpenAI through a proxy server.
The option should be formatted as proxy("127.0.0.1:7890").

{dlgtab:chatgpt read options}

{p 4 4 2}
{opt do(string)} specifies the command to be executed by Stata and submits the execution result to GPT. 
This option is only useful when using {cmd: chatgpt read data}.

{p 4 4 2}
{opt file(string)} specifies the file path to be submitted to GPT for reading. 
It can be an absolute path or a relative path based on the current working path of Stata. 
This option is only useful when using {cmd: chatgpt read other}.

{p 4 4 2}
{opt command(string)} is same as mentioned above.

{p 4 4 2}
{opt session(string)} is same as mentioned above.

{p 4 4 2}
{opt proxy(string)} is same as mentioned above.

{title:Example}

{pstd}
1. Quick Talk

{phang}
{stata `"clear"'}
{p_end}
{phang}
{stata `"global OPENAI_API_KEY "YOUR OPENAN API KEY""'}
{p_end}
{phang}
{stata `"chatgpt talk, openai_api_key($OPENAI_API_KEY) command("how to clearing the dataset?") stata"'}
{p_end}

{pstd}
2. Session Talk

{phang}
{stata `"clear"'}
{p_end}
{phang}
{stata `"global OPENAI_API_KEY "YOUR OPENAN API KEY""'}
{p_end}

{phang}
{stata `"chatgpt session, openai_api_key($OPENAI_API_KEY) set_session("session_talk") stata systemprompt("Please add 'Best,\nGPT' at the end of each response") replace"'}
{p_end}

{phang}
{stata `"chatgpt talk, command("how to clearing the dataset?") session("session_talk")"'}
{p_end}

{phang}
{stata `"chatgpt talk, command("how to new a variable?") session("session_talk")"'}
{p_end}

{phang}
{stata `"chatgpt talk, command("Summarizing the first two commands.") session("session_talk")"'}
{p_end}

{pstd}
3. Read Ado File

{phang}
{stata `"clear"'}
{p_end}
{phang}
{stata `"global OPENAI_API_KEY "YOUR OPENAN API KEY""'}
{p_end}
{phang}
{stata `"ssc install psemail,replace"'}
{p_end}

{phang}
{stata `"chatgpt read psemail.ado, openai_api_key($OPENAI_API_KEY) stata"'}
{p_end}


{pstd}
4. Read Sthlp File

{phang}
{stata `"clear"'}
{p_end}
{phang}
{stata `"global OPENAI_API_KEY "YOUR OPENAN API KEY""'}
{p_end}
{phang}
{stata `"ssc install cntraveltime"'}
{p_end}

{phang}
{stata `"chatgpt read cntraveltime.sthlp, openai_api_key($OPENAI_API_KEY) command("Can this command calculate the travel distance of an ocean freighter?") stata"'}
{p_end}

{pstd}
5. Read Do File

{phang}
{stata `"clear"'}
{p_end}
{phang}
{stata `"global OPENAI_API_KEY "YOUR OPENAN API KEY""'}
{p_end}

{phang}
{stata `"chatgpt read "path/to/the/test.do", openai_api_key($OPENAI_API_KEY) stata command("Enter the question you would like to ask")"'}
{p_end}


{pstd}
6. Read Other Text File

{phang}
{stata `"clear"'}
{p_end}
{phang}
{stata `"global OPENAI_API_KEY "YOUR OPENAN API KEY""'}
{p_end}

{phang}
{stata `"chatgpt read other, openai_api_key($OPENAI_API_KEY) stata file("path/to/the/other/textfile.txt")"'}
{p_end}


{pstd}
7. Read Dataset in Stata, no do() option

{phang}
{stata `"clear"'}
{p_end}
{phang}
{stata `"global OPENAI_API_KEY "YOUR OPENAN API KEY""'}
{p_end}
{phang}
{stata `"sysuse auto"'}
{p_end}
{phang}
{stata `"chatgpt read data, openai_api_key($OPENAI_API_KEY)"'}
{p_end}

{pstd}
8. Read Dataset in Stata, with do() option

{phang}
{stata `"clear"'}
{p_end}
{phang}
{stata `"global OPENAI_API_KEY "YOUR OPENAN API KEY""'}
{p_end}
{phang}
{stata `"sysuse auto"'}
{p_end}
{phang}
{stata `"chatgpt read data, openai_api_key($OPENAI_API_KEY) do("sum mpg,detail")"'}
{p_end}

{pstd}
9. A Complete Session Conversation

{phang}
{stata `"clear"'}
{p_end}
{phang}
{stata `"global OPENAI_API_KEY "YOUR OPENAN API KEY""'}
{p_end}
{phang}
{stata `"sysuse auto"'}
{p_end}

{phang}
{stata `"chatgpt session, openai_api_key($OPENAI_API_KEY) set_session("smile01") stata systemprompt("Please add 'Best,\nGPT' at the end of each response") replace"'}
{p_end}

{phang}
{stata `"chatgpt read data, session("smile01") do("sum *,detail")"'}
{p_end}

{phang}
{stata `"chatgpt talk, command("Which variable in the dataset best fits a normal distribution?") session("smile01")"'}
{p_end}

{phang}
{stata `"chatgpt talk, command("How can I plot its distribution graph?") session("smile01")"'}
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

{pstd}Cong Nie{p_end}
{pstd}HongKong, China{p_end}
{pstd}congnie@ln.hk{p_end}

