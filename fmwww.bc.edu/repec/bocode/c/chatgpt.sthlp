{smcl}
{* 08Aug2024}{...}
{hi:help chatgpt}
{hline}

{title:Title}

{p 4 18 2}
{hi:chatgpt} {hline 2} Provides an interface that allows users to interact with GPT(Generative Pre-trained Transformer) within Stata software.
{p_end}


{title:Syntax}

Main

{p 8 17 2}
{cmd:chatgpt} {help chatgpt##Main:{it: subcommands_Main}} [{cmd:,} {help chatgpt##config_options:{it:config_options}} {help chatgpt##talk_options:{it:talk_options}}]


Other

{p 8 17 2}
{cmd:chatgpt} {help chatgpt##config_sub:{it: config}} {it:config_name} [{cmd:,} {help chatgpt##config_options:{it:config_options}}]

{p 8 17 2}
{cmd:chatgpt} {help chatgpt##update_sub:{it: update}} [{cmd:,} {help chatgpt##generate_opt:{it:generate}}]

{p 8 17 2}
{cmd:chatgpt} {help chatgpt##test_sub:{it: test}}



{p 4 4 2}
where the subcommands can be:


{synoptset 25 tabbed}{...}
{marker subcommands}{synopthdr:subcommands}
{synoptline}
{marker Main}{syntab:Main}
{synopt:talk}with GPT and receive responses.
{p_end}
{synopt:longtalk}long dialogues can be conducted with the GPT, and the GPT's responses will refer to the content of previous questions and responses.
{p_end}
{synopt:multitalk}with the constructed panel data, queries are launched in the same way for different contents, where different contents are stored as different observations within the same variables.
{p_end}
{syntab:Other}
{marker update_sub}{synopt:update}generate a new variable for the query results obtained with the {cmd: multitalk} command.
{p_end}
{marker config_sub}{synopt:config}create a configuration file to facilitate the subsequent initiation of a large number of query requests with the same option configuration. {it: config_name} is {cmd:chat-default} by default.
{p_end}
{marker test_sub}{synopt:test}test if the commands can run, only allow proxy() option.
{p_end}

options for chatgpt

{synoptset 25 tabbed}{...}
{marker config_options}{synopthdr:config_options}
{synoptline}
{synopt:{helpb chatgpt##key_openai:{ul:key}_openai({it:string})}} provides the credentials for GPT model.
{p_end}
{synopt:{helpb chatgpt##stata:stata}} requires responding from the perspective of Stata.
{p_end}
{synopt:{helpb chatgpt##system:{ul:sys}tem({it:string})}} specify a system prompt.
{p_end}
{synopt:{helpb chatgpt##model:{ul:m}odel({it:modellist})}} specify a specific model; default is {cmd:model("gpt-4")}.
{p_end}
{synopt:{helpb chatgpt##temperature:{ul:temp}erature({it:args})}} determine the randomness of the output; default is {cmd: 0.2}; {cmd:0} {ul:<} {it:args} {ul:<} {cmd:2}.
{p_end}
{synopt:{helpb chatgpt##max_tokens:{ul:max}_tokens({it:#})}} specify the maximum number of tokens that can be generated in the response; # > {cmd:0}.
{p_end}
{synopt:{helpb chatgpt##agenturl:agenturl({it:URL})}} specify the requested address of the service provider.
{p_end}
{synopt:{helpb chatgpt##proxy:{ul:p}roxy({it:ip_port})}} specify the proxy server address.
{p_end}


{synoptset 25 tabbed}{...}
{marker talk_options}{synopthdr:talk_options}
{synoptline}
{synopt:{helpb chatgpt##command:command({it:string})}} specify the prompt for GPT.
{p_end}
{synopt:{helpb chatgpt##file:{ul:f}ile({it:filepath})}} specify the text file to be submitted to GPT.
{p_end}
{synopt:{helpb chatgpt##do:do({it:stata_code})}} specify the code to be executed by Stata and submits the execution result to GPT.
{p_end}
{synopt:{helpb chatgpt##config:{ul:c}onfig({it:config_name})}} specify the configuration file.
{p_end}

{synoptset 25 tabbed}{...}
{marker other_options}{synopthdr:other_options}
{synoptline}
{marker generate_opt}{synopt:{helpb chatgpt##generate:{ul:gen}erate({it:variable})}} generate a new variable to hold the results after the {cmd: chatgpt multitalk}.
{p_end}


{title:Description}

{p 4 4 2}
{cmd:chatgpt} provides an interface that allows users to interact with GPT (Generative Pre-trained Transformer) within Stata. To be more specific, chatgpt not only supports in-context learning, just like when users use ChatGPT on the official website. Moreover, it is possible to use the contents of the Stata dataset to implement multiple rounds of parallel queries for the contents of different observations within the same variable.

{p 4 4 2}
At the time of the enquiry, the command can not only make GPT read technical documents related to Stata (such as sthlp file) but can also submit the results from other Stata commands so that GPT can better understand the user's data status and problems. Finally, the answers returned by GPT that contain Stata code will be displayed on the Stata screen in an executable form.


{title:Requirements}


{pstd}
1. {cmd:chatgpt} requires Stata version 15 or higher.
{p_end}

{pstd}
2. Windows Users need to install cURL first({browse "https://curl.se/download.html"}), a command-line tool and a library used for transferring data over various protocols, and set the path of cURL as an environment variable.
{p_end}

{pstd}
3. Python is required for both Windows and MacOS users.
{p_end}


{title:Options for chatgpt}


{dlgtab:config_options}


{marker key_openai}{...}
{phang}
{opt key_openai(string)} provides a key required to use large language models(LLM), distributed by the Open AI platform. 
It is an irregular string and is a required option when using {cmd:chatgpt {help chatgpt##Main:subcommands_Main}}. 
You can get a key from Open AI platform({browse "https://platform.openai.com/account/api-keys"}).


{marker stata}{...}
{phang}
{opt stata} requires responding from the perspective of Stata.
When you ask questions, especially about data processing or econometrics, GPT will answer based on how it can be implemented in Stata, including providing executable Stata code.

{marker system}{...}
{phang}
{opt system(string)} specifies a system prompt along with the actual question to help GPT better understand the question.

{marker model}{...}
{phang}
{opt model(modellist)} specifies a specific model for the GPT; default is {cmd:model("gpt-4")}.
{it:modellist} are

{p2colset 9 35 30 2}{...}
{p2col:{it:modellist}}Description{p_end}
{p2line}
{p2col:{it:gpt-3.5-turbo}}.{p_end}
{p2col:{it:gpt-4}}.{p_end}
{p2col:{it:gpt-4-turbo}}The latest GPT-4 Turbo model with vision capabilities.{p_end}
{p2col:{it:gpt-4-turbo-preview}}GPT-4 Turbo preview model.{p_end}
{p2col:{it:gpt-4o}}High-intelligence flagship model for complex, multi-step tasks. {it:GPT-4o} is cheaper and faster than {it:gpt-4-turbo}.{p_end}
{p2col:{it:gpt-4o-mini}}Affordable and intelligent small model for fast, lightweight tasks. {it:gpt-4o-mini} is cheaper and more capable than {it:gpt-3.5-turbo}.{p_end}
{p2line}
{p2colreset}{...}

{pmore}
For the billing standards of each model, please visit {browse "https://openai.com/api/pricing/"}


{marker temperature}{...}
{phang}
{opt temperature(float)} determines the randomness of the output; default is {cmd: 0.2}; {cmd:0} {ul:<} {it:#} {ul:<} {cmd:2}. 
Higher values like 1.5 will make the output more random, while lower values like 0.2 will make it more focused and deterministic.


{marker max_tokens}{...}
{phang}
{opt max_tokens(#)} specifies the maximum number of tokens that can be generated in the response. 
By default, the length of the reply is not limited.
You can think of tokens as pieces of words, where 1,000 tokens is about 750 words.


{marker agenturl}{...}
{phang}
{opt agenturl(URL)} specifies the proxy address of the intermediary service provider.
By default, {cmd: chatgpt} connect directly to OpenAI.


{marker proxy}{...}
{phang}
{opt proxy(ip_port)} specifies the proxy IP address and port for the local, such as {cmd:127.0.0.1:12345}.
By default, the local does not use a proxy server.


{dlgtab:talk_options}

{marker command}{...}
{phang}
{opt command(string)} specifies the content of the inquiry with GPT, and GPT will response based on the content.

{marker file}{...}
{phang}
{opt file(filepath)} specifies the plain text file to be submitted to GPT for reading. 
{it:filepath} may be one of the following:

{p2colset 9 40 30 2}{...}
{p2col:{it:filepath}}Description{p_end}
{p2line}
{p2col:{it:{cmd: D:/absolute/path/file.txt}}}Absolute path + filename{p_end}
{p2col:{it:{cmd: ../relative/path/file.conf}}}Relative path + filename{p_end}
{p2col:{it:{cmd: stata_command.ado}}}For Stata command files({it:ado files}), no path is needed; the program will automatically search for it.{p_end}
{p2col:{it:{cmd: stata_command.sthlp}}}For Stata help files({it:sthlp files}), no path is needed; the program will automatically search for it.{p_end}
{p2line}
{p2colreset}{...}

{marker do}{...}
{phang}
{opt do(stata_code)} specifies the {it:stata_code} to be executed by Stata and submits the execution result to GPT. 
This option is not allowed in {cmd: chatgpt multitalk}.


{marker config}{...}
{phang}
{opt config(config_name)} specifies the configuration file generated by {cmd: chatgpt config} to interact with GPT.
When using the {cmd:chatgpt talk/multitalk}, we generally recommend altering this or {it: config_options} but not both.
This option is required in {cmd: chatgpt longtalk}.

{dlgtab:other_options}

{marker generate}{...}
{phang}
{opt generate(variable)} generate a new variable and update the results from {cmd: chatgpt multitalk}.
{it: variable} is {cmd:gpt_res} by default.

{title:Example}

{pstd}
1. Quick Start

{phang}
{stata `"clear all"'}
{p_end}
{phang}
{stata `"global OPENAI_API_KEY = fileread("API_KEY.txt")"'}
{p_end}
{phang}
{stata `"chatgpt talk, key_openai($OPENAI_API_KEY) command("how to clear the dataset in Stata?") stata"'}
{p_end}

{pstd}
2. Longtalk Mode

{phang}
{stata `"clear"'}
{p_end}
{phang}
{stata `"global OPENAI_API_KEY = fileread("API_KEY.txt")"'}
{p_end}
{phang}
{stata `"chatgpt config lt, key_openai($OPENAI_API_KEY) stata system("Please add 'powered by GPT' at the end of each response")"'}
{p_end}
{phang}
{stata `"chatgpt longtalk, command("how to clear the dataset in Stata?") config("lt")"'}
{p_end}
{phang}
{stata `"chatgpt longtalk, command("how to generate a variable?") config("lt")"'}
{p_end}
{phang}
{stata `"chatgpt longtalk, command("Summarize the above content.") config("lt")"'}
{p_end}


{pstd}
3. Analyse the Sthlp File

{phang}
{stata `"clear"'}
{p_end}
{phang}
{stata `"ssc install cntraveltime,replace"'}
{p_end}
{phang}
{stata `"chatgpt talk, config("lt") command("Can this command calculate the travel distance of an ocean freighter?") file(cntraveltime.sthlp)"'}
{p_end}


{pstd}
4. Analyse the dataset with {it:do() option}

{phang}
{stata `"clear"'}
{p_end}
{phang}
{stata `"webuse set "https://stata-chatgpt.oss-cn-beijing.aliyuncs.com/chatgpt""'}
{p_end}
{phang}
{stata `"webuse data1,clear"'}
{p_end}
{phang}
{stata `"chatgpt talk,  do("list") config("lt") command("To observe the data details, please indicate how to generate delta using stkcd and year.")"'}
{p_end}


{pstd}
5. Limit the length of the reply

{phang}
{stata `"clear"'}
{p_end}
{phang}
{stata `"global OPENAI_API_KEY = fileread("API_KEY.txt")"'}
{p_end}
{phang}
{stata `"chatgpt talk, command("What are the differences between Stata and Eviews?") max_tokens(100) key_openai($OPENAI_API_KEY)"'}
{p_end}
{phang}
{stata `"chatgpt talk, command("What are the differences between Stata and Eviews?") max_tokens(20) key_openai($OPENAI_API_KEY)"'}
{p_end}


{pstd}
6. Multitalk mode

{phang}
{stata `"clear"'}
{p_end}
{phang}
{stata `"sysuse census.dta, clear"'}
{p_end}
{phang}
{stata `"keep in 1/10"'}
{p_end}
{phang}
{stata `"global OPENAI_API_KEY = fileread("API_KEY.txt")"'}
{p_end}
{phang}
{stata `"chatgpt config nostata, key_openai($OPENAI_API_KEY) model("gpt-4o")"'}
{p_end}
{phang}
{stata `"chatgpt multitalk, config("nostata") command("Please describe the base infomation of {state} of USA.")"'}
{p_end}
{phang}
{stata `"chatgpt update,gen(state_info)"'}
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

