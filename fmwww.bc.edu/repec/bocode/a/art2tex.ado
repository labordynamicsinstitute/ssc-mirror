*! version 2.4 art2tex.ado
*! Authors: Wu Lianghai, Chen Liwen, Hu Fangfang et al.

program define art2tex
    version 16
    syntax [, LANGuage(string) filename(string) Title(string) Author(string)]
    
    // Default settings
    if "`language'" == "" local language "chinese"
    if "`filename'" == "" local filename "paper"
    if `"`title'"' == "" {
        if "`language'" == "chinese" {
            local title "论文标题"
        }
        else {
            local title "Paper Title"
        }
    }
    if `"`author'"' == "" {
        if "`language'" == "chinese" {
            local author "作者姓名"
        }
        else {
            local author "Author Name"
        }
    }
    
    // Handle file extension
    if !strpos("`filename'", ".tex") local filename "`filename'.tex"
    
    // Process author name format
    local author = ustrtrim(`"`author'"')
    local author = subinstr(`"`author'"', ";", ",", .)
    local author = subinstr(`"`author'"', ",", " ", .)
    local author = stritrim(`"`author'"')
    
    // Create LaTeX file
    tempname fh
    quietly file open `fh' using "`filename'", write text replace
    
    // LaTeX preamble
    file write `fh' `"%!TEX program = xelatex"' _n
    if "`language'" == "chinese" {
        file write `fh' `"\documentclass[12pt,a4paper]{ctexart}"' _n
    }
    else {
        file write `fh' `"\documentclass[12pt,a4paper]{article}"' _n
    }
    file write `fh' `"\usepackage{geometry}"' _n
    file write `fh' `"\geometry{a4paper,left=25mm,right=25mm,top=25mm,bottom=25mm}"' _n
    file write `fh' `"\usepackage{booktabs}"' _n
    file write `fh' `"\usepackage{longtable}"' _n
    file write `fh' `"\usepackage{array}"' _n
    file write `fh' `"\usepackage{threeparttable}"' _n
    file write `fh' `"\usepackage{pdflscape}"' _n
    file write `fh' `"\usepackage{multirow}"' _n
    file write `fh' `"\usepackage{dcolumn}"' _n
    file write `fh' `"\newcolumntype{d}[1]{D{.}{.}{#1}}"' _n
    file write `fh' `"\usepackage{graphicx}"' _n
    file write `fh' `"\usepackage{amsmath}"' _n
    file write `fh' `"\usepackage{amssymb}"' _n
    file write `fh' `"\usepackage[round]{natbib}"' _n 
    file write `fh' `"\bibliographystyle{plainnat}"' _n  
    
    file write `fh' `"\usepackage{hyperref}"' _n
    file write `fh' `"\hypersetup{colorlinks=true, linkcolor=blue, citecolor=red}"' _n
    file write `fh' `"\renewcommand{\arraystretch}{1.2}"' _n
    
    file write `fh' `"\title{`title'}"' _n
    file write `fh' `"\author{`author'}"' _n
    file write `fh' `"\date{\today}"' _n
    file write `fh' _n
    file write `fh' `"\begin{document}"' _n
    file write `fh' `"\maketitle"' _n
    file write `fh' _n
    
    // Abstract and keywords
    file write `fh' `"\begin{abstract}"' _n
    if "`language'" == "chinese" {
        file write `fh' `"请在此处粘贴摘要内容"' _n
        file write `fh' `"\end{abstract}"' _n
        file write `fh' `"\noindent\textbf{关键词：} ESG表现，高管变更，股价崩盘风险，双碳目标，公司治理"' _n _n
    }
    else {
        file write `fh' `"Please paste your abstract content here."' _n
        file write `fh' `"\end{abstract}"' _n
        file write `fh' `"\noindent\textbf{Keywords:} ESG performance, executive turnover, stock price crash risk, dual carbon goals, corporate governance"' _n _n
    }
    
    // Document structure - different for Chinese and English
    if "`language'" == "chinese" {
        local sections "引言 文献综述 理论分析与研究假设 研究设计 实证检验 结论建议"
    }
    else {
        local sections "Introduction LiteratureReview TheoreticalAnalysisAndHypotheses ResearchDesign EmpiricalAnalysis Conclusion"
    }
    
    foreach section in `sections' {
        file write `fh' `"\section{`section'}"' _n
        
        // Special handling for empirical section
        if ("`section'" == "实证检验" | "`section'" == "EmpiricalAnalysis") {
            if "`language'" == "chinese" {
                local subsections "主检验 稳健性检验 异质性检验"
            }
            else {
                local subsections "MainResults Robustness Heterogeneity"
            }
            
            foreach subsec in `subsections' {
                file write `fh' `"\subsection{`subsec'}"' _n
                
                if "`language'" == "chinese" {
                    file write `fh' `"请在此处粘贴`subsec'的文本描述"' _n
                }
                else {
                    file write `fh' `"Please paste your `subsec' content here."' _n
                }
                
                // Table placeholder
                if ("`subsec'" == "主检验" | "`subsec'" == "MainResults") {
                    file write `fh' `"\input{tables/descriptive_stats}"' _n
                    file write `fh' `"\input{tables/correlation_matrix}"' _n
                    file write `fh' `"\input{tables/main_regression}"' _n _n
                    
                    // Add mediating effect test
                    if "`language'" == "chinese" {
                        file write `fh' `"\subsection{中介效应检验}"' _n
                        file write `fh' `"请在此处粘贴中介效应检验的文本描述"' _n
                    }
                    else {
                        file write `fh' `"\subsection{Mediation Analysis}"' _n
                        file write `fh' `"Please paste your mediation analysis content here."' _n
                    }
                    file write `fh' `"\input{tables/mediating_effect1}"' _n
                    file write `fh' `"\input{tables/mediating_effect2}"' _n _n
                }
                else {
                    if "`language'" == "chinese" {
                        local tabname = subinstr("`subsec'", "检验", "", .)
                    }
                    else {
                        local tabname = "`subsec'"
                    }
                    file write `fh' `"\input{tables/`tabname'_results}"' _n _n
                }
                
                // Add figure insertion for robustness checks
                if ("`subsec'" == "稳健性检验" | "`subsec'" == "Robustness") {
                    file write `fh' `"\begin{figure}[htbp]"' _n
                    file write `fh' `"\centering"' _n
                    file write `fh' `"\includegraphics[width=0.8\textwidth]{figures/robustness_check}"' _n
                    if "`language'" == "chinese" {
                        file write `fh' `"\caption{稳健性检验结果图示}"' _n
                        file write `fh' `"\label{fig:robustness}"' _n
                    }
                    else {
                        file write `fh' `"\caption{Robustness check results}"' _n
                        file write `fh' `"\label{fig:robustness}"' _n
                    }
                    file write `fh' `"\end{figure}"' _n _n
                }
            }
        }
        // Enhanced research design section
        else if ("`section'" == "研究设计" | "`section'" == "ResearchDesign") {
            if "`language'" == "chinese" {
                file write `fh' `"请在此处粘贴研究设计部分的文本描述。"' _n
                file write `fh' `"可以使用\textbackslash citet命令引用参考文献，例如：\citet{liu2023env}。"' _n _n
                
                // 变量定义表
                file write `fh' `"\subsection{变量定义}"' _n
                file write `fh' `"\begin{table}[htbp]"' _n
                file write `fh' `"\centering"' _n
                file write `fh' `"\caption{变量定义表}"' _n
                file write `fh' `"\label{tab:variable_def}"' _n
                file write `fh' `"\begin{threeparttable}"' _n
                file write `fh' `"\begin{tabular}{llll}"' _n
                file write `fh' `"\toprule"' _n
                file write `fh' `"变量类型 & 变量名称 & 变量符号 & 变量定义 \\\\"' _n
                file write `fh' `"\midrule"' _n
                file write `fh' `"被解释变量 & 环保投资 & EnvInv & 企业环保投资金额（万元） \\\\"' _n
                file write `fh' `"解释变量 & 高管变更 & CEOChange & 1=发生高管变更，0=未变更 \\\\"' _n
                file write `fh' `"调节变量 & 现金持有 & CashHold & 现金及现金等价物/总资产 \\\\"' _n
                file write `fh' `"中介变量 & 绿色创新 & GreenInnov & 绿色专利申请数量（项） \\\\"' _n
                file write `fh' `"中介变量 & 环境管理 & EnvMgmt & 环境管理体系认证得分 \\\\"' _n
                file write `fh' `"\midrule"' _n
                file write `fh' `"\multirow{10}{*}{控制变量} & 企业规模 & Size & 总资产的自然对数 \\\\"' _n
                file write `fh' `" & 资产负债率 & Lev & 总负债/总资产 \\\\"' _n
                file write `fh' `" & 盈利能力 & ROA & 净利润/总资产 \\\\"' _n
                file write `fh' `" & 成长性 & Growth & 营业收入增长率 \\\\"' _n
                file write `fh' `" & 股权集中度 & Top1 & 第一大股东持股比例 \\\\"' _n
                file write `fh' `" & 董事会规模 & BoardSize & 董事会人数 \\\\"' _n
                file write `fh' `" & 独立董事比例 & Indep & 独立董事占比 \\//"' _n
                file write `fh' `" & 两职合一 & Dual & CEO与董事长是否兼任 \\//"' _n
                file write `fh' `" & 行业固定效应 & Industry & 行业虚拟变量 \\//"' _n
                file write `fh' `" & 年度固定效应 & Year & 年度虚拟变量 \\//"' _n
                file write `fh' `"\bottomrule"' _n
                file write `fh' `"\end{tabular}"' _n
                file write `fh' `"\begin{tablenotes}"' _n
                file write `fh' `"\small"' _n
                file write `fh' `"\item 注：变量定义详见\citet{wang2022green}。"' _n
                file write `fh' `"\end{tablenotes}"' _n
                file write `fh' `"\end{threeparttable}"' _n
                file write `fh' `"\end{table}"' _n _n
                
                // 数学模型
                file write `fh' `"\subsection{实证模型}"' _n
                file write `fh' `"基准回归模型如下所示："' _n
                file write `fh' `"\begin{align}"' _n
                file write `fh' `"    \text{EnvInv}_{it} &= \beta_0 + \beta_1 \text{CEOChange}_{it} + \beta_2 \text{CashHold}_{it} \\\\"' _n
                file write `fh' `"    & \quad + \beta_3 (\text{CEOChange} \times \text{CashHold})_{it} + \gamma \mathbf{X}_{it} \\//"' _n
                file write `fh' `"    & \quad + \mu_i + \lambda_t + \varepsilon_{it}"' _n
                file write `fh' `"\end{align}"' _n
                file write `fh' `"其中，$\mathbf{X}_{it}$，控制变量向量"' _n
                file write `fh' `"$\mu_i$, 个体固定效应"' _n
                file write `fh' `"$\lambda_t$, 时间固定效应"' _n _n
            }
            else {
                file write `fh' `"Please paste your research design content here."' _n
                file write `fh' `"You can use \textbackslash citet command to cite references, e.g., \citet{liu2023env}."' _n _n
                
                // Variable definition table
                file write `fh' `"\subsection{Variable Definitions}"' _n
                file write `fh' `"\begin{table}[htbp]"' _n
                file write `fh' `"\centering"' _n
                file write `fh' `"\caption{Variable Definitions}"' _n
                file write `fh' `"\label{tab:variable_def}"' _n
                file write `fh' `"\begin{threeparttable}"' _n
                file write `fh' `"\begin{tabular}{llll}"' _n
                file write `fh' `"\toprule"' _n
                file write `fh' `"Variable Type & Variable Name & Symbol & Definition \\//"' _n
                file write `fh' `"\midrule"' _n
                file write `fh' `"Dependent Variable & Environmental Investment & EnvInv & Corporate environmental investment (10K RMB) \\//"' _n
                file write `fh' `"Independent Variable & CEO Change & CEOChange & 1=CEO changed, 0=otherwise \\//"' _n
                file write `fh' `"Moderator & Cash Holdings & CashHold & Cash and equivalents/Total assets \\//"' _n
                file write `fh' `"Mediator & Green Innovation & GreenInnov & Number of green patent applications \\//"' _n
                file write `fh' `"Mediator & Environmental Management & EnvMgmt & Environmental management system certification score \\//"' _n
                file write `fh' `"\midrule"' _n
                file write `fh' `"\multirow{10}{*}{Control Variables} & Firm Size & Size & Natural logarithm of total assets \\//"' _n
                file write `fh' `" & Leverage & Lev & Total debt/Total assets \\//"' _n
                file write `fh' `" & Profitability & ROA & Net income/Total assets \\//"' _n
                file write `fh' `" & Growth & Growth & Revenue growth rate \\//"' _n
                file write `fh' `" & Ownership Concentration & Top1 & Shareholding ratio of the largest shareholder \\//"' _n
                file write `fh' `" & Board Size & BoardSize & Number of board members \\//"' _n
                file write `fh' `" & Independent Director Ratio & Indep & Proportion of independent directors \\//"' _n
                file write `fh' `" & CEO Duality & Dual & Whether CEO also serves as chairman \\//"' _n
                file write `fh' `" & Industry Fixed Effects & Industry & Industry dummy variables \\//"' _n
                file write `fh' `" & Year Fixed Effects & Year & Year dummy variables \\//"' _n
                file write `fh' `"\bottomrule"' _n
                file write `fh' `"\end{tabular}"' _n
                file write `fh' `"\begin{tablenotes}"' _n
                file write `fh' `"\small"' _n
                file write `fh' `"\item Note: Variable definitions follow \citet{wang2022green}."' _n
                file write `fh' `"\end{tablenotes}"' _n
                file write `fh' `"\end{threeparttable}"' _n
                file write `fh' `"\end{table}"' _n _n
                
                // Econometric model
                file write `fh' `"\subsection{Empirical Model}"' _n
                file write `fh' `"The baseline regression model is specified as follows:"' _n
                file write `fh' `"\begin{align}"' _n
                file write `fh' `"    \text{EnvInv}_{it} &= \beta_0 + \beta_1 \text{CEOChange}_{it} + \beta_2 \text{CashHold}_{it} \\//"' _n
                file write `fh' `"    & \quad + \beta_3 (\text{CEOChange} \times \text{CashHold})_{it} + \gamma \mathbf{X}_{it} \\//"' _n
                file write `fh' `"    & \quad + \mu_i + \lambda_t + \varepsilon_{it}"' _n
                file write `fh' `"\end{align}"' _n
                file write `fh' `"where $\mathbf{X}_{it}$ is a vector of control variables,"' _n
                file write `fh' `"$\mu_i$ represents firm fixed effects,"' _n
                file write `fh' `"and $\lambda_t$ represents year fixed effects."' _n _n
            }
        }
        // Add figure insertion for introduction section
        else if ("`section'" == "引言" | "`section'" == "Introduction") {
            if "`language'" == "chinese" {
                file write `fh' `"请在此处粘贴引言部分内容"' _n _n
                
                file write `fh' `"\begin{figure}[htbp]"' _n
                file write `fh' `"\centering"' _n
                file write `fh' `"\includegraphics[width=0.8\textwidth]{figures/research_background}"' _n
                file write `fh' `"\caption{研究背景图示}"' _n
                file write `fh' `"\label{fig:intro_bg}"' _n
                file write `fh' `"\end{figure}"' _n _n
            }
            else {
                file write `fh' `"Please paste your introduction content here."' _n _n
                
                file write `fh' `"\begin{figure}[htbp]"' _n
                file write `fh' `"\centering"' _n
                file write `fh' `"\includegraphics[width=0.8\textwidth]{figures/research_background}"' _n
                file write `fh' `"\caption{Research background illustration}"' _n
                file write `fh' `"\label{fig:intro_bg}"' _n
                file write `fh' `"\end{figure}"' _n _n
            }
        }
        // Add figure insertion for theoretical analysis section
        else if ("`section'" == "理论分析与研究假设" | "`section'" == "TheoreticalAnalysisAndHypotheses") {
            if "`language'" == "chinese" {
                file write `fh' `"请在此处粘贴理论分析与研究假设部分内容"' _n _n
                
                file write `fh' `"\begin{figure}[htbp]"' _n
                file write `fh' `"\centering"' _n
                file write `fh' `"\includegraphics[width=0.8\textwidth]{figures/theoretical_framework}"' _n
                file write `fh' `"\caption{理论框架图示}"' _n
                file write `fh' `"\label{fig:theoretical_framework}"' _n
                file write `fh' `"\end{figure}"' _n _n
            }
            else {
                file write `fh' `"Please paste your theoretical analysis and hypotheses content here."' _n _n
                
                file write `fh' `"\begin{figure}[htbp]"' _n
                file write `fh' `"\centering"' _n
                file write `fh' `"\includegraphics[width=0.8\textwidth]{figures/theoretical_framework}"' _n
                file write `fh' `"\caption{Theoretical framework illustration}"' _n
                file write `fh' `"\label{fig:theoretical_framework}"' _n
                file write `fh' `"\end{figure}"' _n _n
            }
        }
        // Regular sections
        else {
            if "`language'" == "chinese" {
                file write `fh' `"请在此处粘贴`section'部分内容"' _n _n
            }
            else {
                file write `fh' `"Please paste your `section' content here."' _n _n
            }
        }
    }
    
    file write `fh' `"\clearpage"'_n  
    file write `fh' `"\bibliography{references}"' _n _n
    
    // End document
    file write `fh' `"\end{document}"' _n
    file close `fh'
    
    // Create necessary directories
    capture mkdir tables
    capture mkdir figures
    
    // Create example references file
    quietly {
        file open ref using "references.bib", write text replace
        file write ref `"@article{liu2023env,"' _n
        file write ref `"  title = {Environmental investment and corporate governance},"' _n
        file write ref `"  author = {Liu, X. and Zhang, Y.},"' _n
        file write ref `"  journal = {Journal of Environmental Economics},"' _n
        file write ref `"  volume = {45},"' _n
        file write ref `"  pages = {112-125},"' _n
        file write ref `"  year = {2023}"' _n
        file write ref `"}"' _n _n
        
        file write ref `"@article{wang2022green,"' _n
        file write ref `"  title = {Green innovation and corporate cash holdings},"' _n
        file write ref `"  author = {Wang, M. and Chen, L.},"' _n
        file write ref `"  journal = {Sustainability},"' _n
        file write ref `"  volume = {14},"' _n
        file write ref `"  number = {8},"' _n
        file write ref `"  pages = {45-67},"' _n
        file write ref `"  year = {2022}"' _n
        file write ref `"}"' _n
        file close ref
    }
    
    // Display messages based on language
    if "`language'" == "chinese" {
        di as text _n "LaTeX框架已生成至: `filename'"
        di as text "表格目录已创建: tables/"
        di as text "图形目录已创建: figures/"
        di as text "示例BibTeX文件已创建: references.bib"
        di as text _n "请执行以下步骤:"
        di as text "1. 将Word文档内容粘贴到相应章节"
        di as text "2. 将Stata输出表格保存到tables/文件夹"
        di as text "3. 将Stata生成图形保存到figures/文件夹"
        di as text "4. 以BibTeX格式添加参考文献到references.bib"
        di as text "5. 使用以下顺序编译: xelatex -> bibtex -> xelatex -> xelatex"
        di as text "   (注意：必须运行bibtex编译参考文献)"
        
        di as text _n "表格命令模板已生成: generate_tables.do"
        di as text "图形命令模板已生成: generate_figures.do"
        di as text "章节标题使用默认对齐方式"
        di as text "使用\citet{key}进行文本引用"
        di as text "编译顺序: xelatex -> bibtex -> xelatex -> xelatex"
        di as text "   (特别注意：必须运行bibtex编译参考文献)"
    }
    else {
        di as text _n "LaTeX framework generated to: `filename'"
        di as text "Tables directory created: tables/"
        di as text "Figures directory created: figures/"
        di as text "Example BibTeX file created: references.bib"
        di as text _n "Please perform the following steps:"
        di as text "1. Paste Word document content into corresponding sections"
        di as text "2. Save Stata output tables to tables/ folder"
        di as text "3. Save Stata generated figures to figures/ folder"
        di as text "4. Add references to references.bib in BibTeX format"
        di as text "5. Compile using: xelatex -> bibtex -> xelatex -> xelatex"
        di as text "   (Note: bibtex is essential for reference compilation)"
        
        di as text _n "Table command template generated: generate_tables.do"
        di as text "Figure command template generated: generate_figures.do"
        di as text "Section headings are now using default alignment"
        di as text "Use \citet{key} for citations in text"
        di as text "Compile sequence: xelatex -> bibtex -> xelatex -> xelatex"
        di as text "   (Important: must run bibtex for reference compilation)"
    }
    
    // Generate example table commands
    quietly {
        file open tabcmd using "generate_tables.do", write text replace
        if "`language'" == "chinese" {
            file write tabcmd `"* 变量定义表"' _n
            file write tabcmd `"* 注意：请在LaTeX中手动创建变量定义表"' _n _n
        }
        else {
            file write tabcmd `"* Variable definition table"' _n
            file write tabcmd `"* Note: Manually create variable definition table in LaTeX"' _n _n
        }
        
        if "`language'" == "chinese" {
            file write tabcmd `"* 相关性矩阵"' _n
        }
        else {
            file write tabcmd `"* Correlation matrix"' _n
        }
        file write tabcmd `"estpost correlate EnvInv CEOChange CashHold Size Lev ROA, matrix listwise"' _n
        file write tabcmd `"esttab . using tables/correlation_matrix.tex, replace unstack not noobs compress"' _n _n
        
        if "`language'" == "chinese" {
            file write tabcmd `"* 主回归结果"' _n
        }
        else {
            file write tabcmd `"* Main regression results"' _n
        }
        file write tabcmd `"reg EnvInv CEOChange CashHold c.CEOChange#c.CashHold Size Lev ROA, robust"' _n
        file write tabcmd `"est store m1"' _n
        file write tabcmd `"esttab m1 using tables/main_regression.tex, replace b(3) t(3) star(* 0.1 ** 0.05 *** 0.01) "' _n
        file write tabcmd `"    booktabs label nogap compress"' _n _n
        
        file close tabcmd
    }
    
    // Generate example figure commands
    quietly {
        file open figcmd using "generate_figures.do", write text replace
        if "`language'" == "chinese" {
            file write figcmd `"* 研究背景图示"' _n
        }
        else {
            file write figcmd `"* Research background illustration"' _n
        }
        file write figcmd `"twoway (scatter yvar xvar), title("Research Background")"' _n
        file write figcmd `"graph export figures/research_background.png, replace width(2000)"' _n _n
        
        if "`language'" == "chinese" {
            file write figcmd `"* 理论框架图示"' _n
        }
        else {
            file write figcmd `"* Theoretical framework illustration"' _n
        }
        file write figcmd `"twoway (scatter yvar xvar), title("Theoretical Framework")"' _n
        file write figcmd `"graph export figures/theoretical_framework.png, replace width(2000)"' _n _n
        
        if "`language'" == "chinese" {
            file write figcmd `"* 稳健性检验结果图示"' _n
        }
        else {
            file write figcmd `"* Robustness check results"' _n
        }
        file write figcmd `"twoway (scatter yvar xvar), title("Robustness Check")"' _n
        file write figcmd `"graph export figures/robustness_check.png, replace width(2000)"' _n _n
        
        file close figcmd
    }
end