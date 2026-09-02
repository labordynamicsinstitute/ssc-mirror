*! pythonedu 1.0.0  16 August 2026
*! Python 入门学习程序：安装与基础知识（第一课至第三课）
*! 鼎园会计（Dingyuan Accounting）：科学规范，人文向善
*! 作者：WU Lianghai, School of Business, Anhui University of Technology (AHUT)
*!       agd2010@yeah.net
*!       WU Hanyan, Department of Accountancy, City University of Hong Kong (CityU)
*!       2325476320@qq.com
*! 说明：本程序面向零基础初学者，展示 Python 的安装步骤与入门级基础知识。

program define pythonedu
	version 11

	syntax [, INSTALL BASIC EXAMPLE ALL]

	if "`all'" == "" & "`install'" == "" & "`basic'" == "" & "`example'" == "" {
		local all "all"
	}

	* ---------------- 标题 ----------------
	di as text _n "{hline 72}"
	di as text " {bf:Dingyuan Accounting} -- scientific and standardized, humane and good"
	di as text " {bf:pythonedu}  1.0.0  16 August 2026  Python beginner's learning program"
	di as text "{hline 72}"

	* ---------------- 第一课：安装 ----------------
	if "`install'" != "" | "`all'" != "" {
		di as text _n "{hline 72}"
		di as text " {bf:Lesson 1  Installing Python (Anaconda recommended)}"
		di as text "{hline 72}"
		di as text `" 1. Visit the official website {browse "https://www.anaconda.com":https://www.anaconda.com}"'
		di as text "    and download Anaconda (Python + Jupyter + common packages in one installer)."
		di as text " 2. Run the installer, click Next; tick Add to PATH if you want to use Python"
		di as text "    from a terminal."
		di as text " 3. Open Anaconda Navigator and click Launch:"
		di as text "    - Jupyter Notebook: interactive coding in your browser; best for beginners;"
		di as text "    - Spyder: an integrated development environment (IDE) similar to MATLAB."
		di as text " 4. Test it: open a terminal (cmd) and type {cmd:python --version}."
		di as text "    If it prints Python 3.x.x, the installation is successful."
		di as text " 5. If you installed plain Python from python.org instead, run"
		di as text "    {cmd:pip install pandas numpy matplotlib} to add the common packages."
		di as text " 6. In the terminal type {cmd:python}, press Enter, and try"
		di as text "    {cmd:print('Hello, Dingyuan!')}!"
	}

	* ---------------- 第二课：基础知识 ----------------
	if "`basic'" != "" | "`all'" != "" {
		di as text _n "{hline 72}"
		di as text " {bf:Lesson 2  Python basics (30 minutes to get started)}"
		di as text "{hline 72}"
		di as text " (1) Output: {cmd:print()} is the most frequently used Python function."
		di as input "     print('Hello, Dingyuan Accounting!')"
		di as text " (2) Variables and data types: assign values directly, no declaration needed."
		di as input "     x = 10            # integer (int)"
		di as input "     y = 3.14          # float"
		di as input "     name = 'Dingyuan'   # string (str)"
		di as text " (3) Lists and dictionaries (handy for financial data):"
		di as input "     firms = ['A', 'B', 'C']             # list"
		di as input "     info = {'firm': 'A', 'roe': 0.12}     # dict"
		di as text " (4) Loops and conditions:"
		di as input "     for f in firms:"
		di as input "         print(f)"
		di as input "     if x > 5:"
		di as input "         print('x is greater than 5')"
		di as text " (5) The big three for data analysis (bundled with Anaconda):"
		di as input "     import pandas as pd               # tabular data"
		di as input "     import numpy as np                # numerical computing"
		di as input "     import matplotlib.pyplot as plt   # plotting"
		di as text _n " Tip: learn print() and variables first, then lists and loops, and pandas last."
		di as text " Do not fear errors -- reading error messages is the most important Python lesson."
	}

	* ---------------- 第三课：完整示例 ----------------
	if "`example'" != "" | "`all'" != "" {
		di as text _n "{hline 72}"
		di as text " {bf:Lesson 3  A complete example: ROE analysis of three firms}"
		di as text "{hline 72}"
		di as text " Open Spyder (launch it from Anaconda Navigator). Create a new file"
		di as text " (File > New file), paste the whole script below, and press Run"
		di as text " (green play button, or press F5). The results appear in the"
		di as text " Console and a bar chart opens in the Plots pane."
		di as input _n "   # -*- coding: utf-8 -*-"
		di as input "   # ROE analysis of three firms -- Dingyuan Accounting"
		di as input "   import pandas as pd"
		di as input "   import matplotlib.pyplot as plt"
		di as input ""
		di as input "   # 1. build the data"
		di as input "   df = pd.DataFrame({'firm': ['A', 'B', 'C'],"
		di as input "                        'roe': [0.12, 0.08, 0.15]})"
		di as input ""
		di as input "   # 2. view the table"
		di as input "   print(df)"
		di as input ""
		di as input "   # 3. descriptive statistics of ROE"
		di as input "   print(df['roe'].describe())"
		di as input ""
		di as input "   # 4. mean ROE"
		di as input "   print('Mean ROE = ', round(df['roe'].mean(), 4))"
		di as input ""
		di as input "   # 5. bar chart (a window pops up; close it to finish)"
		di as input "   df.plot.bar(x='firm', y='roe', legend=False)"
		di as input "   plt.title('ROE of Three Firms')"
		di as input "   plt.ylabel('ROE')"
		di as input "   plt.show()"
		di as text _n " In the Console you see the ROE table, summary statistics (count,"
		di as text " mean, std, min, max), and the mean ROE. The bar chart appears in"
		di as text " the Plots pane. Congratulations: you have just finished your first"
		di as text " Python data analysis!"
	}

	* ---------------- 结尾 ----------------
	di as text _n "{hline 72}"
	di as text " After these three lessons, you have taken the first step in Python"
	di as text " data analysis."
	di as text " For more details, see the help file: {help pythonedu}."
	di as text `" Authors: WU Lianghai (AHUT, {browse "mailto:agd2010@yeah.net":agd2010@yeah.net})"'
	di as text `"          WU Hanyan (CityU, {browse "mailto:2325476320@qq.com":2325476320@qq.com})"'
	di as text " Dingyuan Accounting: scientific and standardized, humane and good."
	di as text `" Related: {browse "https://ideas.repec.org/c/boc/bocode/s459595.html":mysuite -- Dingyuan Accounting suite of 39 empirical-accounting Stata programs}"'
	di as text "{hline 72}"
end
