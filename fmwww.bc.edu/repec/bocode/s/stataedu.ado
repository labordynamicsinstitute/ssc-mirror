*! stataedu 1.0.0  16 August 2026
*! Stata 入门学习程序：安装与基础知识（第一课至第三课）
*! 鼎园会计（Dingyuan Accounting）：科学规范，人文向善
*! 作者：WU Lianghai, School of Business, Anhui University of Technology (AHUT)
*!       agd2010@yeah.net
*!       WU Hanyan, Department of Accountancy, City University of Hong Kong (CityU)
*!       2325476320@qq.com
*! 说明：本程序面向零基础初学者，展示 Stata 的安装步骤与入门级基础知识。

program define stataedu
	version 11

	syntax [, INSTALL BASIC EXAMPLE ALL]

	* 未指定任何选项时，默认显示全部三课
	if "`all'" == "" & "`install'" == "" & "`basic'" == "" & "`example'" == "" {
		local all "all"
	}

	* ---------------- 标题 ----------------
	di as text _n "{hline 72}"
	di as text " {bf:Dingyuan Accounting} -- scientific and standardized, humane and good"
	di as text " {bf:stataedu}  1.0.0  16 August 2026  Stata beginner's learning program"
	di as text "{hline 72}"

	* ---------------- 第一课：安装 ----------------
	if "`install'" != "" | "`all'" != "" {
		di as text _n "{hline 72}"
		di as text " {bf:Lesson 1  Installing Stata (about 10 minutes)}"
		di as text "{hline 72}"
		di as text `" 1. Visit the official website {browse "https://www.stata.com":https://www.stata.com}"'
		di as text "    and choose an edition to fit your budget: BE (basic), SE (standard), or MP (fast)."
		di as text " 2. Click Download, enter your name and email, and get the installer and serial number."
		di as text " 3. Run the installer, click Next, and choose an installation folder (the default is fine)."
		di as text " 4. On first launch, enter the serial number to activate your license, then restart Stata."
		di as text " 5. Students and faculty: prefer your university's site license (free and legal)."
		di as text " 6. Test it: type {cmd:sysuse auto, clear} in the Command window; if the data opens,"
		di as text "    your installation is successful."
	}

	* ---------------- 第二课：基础知识 ----------------
	if "`basic'" != "" | "`all'" != "" {
		di as text _n "{hline 72}"
		di as text " {bf:Lesson 2  The Stata interface and the most frequently used commands}"
		di as text "{hline 72}"
		di as text " The Stata window has five main areas:"
		di as text "   (1) Command window: type a command and press Enter to run it;"
		di as text "   (2) Results window: shows the output;"
		di as text "   (3) Variables window: lists the variables in the current dataset;"
		di as text "   (4) Properties window: shows attributes of the variables and the dataset;"
		di as text "   (5) Review window: records the commands you have run; double-click to rerun one."
		di as text _n " The 10 most frequently used commands (type each one yourself):"
		di as input "   . sysuse auto, clear       open the built-in example dataset"
		di as input "   . describe                 inspect the variables"
		di as input "   . list make price mpg      view the data"
		di as input "   . summarize price mpg      descriptive statistics (mean, sd, etc.)"
		di as input "   . tabulate foreign         frequency table"
		di as input "   . generate lnprice = ln(price)      create a new variable"
		di as input "   . replace lnprice = 0 if missing(lnprice)   modify a variable"
		di as input "   . regress price mpg weight   multiple linear regression"
		di as input "   . save mydata, replace      save the data as mydata.dta"
		di as input "   . help regress              look up help at any time"
		di as text _n " Golden rule: {bf:data first, analysis second}. Every analysis starts"
		di as text " by loading the data."
		di as text " Tip: write your commands in the Do-file editor (Ctrl+9) and save them as a .do"
		di as text " file. Do-files can be rerun, shared, and reproduced -- a basic skill for"
		di as text " empirical researchers."
	}

	* ---------------- 第三课：完整示例 ----------------
	if "`example'" != "" | "`all'" != "" {
		di as text _n "{hline 72}"
		di as text " {bf:Lesson 3  A complete example: follow along}"
		di as text "{hline 72}"
		di as text " Open the Do-file editor, type the following, select it, and press Ctrl+D to run:"
		di as input _n "   *==== My first Stata program ====*"
		di as input "   version 16"
		di as input "   sysuse auto, clear"
		di as input "   describe"
		di as input "   summarize price mpg weight"
		di as input "   tabulate foreign"
		di as input "   regress price mpg weight foreign"
		di as input "   * In the results, the larger R-squared, the stronger the model *"
		di as text _n " In the output, look at Obs (sample size), Mean, Std. dev., and"
		di as text " P>|t| (a P-value below 0.05 is usually considered statistically significant)."
	}

	* ---------------- 结尾 ----------------
	di as text _n "{hline 72}"
	di as text " After these three lessons, you know 80% of the Stata commands used most often."
	di as text " For more details, see the help file: {help stataedu}."
	di as text `" Authors: WU Lianghai (AHUT, {browse "mailto:agd2010@yeah.net":agd2010@yeah.net})"'
	di as text `"          WU Hanyan (CityU, {browse "mailto:2325476320@qq.com":2325476320@qq.com})"'
	di as text " Dingyuan Accounting: scientific and standardized, humane and good."
	di as text `" Related: {browse "https://ideas.repec.org/c/boc/bocode/s459595.html":mysuite -- Dingyuan Accounting suite of 39 empirical-accounting Stata programs}"'
	di as text "{hline 72}"
end
