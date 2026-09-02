*! latexedu 1.0.0  16 August 2026
*! LaTeX 入门学习程序：安装与基础知识（第一课至第三课）
*! 鼎园会计（Dingyuan Accounting）：科学规范，人文向善
*! 作者：WU Lianghai, School of Business, Anhui University of Technology (AHUT)
*!       agd2010@yeah.net
*!       WU Hanyan, Department of Accountancy, City University of Hong Kong (CityU)
*!       2325476320@qq.com
*! 说明：本程序面向零基础初学者，展示 LaTeX 的安装步骤与入门级基础知识。

program define latexedu
	version 11

	syntax [, INSTALL BASIC EXAMPLE ALL]

	if "`all'" == "" & "`install'" == "" & "`basic'" == "" & "`example'" == "" {
		local all "all"
	}

	* ---------------- 标题 ----------------
	di as text _n "{hline 72}"
	di as text " {bf:Dingyuan Accounting} -- scientific and standardized, humane and good"
	di as text " {bf:latexedu}  1.0.0  16 August 2026  LaTeX beginner's learning program"
	di as text "{hline 72}"

	* ---------------- 第一课：安装 ----------------
	if "`install'" != "" | "`all'" != "" {
		di as text _n "{hline 72}"
		di as text " {bf:Lesson 1  Installing LaTeX (choose one of two routes)}"
		di as text "{hline 72}"
		di as text " Route A (online, no installation; recommended for beginners):"
		di as text `"   1. Go to Overleaf: {browse "https://www.overleaf.com":https://www.overleaf.com}"'
		di as text "   2. Sign up for a free account, click New Project, and compile a PDF"
		di as text "      directly in your browser."
		di as text " Route B (install locally):"
		di as text `"   1. Windows: install TeX Live ({browse "https://tug.org/texlive":tug.org/texlive})"'
		di as text `"      or MiKTeX ({browse "https://miktex.org":miktex.org}); macOS: install MacTeX."'
		di as text "   2. Install an editor: TeXstudio"
		di as text `"      ({browse "https://www.texstudio.org":texstudio.org}) or VS Code with the"'
		di as text "      LaTeX Workshop extension."
		di as text "   3. Create a .tex file and compile it with XeLaTeX (needed for Chinese)"
		di as text "      to produce a PDF."
		di as text " Note: for Chinese documents, always compile with XeLaTeX and load the"
		di as text " ctex package in the preamble."
	}

	* ---------------- 第二课：基础知识 ----------------
	if "`basic'" != "" | "`all'" != "" {
		di as text _n "{hline 72}"
		di as text " {bf:Lesson 2  LaTeX basics}"
		di as text "{hline 72}"
		di as text " (1) Document skeleton (learn this and you know 50% of LaTeX):"
		di as input "     \documentclass{article}     % document class"
		di as input "     \usepackage[UTF8]{ctex}     % Chinese support"
		di as input "     \begin{document}"
		di as input "         body text goes here ..."
		di as input "     \end{document}"
		di as text " (2) Sections and titles:"
		di as input "     \section{Introduction}"
		di as input "     \subsection{Research question}"
		di as text " (3) Math formulas (essential for empirical papers):"
		di as input "     \[y = \alpha + \beta x + \varepsilon\]"
		di as input "     \[ROA = \frac{NI}{TA}\]"
		di as text " (4) Tables and figures:"
		di as input "     \begin{tabular}{ccc} a & b & c \end{tabular}"
		di as input "     \includegraphics{fig1.png}"
		di as text " (5) Basic rules: comments start with %; commands start with \; arguments"
		di as text "    go in braces {}."
		di as text _n " Tip: treat LaTeX as a typesetting language; memorize the skeleton,"
		di as text " then add content block by block."
	}

	* ---------------- 第三课：完整示例 ----------------
	if "`example'" != "" | "`all'" != "" {
		di as text _n "{hline 72}"
		di as text " {bf:Lesson 3  A complete example: a Chinese paper template}"
		di as text "{hline 72}"
		di as text " Paste the following into Overleaf (compiler: XeLaTeX) and compile"
		di as text " to get a PDF:"
		di as input _n "   \documentclass{article}"
		di as input "   \usepackage[UTF8]{ctex}"
		di as input "   \title{A Short Paper in Chinese}"
		di as input "   \author{WU Lianghai}"
		di as input "   \date{16 August 2026}"
		di as input "   \begin{document}"
		di as input "   \maketitle"
		di as input "   \section{Introduction}"
		di as input "   This is a Chinese document typeset with LaTeX."
		di as input "   \section{Model}"
		di as input "   Accounting quality model: \[Q = f(ROA, LEV, SIZE) + \varepsilon\]."
		di as input "   \end{document}"
		di as text _n " Once it compiles, the PDF you see is the layout of a real paper --"
		di as text " no more fighting with formatting in Word."
	}

	* ---------------- 结尾 ----------------
	di as text _n "{hline 72}"
	di as text " After these three lessons, you can typeset a Chinese paper draft"
	di as text " on your own."
	di as text " For more details, see the help file: {help latexedu}."
	di as text `" Authors: WU Lianghai (AHUT, {browse "mailto:agd2010@yeah.net":agd2010@yeah.net})"'
	di as text `"          WU Hanyan (CityU, {browse "mailto:2325476320@qq.com":2325476320@qq.com})"'
	di as text " Dingyuan Accounting: scientific and standardized, humane and good."
	di as text `" Related: {browse "https://ideas.repec.org/c/boc/bocode/s459595.html":mysuite -- Dingyuan Accounting suite of 39 empirical-accounting Stata programs}"'
	di as text "{hline 72}"
end
