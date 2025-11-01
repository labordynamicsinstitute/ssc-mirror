{smcl}
{title:Title}

{phang}
Quantitative Text Analysis (qta) {hline 2} ESG Disclosure Analysis Tool

{title:Syntax}

{p 8 16 2}
{cmd:qta} [{cmd:,} {cmdab:save:stats}({it:filename}) {cmdab:esgd:ictionary}({it:filename}) {cmdab:sentd:ictionary}({it:filename}) {cmdab:r:eplace} {cmdab:m:ethod}({it:method}) {cmdab:lang:uage}({it:language})]

{title:Description}

{pstd}
{cmd:qta} performs quantitative text analysis on ESG (Environmental, Social, and Governance) 
disclosure reports. The command analyzes text content to measure the extent and 
quality of ESG disclosure based on different text analysis methods and languages.

{pstd}
The command generates multiple ESG disclosure metrics including dimension-specific scores, 
total disclosure score, disclosure quality index, diversity measure, and completeness indicator.

{pstd}
Version 4.4 introduces improved dictionary handling with language consistency checks and 
better error handling.

{title:Options}

{phang}
{cmd:savestats}({it:filename}) saves firm-level ESG statistics to the specified file. 
If no filename is provided or "1" is used, defaults to "ESG_statistics.dta". 
Minimum abbreviation: {cmd:save()}

{phang}
{cmd:esgdictionary}({it:filename}) specifies an external ESG classification dictionary file 
for custom keyword definitions. If not specified, the default built-in dictionary is used.
This option is used with kwf, cosine, and jaccard methods.
Minimum abbreviation: {cmd:esgd()}

{phang}
{cmd:sentdictionary}({it:filename}) specifies an external sentiment dictionary file 
for sentiment analysis. If not specified, the default built-in sentiment dictionary is used.
This option is used with the sentiment method.
Minimum abbreviation: {cmd:sentd()}

{phang}
{cmd:replace} specifies that the output file should be replaced if it already exists.
Minimum abbreviation: {cmd:r}

{phang}
{cmd:method}({it:method}) specifies the text analysis method to use. Available methods include:
{break}{cmd:kwf} - Keyword frequency analysis (default)
{break}{cmd:cosine} - Cosine similarity
{break}{cmd:jaccard} - Jaccard similarity
{break}{cmd:sentiment} - Sentiment analysis
{break}{cmd:complexity} - Text complexity analysis
{break}{cmd:readability} - Text readability analysis
Minimum abbreviation: {cmd:m()}

{phang}
{cmd:language}({it:language}) specifies the language of the text content. Available options:
{break}{cmd:cn} - Chinese text analysis (default)
{break}{cmd:en} - English text analysis
Minimum abbreviation: {cmd:lang()}

{title:Text Analysis Methods}

{pstd}
{bf:1. Keyword Frequency (KWF) Method:}
{break}Counts the frequency of ESG-related keywords in each dimension (Environmental, Social, Governance, General ESG).
{break}Algorithm: Frequency counting with normalization by text length
{break}Outputs: Raw frequency counts, coverage indicators, and composite scores.

{pstd}
{bf:2. Cosine Similarity Method:}
{break}Measures the cosine similarity between document vectors and reference ESG dictionary vectors.
{break}Algorithm: cos(θ) = (A·B) / (||A|| × ||B||)
{break}Outputs: Similarity scores (0-1 range) for each dimension and overall.

{pstd}
{bf:3. Jaccard Similarity Method:}
{break}Calculates Jaccard coefficient based on the presence/absence of ESG keywords.
{break}Algorithm: J(A,B) = |A∩B| / |A∪B|
{break}Outputs: Set similarity scores (0-1 range) for ESG keyword coverage.

{pstd}
{bf:4. Sentiment Analysis Method:}
{break}Analyzes emotional tone using positive/negative sentiment dictionaries.
{break}Algorithm: Sentiment = (Positive - Negative) / Total Words
{break}Outputs: Normalized sentiment scores (0-1 range).

{pstd}
{bf:5. Text Complexity Method:}
{break}Measures linguistic complexity through lexical diversity and structural features.
{break}Chinese: Sentence length, character diversity
{break}English: Sentence length, word length, lexical density
{break}Outputs: Composite complexity index (0-1 range).

{pstd}
{bf:6. Readability Method:}
{break}Assesses text readability using language-specific formulas.
{break}Chinese: Adapted Flesch formula for Chinese text
{break}English: Flesch Reading Ease Score
{break}Outputs: Normalized readability scores (0-1 range, higher = more readable).

{title:Dictionary Support}

{pstd}
{bf:ESG Classification Dictionaries:} Used with kwf, cosine, and jaccard methods
{break}Format: Text file with four sections marked by headers: Environmental, Social, Governance, General_ESG
{break}Example:
{space 8}Environmental
{space 8}环保
{space 8}环境
{space 8}排放
{space 8}...
{space 8}Social
{space 8}员工
{space 8}雇员
{space 8}...

{pstd}
{bf:Sentiment Dictionaries:} Used with sentiment method
{break}Format: Text file with one word per line, followed by comma and sentiment score (1 for positive, -1 or -0.5 for negative)
{break}Example:
{space 8}积极,1
{space 8}重视,1
{space 8}优秀,1
{space 8}问题,-1
{space 8}不足,-1

{title:Required Variables}

{phang}
{cmd:year} - Year of observation{p_end}
{phang}
{cmd:stkcd} - Stock code identifier{p_end}
{phang}
{cmd:ESGreport} - Text content of ESG/sustainability reports{p_end}

{title:Generated Variables}

{phang}
{cmd:esg_environmental_score} - Environmental dimension score{p_end}
{phang}
{cmd:esg_social_score} - Social dimension score{p_end}
{phang}
{cmd:esg_governance_score} - Governance dimension score{p_end}
{phang}
{cmd:esg_general_esg_score} - General ESG topic score{p_end}
{phang}
{cmd:esg_total_score} - Total ESG disclosure score{p_end}
{phang}
{cmd:esg_disclosure_quality} - Quality index{p_end}
{phang}
{cmd:esg_diversity} - Diversity measure across dimensions{p_end}
{phang}
{cmd:esg_completeness} - Completeness percentage across dimensions{p_end}

{title:Method-Specific Variables}

{phang}
{cmd:esg_cosine_similarity} - Cosine similarity score (cosine method){p_end}
{phang}
{cmd:esg_jaccard_similarity} - Jaccard similarity score (jaccard method){p_end}

{title:Default Dictionaries}

{pstd}
The command includes comprehensive built-in dictionaries for both Chinese and English:

{pstd}
{bf:Chinese ESG Dictionary:} Includes 60+ terms across Environmental, Social, Governance, and General_ESG categories.

{pstd}
{bf:English ESG Dictionary:} Includes 60+ terms across Environmental, Social, Governance, and General_ESG categories.

{pstd}
{bf:Chinese Sentiment Dictionary:} Includes 30 positive words and 18 negative words with sentiment scores.

{pstd}
{bf:English Sentiment Dictionary:} Includes 30 positive words and 17 negative words with sentiment scores.

{title:Important Notes}

{pstd}
{bf:Language Consistency:} Ensure that the dictionary language matches the text content language.
Using Chinese dictionaries with English text (or vice versa) will result in poor matching.

{pstd}
{bf:Dictionary Format:} External dictionaries must follow the specified format exactly.
ESG dictionaries use category headers, sentiment dictionaries use comma-separated scores.

{title:Examples}

{pstd}Basic analysis with default Chinese dictionary:{p_end}
{phang2}{cmd:. qta}{p_end}

{pstd}Analysis with English language:{p_end}
{phang2}{cmd:. qta, lang(en)}{p_end}

{pstd}Keyword frequency analysis with custom ESG dictionary:{p_end}
{phang2}{cmd:. qta, esgdictionary(esg_dict_cn.txt)}{p_end}

{pstd}Cosine similarity analysis:{p_end}
{phang2}{cmd:. qta, method(cosine)}{p_end}

{pstd}Jaccard similarity analysis:{p_end}
{phang2}{cmd:. qta, method(jaccard)}{p_end}

{pstd}Sentiment analysis with custom sentiment dictionary:{p_end}
{phang2}{cmd:. qta, method(sentiment) sentdictionary(sentiment_cn.txt)}{p_end}

{pstd}Text complexity analysis:{p_end}
{phang2}{cmd:. qta, method(complexity)}{p_end}

{pstd}Readability analysis:{p_end}
{phang2}{cmd:. qta, method(readability)}{p_end}

{pstd}Analysis with both custom dictionaries:{p_end}
{phang2}{cmd:. qta, esgdictionary(esg_dict_en.txt) sentdictionary(sentiment_en.txt) lang(en)}{p_end}

{pstd}Analysis with custom dictionary and saving statistics:{p_end}
{phang2}{cmd:. qta, savestats(my_esg_stats.dta) esgdictionary(my_esg_dict.txt) replace}{p_end}

{pstd}Using minimum abbreviations:{p_end}
{phang2}{cmd:. qta, save(1) esgd(esg_dict.txt) sentd(sentiment.txt) r m(cosine) lang(en)}{p_end}

{title:Authors}

{pstd}Wu Lianghai{p_end}
{pstd}School of Business, Anhui University of Technology (AHUT){p_end}
{pstd}Ma'anshan, China{p_end}
{pstd}E-mail: {browse "mailto:agd2010@yeah.net":agd2010@yeah.net}{p_end}

{pstd}Chen Liwen{p_end}
{pstd}School of Business, Anhui University of Technology (AHUT){p_end}
{pstd}Ma'anshan, China{p_end}
{pstd}E-mail: {browse "mailto:2184844526@qq.com":2184844526@qq.com}{p_end}

{pstd}Wu Hanyan{p_end}
{pstd}School of Economics and Management, Nanjing University of Aeronautics and Astronautics (NUAA){p_end}
{pstd}Nanjing, China{p_end}
{pstd}E-mail: {browse "mailto:2325476320@qq.com":2325476320@qq.com}{p_end}

{pstd}Shen Yongxu{p_end}
{pstd}School of Business, Anhui University of Technology (AHUT){p_end}
{pstd}Ma'anshan, China{p_end}
{pstd}E-mail: {browse "mailto:3010760031@qq.com":3010760031@qq.com}{p_end}

{title:Version}

{pstd}Version 4.4 - 27Oct2025{p_end}

{title:Also See}

{pstd}
See {help text analysis} for related text analysis commands in Stata.
{*}