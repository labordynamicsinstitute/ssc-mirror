{smcl}
{* Jun 2024} {...}
{hline}
help for {hi:validemail}
{hline}

{title:Title}

{p 4 8 2}{hi:validemail} {hline 2} Email address validation using Regex, DNS/MX lookups, and disposable domain detection


{title:Syntax}

{p 4 8 2}
{cmd:validemail} {it:varname} [{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt gen:erate(newvar)}}New variable for validation status codes (Default: validated_status){p_end}
{synopt:{opt dns(newvar)}}New variable for extracted domains (Default: validated_domain){p_end}
{synopt:{opt ip(newvar)}}New variable for server IP addresses (Default: validated_ip){p_end}
{synopt:{opt dispos:able(newvar)}}New variable indicating disposable email domains (Default: validated_disposable){p_end}
{synopt:{opt mx}}Check for MX (Mail Exchanger) records instead of simple A records{p_end}
{synopt:{opt low:ercase}}Convert emails to lowercase before validation{p_end}
{synopt:{opt mergereport}}Display a tabulation of the validation results{p_end}
{synopt:{opt regex(string)}}Override the default RFC-compliant-ish regex pattern{p_end}
{synoptline}


{title:Description}

{p}{cmd:validemail} provides a multi-stage validation for email address variables. It performs:
{p_end}
{p 4 8 2}1. {bf:Regex Check}: Verifies the format matches standard email patterns.{p_end}
{p 4 8 2}2. {bf:Disposable Check}: Compares domains against a list of known disposable email providers (e.g., mailinator.com).{p_end}
{p 4 8 2}3. {bf:DNS/MX Lookup}: Uses {cmd:nslookup} to verify the domain exists and can receive mail (if {cmd:mx} is specified).{p_end}

{title:Status Codes}

{p}The {opt generate()} variable contains the following codes:{p_end}
{p 4 8 2}{bf:0}: Invalid format (Regex failed){p_end}
{p 4 8 2}{bf:1}: Valid format, but DNS/MX lookup failed (domain might not exist){p_end}
{p 4 8 2}{bf:2}: Valid format and DNS/MX lookup passed{p_end}
{p 4 8 2}{bf:3}: Valid format and DNS/MX passed, but the domain is a known disposable provider{p_end}


{title:Options}

{p 0 4}{opt gen:erate(newvar)} specifies the name of the new variable to hold the validation status. {p_end}

{p 0 4}{opt dns(newvar)} specifies the name of the new variable to hold the domain extracted from the email. {p_end}

{p 0 4}{opt mx} instructs the command to specifically look for MX (Mail Exchanger) records. This is a more accurate way to verify if a domain is configured to receive emails. {p_end}

{p 0 4}{opt low:ercase} converts all email addresses to lowercase before validation. This is recommended as email domains are case-insensitive. {p_end}

{p 0 4}{opt mergereport} displays a summary table of the validation results using the generated status codes. {p_end}

{p 0 4}{opt regex(string)} allows you to provide a custom regular expression for the initial format check. {p_end}


{title:Examples}

{p 4 8 2}1. Basic validation of an email variable:{p_end}
{p 8 12 2}{cmd:. validemail email_address, mergereport}{p_end}

{p 4 8 2}2. Strict validation with MX check and lowercase conversion:{p_end}
{p 8 12 2}{cmd:. validemail email, mx lowercase generate(email_status) mergereport}{p_end}

{p 4 8 2}3. Using a custom regex:{p_end}
{p 8 12 2}{cmd:. validemail email, regex("^[a-z]+@[a-z]+\.com$")}{p_end}


{title:Author}

{p 4 4 2}Eric A. Booth{p_end}
{p 4 4 2}eric.a.booth@gmail.com{p_end}
{p 4 4 2}https://github.com/ericbooth/ValidEmail-stata{p_end}

{title:Also See}

{p 4 4 2}Online: {help ustrregexm}, {help nslookup}{p_end}
