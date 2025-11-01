* Create balanced panel ESG dataset with BOTH Chinese and English versions
* 10 companies × 5 years (2020-2024) = 50 observations
clear
set seed 12345
cd "D:\益友学术\鼎园会计 202517"
* Create balanced panel directly
set obs 50

* Generate numeric company codes (1-10)
gen stkcd = ceil(_n/5)

* Generate years (2020-2024)
bysort stkcd: gen year = 2019 + _n
sort stkcd year

* Create Chinese ESG reports with rich content
gen ESGreport_cn = ""

* Company 1: Excellent ESG disclosure (Chinese)
replace ESGreport_cn = "本公司高度重视环境保护和可持续发展，积极推行节能减排措施，减少碳排放，保护水资源，处理废物污染。在员工权益方面，我们提供健康安全的工作环境和职业培训，关注员工福利和人权保障。公司治理透明，董事会和监事会有效运作，注重风险管理和合规经营。我们秉持社会责任，参与社区公益和慈善活动，为利益相关方创造长期价值。ESG报告全面披露了公司在环境、社会和治理方面的表现。" if stkcd == 1

* Company 2: Good ESG disclosure (Chinese)
replace ESGreport_cn = "公司致力于环境保护，实施能源管理和碳排放控制，推动绿色发展和循环经济。重视员工安全和健康，提供完善的培训和发展机会。董事会有效监督公司运营，确保合规性和透明度。我们积极履行社会责任，关注产品质量和消费者权益，为可持续发展贡献力量。" if stkcd == 2

* Company 3: Good ESG disclosure (Chinese)
replace ESGreport_cn = "在经营过程中，公司注重环境保护，减少污染物排放，节约能源资源。关爱员工，保障劳动权益，提供安全健康的工作环境。治理结构完善，审计和风险控制有效。参与社区建设，支持公益事业，努力实现企业社会责任。" if stkcd == 3

* Company 4: Moderate ESG disclosure (Chinese)
replace ESGreport_cn = "公司关注环境保护，实施节能减排，管理水资源和废物。员工培训和安全健康得到重视。董事会监督公司治理，确保合规经营。认识到社会责任的重要性。" if stkcd == 4

* Company 5: Moderate ESG disclosure (Chinese)
replace ESGreport_cn = "经营中考虑环境因素，减少能源消耗和碳排放。员工权益得到基本保障。公司治理结构正常运作。履行基本的社会责任。" if stkcd == 5

* Company 6: Basic ESG disclosure (Chinese)
replace ESGreport_cn = "公司注意环境保护，管理排放物。员工工作环境安全。董事会发挥作用。承担社会责任。" if stkcd == 6

* Company 7: Basic ESG disclosure (Chinese)
replace ESGreport_cn = "环境保护得到关注，节能减排有所行动。员工权益有保障。治理结构存在。社会责任有所体现。" if stkcd == 7

* Company 8: Minimal ESG disclosure (Chinese)
replace ESGreport_cn = "公司经营中考虑环境因素。员工工作条件正常。治理结构基本完整。" if stkcd == 8

* Company 9: Very minimal ESG disclosure (Chinese)
replace ESGreport_cn = "公司正常经营，业务发展。" if stkcd == 9

* Company 10: Very minimal ESG disclosure (Chinese)
replace ESGreport_cn = "公司运营稳定。" if stkcd == 10

* Create corresponding English ESG reports
gen ESGreport_en = ""

* Company 1: Excellent ESG disclosure (English)
replace ESGreport_en = "Our company attaches great importance to environmental protection and sustainable development, actively implements energy saving and emission reduction measures, reduces carbon emissions, protects water resources, and treats waste pollution. In terms of employee rights, we provide a healthy and safe working environment and vocational training, focusing on employee welfare and human rights protection. Corporate governance is transparent, with effective operation of the board of directors and supervisory board, emphasizing risk management and compliance operations. We adhere to social responsibility, participate in community public welfare and charitable activities, and create long-term value for stakeholders. The ESG report comprehensively discloses the company's performance in environmental, social, and governance aspects." if stkcd == 1

* Company 2: Good ESG disclosure (English)
replace ESGreport_en = "The company is committed to environmental protection, implements energy management and carbon emission control, promotes green development and circular economy. Emphasizes employee safety and health, provides comprehensive training and development opportunities. The board effectively supervises company operations, ensuring compliance and transparency. We actively fulfill social responsibilities, focus on product quality and consumer rights, and contribute to sustainable development." if stkcd == 2

* Company 3: Good ESG disclosure (English)
replace ESGreport_en = "In the operation process, the company focuses on environmental protection, reduces pollutant emissions, and conserves energy resources. Cares for employees, protects labor rights, and provides a safe and healthy working environment. The governance structure is complete, with effective audit and risk control. Participates in community building, supports public welfare, and strives to achieve corporate social responsibility." if stkcd == 3

* Company 4: Moderate ESG disclosure (English)
replace ESGreport_en = "The company pays attention to environmental protection, implements energy saving and emission reduction, manages water resources and waste. Employee training and safety health are valued. The board supervises corporate governance to ensure compliant operations. Recognizes the importance of social responsibility." if stkcd == 4

* Company 5: Moderate ESG disclosure (English)
replace ESGreport_en = "Considers environmental factors in operations, reduces energy consumption and carbon emissions. Employee rights are basically guaranteed. Corporate governance structure operates normally. Fulfills basic social responsibilities." if stkcd == 5

* Company 6: Basic ESG disclosure (English)
replace ESGreport_en = "The company pays attention to environmental protection and manages emissions. Employee working environment is safe. The board plays its role. Undertakes social responsibility." if stkcd == 6

* Company 7: Basic ESG disclosure (English)
replace ESGreport_en = "Environmental protection receives attention, energy saving and emission reduction actions are taken. Employee rights are protected. Governance structure exists. Social responsibility is reflected." if stkcd == 7

* Company 8: Minimal ESG disclosure (English)
replace ESGreport_en = "The company considers environmental factors in operations. Employee working conditions are normal. Governance structure is basically complete." if stkcd == 8

* Company 9: Very minimal ESG disclosure (English)
replace ESGreport_en = "Normal company operations, business development." if stkcd == 9

* Company 10: Very minimal ESG disclosure (English)
replace ESGreport_en = "Stable company operations." if stkcd == 10

* Add year variations for both languages
* Chinese variations
replace ESGreport_cn = ESGreport_cn + " 本年新增环保项目和员工培训计划。" if year == 2022 & stkcd <= 7
replace ESGreport_cn = ESGreport_cn + " 加强治理透明度和风险管理。" if year == 2023 & stkcd <= 5
replace ESGreport_cn = ESGreport_cn + " 推动可持续发展和绿色转型。" if year == 2024 & stkcd <= 3

* English variations
replace ESGreport_en = ESGreport_en + " This year added environmental projects and employee training programs." if year == 2022 & stkcd <= 7
replace ESGreport_en = ESGreport_en + " Enhanced governance transparency and risk management." if year == 2023 & stkcd <= 5
replace ESGreport_en = ESGreport_en + " Promoted sustainable development and green transformation." if year == 2024 & stkcd <= 3

* Format the numeric stkcd to display as 6-digit codes
format stkcd %06.0f

* Label variables
label variable stkcd "Company Code"
label variable year "Year" 
label variable ESGreport_cn "ESG Report Text (Chinese)"
label variable ESGreport_en "ESG Report Text (English)"

* Verify balanced panel
tab stkcd year
di "Panel structure: " r(r) " companies × " r(c) " years = " _N " observations"

* Save two separate datasets for Chinese and English analysis

* 1. Save Chinese version dataset
preserve
keep stkcd year ESGreport_cn
rename ESGreport_cn ESGreport
label variable ESGreport "ESG Report Text (Chinese)"
save sunnyesg_cn.dta, replace
restore

* 2. Save English version dataset
preserve
keep stkcd year ESGreport_en
rename ESGreport_en ESGreport
label variable ESGreport "ESG Report Text (English)"
save sunnyesg_en.dta, replace
restore

* 3. Save combined dataset (both languages)
save sunnyesg_bilingual.dta, replace

* Display sample and check content
di "=== Chinese Version Sample ==="
list stkcd year ESGreport_cn in 1/5, clean noobs

di "=== English Version Sample ==="
list stkcd year ESGreport_en in 1/5, clean noobs

di "First company Chinese ESG report sample:"
list ESGreport_cn if stkcd == 1 & year == 2024

di "First company English ESG report sample:"
list ESGreport_en if stkcd == 1 & year == 2024

di "Bilingual balanced panel ESG dataset created successfully!"
di "Three datasets saved:"
di "1. sunnyesg_cn.dta - Chinese ESG reports"
di "2. sunnyesg_en.dta - English ESG reports" 
di "3. sunnyesg_bilingual.dta - Combined dataset with both languages"