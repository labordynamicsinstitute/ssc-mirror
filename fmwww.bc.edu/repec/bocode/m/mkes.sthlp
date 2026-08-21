{smcl}
{* mkes - Make English Sentences (Spoken English sentence generator)}{...}
{hline}

{title:Title}
{pstd}{bf}mkes{bf} -- Generate English oral sentences from a user-supplied prompt phrase{p_end}

{title:Syntax}
{p 8 8 2}
{cmdab:mkes} {it}"prompt"{it} [{cmd:,} {opt n}({it}#{it}) {opt out}put({it}filename{it}) {opt rep}lace]{p_end}
{p 8 8 2}
{cmdab:mkes} {cmd:,} {opt units}({it}#{it}) [{opt mode}({it}string{it}) {opt n}({it}#{it}) {opt out}put({it}filename{it}) {opt rep}lace {opt start}({it}#{it})]{p_end}
{p 8 8 2}
{cmdab:mkes --list}{p_end}

{title:Description}
{pstd}
{bf}mkes{bf} is a spoken English sentence generator. Provide a short
daily-English prompt phrase -- for example, {cmd:"There is no"},
{cmd:"I want to"}, or {cmd:"Can you"} -- and the program automatically
produces sentences sharing the same grammatical structure. Every English
sentence is paired with a complete Chinese translation, so learners see
the full meaning at a glance.
{p_end}

{pstd}
{bf}New in v3.1:{bf} Multi-unit mode. Specify how many practice units you want
via {opt units}({it}#{it}) and the program generates a single output file
containing multiple spoken-English units -- each featuring a different
sentence pattern -- ready for one-click import into the Dingyuan Accounting
LAN spoken English module. Choose between sequential and random pattern
selection modes.
{p_end}

{pstd}
The program ships with {it}300 sentence patterns{it} spanning grammar
fundamentals and {it}23 daily-life and work scenarios{it} -- habits, purpose,
comfort, gratitude, anticipation, preferences, senses, explanation, opinions,
suggestions, plans, reminders, advantages, interests, emotions, apologies,
inquiries, time, eating and drinking, wishes, discussing, asking around,
invitations -- supported by over {it}1,050 English-Chinese{it} word/phrase
pairs across 31 word banks. The engine is written in Python and runs inside
Stata via the {cmd:python} integration (requires {bf}Stata 16+{bf} with
Python configured).
{p_end}

{pstd}
Smart fallback: if a prompt does not exactly match any known pattern, the
program uses heuristics to guess the appropriate word type and generates
sentences anyway.
{p_end}

{title:Options}

{title:Single-Prompt Mode (original)}
{p 8 8 2}
{opt n}({it}#{it}) -- Number of sentences to generate; default is {opt n(10)}.
Sentences are randomly drawn from the built-in word banks without replacement.
{p_end}
{p 8 8 2}
{opt out}put({it}filename{it}) -- Output filename without extension; default is
{cmd:mkes_output}. The program appends {cmd:.txt} automatically.
{p_end}
{p 8 8 2}
{opt rep}lace -- Overwrite an existing output file of the same name.
{p_end}
{p 8 8 2}
{cmd:--list} -- List all 300 supported sentence pattern templates with their
match keys and available word counts.
{p_end}

{title:Multi-Unit Mode (new in v3.1)}
{pstd}
When {opt units}({it}#{it}) is specified with a value greater than 0, the
program enters multi-unit mode. It automatically selects multiple distinct
sentence patterns and generates a complete multi-unit practice file in a
single run.
{p_end}

{p 8 8 2}
{opt units}({it}#{it}) -- Number of spoken-English practice units to generate.
Each unit uses a different sentence pattern. Required for multi-unit mode.
{p_end}
{p 8 8 2}
{opt mode}({it}string{it}) -- Pattern selection mode. Options:{p_end}
{p 12 12 2}
{cmd:sequential} (default) -- Pick patterns in order from the pattern database,
starting from the index specified by {opt start}().{p_end}
{p 12 12 2}
{cmd:random} -- Pick patterns randomly without replacement. Each run produces
a different set. Use {opt start}() as a random seed for reproducible results.
{p_end}
{p 8 8 2}
{opt start}({it}#{it}) -- Starting pattern number or random seed. Default is {opt start(1)}.{p_end}
{p 12 12 2}
In {cmd:sequential} mode: pattern number to start from (e.g.,
{cmd:start(50)} starts from pattern p050 "I think"). Use {cmd:mkes --list}
to see all pattern numbers. Wraps around if the end is reached.{p_end}
{p 12 12 2}
In {cmd:random} mode: random seed for reproducible pattern selection.
Values > 1 set a fixed seed; omit or use {cmd:start(1)} for system randomness.{p_end}
{p 8 8 2}
{opt n}({it}#{it}) -- Sentences per unit; default is {opt n(10)}.
{p_end}
{p 8 8 2}
{opt out}put({it}filename{it}) and {opt rep}lace -- Same as single-prompt mode.
{p_end}

{title:Examples}

{pstd}
{bf}Single-prompt mode:{p_end}
{p 8 8 2}{cmd:. mkes "I'm", n(30) output(output)}{p_end}
{p 12 12 2}{it}Generates 30 sentences starting with "I'm ...", saved as output.txt{it}{p_end}
{p 8 8 2}{cmd:. mkes "There is no", n(15)}{p_end}
{p 12 12 2}{it}Generates 15 "There is no ..." sentences, saved as mkes_output.txt{it}{p_end}
{p 8 8 2}{cmd:. mkes "Can you", n(10) replace}{p_end}
{p 12 12 2}{it}Generates 10 "Can you ...?" questions, overwriting mkes_output.txt{it}{p_end}

{pstd}
{bf}Multi-unit mode (new v3.1):{p_end}
{p 8 8 2}{cmd:. mkes , units(3) mode(sequential) n(5) replace}{p_end}
{p 12 12 2}{it}Generates 3 units in order (p001, p002, p003), 5 sentences each -> mkes_output.txt{it}{p_end}
{p 8 8 2}{cmd:. mkes , units(5) mode(random) n(10) output(daily_practice) replace}{p_end}
{p 12 12 2}{it}Generates 5 units with random patterns, 10 sentences each -> daily_practice.txt{it}{p_end}
{p 8 8 2}{cmd:. mkes , units(3) mode(sequential) start(50) n(8) output(mid_patterns) replace}{p_end}
{p 12 12 2}{it}Generates 3 units starting from pattern p050, 8 sentences each{it}{p_end}
{p 8 8 2}{cmd:. mkes , units(10) n(5) output(quick_review) replace}{p_end}
{p 12 12 2}{it}Generates 10 units in sequential order (default mode), 5 sentences each{it}{p_end}

{pstd}
{bf}Scenario-based prompts (single-prompt):{p_end}
{p 8 8 2}{cmd:. mkes "I usually", n(10) replace}{p_end}
{p 12 12 2}{it}Habit sentences{it}{p_end}
{p 8 8 2}{cmd:. mkes "Don't worry", n(5) output(comfort)}{p_end}
{p 12 12 2}{it}Comfort and encouragement sentences{it}{p_end}
{p 8 8 2}{cmd:. mkes "Why don't you", n(8) replace}{p_end}
{p 12 12 2}{it}Suggestion sentences{it}{p_end}

{pstd}
List all available patterns:{p_end}
{p 8 8 2}{cmd:. mkes --list}{p_end}
{p 12 12 2}{it}Displays all 300 supported sentence patterns{it}{p_end}

{title:Output Format}
{pstd}
Each output file is a UTF-8 text file. In single-prompt mode, one unit is
written. In multi-unit mode, multiple units are concatenated, each with its
own header.
{p_end}

{p 12 12 2}
{inp:# Unit 1:Pattern title with variants}{p_end}
{p 16 16 2}
{inp:English sentence  |  Chinese translation}{p_end}

{pstd}
Example output for {cmd:mkes "Can you", n(3)}:{p_end}
{p 12 12 2}
{inp:Can you help me?       |  你能帮我吗？}{p_end}
{p 12 12 2}
{inp:Can you wait for me?   |  你能等我吗？}{p_end}
{p 12 12 2}
{inp:Can you lend me?       |  你能借给我吗？}{p_end}

{pstd}
Example output for {cmd:mkes , units(2) mode(sequential) n(2)}:{p_end}
{p 12 12 2}
{inp:# Unit 1:There is / are / was / were / will be (no)...}{p_end}
{p 16 16 2}
{inp:There is no time.     |  没有时间。}{p_end}
{p 16 16 2}
{inp:There is no reply.    |  没有回应。}{p_end}
{p 12 12 2}
{inp:# Unit 2:There is / are / was / were a / an / some...}{p_end}
{p 16 16 2}
{inp:There is a problem.   |  有一个问题。}{p_end}
{p 16 16 2}
{inp:There is a chance.    |  有一个机会。}{p_end}

{pstd}
Output files can be imported directly into the Dingyuan Accounting LAN
({cmd:D:/dingyuan-system}) "Spoken English" training module via the
one-click import function.
{p_end}

{title:Supported Pattern Categories}

{pstd}
{bf}Part I -- Grammar Foundations{bf}{p_end}
{p 8 8 2}
(patterns p001--p311){p_end}

{pstd}
 1. There be existential patterns (There is no/a, There are, There was/were){break}
 2. I have / I've got possession patterns{break}
 3. I want / I'd like desire patterns{break}
 4. I can / I could ability patterns{break}
 5. Can you / Could you request patterns{break}
 6. I think / I believe opinion patterns{break}
 7. It is / It's descriptive patterns{break}
 8. I need / I must / I should necessity patterns{break}
 9. I like / I love / I enjoy preference patterns{break}
10. I hope / I wish desire patterns{break}
11. I'm / I am state patterns{break}
12. I'm going to / I will future patterns{break}
13. I've / I have done perfect patterns{break}
14. I used to / I'm used to habitual patterns{break}
15. How / What question patterns{break}
16. Let's / Let me imperative patterns{break}
17. This is / That is demonstrative patterns{break}
18. I'm trying to / I'm working on progressive patterns{break}
19. I'm sorry / I'm afraid emotional patterns{break}
20. Do you / Did you yes-no question patterns{break}
21. It's important / It's hard evaluative patterns{break}
22. I remember / I forget memory patterns{break}
23. Thank you / Thanks for gratitude patterns{break}
24. If I / If you conditional patterns{break}
25. One of / Some of quantity patterns{break}
26. I was past state patterns{break}
27. I've been / I've had experience patterns{break}
28. I'm looking forward to anticipation patterns{break}
29. I wonder / I was wondering curiosity patterns{break}
30. I'd rather / I'd better preference patterns{break}
31. He is / She is / They are third-person patterns{break}
32. I get / I feel change-of-state patterns
{p_end}

{pstd}
{bf}Part II -- Daily Life and Work Scenarios{bf}{p_end}
{p 8 8 2}
(patterns p312--p459, new in v3.1.0){p_end}

{pstd}
33. Habits -- I usually, I often, I always, I rarely, I never, I tend to{break}
34. Purpose -- I came here to, In order to, My goal is to, So that I can{break}
35. Comfort -- Don't worry, It's okay, Cheer up, I'm here for you{break}
36. Gratitude -- I'm grateful for, I owe you one for, Much appreciated{break}
37. Anticipation -- I can't wait to, I'm excited about, I'm eager to{break}
38. Preferences -- I'm fond of, I'm crazy about, I'm a big fan of{break}
39. Senses -- It sounds, It tastes, It smells, It feels, That sounds like{break}
40. Explanation -- The reason is that, That's because, Let me explain, To be honest{break}
41. Opinions -- As far as I'm concerned, From my perspective, Personally, I think{break}
42. Suggestions -- I suggest you, Why don't you, Have you considered, You could try{break}
43. Plans -- I intend to, I'm planning on, My plan is to{break}
44. Reminders -- Don't forget to, Remember to, Make sure you, Be sure to{break}
45. Advantages -- The advantage is that, One benefit is that, The best part is{break}
46. Interests -- I'm interested in, My hobby is, I'm passionate about, I'm learning to{break}
47. Emotions -- It makes me, I can't help feeling{break}
48. Apologies -- I apologize for, I didn't mean to, I regret, I shouldn't have{break}
49. Inquiries -- Could you tell me, I'd like to know, Do you happen to know{break}
50. Time -- It takes, How long does it take to, It's been, When do you usually{break}
51. Eating and Drinking -- Would you like some, Let's grab, I'm in the mood for, Have you tried{break}
52. Wishes -- I wish I could, If only I could, I dream of, Someday I will{break}
53. Discussing -- Speaking of, Let's talk about, Regarding, What do you think about{break}
54. Asking Around -- I was wondering if, Have you ever heard of, I'm curious about{break}
55. Invitations -- Would you like to join me for, Are you free for, Why don't we
{p_end}

{title:Requirements}
{pstd}
{bf}Stata 16.0{bf} or later with Python integration configured.
{p_end}
{p 8 8 2}{cmd:. python query}{p_end}
{pstd}
If Python is not configured:{p_end}
{p 8 8 2}{cmd:. python search}{p_end}
{p 8 8 2}{cmd:. set python_exec} {it}<path>{it}, {cmd:permanently}{p_end}

{title:Installation}
{pstd}
Place {cmd:mkes.ado} and {cmd:mkes.sthlp} in your Stata personal ado directory:{p_end}
{p 8 8 2}{cmd:. personal}{p_end}
{pstd}
Or add the program directory temporarily with {cmd:adopath}:{p_end}
{p 8 8 2}{cmd:. adopath + "E:/mkes"}{p_end}

{title:Integration}
{pstd}
Output files can be imported directly into the Dingyuan Accounting LAN
({cmd:D:/dingyuan-system}) "Spoken English" training module via the
one-click import function.
{p_end}

{title:Acknowledgments}
{pstd}
Since late July 2025, the {bf:Dingyuan Accounting} ({bf:鼎园会计}) team has
developed a suite of 39 empirical-accounting Stata programs and integrated them
into {bf:mysuite}. Users can batch-download all programs at once by typing:
{p_end}
{p 8 8 2}{cmd:ssc install mysuite, replace}{p_end}
{p 8 8 2}{cmd:mysuite, all download}{p_end}
{pstd}
The team subsequently built the Dingyuan Accounting teaching-and-research
integrated LAN ({cmd:D:/dingyuan-system}), which includes a built-in "Spoken
English" learning module. Users upload a Word ({cmd:.docx}) or plain-text
({cmd:.txt}) file with one click; the system automatically parses and imports
the content. Learners can then practise spoken English in three modes --
sentence-by-sentence follow-reading, sequential playback, or random playback.
{bf:mkes} was purpose-built to generate the spoken-English text files required
by this learning module.
{p_end}
{pstd}
We extend our sincere gratitude to {bf:Professor Christopher F. Baum} for his
invaluable guidance and strong support of the Dingyuan Accounting team's
programme-development work.
{p_end}

{title:Authors}
{pstd}
WU Lianghai{break}
School of Business, Anhui University of Technology (AHUT){break}
Ma'anshan, China{break}
Email: {browse "mailto:agd2010@yeah.net":agd2010@yeah.net}
{p_end}
{pstd}
WU Hanyan{break}
Department of Accountancy, City University of Hong Kong (CityU){break}
Email: {browse "mailto:2325476320@qq.com":2325476320@qq.com}
{p_end}

{title:Version}
{pstd}
3.1.0 -- 2026-08-11 (multi-unit mode; 300 patterns, 55 categories, 1,050+ word pairs; Stata 16+ with Python)
{p_end}

{title:Also see}
{pstd}
{browse "https://ideas.repec.org/c/boc/bocode/s459595.html":mysuite} --
Dingyuan Accounting suite of 39 empirical-accounting Stata programs{p_end}
