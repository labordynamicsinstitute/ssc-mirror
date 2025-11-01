* dictionary.do - ESG文本分析词典生成文件
* 生成中英文ESG分类词典和情感词典
clear all
version 18
set more off

* 设置工作目录
cd "D:\益友学术\鼎园会计 202517"

di "开始生成ESG文本分析词典..."
di "========================================"

* ========================================
* 1. 生成中文ESG分类词典 (esg_dict_cn.txt)
* ========================================
di "生成中文ESG分类词典..."

file open dict_cn using "esg_dict_cn.txt", write replace

* Environmental 类别
file write dict_cn "Environmental" _n
file write dict_cn "环保" _n
file write dict_cn "环境" _n
file write dict_cn "排放" _n
file write dict_cn "碳" _n
file write dict_cn "温室气体" _n
file write dict_cn "能源" _n
file write dict_cn "水资源" _n
file write dict_cn "废物" _n
file write dict_cn "污染" _n
file write dict_cn "可持续发展" _n
file write dict_cn "生态" _n
file write dict_cn "绿色" _n
file write dict_cn "清洁" _n
file write dict_cn "可再生能源" _n
file write dict_cn "气候变化" _n
file write dict_cn "节能减排" _n
file write dict_cn "循环经济" _n
file write dict_cn "" _n

* Social 类别
file write dict_cn "Social" _n
file write dict_cn "员工" _n
file write dict_cn "雇员" _n
file write dict_cn "人权" _n
file write dict_cn "劳动" _n
file write dict_cn "安全" _n
file write dict_cn "健康" _n
file write dict_cn "培训" _n
file write dict_cn "发展" _n
file write dict_cn "社区" _n
file write dict_cn "公益" _n
file write dict_cn "慈善" _n
file write dict_cn "消费者" _n
file write dict_cn "客户" _n
file write dict_cn "产品质量" _n
file write dict_cn "责任" _n
file write dict_cn "福利" _n
file write dict_cn "平等" _n
file write dict_cn "多元化" _n
file write dict_cn "人权保障" _n
file write dict_cn "" _n

* Governance 类别
file write dict_cn "Governance" _n
file write dict_cn "治理" _n
file write dict_cn "董事会" _n
file write dict_cn "监事会" _n
file write dict_cn "独立董事" _n
file write dict_cn "审计" _n
file write dict_cn "风险" _n
file write dict_cn "合规" _n
file write dict_cn "内部控制" _n
file write dict_cn "透明度" _n
file write dict_cn "披露" _n
file write dict_cn "股东" _n
file write dict_cn "利益相关者" _n
file write dict_cn "伦理" _n
file write dict_cn "反腐败" _n
file write dict_cn "商业道德" _n
file write dict_cn "" _n

* General_ESG 类别
file write dict_cn "General_ESG" _n
file write dict_cn "ESG" _n
file write dict_cn "可持续" _n
file write dict_cn "社会责任" _n
file write dict_cn "企业公民" _n
file write dict_cn "道德" _n
file write dict_cn "伦理" _n
file write dict_cn "长期价值" _n
file write dict_cn "利益相关方" _n
file write dict_cn "可持续发展报告" _n

file close dict_cn

di "中文ESG分类词典已保存: esg_dict_cn.txt"

* ========================================
* 2. 生成英文ESG分类词典 (esg_dict_en.txt)
* ========================================
di "生成英文ESG分类词典..."

file open dict_en using "esg_dict_en.txt", write replace

* Environmental 类别
file write dict_en "Environmental" _n
file write dict_en "environmental protection" _n
file write dict_en "environment" _n
file write dict_en "emission" _n
file write dict_en "carbon" _n
file write dict_en "greenhouse gas" _n
file write dict_en "energy" _n
file write dict_en "water resource" _n
file write dict_en "waste" _n
file write dict_en "pollution" _n
file write dict_en "sustainable development" _n
file write dict_en "ecology" _n
file write dict_en "green" _n
file write dict_en "clean" _n
file write dict_en "renewable energy" _n
file write dict_en "climate change" _n
file write dict_en "energy saving and emission reduction" _n
file write dict_en "circular economy" _n
file write dict_en "" _n

* Social 类别
file write dict_en "Social" _n
file write dict_en "employee" _n
file write dict_en "staff" _n
file write dict_en "human rights" _n
file write dict_en "labor" _n
file write dict_en "safety" _n
file write dict_en "health" _n
file write dict_en "training" _n
file write dict_en "development" _n
file write dict_en "community" _n
file write dict_en "public welfare" _n
file write dict_en "charity" _n
file write dict_en "consumer" _n
file write dict_en "customer" _n
file write dict_en "product quality" _n
file write dict_en "responsibility" _n
file write dict_en "welfare" _n
file write dict_en "equality" _n
file write dict_en "diversity" _n
file write dict_en "human rights protection" _n
file write dict_en "" _n

* Governance 类别
file write dict_en "Governance" _n
file write dict_en "governance" _n
file write dict_en "board of directors" _n
file write dict_en "supervisory board" _n
file write dict_en "independent director" _n
file write dict_en "audit" _n
file write dict_en "risk" _n
file write dict_en "compliance" _n
file write dict_en "internal control" _n
file write dict_en "transparency" _n
file write dict_en "disclosure" _n
file write dict_en "shareholder" _n
file write dict_en "stakeholder" _n
file write dict_en "ethics" _n
file write dict_en "anti-corruption" _n
file write dict_en "business ethics" _n
file write dict_en "" _n

* General_ESG 类别
file write dict_en "General_ESG" _n
file write dict_en "ESG" _n
file write dict_en "sustainability" _n
file write dict_en "social responsibility" _n
file write dict_en "corporate citizen" _n
file write dict_en "ethics" _n
file write dict_en "ethical" _n
file write dict_en "long-term value" _n
file write dict_en "stakeholder" _n
file write dict_en "sustainability report" _n

file close dict_en

di "英文ESG分类词典已保存: esg_dict_en.txt"

* ========================================
* 3. 生成中文情感词典 (sentiment_cn.txt)
* ========================================
di "生成中文情感词典..."

file open sent_cn using "sentiment_cn.txt", write replace

* 正面情感词汇 (评分=1)
file write sent_cn "积极,1" _n
file write sent_cn "重视,1" _n
file write sent_cn "优秀,1" _n
file write sent_cn "良好,1" _n
file write sent_cn "完善,1" _n
file write sent_cn "有效,1" _n
file write sent_cn "透明,1" _n
file write sent_cn "全面,1" _n
file write sent_cn "可持续发展,1" _n
file write sent_cn "节能减排,1" _n
file write sent_cn "环境保护,1" _n
file write sent_cn "健康安全,1" _n
file write sent_cn "职业培训,1" _n
file write sent_cn "福利保障,1" _n
file write sent_cn "风险管理,1" _n
file write sent_cn "合规经营,1" _n
file write sent_cn "社会责任,1" _n
file write sent_cn "公益慈善,1" _n
file write sent_cn "长期价值,1" _n
file write sent_cn "绿色转型,1" _n
file write sent_cn "新增,1" _n
file write sent_cn "加强,1" _n
file write sent_cn "推动,1" _n
file write sent_cn "致力于,1" _n
file write sent_cn "关注,1" _n
file write sent_cn "注重,1" _n
file write sent_cn "关爱,1" _n
file write sent_cn "保障,1" _n
file write sent_cn "提升,1" _n
file write sent_cn "改善,1" _n

* 负面情感词汇 (评分=-1或-0.5)
file write sent_cn "问题,-1" _n
file write sent_cn "不足,-1" _n
file write sent_cn "缺陷,-1" _n
file write sent_cn "污染,-1" _n
file write sent_cn "排放,-1" _n
file write sent_cn "风险,-1" _n
file write sent_cn "挑战,-1" _n
file write sent_cn "困难,-1" _n
file write sent_cn "压力,-1" _n
file write sent_cn "基本,-0.5" _n
file write sent_cn "一般,-0.5" _n
file write sent_cn "有限,-0.5" _n
file write sent_cn "初步,-0.5" _n
file write sent_cn "有待,-0.5" _n
file write sent_cn "缺乏,-1" _n
file write sent_cn "不足,-1" _n
file write sent_cn "缺失,-1" _n
file write sent_cn "落后,-1" _n

file close sent_cn

di "中文情感词典已保存: sentiment_cn.txt"

* ========================================
* 4. 生成英文情感词典 (sentiment_en.txt)
* ========================================
di "生成英文情感词典..."

file open sent_en using "sentiment_en.txt", write replace

* 正面情感词汇 (评分=1)
file write sent_en "excellent,1" _n
file write sent_en "good,1" _n
file write sent_en "comprehensive,1" _n
file write sent_en "effective,1" _n
file write sent_en "transparent,1" _n
file write sent_en "sustainable,1" _n
file write sent_en "development,1" _n
file write sent_en "protection,1" _n
file write sent_en "healthy,1" _n
file write sent_en "safe,1" _n
file write sent_en "training,1" _n
file write sent_en "welfare,1" _n
file write sent_en "rights,1" _n
file write sent_en "management,1" _n
file write sent_en "compliance,1" _n
file write sent_en "responsibility,1" _n
file write sent_en "charitable,1" _n
file write sent_en "value,1" _n
file write sent_en "green,1" _n
file write sent_en "added,1" _n
file write sent_en "enhanced,1" _n
file write sent_en "promoted,1" _n
file write sent_en "reduces,1" _n
file write sent_en "conserves,1" _n
file write sent_en "committed,1" _n
file write sent_en "focuses,1" _n
file write sent_en "emphasizes,1" _n
file write sent_en "cares,1" _n
file write sent_en "ensures,1" _n
file write sent_en "improves,1" _n

* 负面情感词汇 (评分=-1或-0.5)
file write sent_en "problem,-1" _n
file write sent_en "deficiency,-1" _n
file write sent_en "defect,-1" _n
file write sent_en "pollution,-1" _n
file write sent_en "emission,-1" _n
file write sent_en "risk,-1" _n
file write sent_en "challenge,-1" _n
file write sent_en "difficulty,-1" _n
file write sent_en "pressure,-1" _n
file write sent_en "basic,-0.5" _n
file write sent_en "normal,-0.5" _n
file write sent_en "limited,-0.5" _n
file write sent_en "preliminary,-0.5" _n
file write sent_en "lacks,-1" _n
file write sent_en "deficient,-1" _n
file write sent_en "missing,-1" _n
file write sent_en "backward,-1" _n

file close sent_en

di "英文情感词典已保存: sentiment_en.txt"

* ========================================
* 5. 创建词典统计信息 (修正版)
* ========================================
di ""
di "词典生成完成！"
di "========================================"
di "生成的词典文件统计:"

* 统计中文ESG词典
quietly: insheet using "esg_dict_cn.txt", clear nonames
* 只保留词汇行，去除类别标题和空行
keep if v1 != "" & v1 != "Environmental" & v1 != "Social" & v1 != "Governance" & v1 != "General_ESG"
local total_cn = _N
di "中文ESG词典: `total_cn' 个词汇"

* 统计英文ESG词典
quietly: insheet using "esg_dict_en.txt", clear nonames
* 只保留词汇行，去除类别标题和空行
keep if v1 != "" & v1 != "Environmental" & v1 != "Social" & v1 != "Governance" & v1 != "General_ESG"
local total_en = _N
di "英文ESG词典: `total_en' 个词汇"

* 统计中文情感词典
quietly: insheet using "sentiment_cn.txt", clear comma nonames
gen positive = v2 > 0
gen negative = v2 < 0
quietly: count if positive
local pos_cn = r(N)
quietly: count if negative  
local neg_cn = r(N)
di "中文情感词典: `pos_cn' 个正面词汇, `neg_cn' 个负面词汇"

* 统计英文情感词典
quietly: insheet using "sentiment_en.txt", clear comma nonames
gen positive = v2 > 0
gen negative = v2 < 0
quietly: count if positive
local pos_en = r(N)
quietly: count if negative  
local neg_en = r(N)
di "英文情感词典: `pos_en' 个正面词汇, `neg_en' 个负面词汇"

di "========================================"
di "所有词典文件已成功生成！"
di "文件列表:"
di "1. esg_dict_cn.txt    - 中文ESG分类词典"
di "2. esg_dict_en.txt    - 英文ESG分类词典" 
di "3. sentiment_cn.txt   - 中文情感词典"
di "4. sentiment_en.txt   - 英文情感词典"
di "========================================"

* 清理临时变量
clear