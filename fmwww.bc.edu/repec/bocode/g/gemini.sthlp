{smcl}
{* *! version 2.3.2  27apr2026}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "gemini##syntax"}{...}
{viewerjumpto "Description" "gemini##description"}{...}
{viewerjumpto "Options" "gemini##options"}{...}
{viewerjumpto "Examples" "gemini##examples"}{...}
{viewerjumpto "Installation Guide" "gemini##installation"}{...}
{viewerjumpto "Troubleshooting" "gemini##troubleshooting"}{...}

{title:Title}

{phang}
{bf:gemini} {hline 2} Use Gemini AI directly from the Stata command line to support research, coding, and data tasks.

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{bf:gemini} {it:query} [{cmd:,} {it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt csv}}Format results as a CSV table and import into Stata memory.{p_end}
{synopt :{opt json}}Format results as JSON and import into Stata memory (requires Python).{p_end}
{synopt :{opt clear}}Required if {cmd:csv} or {cmd:json} is used and data is already in memory.{p_end}
{synopt :{opt path(string)}}Specify the absolute path to the gemini executable.{p_end}
{synopt :{opt model(string)}}Specify the Gemini model (e.g., {cmd:gemini-1.5-flash}).{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:gemini} integrates the Gemini CLI with Stata. It allows you to perform live web searches, 
generate synthetic datasets, get coding assistance, and extract structured data directly into Stata 
using Google's Gemini models. This command requires the {cmd:@google/gemini-cli} to be installed 
on your system.

{marker options}{...}
{title:Options}

{phang}
{opt csv}: Instructs Gemini to return data in CSV format, which is then automatically imported into Stata.

{phang}
{opt json}: Instructs Gemini to return data in JSON format. This requires Python with the {cmd:pandas} library installed to convert the data for Stata import.

{phang}
{opt clear}: Standard Stata option to clear existing data from memory before importing new results.

{phang}
{opt path(string)}: Use this if the command cannot find your {cmd:gemini} installation. Provide the full path (e.g., {cmd:/usr/local/bin/gemini} or {cmd:C:\Users\Name\AppData\Roaming\npm\gemini.cmd}).

{phang}
{opt model(string)}: Specify the model to use. Common options include {cmd:gemini-1.5-flash} (fast/cheap) and {cmd:gemini-1.5-pro} (complex tasks).

{marker examples}{...}
{title:Examples}

{dlgtab:1. General Research}
{phang2}{cmd:. gemini "What are the current top 5 largest cities in Texas by population?"}{p_end}

{dlgtab:2. Data Extraction}
{phang2}{cmd:. gemini "List the top 5 largest cities in Texas with their 2020 and 2024 estimated population", csv clear}{p_end}

{dlgtab:3. Synthetic Data}
{phang2}{cmd:. gemini "Generate a synthetic dataset of 100 observations with 'age', 'income', and 'education' (HS, College, Grad)", csv clear}{p_end}

{dlgtab:4. Stata Coding Help}
{phang2}{cmd:. gemini "How do I use the -margins- command after a probit regression with an interaction term?"}{p_end}

{marker installation}{...}
{title:Installation Guide}

{pstd}This command is a wrapper for the {bf:Gemini CLI}. You MUST install the CLI first.{p_end}

{dlgtab:Step 1: Install Node.js}
{pstd}{bf:macOS}: Install via Homebrew: {cmd:brew install node}{p_end}
{pstd}{bf:Windows}: Download the installer from {browse "https://nodejs.org/"} (LTS version recommended).{p_end}
{pstd}{bf:Linux (Ubuntu/Debian)}: {cmd:sudo apt update && sudo apt install nodejs npm}{p_end}

{dlgtab:Step 2: Install Gemini CLI}
{pstd}Open your terminal (Terminal on Mac/Linux, PowerShell on Windows) and run:{p_end}
{pmore}{cmd:npm install -g @google/gemini-cli}{p_end}

{dlgtab:Step 3: Authentication}
{pstd}In your terminal, run:{p_end}
{pmore}{cmd:gemini}{p_end}
{pstd}Follow the prompts to log in to your Google account and authorize the CLI.{p_end}

{marker troubleshooting}{...}
{title:Troubleshooting}

{phang}{bf:Command not found in Stata}{p_end}
{pstd}Stata's {cmd:shell} environment may have a different PATH than your terminal. 
Run {cmd:which gemini} (Mac/Linux) or {cmd:where gemini} (Windows) in your terminal to find the path, then use the {cmd:path()} option in Stata:{p_end}
{pmore}{cmd:gemini "test", path("/usr/local/bin/gemini")}{p_end}

{phang}{bf:Permission Errors (Mac/Linux)}{p_end}
{pstd}If {cmd:npm install} fails, you may need to use {cmd:sudo} or fix your npm permissions. 
Using a version manager like {cmd:nvm} is recommended to avoid permission issues.{p_end}

{phang}{bf:Execution Policy (Windows)}{p_end}
{pstd}If PowerShell blocks the script, run PowerShell as Administrator and execute:{p_end}
{pmore}{cmd:Set-ExecutionPolicy RemoteSigned -Scope CurrentUser}{p_end}

{phang}{bf:JSON Import Fails}{p_end}
{pstd}Ensure Python is installed and accessible to Stata ({cmd:python query}). 
Install pandas: {cmd:pip install pandas}.{p_end}

{marker alternative}{...}
{title:Bonus: Alternative 'stata_ai' (Local LLM via Ollama)}

{pstd}
For users on macOS who require total data privacy, you can install and run a local LLM (Sandboxed) using Ollama. This allows you to generate Stata code without any data leaving your machine.
{p_end}

{pstd}
Copy and paste the following block into your Terminal. This script will install Ollama, download the top-performing Stata model (Gemma 3), and set up an alias to generate code instantly from your terminal or via {cmd:!stata_ai} in Stata.
{p_end}

{pmore}
{it:# Install Ollama runner} {break}
{cmd:brew install ollama} {break}
{break}
{it:# Start Ollama in the background} {break}
{cmd:nohup ollama serve > /dev/null 2>&1 &} {break}
{break}
{it:# Pull Gemma 3 (12B) - High-accuracy for Stata} {break}
{cmd:ollama pull gemma3:12b} {break}
{break}
{it:# Create a 'stata_ai' alias for precision} {break}
{cmd:alias stata_ai='ollama run gemma3:12b "Act as an expert Stata programmer. Provide only the code, no explanation unless asked. My query: "'}
{p_end}

{phang}
{bf:Why this setup?} {p_end}
{p 8 12 2}1. {bf:Gemma 3}: Identified as a top local performer for Stata (77.8%+ accuracy). {p_end}
{p 8 12 2}2. {bf:Low Temp}: The alias forces logical consistency over creativity. {p_end}
{p 8 12 2}3. {bf:Privacy}: The entire pipeline is local; sensitive data never leaves your computer. {p_end}


{title:Author}

{pstd}Eric A. Booth{p_end}
{pstd}eric.a.booth@gmail.com{p_end}
{pstd}Texas 2036 ({browse "https://texas2036.org/"}){p_end}
{pstd}{browse "https://github.com/ericbooth/Gemini-stata"}{p_end}
