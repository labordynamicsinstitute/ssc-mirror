*! qta.ado - Quantitative Text Analysis for ESG Disclosure
*! Version 4.4 - 27Oct2025
*! Authors: Wu Lianghai, Chen Liwen, Wu Hanyan, Shen Yongxu
*! School of Business, Anhui University of Technology (AHUT)
*! School of Economics and Management, Nanjing University of Aeronautics and Astronautics (NUAA)
*! Contact: agd2010@yeah.net, 2184844526@qq.com, 2325476320@qq.com, 3010760031@qq.com

program define qta
    version 16
    syntax [, SAVEstats(string) ESGDictionary(string) SENTDictionary(string) Replace Method(string) Language(string)]
    
    * Set default method if not specified
    if "`method'" == "" {
        local method "kwf"
    }
    
    * Set default language if not specified
    if "`language'" == "" {
        local language "cn"
    }
    
    * Validate method option
    if !inlist("`method'", "kwf", "cosine", "jaccard", "sentiment", "complexity", "readability") {
        di as error "Invalid method: `method'. Valid methods are: kwf, cosine, jaccard, sentiment, complexity, readability"
        exit 198
    }
    
    * Validate language option
    if !inlist("`language'", "cn", "en") {
        di as error "Invalid language: `language'. Valid languages are: cn (Chinese), en (English)"
        exit 198
    }
    
    di "Starting Quantitative Text Analysis for ESG disclosure..."
    di "Using method: `method'"
    di "Using language: `language'"
    
    * Check required variables
    cap confirm variable year stkcd ESGreport
    if _rc {
        di as error "Missing required variables: year, stkcd, ESGreport"
        di as error "Please make sure your dataset contains these variables before running qta"
        exit 111
    }
    
    * Clean previous variables
    cap drop esg_*
    
    * ========================================
    * Load ESG dictionaries (for kwf, cosine, jaccard methods)
    * ========================================
    if inlist("`method'", "kwf", "cosine", "jaccard") {
        if "`esgdictionary'" != "" {
            di "Loading ESG dictionary from: `esgdictionary'"
            cap confirm file "`esgdictionary'"
            if _rc {
                di as error "ESG dictionary file `esgdictionary' not found"
                exit 601
            }
            
            * Read external ESG dictionary file
            tempname fh
            file open `fh' using "`esgdictionary'", read
            file read `fh' line
            
            local section ""
            local env_words ""
            local social_words ""
            local gov_words ""
            local general_words ""
            
            while r(eof)==0 {
                if trim("`line'") != "" {
                    if inlist(trim("`line'"), "Environmental", "Social", "Governance", "General_ESG") {
                        local section = trim("`line'")
                    }
                    else {
                        if "`section'" == "Environmental" {
                            local env_words "`env_words' `=trim("`line'")'"
                        }
                        else if "`section'" == "Social" {
                            local social_words "`social_words' `=trim("`line'")'"
                        }
                        else if "`section'" == "Governance" {
                            local gov_words "`gov_words' `=trim("`line'")'"
                        }
                        else if "`section'" == "General_ESG" {
                            local general_words "`general_words' `=trim("`line'")'"
                        }
                    }
                }
                file read `fh' line
            }
            file close `fh'
            
            * Remove leading/trailing spaces and clean up
            local env_words = trim("`env_words'")
            local social_words = trim("`social_words'")
            local gov_words = trim("`gov_words'")
            local general_words = trim("`general_words'")
            
            di "External ESG dictionary loaded successfully"
            di "Environmental words: `: word count `env_words''"
            di "Social words: `: word count `social_words''"
            di "Governance words: `: word count `gov_words''"
            di "General ESG words: `: word count `general_words''"
        }
        else {
            * Use default built-in ESG dictionary based on language
            if "`language'" == "cn" {
                di "Using default Chinese ESG dictionary"
                local env_words "环保 环境 排放 碳 温室气体 能源 水资源 废物 污染 可持续发展 生态 绿色 清洁 可再生能源 气候变化 节能减排 循环经济"
                local social_words "员工 雇员 人权 劳动 安全 健康 培训 发展 社区 公益 慈善 消费者 客户 产品质量 责任 福利 平等 多元化 人权保障"
                local gov_words "治理 董事会 监事会 独立董事 审计 风险 合规 内部控制 透明度 披露 股东 利益相关者 伦理 反腐败 商业道德"
                local general_words "ESG 可持续 社会责任 企业公民 道德 伦理 长期价值 利益相关方 可持续发展报告"
            }
            else if "`language'" == "en" {
                di "Using default English ESG dictionary"
                local env_words "environmental protection environment emission carbon greenhouse gas energy water resource waste pollution sustainable development ecology green clean renewable energy climate change energy saving and emission reduction circular economy"
                local social_words "employee staff human rights labor safety health training development community public welfare charity consumer customer product quality responsibility welfare equality diversity human rights protection"
                local gov_words "governance board of directors supervisory board independent director audit risk compliance internal control transparency disclosure shareholder stakeholder ethics anti-corruption business ethics"
                local general_words "ESG sustainability social responsibility corporate citizen ethics ethical long-term value stakeholder sustainability report"
            }
        }
        
        * Language consistency check
        if "`esgdictionary'" != "" {
            di "Note: Using external ESG dictionary. Please ensure dictionary language matches text content language."
        }
    }
    
    * ========================================
    * Load sentiment dictionaries (for sentiment method)
    * ========================================
    if "`method'" == "sentiment" {
        if "`sentdictionary'" != "" {
            di "Loading sentiment dictionary from: `sentdictionary'"
            cap confirm file "`sentdictionary'"
            if _rc {
                di as error "Sentiment dictionary file `sentdictionary' not found"
                exit 601
            }
            
            * Read external sentiment dictionary file
            tempname fh
            file open `fh' using "`sentdictionary'", read
            file read `fh' line
            
            local positive_words ""
            local negative_words ""
            while r(eof)==0 {
                if trim("`line'") != "" {
                    tokenize "`line'", parse(",")
                    local word = trim("`1'")
                    local score = trim("`3'")
                    
                    if "`score'" == "1" {
                        local positive_words "`positive_words' `word'"
                    }
                    else if "`score'" == "-1" | "`score'" == "-0.5" {
                        local negative_words "`negative_words' `word'"
                    }
                }
                file read `fh' line
            }
            file close `fh'
            
            * Clean up word lists
            local positive_words = trim("`positive_words'")
            local negative_words = trim("`negative_words'")
            
            di "External sentiment dictionary loaded successfully"
            di "Positive words: `: word count `positive_words''"
            di "Negative words: `: word count `negative_words''"
        }
        else {
            * Use default built-in sentiment dictionary based on language
            if "`language'" == "cn" {
                di "Using default Chinese sentiment dictionary"
                local positive_words "积极 重视 优秀 良好 完善 有效 透明 全面 可持续发展 节能减排 环境保护 健康安全 职业培训 福利保障 风险管理 合规经营 社会责任 公益慈善 长期价值 绿色转型 新增 加强 推动 致力于 关注 注重 关爱 保障 提升 改善"
                local negative_words "问题 不足 缺陷 污染 排放 风险 挑战 困难 压力 基本 一般 有限 初步 有待 缺乏 缺失 落后"
            }
            else if "`language'" == "en" {
                di "Using default English sentiment dictionary"
                local positive_words "excellent good comprehensive effective transparent sustainable development protection healthy safe training welfare rights management compliance responsibility charitable value green added enhanced promoted reduces conserves committed focuses emphasizes cares ensures improves"
                local negative_words "problem deficiency defect pollution emission risk challenge difficulty pressure basic normal limited preliminary lacks deficient missing backward"
            }
        }
        
        * Language consistency check
        if "`sentdictionary'" != "" {
            di "Note: Using external sentiment dictionary. Please ensure dictionary language matches text content language."
        }
    }
    
    * Method-specific processing
    if "`method'" == "kwf" {
        * Keyword Frequency Method
        di "Using Keyword Frequency (KWF) method..."
        
        * Initialize all score variables first
        gen esg_environmental_score = 0
        gen esg_social_score = 0
        gen esg_governance_score = 0
        gen esg_general_esg_score = 0
        
        * Process environmental keywords
        di "Processing environmental keywords..."
        local env_count = 0
        foreach word in `env_words' {
            quietly replace esg_environmental_score = esg_environmental_score + ///
                (length(ESGreport) - length(subinstr(ESGreport, "`word'", "", .))) / length("`word'")
            local env_count = `env_count' + 1
        }
        gen esg_environmental_coverage = (esg_environmental_score > 0)
        
        * Process social keywords  
        di "Processing social keywords..."
        local social_count = 0
        foreach word in `social_words' {
            quietly replace esg_social_score = esg_social_score + ///
                (length(ESGreport) - length(subinstr(ESGreport, "`word'", "", .))) / length("`word'")
            local social_count = `social_count' + 1
        }
        gen esg_social_coverage = (esg_social_score > 0)
        
        * Process governance keywords
        di "Processing governance keywords..."
        local gov_count = 0
        foreach word in `gov_words' {
            quietly replace esg_governance_score = esg_governance_score + ///
                (length(ESGreport) - length(subinstr(ESGreport, "`word'", "", .))) / length("`word'")
            local gov_count = `gov_count' + 1
        }
        gen esg_governance_coverage = (esg_governance_score > 0)
        
        * Process general ESG keywords
        di "Processing general ESG keywords..."
        local general_count = 0
        foreach word in `general_words' {
            quietly replace esg_general_esg_score = esg_general_esg_score + ///
                (length(ESGreport) - length(subinstr(ESGreport, "`word'", "", .))) / length("`word'")
            local general_count = `general_count' + 1
        }
        gen esg_general_esg_coverage = (esg_general_esg_score > 0)
        
        * Calculate composite scores
        gen esg_total_score = esg_environmental_score + esg_social_score + esg_governance_score + esg_general_esg_score
        gen esg_vocabulary = esg_total_score
        
        * Calculate disclosure quality (avoid division by zero)
        gen text_length = length(ESGreport)
        replace text_length = 1 if text_length == 0
        gen esg_disclosure_quality = esg_total_score / (text_length / 1000)
        replace esg_disclosure_quality = 0 if missing(esg_disclosure_quality)
        drop text_length
        
        gen esg_diversity = esg_environmental_coverage + esg_social_coverage + esg_governance_coverage + esg_general_esg_coverage
        gen esg_completeness = (esg_diversity / 4) * 100
        
        * Display processing summary
        di "Keywords processed - Environmental: `env_count', Social: `social_count', Governance: `gov_count', General: `general_count'"
        
    }
    else if "`method'" == "cosine" {
        * Cosine Similarity Method
        di "Using Cosine Similarity method..."
        
        * Initialize all dimension scores first
        gen esg_environmental_score = 0
        gen esg_social_score = 0
        gen esg_governance_score = 0
        gen esg_general_esg_score = 0
        
        * Process environmental dimension
        local word_count : word count `env_words'
        if `word_count' > 0 {
            tempvar dot_product ref_norm doc_norm
            gen `dot_product' = 0
            gen `ref_norm' = sqrt(`word_count')
            gen `doc_norm' = 0
            
            * Calculate dot product and document norm
            foreach word in `env_words' {
                tempvar word_freq
                quietly gen `word_freq' = (length(ESGreport) - length(subinstr(ESGreport, "`word'", "", .))) / length("`word'")
                quietly replace `dot_product' = `dot_product' + `word_freq'
                quietly replace `doc_norm' = `doc_norm' + `word_freq' * `word_freq'
                drop `word_freq'
            }
            
            quietly replace `doc_norm' = sqrt(`doc_norm')
            quietly replace `doc_norm' = 1 if `doc_norm' == 0
            
            * Calculate cosine similarity for environmental dimension
            quietly replace esg_environmental_score = `dot_product' / (`ref_norm' * `doc_norm')
            quietly replace esg_environmental_score = 0 if missing(esg_environmental_score)
            
            drop `dot_product' `ref_norm' `doc_norm'
        }
        
        * Process social dimension
        local word_count : word count `social_words'
        if `word_count' > 0 {
            tempvar dot_product ref_norm doc_norm
            gen `dot_product' = 0
            gen `ref_norm' = sqrt(`word_count')
            gen `doc_norm' = 0
            
            foreach word in `social_words' {
                tempvar word_freq
                quietly gen `word_freq' = (length(ESGreport) - length(subinstr(ESGreport, "`word'", "", .))) / length("`word'")
                quietly replace `dot_product' = `dot_product' + `word_freq'
                quietly replace `doc_norm' = `doc_norm' + `word_freq' * `word_freq'
                drop `word_freq'
            }
            
            quietly replace `doc_norm' = sqrt(`doc_norm')
            quietly replace `doc_norm' = 1 if `doc_norm' == 0
            
            quietly replace esg_social_score = `dot_product' / (`ref_norm' * `doc_norm')
            quietly replace esg_social_score = 0 if missing(esg_social_score)
            
            drop `dot_product' `ref_norm' `doc_norm'
        }
        
        * Process governance dimension
        local word_count : word count `gov_words'
        if `word_count' > 0 {
            tempvar dot_product ref_norm doc_norm
            gen `dot_product' = 0
            gen `ref_norm' = sqrt(`word_count')
            gen `doc_norm' = 0
            
            foreach word in `gov_words' {
                tempvar word_freq
                quietly gen `word_freq' = (length(ESGreport) - length(subinstr(ESGreport, "`word'", "", .))) / length("`word'")
                quietly replace `dot_product' = `dot_product' + `word_freq'
                quietly replace `doc_norm' = `doc_norm' + `word_freq' * `word_freq'
                drop `word_freq'
            }
            
            quietly replace `doc_norm' = sqrt(`doc_norm')
            quietly replace `doc_norm' = 1 if `doc_norm' == 0
            
            quietly replace esg_governance_score = `dot_product' / (`ref_norm' * `doc_norm')
            quietly replace esg_governance_score = 0 if missing(esg_governance_score)
            
            drop `dot_product' `ref_norm' `doc_norm'
        }
        
        * Process general ESG dimension
        local word_count : word count `general_words'
        if `word_count' > 0 {
            tempvar dot_product ref_norm doc_norm
            gen `dot_product' = 0
            gen `ref_norm' = sqrt(`word_count')
            gen `doc_norm' = 0
            
            foreach word in `general_words' {
                tempvar word_freq
                quietly gen `word_freq' = (length(ESGreport) - length(subinstr(ESGreport, "`word'", "", .))) / length("`word'")
                quietly replace `dot_product' = `dot_product' + `word_freq'
                quietly replace `doc_norm' = `doc_norm' + `word_freq' * `word_freq'
                drop `word_freq'
            }
            
            quietly replace `doc_norm' = sqrt(`doc_norm')
            quietly replace `doc_norm' = 1 if `doc_norm' == 0
            
            quietly replace esg_general_esg_score = `dot_product' / (`ref_norm' * `doc_norm')
            quietly replace esg_general_esg_score = 0 if missing(esg_general_esg_score)
            
            drop `dot_product' `ref_norm' `doc_norm'
        }
        
        * Calculate overall score
        egen esg_total_score = rowmean(esg_environmental_score esg_social_score esg_governance_score esg_general_esg_score)
        replace esg_total_score = 0 if missing(esg_total_score)
        
        * Create method-specific variable
        gen esg_cosine_similarity = esg_total_score
        
        * Calculate composite scores
        gen esg_disclosure_quality = esg_total_score
        gen esg_diversity = (esg_environmental_score > 0) + (esg_social_score > 0) + (esg_governance_score > 0) + (esg_general_esg_score > 0)
        gen esg_completeness = (esg_diversity / 4) * 100
        
    }
    else if "`method'" == "jaccard" {
        * Jaccard Similarity Method
        di "Using Jaccard Similarity method..."
        
        * Initialize all dimension scores
        gen esg_environmental_score = 0
        gen esg_social_score = 0
        gen esg_governance_score = 0
        gen esg_general_esg_score = 0
        
        * Process environmental dimension
        local word_count : word count `env_words'
        if `word_count' > 0 {
            tempvar intersection union
            gen `intersection' = 0
            gen `union' = `word_count'
            
            * Calculate intersection
            foreach word in `env_words' {
                tempvar word_present
                quietly gen `word_present' = (strpos(ESGreport, "`word'") > 0)
                quietly replace `intersection' = `intersection' + `word_present'
                drop `word_present'
            }
            
            * Avoid division by zero
            quietly replace `union' = 1 if `union' == 0
            
            * Calculate Jaccard similarity
            quietly replace esg_environmental_score = `intersection' / `union'
            quietly replace esg_environmental_score = 0 if missing(esg_environmental_score)
            
            drop `intersection' `union'
        }
        
        * Process social dimension
        local word_count : word count `social_words'
        if `word_count' > 0 {
            tempvar intersection union
            gen `intersection' = 0
            gen `union' = `word_count'
            
            foreach word in `social_words' {
                tempvar word_present
                quietly gen `word_present' = (strpos(ESGreport, "`word'") > 0)
                quietly replace `intersection' = `intersection' + `word_present'
                drop `word_present'
            }
            
            quietly replace `union' = 1 if `union' == 0
            
            quietly replace esg_social_score = `intersection' / `union'
            quietly replace esg_social_score = 0 if missing(esg_social_score)
            
            drop `intersection' `union'
        }
        
        * Process governance dimension
        local word_count : word count `gov_words'
        if `word_count' > 0 {
            tempvar intersection union
            gen `intersection' = 0
            gen `union' = `word_count'
            
            foreach word in `gov_words' {
                tempvar word_present
                quietly gen `word_present' = (strpos(ESGreport, "`word'") > 0)
                quietly replace `intersection' = `intersection' + `word_present'
                drop `word_present'
            }
            
            quietly replace `union' = 1 if `union' == 0
            
            quietly replace esg_governance_score = `intersection' / `union'
            quietly replace esg_governance_score = 0 if missing(esg_governance_score)
            
            drop `intersection' `union'
        }
        
        * Process general ESG dimension
        local word_count : word count `general_words'
        if `word_count' > 0 {
            tempvar intersection union
            gen `intersection' = 0
            gen `union' = `word_count'
            
            foreach word in `general_words' {
                tempvar word_present
                quietly gen `word_present' = (strpos(ESGreport, "`word'") > 0)
                quietly replace `intersection' = `intersection' + `word_present'
                drop `word_present'
            }
            
            quietly replace `union' = 1 if `union' == 0
            
            quietly replace esg_general_esg_score = `intersection' / `union'
            quietly replace esg_general_esg_score = 0 if missing(esg_general_esg_score)
            
            drop `intersection' `union'
        }
        
        * Calculate overall score
        egen esg_total_score = rowmean(esg_environmental_score esg_social_score esg_governance_score esg_general_esg_score)
        replace esg_total_score = 0 if missing(esg_total_score)
        
        * Create method-specific variable
        gen esg_jaccard_similarity = esg_total_score
        
        * Calculate composite scores
        gen esg_disclosure_quality = esg_total_score
        gen esg_diversity = (esg_environmental_score > 0) + (esg_social_score > 0) + (esg_governance_score > 0) + (esg_general_esg_score > 0)
        gen esg_completeness = (esg_diversity / 4) * 100
        
    }
    else if "`method'" == "sentiment" {
        * Sentiment Analysis Method - FIXED
        di "Using Sentiment Analysis method..."
        
        * Count positive and negative words
        tempvar pos_count neg_count total_words raw_sentiment
        gen `pos_count' = 0
        gen `neg_count' = 0
        
        * Count positive words quietly
        local pos_processed = 0
        foreach word in `positive_words' {
            quietly replace `pos_count' = `pos_count' + (length(ESGreport) - length(subinstr(ESGreport, "`word'", "", .))) / length("`word'")
            local pos_processed = `pos_processed' + 1
        }
        
        * Count negative words quietly
        local neg_processed = 0
        foreach word in `negative_words' {
            quietly replace `neg_count' = `neg_count' + (length(ESGreport) - length(subinstr(ESGreport, "`word'", "", .))) / length("`word'")
            local neg_processed = `neg_processed' + 1
        }
        
        di "Sentiment words processed - Positive: `pos_processed', Negative: `neg_processed'"
        
        * Estimate total words
        if "`language'" == "cn" {
            gen `total_words' = length(ESGreport) / 1.5
        }
        else {
            gen `total_words' = length(ESGreport) - length(subinstr(ESGreport, " ", "", .)) + 1
        }
        replace `total_words' = 1 if `total_words' == 0
        
        * Calculate raw sentiment
        gen `raw_sentiment' = (`pos_count' - `neg_count') / `total_words'
        replace `raw_sentiment' = 0 if missing(`raw_sentiment')
        
        * Check if any sentiment words were found
        sum `pos_count' `neg_count'
        if r(max) == 0 {
            di "Warning: No sentiment words found. Please check if dictionary language matches text language."
            gen esg_total_score = 0.5
        }
        else {
            * Normalize to 0-1 range
            sum `raw_sentiment'
            if r(max) != r(min) & r(max) != . & r(min) != . {
                gen esg_total_score = (`raw_sentiment' - r(min)) / (r(max) - r(min))
            }
            else {
                gen esg_total_score = 0.5
            }
        }
        replace esg_total_score = 0 if missing(esg_total_score)
        
        * Set dimension scores
        gen esg_environmental_score = esg_total_score
        gen esg_social_score = esg_total_score
        gen esg_governance_score = esg_total_score
        gen esg_general_esg_score = esg_total_score
        
        * Calculate composite scores
        gen esg_disclosure_quality = esg_total_score
        gen esg_diversity = 4
        gen esg_completeness = 100
        
        drop `pos_count' `neg_count' `total_words' `raw_sentiment'
        
    }
    else if "`method'" == "complexity" {
        * Text Complexity Analysis Method
        di "Using Text Complexity Analysis method..."
        
        tempvar word_count sentence_count char_count avg_sent_len lex_div complexity_raw
        
        if "`language'" == "cn" {
            * Chinese complexity measures
            gen `word_count' = length(ESGreport) / 1.5
            replace `word_count' = 1 if `word_count' == 0
            gen `char_count' = length(ESGreport)
            replace `char_count' = 1 if `char_count' == 0
            
            * Sentence count using Chinese delimiters
            gen `sentence_count' = (length(ESGreport) - length(subinstr(ESGreport, "。", "", .)) + ///
                                   length(ESGreport) - length(subinstr(ESGreport, "！", "", .)) + ///
                                   length(ESGreport) - length(subinstr(ESGreport, "？", "", .)))
            replace `sentence_count' = 1 if `sentence_count' == 0
            
            * Average sentence length
            gen `avg_sent_len' = `word_count' / `sentence_count'
            
            * Simplified lexical diversity (character diversity)
            tempvar unique_chars
            gen `unique_chars' = 0
            local max_chars = min(50, length(ESGreport[1]))
            forval i = 1/`max_chars' {
                tempvar char
                gen `char' = substr(ESGreport, `i', 1) if length(ESGreport) >= `i'
                replace `unique_chars' = `unique_chars' + 1 if `char' != "" & `i' == 1
                drop `char'
            }
            gen `lex_div' = `unique_chars' / `char_count'
            replace `lex_div' = 0 if missing(`lex_div')
            
            * Composite complexity score
            gen `complexity_raw' = (`avg_sent_len' + `lex_div' * 100) / 2
            
            drop `unique_chars'
        }
        else {
            * English complexity measures
            gen `word_count' = length(ESGreport) - length(subinstr(ESGreport, " ", "", .)) + 1
            replace `word_count' = 1 if `word_count' == 0
            gen `char_count' = length(ESGreport)
            replace `char_count' = 1 if `char_count' == 0
            
            * Sentence count
            gen `sentence_count' = (length(ESGreport) - length(subinstr(ESGreport, ".", "", .)) + ///
                                   length(ESGreport) - length(subinstr(ESGreport, "!", "", .)) + ///
                                   length(ESGreport) - length(subinstr(ESGreport, "?", "", .)))
            replace `sentence_count' = 1 if `sentence_count' == 0
            
            * Average sentence length
            gen `avg_sent_len' = `word_count' / `sentence_count'
            
            * Average word length
            tempvar avg_word_len
            gen `avg_word_len' = (`char_count' - (length(ESGreport) - length(subinstr(ESGreport, " ", "", .)))) / `word_count'
            replace `avg_word_len' = 0 if missing(`avg_word_len')
            
            * Simplified lexical diversity
            gen `lex_div' = `word_count' / `char_count' * 2
            replace `lex_div' = 0 if missing(`lex_div')
            
            * Composite complexity score
            gen `complexity_raw' = (`avg_sent_len' + `avg_word_len' + `lex_div') / 3
            
            drop `avg_word_len'
        }
        
        * Normalize complexity score
        sum `complexity_raw'
        if r(max) != r(min) & r(max) != . & r(min) != . {
            gen esg_total_score = (`complexity_raw' - r(min)) / (r(max) - r(min))
        }
        else {
            gen esg_total_score = 0.5
        }
        replace esg_total_score = 0 if missing(esg_total_score)
        
        * Set dimension scores
        gen esg_environmental_score = esg_total_score
        gen esg_social_score = esg_total_score
        gen esg_governance_score = esg_total_score
        gen esg_general_esg_score = esg_total_score
        
        * Calculate composite scores
        gen esg_disclosure_quality = esg_total_score
        gen esg_diversity = 4
        gen esg_completeness = 100
        
        drop `word_count' `sentence_count' `char_count' `avg_sent_len' `lex_div' `complexity_raw'
        
    }
    else if "`method'" == "readability" {
        * Text Readability Analysis Method
        di "Using Text Readability Analysis method..."
        
        * Use permanent variables instead of tempvar to avoid issues
        gen _qta_word_count = .
        gen _qta_sentence_count = .
        gen _qta_syllable_count = .
        gen _qta_readability_raw = .
        
        if "`language'" == "cn" {
            * Chinese readability
            replace _qta_word_count = length(ESGreport) / 1.5
            replace _qta_word_count = 1 if _qta_word_count == 0
            
            * Sentence count using Chinese delimiters
            replace _qta_sentence_count = (length(ESGreport) - length(subinstr(ESGreport, "。", "", .)) + ///
                                   length(ESGreport) - length(subinstr(ESGreport, "！", "", .)) + ///
                                   length(ESGreport) - length(subinstr(ESGreport, "？", "", .)))
            replace _qta_sentence_count = 1 if _qta_sentence_count == 0
            
            * Chinese readability formula (simplified)
            replace _qta_readability_raw = 206.835 - 1.015 * (_qta_word_count / _qta_sentence_count) - 84.6 * (length(ESGreport) / _qta_word_count)
        }
        else {
            * English readability (Flesch)
            replace _qta_word_count = length(ESGreport) - length(subinstr(ESGreport, " ", "", .)) + 1
            replace _qta_word_count = 1 if _qta_word_count == 0
            
            replace _qta_sentence_count = (length(ESGreport) - length(subinstr(ESGreport, ".", "", .)) + ///
                                   length(ESGreport) - length(subinstr(ESGreport, "!", "", .)) + ///
                                   length(ESGreport) - length(subinstr(ESGreport, "?", "", .)))
            replace _qta_sentence_count = 1 if _qta_sentence_count == 0
            
            * Syllable estimation
            replace _qta_syllable_count = _qta_word_count * 1.5
            
            * Flesch Reading Ease
            replace _qta_readability_raw = 206.835 - 1.015 * (_qta_word_count / _qta_sentence_count) - 84.6 * (_qta_syllable_count / _qta_word_count)
        }
        
        * Normalize readability score (higher = more readable)
        sum _qta_readability_raw
        if r(max) != r(min) & r(max) != . & r(min) != . {
            gen esg_total_score = (_qta_readability_raw - r(min)) / (r(max) - r(min))
        }
        else {
            gen esg_total_score = 0.5
        }
        
        * For both languages, ensure higher score = more readable
        replace esg_total_score = 0 if missing(esg_total_score)
        
        * Set dimension scores
        gen esg_environmental_score = esg_total_score
        gen esg_social_score = esg_total_score
        gen esg_governance_score = esg_total_score
        gen esg_general_esg_score = esg_total_score
        
        * Calculate composite scores
        gen esg_disclosure_quality = esg_total_score
        gen esg_diversity = 4
        gen esg_completeness = 100
        
        * Clean up temporary variables
        drop _qta_word_count _qta_sentence_count _qta_syllable_count _qta_readability_raw
        
    }
    
    * Label variables with language and method info
    local dict_source = cond("`esgdictionary'" != "" | "`sentdictionary'" != "", "external", "built-in")
    label variable esg_environmental_score "Environmental dimension score (`method' - `language' - `dict_source')"
    label variable esg_social_score "Social dimension score (`method' - `language' - `dict_source')"
    label variable esg_governance_score "Governance dimension score (`method' - `language' - `dict_source')"
    label variable esg_general_esg_score "General ESG score (`method' - `language' - `dict_source')"
    label variable esg_total_score "Total ESG disclosure score (`method' - `language' - `dict_source')"
    label variable esg_disclosure_quality "ESG disclosure quality index (`method' - `language' - `dict_source')"
    label variable esg_diversity "ESG disclosure diversity (`method' - `language' - `dict_source')"
    label variable esg_completeness "ESG disclosure completeness (`method' - `language' - `dict_source')"
    
    * Method-specific variable labels
    if "`method'" == "cosine" {
        label variable esg_cosine_similarity "Cosine similarity score (`language' - `dict_source')"
    }
    else if "`method'" == "jaccard" {
        label variable esg_jaccard_similarity "Jaccard similarity score (`language' - `dict_source')"
    }
    
    * Save statistics if requested
    if "`savestats'" != "" {
        preserve
        collapse (mean) esg_total_score esg_disclosure_quality esg_diversity esg_completeness ///
                 (sd) esg_score_sd = esg_total_score ///
                 (count) n_years = esg_total_score, by(stkcd)
        egen esg_score_rank = rank(esg_total_score)
        
        local savefile = cond("`savestats'" == "1", "ESG_statistics.dta", "`savestats'")
        
        cap confirm file "`savefile'"
        if _rc == 0 & "`replace'" == "" {
            di as error "File `savefile' already exists."
            di as error "Use the {bf:replace} option to overwrite the existing file:"
            di as error `"  . qta, save(`savestats') replace"' 
            di as error "or use a different filename."
            restore
            exit 602
        }
        
        if "`replace'" != "" {
            save "`savefile'", replace
            di "ESG statistics saved to `savefile' (replace)"
        }
        else {
            save "`savefile'"
            di "ESG statistics saved to `savefile'"
        }
        restore
    }
    
    * Display results
    di _n "Quantitative Text Analysis Results:"
    di "Method used: `method'"
    di "Language used: `language'"
    di "Dictionary source: `dict_source'"
    if "`esgdictionary'" != "" di "ESG dictionary: `esgdictionary'"
    if "`sentdictionary'" != "" di "Sentiment dictionary: `sentdictionary'"
    
    * Clean summary output
    quietly capture confirm variable esg_total_score esg_disclosure_quality esg_diversity
    if _rc == 0 {
        summarize esg_total_score esg_disclosure_quality esg_diversity
    }
    
    di "QTA analysis completed successfully!"
end