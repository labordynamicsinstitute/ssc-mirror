*! case2tex v1.7.4 19Oct2025
*! Authors: Wu Lianghai, Chen Liwen, Zhao Xin, Liu Rui, Wu Hanyan
*! School of Business, Anhui University of Technology(AHUT)
*! School of Economics and Management, Nanjing University of Aeronautics and Astronautics(NUAA)
*! Ma'anshan/Nanjing, China
*! Emails: agd2010@yeah.net, 2184844526@qq.com, 1980124145@qq.com, 3221241855@qq.com, 2325476320@qq.com

program define case2tex
    version 18.0
    syntax [, Language(str) Filename(str) Replace Title(str) Author(str) ///
              ABStractalign(str) Keywordseparator(str) FONT(str) FONTSize(str) LINEspacing(str)]
    
    * Set default values
    if "`language'" == "" local language "chinese"
    if "`filename'" == "" local filename "case_study_template"
    if "`title'" == "" {
        if "`language'" == "chinese" local title "案例研究标题"
        else local title "Case Study Title"
    }
    if "`author'" == "" {
        if "`language'" == "chinese" local author "作者姓名"
        else local author "Author Name"
    }
    if "`abstractalign'" == "" local abstractalign "indent"
    if "`keywordseparator'" == "" local keywordseparator "comma"
    if "`font'" == "" local font "Times New Roman"
    if "`fontsize'" == "" local fontsize "12pt"
    if "`linespacing'" == "" local linespacing "1.5"
    
	// Check if file exists and handle replace option
    capture confirm file "`filename'"
    if _rc == 0 & "`replace'" == "" {
        di as error "File `filename' already exists. Use replace option to overwrite."
        exit 602
    }
	
    * Create subdirectories
    capture mkdir figures
    capture mkdir tables
    
    * Create .tex file
    tempname texfile
    file open `texfile' using "`filename'.tex", write replace
    
    * Write LaTeX preamble
    file write `texfile' "\documentclass[`fontsize']{article}" _n
    file write `texfile' "\usepackage[utf8]{inputenc}" _n
    file write `texfile' "\usepackage{fontspec}" _n
    if "`language'" == "chinese" {
        file write `texfile' "\usepackage{xeCJK}" _n
        file write `texfile' "\setCJKmainfont{SimSun}" _n
    }
    file write `texfile' "\usepackage{setspace}" _n
    file write `texfile' "\usepackage{graphicx}" _n
    file write `texfile' "\usepackage{amsmath}" _n
    file write `texfile' "\usepackage{booktabs}" _n
    file write `texfile' "\usepackage{caption}" _n
    file write `texfile' "\usepackage{float}" _n
    file write `texfile' "\usepackage{natbib}" _n
    file write `texfile' "\usepackage{comment}" _n
    file write `texfile' "\setmainfont{`font'}" _n
    file write `texfile' "\linespread{`linespacing'}" _n
    file write `texfile' _n
    file write `texfile' "\title{`title'}" _n
    file write `texfile' "\author{`author'}" _n
    file write `texfile' "\date{\today}" _n
    file write `texfile' _n
    file write `texfile' "\begin{document}" _n
    file write `texfile' _n
    file write `texfile' "\maketitle" _n
    file write `texfile' _n
    
    * Compilation instructions
    if "`language'" == "chinese" {
        file write `texfile' "% 编译顺序: XeLaTeX -> BibTeX -> XeLaTeX -> XeLaTeX" _n
        file write `texfile' "% 注意: 编译前请确保figures目录下存在所需的图片文件" _n
        file write `texfile' "% 提示: 可以使用comment环境添加多行注释，例如：" _n
        file write `texfile' "% \begin{comment}" _n
        file write `texfile' "% 这里是被注释的内容" _n
        file write `texfile' "% 不会出现在最终文档中" _n
        file write `texfile' "% \end{comment}" _n
    }
    else {
        file write `texfile' "% Compilation sequence: XeLaTeX -> BibTeX -> XeLaTeX -> XeLaTeX" _n
        file write `texfile' "% Note: Make sure the required image files exist in the figures directory before compilation" _n
        file write `texfile' "% Tip: You can use the comment environment to add multi-line comments, for example:" _n
        file write `texfile' "% \begin{comment}" _n
        file write `texfile' "% This is commented content" _n
        file write `texfile' "% It will not appear in the final document" _n
        file write `texfile' "% \end{comment}" _n
    }
    file write `texfile' _n
    
    * Abstract section
    if "`abstractalign'" == "indent" {
        if "`language'" == "chinese" {
            file write `texfile' "\begin{abstract}" _n
        }
        else {
            file write `texfile' "\begin{abstract}" _n
        }
    }
    else {
        file write `texfile' "\begin{flushleft}" _n
        if "`language'" == "chinese" {
            file write `texfile' "\textbf{摘要：}" _n
        }
        else {
            file write `texfile' "\textbf{Abstract:}" _n
        }
    }
    
    if "`language'" == "chinese" {
        file write `texfile' "此处填写摘要内容。" _n
    }
    else {
        file write `texfile' "Your abstract text goes here." _n
    }
    
    if "`abstractalign'" == "indent" {
        file write `texfile' "\end{abstract}" _n
    }
    else {
        file write `texfile' "\end{flushleft}" _n
    }
    file write `texfile' _n
    
    * Keywords section
    if "`language'" == "chinese" {
        file write `texfile' "\noindent\textbf{关键词}: "
    }
    else {
        file write `texfile' "\noindent\textbf{Keywords}: "
    }
    
    if "`keywordseparator'" == "comma" {
        if "`language'" == "chinese" {
            file write `texfile' "关键词1, 关键词2, 关键词3" _n
        }
        else {
            file write `texfile' "keyword1, keyword2, keyword3" _n
        }
    }
    else if "`keywordseparator'" == "semicolon" {
        if "`language'" == "chinese" {
            file write `texfile' "关键词1; 关键词2; 关键词3" _n
        }
        else {
            file write `texfile' "keyword1; keyword2; keyword3" _n
        }
    }
    else {
        if "`language'" == "chinese" {
            file write `texfile' "关键词1 关键词2 关键词3" _n
        }
        else {
            file write `texfile' "keyword1 keyword2 keyword3" _n
        }
    }
    file write `texfile' _n
    
    * Main content sections
    if "`language'" == "chinese" {
        local sections "引言 文献综述 研究方法 案例分析 研究结果 讨论 结论"
        local section_sub "子节"
        local section_subsub "子子节"
        local content_placeholder "此处填写内容"
    }
    else {
        local sections "Introduction Literature_Review Methodology Case_Analysis Results Discussion Conclusion"
        local section_sub "Subsection"
        local section_subsub "Subsubsection"
        local content_placeholder "Your content here"
    }
    
    foreach section in `sections' {
        * Replace underscores with spaces for English section titles
        if "`language'" == "english" {
            local section_display = subinstr("`section'", "_", " ", .)
        }
        else {
            local section_display "`section'"
        }
        
        file write `texfile' "\section{`section_display'}" _n
        
        if "`language'" == "chinese" {
            file write `texfile' "% 在此处填写`section_display'内容" _n
        }
        else {
            file write `texfile' "% Replace with your specific `section_display' content" _n
        }
        
        * Add citation example in literature review section
        if "`section'" == "文献综述" | "`section'" == "Literature_Review" {
            if "`language'" == "chinese" {
                file write `texfile' "现有研究表明数据资产对企业绩效有显著影响（\cite{zhang2020}）。" _n
                file write `texfile' "此外，数据治理框架也是提升数据价值的关键因素（\cite{li2022, wang2021}）。" _n
            }
            else {
                file write `texfile' "Existing research shows that data assets have a significant impact on firm performance (\cite{zhang2020})." _n
                file write `texfile' "Additionally, data governance frameworks are also key factors in enhancing data value (\cite{li2022, wang2021})." _n
            }
        }
        
        * Add mathematical formulas in methodology section
        if "`section'" == "研究方法" | "`section'" == "Methodology" {
            if "`language'" == "chinese" {
                file write `texfile' "本研究采用熵值法确定指标权重，具体计算步骤如下：" _n
                file write `texfile' _n
                file write `texfile' "首先，对原始数据进行标准化处理：" _n
                file write `texfile' "\begin{equation}" _n
                file write `texfile' "\label{eq:standardization}" _n
                file write `texfile' "x_{ij}' = \frac{x_{ij} - \min(x_j)}{\max(x_j) - \min(x_j)}" _n
                file write `texfile' "\end{equation}" _n
                file write `texfile' _n
                file write `texfile' "其中，\$x_{ij}\$ 表示第 \$i\$ 个样本的第 \$j\$ 个指标值。" _n
                file write `texfile' _n
                file write `texfile' "然后，计算第 \$j\$ 项指标下第 \$i\$ 个样本的比重：" _n
                file write `texfile' "\begin{equation}" _n
                file write `texfile' "\label{eq:proportion}" _n
                file write `texfile' "p_{ij} = \frac{x_{ij}'}{\sum_{i=1}^{n} x_{ij}'}" _n
                file write `texfile' "\end{equation}" _n
                file write `texfile' _n
                file write `texfile' "接着，计算第 \$j\$ 项指标的熵值：" _n
                file write `texfile' "\begin{equation}" _n
                file write `texfile' "\label{eq:entropy}" _n
                file write `texfile' "e_j = -k \sum_{i=1}^{n} p_{ij} \ln(p_{ij})" _n
                file write `texfile' "\end{equation}" _n
                file write `texfile' _n
                file write `texfile' "其中，\$k = 1/\ln(n)\$，\$n\$ 为样本数。" _n
                file write `texfile' _n
                file write `texfile' "最后，计算第 \$j\$ 项指标的权重：" _n
                file write `texfile' "\begin{equation}" _n
                file write `texfile' "\label{eq:weight}" _n
                file write `texfile' "w_j = \frac{1 - e_j}{\sum_{j=1}^{m} (1 - e_j)}" _n
                file write `texfile' "\end{equation}" _n
                file write `texfile' _n
                file write `texfile' "其中，\$m\$ 为指标数量。" _n
            }
            else {
                file write `texfile' "This study uses the entropy method to determine indicator weights. The specific calculation steps are as follows:" _n
                file write `texfile' _n
                file write `texfile' "First, standardize the original data:" _n
                file write `texfile' "\begin{equation}" _n
                file write `texfile' "\label{eq:standardization}" _n
                file write `texfile' "x_{ij}' = \frac{x_{ij} - \min(x_j)}{\max(x_j) - \min(x_j)}" _n
                file write `texfile' "\end{equation}" _n
                file write `texfile' _n
                file write `texfile' "where \$x_{ij}\$ represents the value of the \$j\$th indicator for the \$i\$th sample." _n
                file write `texfile' _n
                file write `texfile' "Then, calculate the proportion of the \$i\$th sample under the \$j\$th indicator:" _n
                file write `texfile' "\begin{equation}" _n
                file write `texfile' "\label{eq:proportion}" _n
                file write `texfile' "p_{ij} = \frac{x_{ij}'}{\sum_{i=1}^{n} x_{ij}'}" _n
                file write `texfile' "\end{equation}" _n
                file write `texfile' _n
                file write `texfile' "Next, calculate the entropy value of the \$j\$th indicator:" _n
                file write `texfile' "\begin{equation}" _n
                file write `texfile' "\label{eq:entropy}" _n
                file write `texfile' "e_j = -k \sum_{i=1}^{n} p_{ij} \ln(p_{ij})" _n
                file write `texfile' "\end{equation}" _n
                file write `texfile' _n
                file write `texfile' "where \$k = 1/\ln(n)\$ and \$n\$ is the number of samples." _n
                file write `texfile' _n
                file write `texfile' "Finally, calculate the weight of the \$j\$th indicator:" _n
                file write `texfile' "\begin{equation}" _n
                file write `texfile' "\label{eq:weight}" _n
                file write `texfile' "w_j = \frac{1 - e_j}{\sum_{j=1}^{m} (1 - e_j)}" _n
                file write `texfile' "\end{equation}" _n
                file write `texfile' _n
                file write `texfile' "where \$m\$ is the number of indicators." _n
            }
        }
        
        * For subsection and subsubsection titles, use the original section name without underscores
        if "`language'" == "english" {
            local subsection_title = subinstr("`section'", "_", " ", .) + " `section_sub'"
            local subsubsection_title = subinstr("`section'", "_", " ", .) + " `section_subsub'"
        }
        else {
            local subsection_title "`section' `section_sub'"
            local subsubsection_title "`section' `section_subsub'"
        }
        
        file write `texfile' "\subsection{`subsection_title'}" _n
        file write `texfile' "`content_placeholder'" _n
        file write `texfile' "\subsubsection{`subsubsection_title'}" _n
        file write `texfile' "`content_placeholder'" _n
        file write `texfile' _n
    }
    
    * Example table and figures
    if "`language'" == "chinese" {
        file write `texfile' "\begin{table}[H]" _n
        file write `texfile' "\centering" _n
        file write `texfile' "\caption{示例表格}" _n
        file write `texfile' "\label{tab:example}" _n
        file write `texfile' "\input{tables/example_table.tex}" _n
        file write `texfile' "\end{table}" _n
        file write `texfile' _n
        
        file write `texfile' "% 请确保figures目录中存在以下图片文件，或修改为您的图片文件名" _n
        file write `texfile' "\begin{figure}[H]" _n
        file write `texfile' "\centering" _n
        file write `texfile' "\includegraphics[width=0.8\textwidth]{figures/global_data_growth.png}" _n
        file write `texfile' "\caption{全球数据量增长趋势 (2000-2024)}" _n
        file write `texfile' "\label{fig:data_growth}" _n
        file write `texfile' "\end{figure}" _n
        file write `texfile' _n
        
        file write `texfile' "\begin{figure}[H]" _n
        file write `texfile' "\centering" _n
        file write `texfile' "\includegraphics[width=0.8\textwidth]{figures/scatter_plot.png}" _n
        file write `texfile' "\caption{数据资产资本化率与ROA的关系}" _n
        file write `texfile' "\label{fig:scatter}" _n
        file write `texfile' "\end{figure}" _n
        file write `texfile' _n
    }
    else {
        file write `texfile' "\begin{table}[H]" _n
        file write `texfile' "\centering" _n
        file write `texfile' "\caption{Example Table}" _n
        file write `texfile' "\label{tab:example}" _n
        file write `texfile' "\input{tables/example_table.tex}" _n
        file write `texfile' "\end{table}" _n
        file write `texfile' _n
        
        file write `texfile' "% Please make sure the following image files exist in the figures directory, or modify to your image file names" _n
        file write `texfile' "\begin{figure}[H]" _n
        file write `texfile' "\centering" _n
        file write `texfile' "\includegraphics[width=0.8\textwidth]{figures/global_data_growth.png}" _n
        file write `texfile' "\caption{Global Data Growth Trend (2000-2024)}" _n
        file write `texfile' "\label{fig:data_growth}" _n
        file write `texfile' "\end{figure}" _n
        file write `texfile' _n
        
        file write `texfile' "\begin{figure}[H]" _n
        file write `texfile' "\centering" _n
        file write `texfile' "\includegraphics[width=0.8\textwidth]{figures/scatter_plot.png}" _n
        file write `texfile' "\caption{Relationship between Data Asset Capitalization Rate and ROA}" _n
        file write `texfile' "\label{fig:scatter}" _n
        file write `texfile' "\end{figure}" _n
        file write `texfile' _n
    }
    
    * References section
    if "`language'" == "chinese" {
        file write `texfile' "\section*{参考文献}" _n
        file write `texfile' "\addcontentsline{toc}{section}{参考文献}" _n
    }
    else {
        file write `texfile' "\section*{References}" _n
        file write `texfile' "\addcontentsline{toc}{section}{References}" _n
    }
    
    file write `texfile' "\bibliographystyle{plainnat}" _n
    file write `texfile' "\bibliography{references}" _n
    file write `texfile' _n
    
    file write `texfile' "\end{document}" _n
    file close `texfile'
    
    * Create example table file
    tempname tabfile
    file open `tabfile' using "tables/example_table.tex", write replace
    
    if "`language'" == "chinese" {
        file write `tabfile' "\begin{tabular}{lcc}" _n
        file write `tabfile' "\toprule" _n
        file write `tabfile' "变量 & 均值 & 标准差 \\\\" _n
        file write `tabfile' "\midrule" _n
        file write `tabfile' "X1 & 0.5 & 0.1 \\\\" _n
        file write `tabfile' "X2 & 0.3 & 0.2 \\\\" _n
        file write `tabfile' "\bottomrule" _n
        file write `tabfile' "\end{tabular}" _n
    }
    else {
        file write `tabfile' "\begin{tabular}{lcc}" _n
        file write `tabfile' "\toprule" _n
        file write `tabfile' "Variable & Mean & SD \\\\" _n
        file write `tabfile' "\midrule" _n
        file write `tabfile' "X1 & 0.5 & 0.1 \\\\" _n
        file write `tabfile' "X2 & 0.3 & 0.2 \\\\" _n
        file write `tabfile' "\bottomrule" _n
        file write `tabfile' "\end{tabular}" _n
    }
    
    file close `tabfile'
    
    * Create README file for images
    tempname readmefile
    file open `readmefile' using "figures/README.txt", write replace
    
    if "`language'" == "chinese" {
        file write `readmefile' "请将以下图片文件放入此目录：" _n
        file write `readmefile' "1. global_data_growth.png - 全球数据量增长趋势图" _n
        file write `readmefile' "2. scatter_plot.png - 数据资产资本化率与ROA关系散点图" _n
        file write `readmefile' _n
        file write `readmefile' "或者修改主.tex文件中的图片文件名以匹配您的实际图片文件。" _n
    }
    else {
        file write `readmefile' "Please place the following image files in this directory:" _n
        file write `readmefile' "1. global_data_growth.png - Global data growth trend chart" _n
        file write `readmefile' "2. scatter_plot.png - Scatter plot of data asset capitalization rate and ROA" _n
        file write `readmefile' _n
        file write `readmefile' "Or modify the image file names in the main .tex file to match your actual image files." _n
    }
    
    file close `readmefile'
    
    * Create references.bib file
    tempname reffile
    file open `reffile' using "references.bib", write replace
    
    if "`language'" == "chinese" {
        file write `reffile' "@article{zhang2020," _n
        file write `reffile' "  title={数据资产对企业绩效的影响研究}," _n
        file write `reffile' "  author={张三 and 李四}," _n
        file write `reffile' "  journal={管理科学学报}," _n
        file write `reffile' "  volume={25}," _n
        file write `reffile' "  number={3}," _n
        file write `reffile' "  pages={45--60}," _n
        file write `reffile' "  year={2020}" _n
        file write `reffile' "}" _n _n
        
        file write `reffile' "@article{li2022," _n
        file write `reffile' "  title={数据治理框架与企业价值创造}," _n
        file write `reffile' "  author={王五 and 赵六}," _n
        file write `reffile' "  journal={经济研究}," _n
        file write `reffile' "  volume={57}," _n
        file write `reffile' "  number={5}," _n
        file write `reffile' "  pages={112--125}," _n
        file write `reffile' "  year={2022}" _n
        file write `reffile' "}" _n _n
        
        file write `reffile' "@book{wang2021," _n
        file write `reffile' "  title={数字化转型与案例研究}," _n
        file write `reffile' "  author={陈七}," _n
        file write `reffile' "  publisher={中国社会科学出版社}," _n
        file write `reffile' "  address={北京}," _n
        file write `reffile' "  year={2021}" _n
        file write `reffile' "}" _n
    }
    else {
        file write `reffile' "@article{zhang2020," _n
        file write `reffile' "  title={The Impact of Data Assets on Firm Performance}," _n
        file write `reffile' "  author={Zhang, San and Li, Si}," _n
        file write `reffile' "  journal={Journal of Management Science}," _n
        file write `reffile' "  volume={25}," _n
        file write `reffile' "  number={3}," _n
        file write `reffile' "  pages={45--60}," _n
        file write `reffile' "  year={2020}" _n
        file write `reffile' "}" _n _n
        
        file write `reffile' "@article{li2022," _n
        file write `reffile' "  title={Data Governance Framework and Enterprise Value Creation}," _n
        file write `reffile' "  author={Wang, Wu and Zhao, Liu}," _n
        file write `reffile' "  journal={Economic Research}," _n
        file write `reffile' "  volume={57}," _n
        file write `reffile' "  number={5}," _n
        file write `reffile' "  pages={112--125}," _n
        file write `reffile' "  year={2022}" _n
        file write `reffile' "}" _n _n
        
        file write `reffile' "@book{wang2021," _n
        file write `reffile' "  title={Digital Transformation and Case Study Research}," _n
        file write `reffile' "  author={Chen, Qi}," _n
        file write `reffile' "  publisher={China Social Sciences Press}," _n
        file write `reffile' "  address={Beijing}," _n
        file write `reffile' "  year={2021}" _n
        file write `reffile' "}" _n
    }
    
    file close `reffile'
    
    * Display message
    if "`language'" == "chinese" {
        di as text "LaTeX模板已创建: " as result "`filename'.tex"
        di as text "已创建子目录 'figures' 和 'tables'"
        di as text "已添加示例文件到子目录"
        di as text "已创建参考文献文件: references.bib"
        di as text "已在figures目录中创建README.txt文件，请按照说明添加图片文件"
        di as text "编译顺序: XeLaTeX -> BibTeX -> XeLaTeX -> XeLaTeX"
        di as text "注意: 编译前请确保figures目录中存在所需的图片文件"
        di as text "新增: 已添加comment包支持，可在文档中使用comment环境添加多行注释"
    }
    else {
        di as text "LaTeX template created: " as result "`filename'.tex"
        di as text "Subdirectories 'figures' and 'tables' created"
        di as text "Example files added to subdirectories"
        di as text "References file created: references.bib"
        di as text "README.txt file created in figures directory, please follow the instructions to add image files"
        di as text "Compilation sequence: XeLaTeX -> BibTeX -> XeLaTeX -> XeLaTeX"
        di as text "Note: Make sure the required image files exist in the figures directory before compilation"
        di as text "New: Added comment package support for multi-line comments using the comment environment"
    }
end