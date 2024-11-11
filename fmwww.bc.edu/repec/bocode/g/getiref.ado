*!  version 2.1  2024/7/12 
*    Papers form arXiv.org can be sent to CLIP now. 
*  version 1.10.1 2024/5/18
*    update American Journal of Political Science (open access)
*    https://onlinelibrary.wiley.com/doi/epdf/10.1111/ajps.12808
*  version 1.10 2024/5/17
*    update PDF link for SJ papers
*  version 1.9 2024/1/15
*    fix bugs for 'latex' option
*  version 1.8 2024/1/11
*    more robust to mirror error or bug
*  version 1.7 2024/1/7 
*    兼容来自 datacite 的 doi，如 arXiv
*  version 1.6 2024/1/2 
*    更新 Markdown 链接 
*  version 1.5 2023/12/31 
*    add option 'nogoogle', deal with WP (SSRN, arXiv, NBER)
*  version 1.4 2023/12/18
*    add option -pdf-, -bib-, -all-
*  version 1.2 2023/10/4, add option -clipoff-, -nodiocheck-
*! version 1.1 2023/9/26
*! Yujun Lian, arlionn@163.com

* input:  getref {DOI}
* output: Citation information. 
*    Author, Year, Title, Journal, Vol(Issue): Pages. Link, PDF
  
/*
      
:: 修改 :: 2023/10/13 8:42

[?] 同时使用 bibtex 格式，抽取作者信息等，提供三种基本的引文格式
[?] 输出引用格式，Author (Year, PDF), 
    其中 Year 为论文主页链接，PDF 为 PDF 链接  
[?] 增加 pdf 选项，调用 get_pdf.ado 子程序  
[?] 增加 cite 选项，以便可以输出 Author(Year, PDF) 格式 2023/10/20 17:29
    cite      Author(Year)
    citepdf   Author(Year, PDF)
                [Year](link),  [PDF](link)
            
* 2023/12/17 11:56 修订了 SCI-HUB 中 PDF 文档的 {DOI} 包含特殊字符的情形               
            
* 2023/12/19 0:44 ------------------- getref.ado 需要优化的问题 [OK-done]

1. Title 中的特殊字符  
   a. 去掉 (<[/\w]+>); 
   b. (&amp;) 修改为 (&)
   e.g., Amosh, H., & Khatib, S. F. A. (2023). 
      <scp>COVID‐19</scp> impact, financial and <scp>ESG</scp> performance: 
      Evidence from <scp>G</scp>20 countries. 
      Business Strategy &amp; Development, 6(3), 310–321. Portico.
2. 修改期刊名称
   The Stata Journal: Promoting Communications on Statistics and Stata
修改为：
   The Stata Journal                  

* 2023/12/19 21:22 --- 标题中包含数学符号    RegEX: '<\/?.+?>'
getref 10.1016/j.spl.2016.02.012

Romano, J. P., & Wolf, M. (2016). Efficient computation of adjusted <mml:math xmlns:mml="http://www.w3.org/1998/Math/MathML" altimg="si1.gif" display="inline" overflow="scroll"><mml:mi>p</mml:mi></mml:math>-values for resampling-based stepdown multiple testing. Statistics & Probability Letters, 113, 38–40.   


* 2023/12/25 8:22 -- 若 {DOI} 中包含 ssrn, NBER,  等 working paper 网站的关键词，则：
  1. 不显示 PDF 链接
  2. 提示：SSRN 网站的 PDF 文档需要手动下载

* 2023/12/26 0:00 -- 给不同的错误制定不同的错误码
  basic meta   fail == "doi"
  PDF          fail == "PDF"
  bibtex, ris  fail == "bib"
  随后 getref_OpenCitation 调用时分类显示错误信息；显示部分也酌情处理

*-帮助文件中需要说明的信息
getref "Gallen, Trevor, Broken Instruments (June 16th, 2020). Available at SSRN: https://ssrn.com/abstract=3671850 or http://dx.doi.org/10.2139/ssrn.3671850"
如果输入的表达式中包含 ',' 等特殊字符，需要将输入的字符串用 "" 包裹起来
   
   
* 2023/12/21 9:55  {DOI} 中包含 ssrn, 等 working paper 网站标示时，[-PDF-]() 不再显示，或者直接显示链接
  
  SSRN: 10.2139/ssrn.3671850   
  
  NBER: 10.3386/w31184
        10.3386/w29723 
    PDF: https://www.nber.org/system/files/working_papers/w31184/w31184.pdf
         https://www.nber.org/system/files/working_papers/w29723/w29723.pdf
  
  arXiv: 10.48550/arXiv.{ID}
    Link: https://doi.org/10.48550/arXiv.2312.05400
          https://doi.org/10.48550/arXiv.{ID}
     PDF: https://arxiv.org/pdf/2312.05400.pdf
          https://arxiv.org/pdf/{ID}.pdf
          
          
* 2023/12/26 8:52 主要期刊 DOI
  JASA  10.2307    10.2307/2283916   
  AER   
  
  * DOI 基础知识：https://www.medra.org/en/DOI.htm
                  https://www.doi.org/the-identifier/resources/factsheets/key-facts-on-digital-object-identifier-system
                  https://www.scribbr.com/citing-sources/what-is-a-doi/
    
* Google Scholar URL
  https://scholar.google.com/scholar?q={Title_encode}
                                        ------------
                                        转码后的论文标题
  mata: st_local("Title_encode", urlencode(`"`Title'"'))
  
  local title "Accommodating Time-Varying Heterogeneity in Risk Estimation under the Cox Model"
  local title "Economies of scale, technical change and persistent and time-varying cost"
  local title "Dynamic firm performance and estimator choice'"
  mata: st_local("title_encode", urlencode(`"`title'"'))
  local google_head "https://scholar.google.com/scholar?q="
  local google_url "`google_head'`title_encode'"
  local google_br `"{browse `"`google_url'"':Google}"'
  dis  "`google_url'"
  dis `"`google_br'"'
  
* OK - 2023/12/29 17:31 部分论文的作者姓名全为大写，需要替换成正常写法
  10.1111/1475-679X.12496      
  GOLDSTEIN, I., YANG, S., & ZUO, L. (2023). The Real Effects of ...    
  Solution: help ustrtitle() , string function     
      

* 2023/12/30 10:06
* TBD: Open Access Journals, Free to browse PDF documents 
  View our list of Wiley and Hindawi fully open access journals.
  https://authorservices.wiley.com/open-research/open-access/browse-journals.html
  e.g., Quantitative Economics, Theoretical Economics
      
      
*------------------------------------ test ---------------------------       
:: test ::
global DOI   ""10.1257/aer.109.4.1197""     // double """"
global DOI "10.1016/j.eneco.2022.106017" // many authors, special characters 
global DOI "10.1162/rest.90.3.592"       // RES
global DOI "10.1177/1536867X231175332"   // SJ 23-2
global DOI "10.3969/j.issn.1000-6249.2007.01.003"  // Chinese article
global DOI "10.2139/ssrn.3765862"          // SSRN   
global DOI "10.48550/arXiv.1301.3781"      // arXiv
global DOI "10.1111/j.1467-629X.2010.00375.x"
global DOI "10.1016/j.jeconom.2020.06.003"
global DOI "10.1007/978-3-030-21432-6"  // Open Access books 
global DOI "10.1007/978-3-030-86186-5"

cls 
// set trace on 
  
getiref "$DOI", d             
                
         */ 
  
*-get individual reference for given {DOI} 
* renamed from 'getref.ado', 2023/12/20 23:45

cap program drop getiref
program define getiref, rclass 
version 14

	syntax anything(everything) ///
	    [, PAth(string)         ///
           Md                   ///  // [Link], [PDF], [Google], [Appendix]
           md1                  ///  // clean format. Only [Link], [PDF]
           md2                  ///  // similar as 'md' , with blanks in links
           md3                  ///  // similar as 'md2', with blanks in links
		   Latex                ///  // Same as {cmd:md}, but with links in TeX format.       
		   Wechat               ///  // Plain text format: Author, Year, title, URL
		   Text            	    ///  // Equivalent to {bf:wechat}           
           Cite                 ///  // 'Author (Year)'    with Markdown links
           cite1                ///  // 'Author, Year'     with Markdown links, in text
             c1                 ///  //  short version of CIte1   
           cite2                ///  // 'Author (Year)'    plain text 
             c2                 ///  //  short version of CIte2  
           DISfn                ///  // display filename for saving by hand 
           All                  ///  // both -pdf- and -bib- options are used
           Pdf                  ///  // auto save PDF, defult name: [Author_Year_Title]
             BLank(string)      ///  // Title format: See == Note 1 ==
             NOTItle            ///  // Hansen-2023
             ALTname(string)    ///  // Alternative name: user specified PDF file name, seldom use 
           Bib                  ///  // download and list .ris and bibtex files used for reference managers 
           FASTscihub           ///  // re-search the fast url of SCI-Hub. Seldom use. Time use: 1-2 seconds
           CLEAN                ///  // clean pattern: Display only [link] and [PDF]. Default: [link] (rep), [PDF], [Appendix]
           CLIPoff              ///  // do not send message to clipboard
           Notip                ///  // do not display 'Tips: Text is on clipboard.'
           NOGoogle             ///  // don't display google links
           Doicheck             ///  // get {DOI} using regular expression from text given by user. 
                                ///  // e.g, from 'xxx https://doi.org/{DOI}' to '{DOI}'
        ]   
           
/*
  ==Note 1==: blank(string), where string can be 'bar' or 'keep'
  default: Hansen_2023_The_Crisis
      bar: Hansen-2023-The-Crisis
     keep: Hansen 2023 The Crisis
*/  


preserve //>>>>>>>>>>>>>>>>>>>>>>>>>>>>> preserve begin  

  clear

*-record working directory

  local pwd: pwd 
  
  
*-to be done  2024/1/11 9:03
* auto logfile: record the {DOI}s in a text file 
* Save in folder: 
*    '../_log_DOIs/_log_doi_Date.txt'
* Usage: 
*    users can 'infile' this file and loop {DOI}s to download PDF and .ris  

  
*---------------  
*-options check
*---------------

  if "`all'" != ""{
      local pdf "pdf"
      local bib "bib"
  }
  * Note:    getiref DOI, all 
  *  is same as 
  *          getiref DOI, pdf bib 
  
  if "`altname'" != ""{
      
      local pdf_save = "1"  // downlaod PDF document
      
      local filename "`altname'"
      
      if strpos(`"`altname'"', "/") | strpos(`"`altname'"', "\"){
          dis as error "Invalid filename. You should specify directory in {cmd:path()} option."
          exit 
      }
      if "`notitle'" != ""{
          dis as text "Note: option {cmd:notitle} can only take effect with {cmd:pdf} option"
      }
      
  }  

  if "`blank'" != ""{
      if wordcount("`blank'")>1{
          dis as error "Only one arguments allowed in option {cmd:blank(string)}"
          exit
      }
      if "`blank'"!="bar" & "`blank'"!="keep"{
          dis as error "Only {cmd:blank(bar)} or {cmd:blank(bar)} is allowed"
          exit
      }
  }
  
  if ("`pdf'" != ""){
      local pdf_save = "1"  // downlaod PDF document 'from SCI-HUB'
  }
  
  
  *-check option conflicts
  
  local dis_opt "`md'`md2'`cite'`cite1'`c1'`cite2'`c2'`latex'`wechat'`text'"  
  if wordcount("`dis_opt'")>1{
        dis as error "Options conflict: only one of {cmd:md} / {cmd:latex} / {cmd:cite / {cmd:c2} / {cmd:wechat} / {cmd:text} options is allowed"
        exit
  }
  
  
*-delete " 
  local anything = subinstr(`"`anything'"', `"""', "", .) 
  
  
*---------------  
*- path, SCI-Hub --> .dta of reference
*---------------  

*-Path

  if "`path'" == ""{
      local path "_temp_getref_"
  }
  
  qui get_checkpath "`path'"
  local path "`r(path)'"
 
/*
  // to be done   2024/1/11 9:09
  Sub Folders 
    [PDF_getref_]
    [ris_getref_]
    [log_getref_]
    readme_getref_.txt 
       say soming guides for usage of these files
*/
    
  
*-host of SCI-Hub 

  if ("${sci__hub_}" == "") | ("`fastscihub'" != ""){
      
      cap get_scihub       // get the fast url of SCI-Hub 
      
      if _rc==0{
          global  sci__hub_ "`r(best)'"
      }
      else{
          global  sci__hub_ "http://sci-hub.ren"
      }
  }
   
    
*-get DOI 

  if "`doicheck'" != ""{  // get {DOI} and check validity
  
//    cap noi get_doi `"`anything'"', nodisplay   // old
      cap noi get_doi `anything', nodisplay
      
      if `r(valid)' == 0{
          exit
      }
      else{
          local DOI "`r(doi)'"
      }
  }
  else{
      local DOI "`anything'"
  }


*---------------  
*- download meta data and get meta information 
*--------------- 
//    local DOI "10.1111/j.1467-629X.2010.00375.x"
//    local DOI 10.1111/j.1467-629X.2010.00375.x

   if "`latex'" == ""    local tex_opt ""
   else                  local tex_opt ", `latex'"
       
   get_doidata `DOI' `tex_opt'  // .... download meta data , new 2024/1/8 13:27
                       // suit for both 'crossref' and 'datacite'
   
   local DOI = "`r(DOI)'"
   
  *-text of reference  
    local ref_body = r(ref_body)
    local ref_full = r(ref_full)
    
   qui  set obs 1 
   tempvar v_body
   qui gen strL `v_body' = `"`ref_body'"' 
    
*-filename of PDF document

  *-Get file name of PDF article:
  *    Author-Year-Title
  
    get_au_yr_ti "`ref_body'", doi("`DOI'") 
  
  *-filename of PDF document
    if "`notitle'" == ""{
        local fn_au_year `"`r(au_yr_ti)'"'
    }
    else{
        local fn_au_year `"`r(au_yr)'"'
    }
    
    local ar_title = "`r(title)'"   // Title of the article   
    
  *-transfer to valid filename (delete invalid characters: '* \ / : * ? " < > | ')
    if "`blank'" == ""{
        get_filename "`fn_au_year'"
    }  
    else{
        get_filename "`fn_au_year'", blank(`blank')
    }
  
  if "`filename'" == ""{            // Gomez_2023_The_Effect_of_Mandatory_Disclosure……
      local filename `"`r(fn)'"'
  }
  

    
    
*------------------
*- article page (link) and PDF url 
*------------------

*-Common setting: General Journal articles 

  * article page 
    local link    "https://doi.org/`DOI'"
    local link_br  `"{browse "`link'":Link}"'
    
  * PDF url given by SCI-HUB
    local pdf_web "${sci__hub_}/`DOI'"  // http://sci-hub.ren/ or return by 'get_scihub.ado'  
    local  pdf_br  `"{browse "`pdf_web'":PDF}"'
     
    *-deal with ASCII characters in {DOI}
      
      get_doi_scihub_special  `DOI'           // deal with special characters
      
      local DOI_scihub "`r(doi_scihub)'"
    
      local scihub "https://sci.bban.top/pdf" 
      local pdf_web_full "`scihub'/`DOI_scihub'.pdf"  // full: full screen
      local pdf_br_full  `"{browse "`pdf_web_full'":PDF}"'
  
  *-default: 
    * with PDF doucument 
      local pdf_Yes = 1
    
    * Source of PDF document
      local pdf_source = 0  // "SCI-HUB"
      
    * without replication 
      local rep_Yes = 0
    
    * without appendix 
      local app_Yes = 0
  
 
  

**** Note: 
*   [xxx_web] means [xxx_url]
*   [link]    means the url of article page 
*   [xxx_br]  means the text for displaying as browse pattern in Results Window  
  
*------------------
*- working papers  
*------------------
*-SSRN 
* 10.2139/ssrn.3671850 , 无法直接获取 PDF    
  local key "10.2139/ssrn"
  if strpos(`"`DOI'"', "`key'"){
//       local pdf_web "none"
      local pdf_br  ""
      local pdf_Yes = 0
  }

*-EconPapers
* DOI: 10.32468/Espe.5704 , 无法直接获取 PDF 
  local key "10.32468/Espe"
  if strpos(`"`DOI'"', "`key'"){
//       local pdf_web "none"
      local pdf_br  ""
      local pdf_Yes = 0
  }
  
  
*-arXiv          with PDF
* DOI: 10.48550/arXiv.2312.05400  -->  10.48550/arXiv.{ID}  
  local key "10.48550/arXiv"
  if strpos(`"`DOI'"', "`key'"){
      local ar_ID = subinstr("`DOI'", "`key'.", "", 1)  // get: 2312.05400 ({article ID})
      local pdf_web "https://arxiv.org/pdf/`ar_ID'.pdf"
      local pdf_source = 1  // non SCI-HUB
      local rep_web "https://arxiv.org/e-print/`ar_ID'"
      local rep_br  `"{browse "`rep_web'":Sources}"'    // 参考文献 .bibtex, 原始 .tex 文档等
      local rep_Yes = 1 // replication Data & Codes (may has)
  }
  
*-NBER           with PDF
* DOI: 10.3386/w31184  -->  10.3386/{ar_ID}
* PDF: https://www.nber.org/system/files/working_papers/{ID}/{ID}.pdf
* - e.g. https://www.nber.org/system/files/working_papers/w31184/w31184.pdf
  local key "10.3386/"
  if strpos(`"`DOI'"', "`key'"){
      local ar_ID = subinstr("`DOI'", "`key'", "", 1)  // get: w31184 ({article ID})
      local pdf_root "https://www.nber.org/system/files/working_papers"
      local pdf_web "`pdf_root'/`ar_ID'/`ar_ID'.pdf"
      local pdf_source = 1  // non SCI-HUB
  }  
     
*---------------------
*- Open Access Journal  
*---------------------
*-QE 
* DOI: 10.3982/QE1288
* PDF: https://onlinelibrary.wiley.com/doi/epdf/10.3982/QE1288
  local key "10.3982/QE"
  if strpos(`"`DOI'"', "`key'"){
      local link "https://onlinelibrary.wiley.com/doi/`DOI'"
      local pdf_root "https://onlinelibrary.wiley.com/doi/epdf"
      local pdf_web "`pdf_root'/`DOI'"
      local pdf_source = 1  // non SCI-HUB
  } 
  
*-Stata Journal  
* DOI: 10.1177/1536867
* PDF: https://journals.sagepub.com/doi/pdf/10.1177/1536867X20909689
*      https://journals.sagepub.com/doi/pdf/10.1177/1536867X1801800409
  local key "10.1177/1536867"
  if strpos(`"`DOI'"', "`key'"){
      local link "https://journals.sagepub.com/doi/`DOI'"
      local pdf_root "https://journals.sagepub.com/doi/pdf"
      local pdf_web "`pdf_root'/`DOI'"
      local pdf_source = 1  // non SCI-HUB
  }   
  
  
/* 2022年以前的都可以通过 SCI-HUB 获取，只有最近两年的需要特别处理
*-American Journal of Political Science (open access)
* DOI: 10.1111/ajps
* PDF: https://onlinelibrary.wiley.com/doi/pdf/10.1111/ajps.12808  
  local key "10.1111/ajps"
  if strpos(`"`DOI'"', "`key'"){
      local link "https://onlinelibrary.wiley.com/doi/`DOI'"
      local pdf_root "https://onlinelibrary.wiley.com/doi/pdf/"
      local pdf_web "`pdf_root'/`DOI'"
      local pdf_source = 1  // non SCI-HUB
  }  */ 
  
*-TBD: add more Journals with Open Access
/* Open Access Journal list
   view browse "https://openaccesspub.org/about"
   
* wiley.com: Browse Fully Open Access Journals   
   https://authorservices.wiley.com/open-research/open-access/browse-journals.html
   
* sagepub.com 
   https://journals.sagepub.com/doi/pdf/10.1177/1536867X231212425  

* https://wires.onlinelibrary.wiley.com/   
   https://wires.onlinelibrary.wiley.com/doi/full/10.1002/wrna.1824
   
* https://www.tandfonline.com/doi/full/10.1080/10705511.2022.2131555   
   
*/

  
*-----------------  
*-Online Appendix and/or Replication (Codes & Data)
*-----------------

* general case 
  local app_url = ""   // 'app' means 'Appendix'
  local app_br  = ""
  local app_Yes = 0
  local rep_Yes = 0    // 'rep' means 'Replication'
  
* AEA journals
// Most journals in 'American Economic Association' 
// provide data & codes for replication, and online appendix. 
// - DOI start with '10.1257' is a journal under AEA.
// - The URL of online appendix for AEA journals:
//   https://www.aeaweb.org/doi/{DOI}.appx
*---------------
// e.g. [*American Economic Review*](https://www.aeaweb.org/journals/aer)
//   - DOI: 10.1257/aer.20210710
//   - Appendix: `https://www.aeaweb.org/doi/{DOI}.appx`
//   - e.g. <https://www.aeaweb.org/doi/10.1257/aer.20210710.appx>
  local key "10.1257/"  // AEA Journals, e.g. AER
  if strpos("`DOI'", "`key'"){
      local app_url "https://www.aeaweb.org/doi/`DOI'.appx"
      local app_Yes = 1 // with appendix 
      local rep_Yes = 1 // replication Data & Codes (may has)
  }  
  
*-arXiv
  local key "10.48550/arXiv"
  if strpos(`"`DOI'"', "`key'"){
      local rep_Yes = 1
  }  
 
*-JPE, JLE
// **JPE** Journal of Political Economy: [Supplemental Material](https://www.journals.uchicago.edu/toc/jpe/current)
//   - DOI: 10.1086/xxx
//   - PDF: https://www.journals.uchicago.edu/doi/epdf/{DOI} 
//   - Supp: https://www.journals.uchicago.edu/doi/suppl/10.1086/725171  
 
  local key "10.1086/"   // JPE, JLE
  if strpos("`DOI'", "`key'"){
      local app_url  "https://www.journals.uchicago.edu/doi/suppl/`DOI'"
      local app_Yes = 1 // with appendix 
      local rep_Yes = 1 // may has replication Data & Codes
  }  
  

*---------------------------
* Journals with replications

  #delimit ;
    local jlist 
         "
          10.48550/arXiv
          10.1257/
          10.1086/
          10.3982/ECTA 
          10.1016/j.eneco 
          10.1111/jofi
          10.1016/j.jfineco 
          10.1093/rfs
          10.15456/jbnst
          10.18637/jss
          10.1371/journal.pone
          10.1093/qje
          10.1002/jae
          10.1016/j.red
          10.1093/ej
          10.1093/restud
          10.1016/j.euroecorev
          10.3982/QE 
         " ;
  #d cr 

  foreach jj of local jlist{
      if strpos("`DOI'", "`jj'"){    
          local rep_Yes = 1 // may has replication Data & Codes
      }
  }
  
  
* Important!!!!!!  
*-------------------
*- export reference: Markdown, LaTeX or plain text 
*------------------- 
*  text to be displayed as links  

* md2: add a blank to url in Markdown text
  if "`md2'" != ""     local a_blank " "
  else                 local a_blank ""
  
* Link: article page 
//      local link    "https://doi.org/`DOI'"
//      local link_br  `"{browse "`link'":Link}"'
        local link_md      `" [Link](`a_blank'`link'`a_blank')"'
        local link_md_dis  `" [`link_br'](`a_blank'`link'`a_blank')"'
        local link_tex     `" \href{`link'}{Link}"'
        local link_tex_dis `" \href{`link'}{`link_br'}"'
        local link_plain   `" Link: `link'"'   

* PDF 
    if `pdf_Yes' == 1{
        local pdf_br      `"{browse "`pdf_web'":PDF}"' 
        local pdf_md      `", [PDF](`a_blank'`pdf_web'`a_blank')"'
        local pdf_md_dis  `", [`pdf_br'](`a_blank'`pdf_web'`a_blank')"'
        local pdf_md_full `", [PDF](`a_blank'`pdf_web_full'`a_blank')"'  // only for SCI-HUB
        local pdf_tex     `", \href{`pdf_web'}{PDF}"'
        local pdf_tex_dis `", \href{`pdf_web'}{`pdf_br'}"'
        local pdf_plain   `", PDF: `pdf_web'"'
    }
    else{
        local pdf_br      ""
        local pdf_md      ""
        local pdf_md_dis  ""
        local pdf_md_full ""
        local pdf_tex     ""
        local pdf_tex_dis ""
        local pdf_plain   ""      
    }

  
* replication 
   if `rep_Yes' == 1{
       local _rep " (rep)"
   }
   else{
       local _rep ""
   }
   
* Appendix   
   if `app_Yes' == 1{
       local app_br      `"{browse "`app_url'":Appendix}"' 
       local app_md      `", [Appendix](`a_blank'`app_url'`a_blank')"'
       local app_md_dis  `", [`app_br'](`a_blank'`app_url'`a_blank')"'
       local app_tex     `", \href{`app_url'}{Appendix}"'
       local app_tex_dis `", \href{`app_url'}{`app_br'}"'
       local app_plain   `", Appendix: `app_url'"'       
   }
   else{
       local app_br      ""
       local app_md      ""
       local app_md_dis  ""
       local app_tex     ""
       local app_tex_dis ""
       local app_plain   ""
   }    
   
*-Google scholar link  

  if "`nogoogle'" == ""{
      local google_head  "https://scholar.google.com/scholar?q="
      local google_url  `"`google_head'`ar_title'"'
      
// Google url need not encode. 
// The drawback of encoding is that if the length of "`at_title_encode'" 
// exceeds 254 digits, which is the max limit of 'dis {browse ....}', 
// an error message will be reported 
   // the URL in 'browse' cmd is limited in 253 digits
      local google_url_trim = substr(`"`google_url'"', 1, 253) 
     
// Encoding version: used for displaying as plain text
      mata: st_local("google_url_encode", urlencode(`"`google_url'"'))
      local google_url_encode_trim = substr(`"`google_url_encode'"', 1, 253) 
      
      local google_br      `"{browse `"`google_url_trim'"':Google}"'
      local google_md      `", [Google](`a_blank'<`google_url'>`a_blank')"'
      local google_md_dis  `", [`google_br'](`a_blank'<`google_url'>`a_blank')"'
      local google_tex     `", \href{`google_url'}{Google}"'
      local google_tex_dis `", \href{`google_url'}{`google_br'}"'
      local google_plain   `", Google: `google_url_encode_trim'"'         
  }
  else{
      local google_br      ""
      local google_md      ""
      local google_md_dis  ""
      local google_tex     ""
      local google_tex_dis ""
      local google_plain   ""
  }
  
  
  
*---------------------------
*-Display in Results Window  
*---------------------------

*-clean option
  if "`clean'" != ""{
      local _rep      ""
      local google_br ""
      local app_br    ""
      
      local keylist "md tex plain"
      foreach key of local keylist{
          local app_`key'          ""
          local app_`key'_dis      ""
          local google_`key'       ""
          local google_`key'_dis   ""
      } 
  }
  
*-Default format: 
* == Author, Year, Title, Journal, Vol(Issue): pages. 'link', 'PDF-url'.
      
      noi dis "  "  // add a blank line
      
      noi dis as text `"`ref_body'"'
      noi dis as text _col(5) `"`link_br'`_rep'"'  ///
                     _skip(4) `"`pdf_br'"'         ///
                     _skip(4) `"`google_br'"'      ///
                     _skip(4) `"`app_br'"'         ///
                     _n  
                     
      local refout = `"`ref_body'"'

      
* ??????????????????????????????????????????????
* 这两行好像没什么用了 2024/1/1 0:15    ???????
* ??????????????????????????????????????????????
  local ref_link_pdf       `"`ref_body' `link_br', `pdf_br'"'
  local ref_link_pdf_full  `"`ref_body' `link_br', `pdf_br_full'"'      
      
  
*-Options for display in Results Window  
  
  *-Markdown 
* Link: article page 
      
        
  if "`md'`md2'" != ""{     // [text](URL)    
      local refout  `"`ref_body'`link_md'`_rep'`pdf_md'`app_md'`google_md'."' 
      local refdis  `"`ref_body'`link_md_dis'`_rep'`pdf_md_dis'`app_md_dis'`google_md_dis'."' 
      dis as text `"`refdis'"'
  } 
  
  *-LaTeX

  if "`latex'" != ""{  // \href{text}{URL}
      local refout  `"`ref_body'`link_tex'`_rep'`pdf_tex'`app_tex'`google_tex'."' 
      local refdis  `"`ref_body'`link_tex_dis'`_rep'`pdf_tex_dis'`app_tex_dis'`google_tex_dis'."' 
      dis as text `"`refdis'"'
  } 
  
  *-Plain tet
  if ("`wechat'" != "") | ("`text'" != ""){ 
      local refout  `"`ref_body'`link_plain'`_rep'`pdf_plain'`app_plain'`google_plain'"' 
      dis as text `"`refout'"'
      *dis as text _col(5) `"`link_br'"'  _col(15) `"`pdf_br'"'
  } 
  

  
*---------------
*- export: cite   Author (Year)
*---------------  
// set trace on 
  if "`cite'" != ""{
      get_cite `v_body', doi("`DOI'") link `latex'         // author (Year), with link
  }
  if "`c1'" != "" | "`cite1'" != ""{                       // intext, with link
      get_cite `v_body', doi("`DOI'") link intext `latex'  // (author, Year)
  }  
  if "`c2'" != "" | "`cite2'" != ""{              // plain text, no link
      get_cite `v_body', doi("`DOI'")      
  }
  if "`cite'`c1'`cite1'`c2'`cite2'" != ""{
      local refout "`r(cite)'"
      noi dis as text `"`refout'"'
      noi dis as text _col(5) `"`link_br'"'  _skip(6) `"`pdf_br'"'
      return add      
  }

  
  
*------------------             ------------
*-download and display links of PDF document
*------------------             ------------

  if "`pdf'" != "" & ("`dis_opt'") == ""{
      local refout "`ref_body' `link'"
  }
  
  if ("`pdf_save'"=="1"){ // want to save and have PDF
      if `pdf_Yes'==0{
          dis as error `"{cmd:Warning}: Failed to downland PDF document for {browse "`link'":`DOI'}"'
          dis as text `"{cmd:Maybe}, you can save it by hand at the {browse "`link'":{ul:article page}} using filename:"'
          dis as text _skip(2) `"{cmd:`filename'}"'
      } 
      else{
          if `pdf_source' == 0{ // from SCI-HUB
              cap noi get_pdf_scihub    "`DOI'", saving("`filename'") path("`path'")
              
              * Stata Journal: Some paper is open-access
              if `r(pdf_got)'==0 & strpos("`DOI'", "10.1177/1536867"){
                  local pdf_source = 1
              }
          }
          else{
              get_pdf_nonSCIHUB "`DOI'", saving("`filename'") path("`path'")            
          }
           
//           return local pdfurl `"`r(pdfurl)'"'
          
      }
  } 



*---------------------   
*- .bibtex, .ris files 
*---------------------

  if "`bib'" != ""{
      
      get_bib `DOI', path("`path'") `notip'
      
      local got_bib = `r(got_bib)'
      local bibtex "`r(bibtex)'"
      local ris    "`r(ris)'"        

  }  
     
  *-send to CLIP

    if "`clipoff'" == ""{
        dis " "
        get_clipout "`refout'", `clipoff' `notip'  
    }

    
*-----------------    
*-display filename for saving by hand 
*-----------------

  if "`disfn'" != ""{
      dis " "
      dis `"`filename'"' 
      
      *-send to CLIP
      if "`clipoff'" == ""{
          get_clipout "`filename'", `clipoff' notip
      }       
  }
  

*--------------   
*-return values 
*--------------

  get_au_yr_ti "`ref_body'", doi("`DOI'") 

  return local au_yr "`r(au_yr)'"
  return local au_yr_ti "`r(au_yr_ti)'"
  return local au_yr_doi "`r(au_yr_doi)'"
   
  return local link_br      = `"`link_br'"'
  return local pdf_br       = `"`pdf_br'"'
  return local pdf_br_full  = `"`pdf_br_full'"'
  return local ref_link_pdf = `"`ref_link_pdf'"'
  return local ref_link_pdf_full = `"`ref_link_pdf_full'"'
  return local refdis   "`refdis'"
  
  return local AD "-------- Below: advanced values --------"
  
  return scalar with_app = `app_Yes'
  return scalar with_rep = `rep_Yes'
  
  if "`bib'"!=""{
      return scalar got_bib = `got_bib'
      return local bibtex   "`bibtex'"
      return local ris      "`ris'"      
  }    
  if "`pdf'"!="" return scalar got_pdf = `pdf_Yes'

  return local pdf_web `"`pdf_web'"'
  return local ref      "`refout'"
  return local refbody  `"`ref_body'"'
  return local link     "`link'" 
  return local filename "`filename'"
  return local title    "`r(title)'"
  return local year     "`r(year)'"
  return local author1  "`r(author)'"
  return local doi      "`DOI'"
 
restore //>>>>>>>>>>>>>>>>>>>>>>>>>>>>> preserve over

end 



*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*                            over 
*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>




*------------------ subprogram ------------- get_doi.ado
cap program drop get_doi
program define get_doi, rclass
version 14

*  input: reference text including {DOI} information 
* output: {DOI} saved in r(doi)

syntax anything [, Display aregex]

    if "`aregex'" == ""{
        local regex `"10\.\d{4,9}[^\s]+[^",，。（）()<>`'\s]"' 
    }        
    else{
        local regex "10\.[\d]{4,}/[^\s]+[\d]"  // regular expression of {DOI}
    }
    
    local m = ustrregexm(`"`anything'"', `"`regex'"')
    
    if `m'==0{
        dis as error "Can not find valid {DOI}, please check."
        return scalar valid = `m'
        exit 
    }
    else{
        local doi = ustrregexs(0)
        if "`display'" != ""{
            noi dis "`doi'"
        }
        *-Return values 
          return local  doi = "`doi'"  
          return scalar valid = `m'  // 1 = get valid DOI, 0 = otherwise
    }

end 


*------------------ subprogram ------------- get_doiserver.ado
* version 1.1  08jan2024
* Yujun Lian,  arlionn@163.com
*
*== Goal: 
*   return the 'server' of {DOI}. e.g, Crossref, Datacite 

*  input: {DOI}
* output: server name 

*== Usage:
*  doiserver "10.5281/zenodo.1308060"  
*  ret list 

* 平均耗时：0.15s
*--------------------------- get_doiserver.ado -------------- 0 ------------
cap program drop get_doiserver
program define   get_doiserver, rclass

syntax anything(name=doi) [, Display]

// local doi 10.48550/arXiv.2312.05400

gettoken doi_head: doi , parse(/)  //    '10.48550/arXiv.2312.05400' 
                                   // to '10.48550'

local url "https://doi.org/`doi_head'"
  
cap mata: mata drop urlText 
mata: urlText = cat("`url'")  

*-to be done: get the name of SERVER
mata: is_server_name = ustrregexm(urlText, `".*10.SERV/([\w]+)</td></tr>"')
mata: sub_sample = select(urlText, is_server_name:==1)
mata: server = ustrregexra(sub_sample, `".*10.SERV/([\w]+)</td></tr>"', `"$1"')
mata: st_local("server", server)

local is_crossref = ("`server'" == "CROSSREF")
local is_datacite = ("`server'" == "DATACITE")

if "`display'" != ""{
    dis as text "SERVER: `server'"
}

return local  url    "`url'"
return local  server "`server'"
return scalar is_crossref = `is_crossref'
return scalar is_datacite = `is_datacite'

end 
*--------------------------- get_doi_server.ado -------------- 1 ------------
/*
* === test 

global doi "10.5281/zenodo.1308060"        // datacite
global doi "10.48550/arXiv.2312.05400"     // datacite 
global doi "10.13140/rg.2.2.18135.01449"   // datacite
global doi "10.1016/j.eneco.2023.107287"   // crossref
global doi "10.1126/science.169.3946.635"   // crossref
global doi "10.1016/j.jhealeco.2015.10.004" // crossref

get_doiserver $doi, dis 
ret list

. get_doiserver $doi, dis 
SERVER: DATACITE

. ret list

scalars:
        r(is_datacite) =  1
        r(is_crossref) =  0

macros:
             r(server) : "DATACITE"
                r(url) : "https://doi.org/10.48550"      
*/



*------------------ subprogram ------------- get_doidata.ado

*  version 1.1 2024/1/7 23:17
*    suit for both 'crossref' and 'datacite'
*  version 1.0 2023/12/23 18:06

cap program drop get_doidata
program define get_doidata, rclass

*  input: {DOI}
* output: local `ref_body' and `ref_full' with meta data for given {DOI} 

syntax anything(name=DOI) [, Display Latex]

preserve 

// ========= datacite =====
* API: 
  local head         "https://data.crosscite.org"
  local mine         "text/x-bibliography"
  local style        "apa"             // abb of style 
  local styleexp     "?style=`style'"  // expression of style
  local url_datacite "`head'/`mine'/`DOI'`styleexp'"


// ========= crossref =====
*-API and MIME from <api.crossref.org>
* url: https://github.com/CrossRef/rest-api-doc#resource-components
  
  local API   "http://api.crossref.org/works"
  local trans "transform/text/x-bibliography"   
  local url_crossref "`API'/`DOI'/`trans'"

  
// ========= copy webdata to .txt 
  * S1: copy data using Crossref's API
  * S2: if failed, copy data using Datacite's API
  
  tempfile doi_ref 
  cap qui copy `"`url_crossref'"'  "`doi_ref'.txt", replace   // crossref
  
  if _rc==0{
      local server "CROSSREF"
  }
  else{                    // can not get meta data: first time ('crossref')
    *-check/get the DOI
      cap noi get_doi `DOI', nodisplay
      
      if `r(valid)' == 0{
          dis as error `"Invalid DOI. See {browse "https://www.doi.org/the-identifier/what-is-a-doi/":DOI-1}, {browse "https://academicguides.waldenu.edu/library/doi":DOI-2} or {browse "https://www.doi.org/the-identifier/resources/handbook":DOI-Handbook} for details."'
          exit 198
      }
      else{
          local DOI "`r(doi)'"  // valid DOI
          local url_crossref "`API'/`DOI'/`trans'"
          cap qui copy `"`url_crossref'"'  "`doi_ref'.txt", replace   // crossref
          
          if _rc==0{
              local server "CROSSREF"
          }
          else{
               qui get_doiserver `DOI'       // get agency server of {DOI}
               
               local server "`r(server)'"
               
               if `r(is_crossref)' == 1{
                   get_error_doi_data `DOI'  // show error message 
               }
               else if `r(is_datacite)' == 1{
                   cap qui copy `"`url_datacite'"'  "`doi_ref'.txt", replace   // datacite  
                   if _rc{       // can not get meta data: second time ('datacite')
                       get_error_doi_data `DOI'
                   }
               }
               else{
                   get_error_doi_data `DOI', only simple          
               }
          }
      }
  }
 
*-save as .dta
  tempvar v_ref
  qui infix strL `v_ref' 1-1000 using "`doi_ref'.txt", clear


*-deal with special characters
  * e.g. for crossref
  *       "growth and <scp>energy</scp>, R&amp;D Exp, Business &amp; Economics"
  *                   -----      ------   -----                -----
  * e.g. for datacite
  *       "<i>Generalized difference-in-differences</i>" 
  *        ---                                     ---- 
  *  "<i>Xxxx</i>"  to  "Xxxx"
  
  qui replace `v_ref' = ustrregexra(`v_ref', `"<i>(.*)</i>"', `"$1"')  

  local regex "(<\/?.+?>)"
  qui replace `v_ref' = ustrregexra(`v_ref', `"`regex'"', "", 1)
    
  local regex "&amp;"
  qui replace `v_ref' = subinstr(`v_ref', `"`regex'"', "&", .)

  if "`latex'"!=""{  // update: 2024/1/13 18:14
      local regex "&"
      qui replace `v_ref' = subinstr(`v_ref', "`regex'", "\&", .)      
  }

*-Author names: from 'ALL Upper' to 'Proper' 
  * e.g.   GOLDSTEIN, I., YANG, S., & ZUO, L. (2023)
  *  to    Goldstein, I., Yang, S., & Zuo, L. (2023).
  
  * All authors
    tempvar au
    qui split `v_ref', parse(`". ("') gen(`au')
    qui replace `au'1 = ustrtitle(`au'1) // From: HÉMET, C., & MALGOUYRES, C. (2017)
                                         //   To: Hémet, C., & Malgouyres, C. (2017)
    qui replace `v_ref' = `au'1 + ". (" + `au'2
    qui cap drop `au'*  
  
*-full meta data (citation)  
  local ref0 = `v_ref'[1]    // the meta data
  
*-delete trailing blanks
  local ref0 = strrtrim(`"`ref0'"') 

*-delete special characters (e.g., '\t', '\n')
  local ref0 = subinstr(`"`ref0'"', char(9),  "", .)  // 去掉制表符
  local ref0 = subinstr(`"`ref0'"', char(10), "", .)  // 去掉换行符
  local ref0 = subinstr(`"`ref0'"', char(13), "", .)  // 去掉回车符
  local ref0 = subinstr(`"`ref0'"', char(12), "", .)  // 去掉换页符
  local ref0 = subinstr(`"`ref0'"', char(11), "", .)  // 去掉垂直制表符
  local ref0 = subinstr(`"`ref0'"', char(0),  "", .)  // 去掉空字符
  local ref0 = subinstr(`"`ref0'"', char(8),  "", .)  // 去掉退格符  

*-shorter Journal name
  * From: The Stata Journal:Promoting Communications on Statistics and Stata"
  *   To: The Stata Journal"
  * local regex ": Promoting Communications on Statistics and Stata"
    local regex ":[\s]?Promoting.*on .*and Stata"
    local ref0 = ustrregexra(`"`ref0'"', `"`regex'"', "", 1) 
   
*-ref_body, ref_full   
  
  local regex " http[s]?://.+"
  local ref_body = ustrregexra(`"`ref0'"', `"`regex'"', "", 1) 
    
*-display 
  if "`display'" != ""{
      dis `"`ref0'"' 
  }    
    
*-return value 
  return local ref_full  `"`ref0'"'
  return local ref_body  `"`ref_body'"'
  return local url       `"`url'"'
  return local DOI       `"`DOI'"'
  return local server    "`server'" 
    
restore

end     

/*  === test ===

global DOI "10.1111/j.1467-629X.2010.00375.x"
global DOI "10.1016/j.jeconom.2020.06.003"
global DOI "10.1111/1475-679X.12496"   // GOLDSTEIN, I., YANG, S., & ZUO, L. (2023).
global doi "10.48550/arXiv.2312.05400" // datacite 
global doi "10.14454/fxws-0523"        // datacite 

// set trace on 
get_doidata $doi
ret list 

get_doidata $doi, dis
ret list 
dis "|`r(ref_body)'|"
dis "|`r(ref_full)'|"
*/  



*------------------ subprogram ------------- get_error_doi_data .ado 
cap program drop get_error_doi_data      
program define get_error_doi_data, rclass

syntax anything(name=DOI) [, Simple Only]

    dis as error `"Failed to get data for DOI: {cmd:`DOI'}. Visit {browse "https://doi.org/`DOI'":{ul:article page}}"'
    
    if "`only'" !=""{
        dis as error `"Only DOI with agency {browse "https://project-thor.readme.io/docs/who-are-datacite-and-crossref":{ul:crossref}} or {browse "https://project-thor.readme.io/docs/who-is-crossref":{ul:datacite}} is supported. See {browse "https://www.doi.org/the-community/existing-registration-agencies/":DOI Servers} for details"'
    }
    
    if "`simple'" == ""{
        dis as error `"Check the validity of DOI at {browse "https://doi.org/`DOI'":doi.org}, or try it later."'
    }

    exit 601
    
end 




*------------------ subprogram ------------- get_au_yr_ti.ado 
* version 1.2  change the input from 'varname' to 'string' (ref_full)
* 2023/12/23 16:41

cap program drop get_au_yr_ti
program define get_au_yr_ti, rclass

*  input: {DOI}
* output: filename --> Author-Year-Title

syntax anything [, DOI(string) doifn ]

preserve 

*-delete " 
  local anything = subinstr(`"`anything'"', `"""', "", .) 

*-begin
    local ref_body = `"`anything'"' // reference 
    
    * First Author
//       tempvar au
//       qui split `varlist', parse(,) gen(`au')
      local regex `"(^.+?),"'
      if ustrregexm(`"`ref_body'"', "`regex'"){
          local author = ustrregexs(1) 
      }
      else{
          local author = ""
      }
      
    * Year
      local regex   = `"(?<= \()(\d\d\d\d)(?=\))"'
      if ustrregexm(`"`ref_body'"', "`regex'"){
          local year = ustrregexs(0) 
      }
      else{
          local year = ""
      }
      
    * Title
      local regex `"(?<=\).\s)(.+)(?=[\.\?]\s)"'
      if ustrregexm(`"`ref_body'"', "`regex'"){
          local title = ustrregexs(1) 
      }  
      else{
          local title = ""
      }
      
    * Title: delete special characters       
    * doifn: transfer {DOI} to valid 'filename'
//      "10.1111/j.1467-629X.2010.00375.x" 
// to
//      "10.1111_j.1467-629X.2010.00375.x"    //  "`doifn'" == ""
//      "10_1111_j_1467-629X_2010_00375_x"    //  "`doifn'" != ""
      if "`doi'" != ""{
          if "`doifn'" != ""{
              local doi = ustrregexra(`"`doi'"', "[^0-9a-zA-Z-]", "_") 
          }
          else{
              local doi = ustrregexra(`"`doi'"', "/", "_") 
          }  
          local au_yr_doi = `"`author'-`year'-`doi'"'
      }
      else{
          local au_yr_doi = `"`author'-`year'"'
      }


    * return values 
      return local au_yr_doi = `"`au_yr_doi'"'
      return local au_yr_ti = `"`author' `year' `title'"'
      return local au_yr  = "`author' `year'"
      return local title  = "`title'"
      return local year   = "`year'"
      return local author = "`author'"
     
restore

end

/*
// new version: 2023/12/23 17:33
global doi "10.1111/j.1467-629X.2010.00375.x"
global doi 10.1111/j.1467-629X.2010.00375.x
get_doidata $doi
ret list 
global ref_body "`r(ref_body)'"
get_au_yr_ti "$ref_body", doi($doi)
ret list 
get_au_yr_ti "$ref_body", doi($doi) doifn
ret list 
*/



*------------------ subprogram -------------get_filename.ado
* version 1.0 29dec2023
* this is a simplified version of 'getfn.ado'

// Goal: delete/replace invalid characters in 'filename' (fn)
// The default invalid characters in filenames
                    * \ / : * ? " < > | 
// Source: https://learn.microsoft.com/en-us/windows/win32/fileio/naming-a-file

cap program drop get_filename 
program define   get_filename, rclass

syntax anything(name=filename) [, Delete(string) Blank(string)]

  *-user specified characters to be deleted 
    if "`delete'" != ""{
        local delete = subinstr("`delete'", " ", "",.)
    }  
  
  *-replace invalid characters with 'blanks'
    local filename = ustrregexra(`"`filename'"', `"[",，\\/:\*\?<>|`delete']"', " ")
    local filename = ustrregexra(`"`filename'"', `"  "', " ")
    local filename = ustrregexra(`"`filename'"', `"  "', " ")
  
  *-delete leading and trailing blanks  
    local filename = strtrim(`"`filename'"')
    
  *-option -blank(string)-: replace blank with '-'; default: '_'
    * option blank()
    * "_"  default, if user do not specify option -blank-, i.e., "`blank'"==""
    * " "  blank(keep)
    * "-"  blank(bar)    
    if "`blank'" == ""{
        local reblank "_"
    }
    if "`blank'" == "bar"{
        local reblank "-"
    }
    if "`blank'" == "keep"{
        local reblank " "
    }
   
    *-replace blank
      local fn = ustrregexra("`filename'", "\s", "`reblank'") 
      
  *-return value  
      return local fn "`fn'"   // return value, nb: No Blank  

end 




*------------------ subprogram -------------get_cite.ado

/*
test:
global DOI "10.1093/rfs/hhs072" 
global DOI "10.1257/aer.109.4.1197"  
global DOI "10.1016/j.jeconom.2020.10.012"  // 2 authors
get_cite body, doi("$DOI") 
ret list 
get_cite body, doi("$DOI") link
ret list 
*/

cap program drop get_cite
program define get_cite, rclass

*  input: {DOI}
* output: Author (Year)

syntax varname , DOI(string) [Link Intext Latex]

preserve 

    local ref_body = `varlist'[1] // reference 
    
    local DOI "`doi'"
    
  * Year
    local regex   = `"(?<= \()(\d\d\d\d)(?=\))"'
    if ustrregexm(`"`ref_body'"', "`regex'"){
        local year = ustrregexs(0) 
        local year_link = "[`year']()]"
    }
    else{
        local year = ""
    }    
  
  * First Author
    tempvar au
    qui split `varlist', parse(,) gen(`au')
    local au_1 = `au'1[1]    
    cap drop `au'*
    
  * All authors
    tempvar au aulist 
    qui split `varlist', parse(`". ("') gen(`au')
    qui gen `aulist' = `au'1
    local authors = `au'1[1]
    cap drop `au'*
      
  *-Number of authors    
    local n_authors = length("`authors'") - length(subinstr("`authors'", ".,", "", .))
    local n_authors = `n_authors'/2 + 1

  *-get Author 2
    tempvar au au_u
    if `n_authors' == 2{
        replace `aulist' = subinstr(`aulist', "\", "", .)
        qui split `aulist', parse(`" & "') gen(`au')
        qui split `au'2, parse(,) gen(`au_u')
        local au_2 = `au_u'1[1]
    }
    
  *-Link
    if "`link'" != ""{
        local art_link "https://doi.org/`DOI'"
        local pdf_web  "${sci__hub_}/`DOI'"     // http://sci-hub.ren/ or return by get_scihub.ado
        
        if "`latex'"==""{  // link with Markdown format
            local au_1 "[`au_1'](`art_link')"
            local year "[`year'](`pdf_web')"
        }
        else{
            local au_1 "\href{`art_link'}{`au_1'}"
            local year "\href{`pdf_web'}{`year'}"            
        }
        
    }
    
  *-cite format 
  
    if `n_authors' == 1{       // Hansen (2023)
         if "`intext'" == ""  local cite "`au_1' (`year')"
         else                 local cite "(`au_1', `year')"
    }       
    else if `n_authors' == 2{  // Hansen and Levin (2023)
         if "`intext'" == ""  local cite "`au_1' and `au_2' (`year')"         
         else                 local cite "(`au_1' and `au_2', `year')" 
    }
    else{  // #(authors)>=3     Hansen et al. (2023)
         if "`intext'" == ""  local cite "`au_1' et al. (`year')"
         else                 local cite "(`au_1' et al., `year')"
    }
    
    if `n_authors' == 2{
        return local au2 "`au_2'" 
    }
    else{
        return local au2 " " 
    }
    
  *--------------  
  * return values 
    
    return scalar n_authors = `n_authors'
    return local au1        = "`au_1'"
    return local year       = "`year'"
    return local authors    = "`authors'"
    return local cite       = "`cite'"
     
restore

end




*------------------ subprogram ------------- get_doi_scihub_special.ado

* version 1.0, 17Dec2023
* Yujun Lian, arlionn@163.com

*-Goal: transfer special characters in {DOI} to ASCII 
*       get {url} of PDF documents using SCI-HUB    

*- input: {DOI}
*-output: 
*         {DOI_scihub}
*         "`scihub'/`DOI_scihub'`suffix'"   (url of PDF)

cap program drop get_doi_scihub_special
program define   get_doi_scihub_special, rclass
 
syntax anything(name=DOI) [, View] 

local DOI = subinstr(`"`DOI'"', `"""', "", .)  // 去掉多余的引号

// local DOI "10.1177/1536867X1101100308"
// local DOI "10.1111/j.1467-629X.2010.00375.x"
  
  *-deal with ASCII characters in {DOI}
  * '10.1016/0304-4076(74)90034-7'            --> 
  * '10.1016/0304-4076%252874%252990034-7'
  *
  * '10.1177/1536867x19830921'    -->
  * '10.1177%2F1536867x19830921'
  *         ---
  // URL --> percent-encoded ASCII format
  // mata: st_local("DOI_ascii", urlencode(`"`DOI'"')) 
  
mata: st_local("DOI_test", urlencode("`DOI'"))

*-number of '%': special characters 
local n_per = length("`DOI_test'") - length(subinstr("`DOI_test'", "%", "", .))

*-lowering
  if `n_per' > 1{
      local DOI_lower = lower("`DOI'")
  }
  else{
      local DOI_lower = "`DOI'"
  }
  
*-URL --> percent-encoded ASCII format
if `n_per' == 1 & strpos("`DOI_test'", "%2F")>0{
    local DOI_scihub = "`DOI'"
}
else{
    mata: st_local("DOI_ascii", urlencode("`DOI_lower'")) 
    
    local DOI_ascii  = subinstr("`DOI_ascii'", "%2F", "/"  , 1)  // '%2F' --> '/'
    local DOI_scihub = subinstr("`DOI_ascii'", "%"  , "%25", .)  // '%28'   --> '%2528'    
}

*-PDF link of SCI-HUB
  local scihub "https://sci.bban.top/pdf" 
  local pdf_scihub "`scihub'/`DOI_scihub'.pdf"
  local pdf_scihub_br = `"{browse "`pdf_scihub'" : PDF}"'
  
*-view 
  if "`view'" != ""{
      dis `"`pdf_scihub_br'"' 
  }
  
*-return values 
  return local scihub = "`scihub'"
  return local pdf_scihub_br = `"`pdf_scihub_br'"'
  return local pdf_scihub = "`pdf_scihub'"
  return local doi_ascii  = "`DOI_ascii'"    // Stata 格式
  return local doi_scihub = "`DOI_scihub'" 

end  
/*
*--- Test ----
set trace on 
local DOI "10.1002/1521-3951(200101)223:1<293::AID-PSSB293>3.0.CO;2-N"
get_doi_scihub_special "`DOI'"
ret list 

get_doi_scihub_special "`DOI'", view
ret list 

cls 
set trace on
local DOI "10.1177/1536867X1101100308"
get_doi_scihub_special "`DOI'", view
ret list 
*/



*------------------ subprogram -------------get_pdf_scihub.ado

* version 1.2 2023/12/24 11:10
* chg: sometimes, SCI-HUB may change the Upper letter in {DOI} into lower case, 
*      so that we can download the PDF document properly 


* download PDF article using sci-hub
*  input: {DOI}
* output: PDF document of the article given {DOI}
*  output: ../pwd/filename.pdf

* Example:
*    get_pdf `DOI', saving(`filename')

*-- basic idea: --
*   copy "https://sci.bban.top/pdf/{DOI}.pdf"  abc.pdf

cap program drop get_pdf_scihub
program   define get_pdf_scihub, rclass

syntax anything [ , Saving(string) Path(string) ]

//   local DOI = subinstr(`"`DOI'"', `"""', "", .)
  if strpos(`"`anything'"', `"""')>0{
      local DOI `anything'
  }
  else{
      local DOI "`anything'"
  }
  
*-path 
  if "`path'" == ""{
      local path: pwd 
  }  
  
*-filename 
  if "`saving'" != ""{
      local fn "`saving'"
  }
  else{  // use DOI as file   
      local fn = "_" + ustrregexra("`DOI'", "[^0-9a-zA-Z]", "_") 
  }
  
*-download
  * copy "https://sci.bban.top/pdf/{DOI}.pdf"  abc.pdf
  *       ------------------------      -----
  *               scihub                suffix
  * e.g.  https://sci.bban.top/pdf/10.1111/j.1467-629x.2010.00375.x.pdf  
  
  get_doi_scihub_special `DOI'           // deal with special characters
  
  local DOI_scihub "`r(doi_scihub)'"
  
//   dis in red "`DOI_scihub'"  // ++++++++++++++++++++++++++++++++++++
  
  local scihub "https://sci.bban.top/pdf" 
//   local suffix ".pdf"
  local pdf_url "`scihub'/`DOI_scihub'.pdf"
  
  local link     "https://doi.org/`DOI'"
  local pdf_web  "${sci__hub_}/`DOI'"
  
//   dis "`pdf_url'"
  
  *-把 // 修改为 /
  local pdf_url = subinstr("`pdf_url'", `"//10"', "/10",.) 

  *-download PDF file
  cap qui copy `"`pdf_url'"'  `"`path'/`fn'.pdf"', replace   // download PDF document  
  
  if _rc{    // >>> try 1: lower case of the {DOI} 
  
      local DOI_scihub = lower("`DOI'")  // https://sci.bban.top/pdf/10.1111/j.1467-629X.2010.00375.x.pdf 
                                         // change to ('X' --> 'x')
                                         // https://sci.bban.top/pdf/10.1111/j.1467-629x.2010.00375.x.pdf 
                                         
      local pdf_url "`scihub'/`DOI_scihub'.pdf"
      cap qui copy `"`pdf_url'"'  `"`path'/`fn'.pdf"', replace   // download PDF document  
      
      if _rc==0{
          local pdf_ok = 1
      }
      else{  // >>> try 2: upper case of the {DOI} 
          
          local DOI_scihub = upper("`DOI'")  // https://sci.bban.top/pdf/10.3982/ecta13117.pdf
                                             // change to 
                                             // https://sci.bban.top/pdf/10.3982/ECTA13117.pdf
          local pdf_url "`scihub'/`DOI_scihub'.pdf"
          cap qui copy `"`pdf_url'"'  `"`path'/`fn'.pdf"', replace   // download PDF 
          if _rc==0{
              local pdf_ok = 1
          }
          else{
              local pdf_ok = 0
          }
      }
  }
  else{
          local pdf_ok = 1
  }
  
*-display error message, hints and show results 
  
  if `pdf_ok' == 0{
           dis as error  "Failed to Download/Save PDF document. Possible reasons:"
           dis as error  "  1. The PDF document with same filename has been opened, and is read-only."
           dis as error `"  2. The paper is too new, or is a working paper. You can visit {browse "`link'":{ul:aricle page}} to download by hand using filename:"'
           dis as text _skip(2) `"{cmd:`fn'}."'
           dis as error `"  3. There are some wrong with the URL. You can try {browse "`pdf_web'":PDF_online}."'
           dis as text "If necessary, report bugs to <arlionn@163.com>." 
//            exit 
  }  
  else{  // 这部分内容做成一个子程序  get_pdf_dis.ado 
      *local path `"`c(pwd)'"'
	  local path = subinstr(`"`path'"', "\", "/", .)
      if "`c(os)'" == "Windows" {
         noi dis _col(9)  "{cmd:PDF:}"                        ///
                 _skip(2) `"{browse `"`path'"': dir}"'        ///
                 _skip(3) `"{browse `"`pdf_url'"': view_online}"' ///
                 _skip(4) `"{stata `" winexec cmd /c start "" "`path'/`fn'.pdf" "' : Open}"' 
	  }  
	  if "`c(os)'" == "MacOSX" {
         noi dis _col(4)  "{cmd:PDF:}"                        ///
                 _skip(2) `"{browse `"`path'"': dir}"'        ///
                 _skip(3) `"{browse `"`pdf_url'"': view_online}"' ///
         		 _skip(4) `"{stata `" !open "`path'/`fn'.pdf" "' : Open}"'
	  }
  }

  
*-return value  
  return local  pdfurl  = `"`pdf_url'"'
  return local  pdfweb  = `"`pdf_web'"'
  return scalar pdf_got = `pdf_ok'     // Fail to download PDF document? 
  
end 

/*
*-  test
  global DOI "10.1111/j.1467-629X.2010.00375.x"   // need lower 
  global DOI "10.3982/ecta13117"                  // need upper
  global DOI "10.1016/j.jbankfin.2019.07.014"
  cls 
  set trace on
  get_pdf_scihub $DOI 
  get_pdf_scihub $DOI, saving(Hansen-2021)
  get_pdf_scihub $DOI, saving(Hansen-2021) hline 
*/


/*
to be done: sepecial case 
* SCI-HUB 中部分 DOI 的大小写更改具有随机性
* REST 的其他文章不存在这个问题 

DOI: 10.1162/rest_a_00775
https://sci.bban.top/pdf/10.1162/REST_a_00775.pdf
*/





*------------------ subprogram -------------get_pdf_nonSCIHUB.ado

* version 1.1 2024/1/10 10:03

* download PDF documents for articles in 
*          NBER, arXiv, and Open-access Journals 
*  input: {DOI}
* output: PDF document of the article given {DOI}
*  output: ../pwd/filename.pdf

* Example:
*    get_pdf `DOI', saving(`filename')

*-- basic idea: --
*   copy "https:xxxx/pdf/{DOI}.pdf"  path/abc.pdf

cap program drop get_pdf_nonSCIHUB
program   define get_pdf_nonSCIHUB, rclass

syntax anything(name=DOI) [ , Saving(string) Path(string) ]

  local DOI = subinstr(`"`DOI'"', `"""', "", .)  // delete '"'
  
  * article page 
    local link    "https://doi.org/`DOI'"
    local link_br  `"{browse "`link'":Link}"'  
  
*-path 
  if "`path'" == ""{
      local path: pwd 
  }  
  
*-filename 
  if "`saving'" != ""{
      local fn "`saving'"
  }
  else{  // use DOI as file   
      local fn = "_" + ustrregexra("`DOI'", "[^0-9a-zA-Z]", "_") 
  }
  
*-download


*-arXiv  
* DOI: 10.48550/arXiv.2312.05400  -->  10.48550/arXiv.{ID}  
  local key "10.48550/arXiv"
  if strpos(`"`DOI'"', "`key'"){
      local ar_ID = subinstr("`DOI'", "`key'.", "", 1)  // get: 2312.05400 ({article ID})
      local pdf_url "https://arxiv.org/pdf/`ar_ID'.pdf"
  }
        
*-NBER           with PDF
* DOI: 10.3386/w31184  -->  10.3386/{ar_ID}
* PDF: https://www.nber.org/system/files/working_papers/{ID}/{ID}.pdf
* - e.g. https://www.nber.org/system/files/working_papers/w31184/w31184.pdf
  local key "10.3386/"
  if strpos(`"`DOI'"', "`key'"){
      local ar_ID = subinstr("`DOI'", "`key'", "", 1)  // get: w31184 ({article ID})
      local pdf_root "https://www.nber.org/system/files/working_papers"
      local pdf_url "`pdf_root'/`ar_ID'/`ar_ID'.pdf"
  }  
  
*---------------------
*- Open Access Journal  
*---------------------
*-QE 
* DOI: 10.3982/QE1288
* PDF: https://onlinelibrary.wiley.com/doi/epdf/10.3982/QE1288
  local key "10.3982/QE"
  if strpos(`"`DOI'"', "`key'"){
      local link "https://onlinelibrary.wiley.com/doi/`DOI'"
      local pdf_root "https://onlinelibrary.wiley.com/doi/epdf"
      local pdf_url "`pdf_root'/`DOI'"
  } 

*-Stata Journal  
* DOI: 10.1177/1536867X
* PDF: https://journals.sagepub.com/doi/epdf/10.1177/1536867X1801800306
  local key "10.1177/1536867"
  if strpos(`"`DOI'"', "`key'"){
      local pdf_root "https://journals.sagepub.com/doi/epdf"
      local pdf_url "`pdf_root'/`DOI'"
  } 


*-Save the PDF document 

  *-把 // 修改为 /
  local pdf_url = subinstr("`pdf_url'", `"//10"', "/10",.) 

  *-download PDF file
  cap qui copy `"`pdf_url'"'  `"`path'/`fn'.pdf"', replace   // download PDF document  
  
  if _rc{   
      local pdf_ok = 0
  }
  else{
      local pdf_ok = 1
  }
  
*-display error message, hints and show results 
  
  if `pdf_ok' == 0{
           dis as error  "Failed to Download/Save PDF document. Possible reasons:"
           dis as error  "  1. The PDF document with same filename has been opened, and is read-only. You can close this file and rename it"
           dis as error `"  2. There are some wrong  or changes with the URL. You can visit {browse "`link'":aricle page} and download by hand."'
           dis as error "If necessary, report bugs to <arlionn@163.com>." 
  }  
  else{  // TBD: 这部分内容做成一个子程序  get_pdf_dis.ado 
	  local path = subinstr(`"`path'"', "\", "/", .)
      if "`c(os)'" == "Windows" {
         noi dis _col(9)  "{cmd:PDF:}"                        ///
                 _skip(2) `"{browse `"`path'"': dir}"'        ///
                 _skip(3) `"{browse `"`pdf_url'"': view_online}"' ///
                 _skip(4) `"{stata `" winexec cmd /c start "" "`path'/`fn'.pdf" "' : Open}"' 
	  }  
	  if "`c(os)'" == "MacOSX" {
         noi dis _col(4)  "{cmd:PDF:}"                        ///
                 _skip(2) `"{browse `"`path'"': dir}"'        ///
                 _skip(3) `"{browse `"`pdf_url'"': view_online}"' ///
         		 _skip(4) `"{stata `" !open "`path'/`fn'.pdf" "' : Open}"'
	  }
  }

  
*-return value  
  return local  pdfurl  = `"`pdf_url'"'
  return scalar pdf_got = `pdf_ok'     // Fail to download PDF document? 
  
end 

/*
test 

*-arXiv
  global DOI  "10.48550/arXiv.1301.3781"
  
*-NBER
  global DOI 10.3386/w31184  
  global DOI 10.3386/w3110
  
*-QE Open Access Journal
  global DOI 10.3982/QE1288 
  
  get_pdf_nonSCIHUB $DOI
*/




*------------------ subprogram ------------- get_bib.ado
* version 1.0 13Dec2023
* Yujun Lian

cap program drop get_bib 
program define get_bib, rclass
version 14

*:Goal: download and list .ris and .bibtex files for given {DOI}
*--  input: {DOI} e.g.,  10.1016/j.jbankfin.2019.07.014
*-- output: doi.ris, doi.bibtex 
*::ideas: "`API'/`DOI'/`trans'"
* e.g, "http://api.crossref.org/works/{DOI}/transform/application/x-bibtex"

syntax anything(name=DOI) [, Path(string) Notip ] 

*-generate filename according {DOI} (replace '.' with '_')
  local fn = "_" + ustrregexra("`DOI'", "[^0-9a-zA-Z]", "_")   
  * input:  "10.1257/aer.109.4.1197"
  *output: "_10_1257_aer_109_4_1197"

*-common url
  local API   "http://api.crossref.org/works"

*-.bibtex (.tex file or Zotero)
  local trans "transform/application/x-bibtex"
  local url_bib "`API'/`DOI'/`trans'"

*-.ris (endnote, refworks, ProCite, Reference Manager)
  local trans "transform/application/x-research-info-systems"   
  local url_ris "`API'/`DOI'/`trans'"


* help document
* .RIS file can be used to import meta data to software like: ProCite, Reference Manager, EndNote
* .bibtex file can be used to import meta data to .tex file or Zotero software  
  
  cap copy `"`url_bib'"'  "`path'/`fn'.bibtex", replace 
  if _rc==0{
      local got_bib = 1
      qui copy `"`url_ris'"'  "`path'/`fn'.ris", replace     
  }
  else{
      local got_bib = 0
      dis as error "Warning: Can not download '.bibtex' and '.ris' files. This may occur for newly published papers or working papers. Please check your {DOI}." 
      dis as error "You can report bugs to <arlionn@163.com>."
//       exit 
  }
  
  if `got_bib' == 1 {
//       local path : pwd  // Current working directory
	  local path = subinstr(`"`path'"', "\", "/", .)
      if "`pdf'" == ""{
          local dis_dir " . "
      }
      else{
          local dis_dir "dir"
      }
      
      if "`c(os)'" == "Windows" {
         noi dis _col(4)   "{cmd:Citation:}"                        ///
                 _skip(2) `"{browse `"`path'"': `dis_dir'}"'        ///
                 _skip(3) `"{stata `" winexec cmd /c start "" "`path'/`fn'.bibtex" "' : Bibtex}"' ///
                 _skip(4) `"{stata `" winexec cmd /c start "" "`path'/`fn'.ris" "' : RIS}"'  
	  }  
	  if "`c(os)'" == "MacOSX" {
         noi dis _col(4)   "{cmd:Citation:}"                        ///
                 _skip(2) `"{browse `"`path'"': `dis_dir'}"'        ///
                 _skip(3) `"{stata `" !open "`path'/`fn'.bibtex" "' : Bibtex}"' ///
         		 _skip(4) `"{stata `" !open "`path'/`fn'.ris" "' : RIS}"'
	  }
      if "`notip'" == ""{
            noi dis _col(4) as text "Notes: {cmd:RIS} - EndNote, ProCite, Mendeley"
            noi dis _col(11) as text "{cmd:Bibtex} - LaTeX, Zotero, Mendeley" 
      }
  }

*-return value  
  return scalar got_bib = `got_bib'   
  
  if `got_bib' == 1 {
      return local bibtex = `"`url_bib'"'
      return local ris    = `"`url_ris'"'      
  }
  else{
      return local bibtex = ""
      return local ris    = ""
  }

    
end   

/* test and Examples

   local DOI "10.1016/j.jbankfin.2019.07.014"
   get_bib `DOI'
   ret list 
   
  ==Citation Export== RIS: EndNote, ProCite, Mendeley
    dir               Bibtex: LaTeX, Zotero, Mendeley
    Windows: Bibtex RIS        MacOS: Bibtex  RIS
   
macros:
            r(url_ris) : "http://api.crossref.org/works/10.1016/j.jbankfin.2019.07.014/transform/application/x-research-info-systems"
            r(url_bib) : "http://api.crossref.org/works/10.1016/j.jbankfin.2019.07.014/transform/application/x-bibtex"
                r(doi) : "10.1016/j.jbankfin.2019.07.014"
   
*/




*------------------ subprogram ------------- get_checkpath.ado 
cap program drop get_checkpath 
program define get_checkpath, rclass
version 14

syntax anything(name=path)

      local pwd : pwd 

      local path = subinstr(`"`path'"', `"""', "", .)  // 去掉双引号
 
      if strpos(`"`path'"', "/") | strpos(`"`path'"', "\"){ // full path
          cap cd `"`path'"'
          if _rc{
              dis as text `"'`path'' does not exist."' 
              local path = subinstr(`"`path'"', "/", "\", .)
              dis "`path'"
              !md "`path'"
              cap noi cd `"`path'"'
              if _rc==0{
                  dis as text `"new path '`path'' is created"'
              }
              else{
                  dis as error "invalid path(), please check it"
                  exit 
              }
          }  
      }
      else{
          local pwd : pwd 
          cap cd "`path'"
          if _rc{
              mkdir "`path'" 
              cd "`path'"
          }
          local path `"`pwd'/`path'"'
      }
      
      local path = subinstr(`"`path'"', "\", "/", .)
      
      return local path "`path'"
      
      cd "`pwd'"
      
end 
/*
=== test

get_checkpath aaa
ret list 
 
get_checkpath "D:/___temp/delete_later"
ret list

*/



*------------------ subprogram ------------- get_clipout.ado --v2--
*  version 1.1 2023/2/23 16:15
*  version 1.2 2023/11/14 23:07
*  echo text to clipboard. Support: Windows, MacOSX

* Tips
* 1. The 'notice' appears no more than 3 times
* 2. Once -NOTIP- specified, the 'notice' will not appear before you restart Stata
* 3. You can execute "global  clipout__times_ = 10" to hind 'notice'
* notice := "Text is on clipboard. Press '`shortcut'' to paste"

* =refs:
*  https://www.alphr.com/echo-without-newline/
*  https://linuxhandbook.com/echo-without-newline/

cap program drop get_clipout
program define get_clipout

    syntax anything [, Clipoff NOTIP]
	
	if "`clipoff'" ~= ""{
		exit 
	}
	
	if "`c(os)'" == "Windows" {
		local shellcmd `"shell echo | set /p=`anything'| clip"'
		local shortcut "Ctrl+V"
	}  
	
	if "`c(os)'" == "MacOSX" {
        local shellcmd `"shell echo -n `anything'| pbcopy"'
		local shortcut "Command+V"
	}
	
	`shellcmd'               // auto copy to clipboard
		
  *-Warning for non ASCII characters
    *local au "M. Dąbrowski, Papież, M."
//     mata: st_local("Yes_ascii", strofreal(isascii("`anything'")))
//     mata: st_local("Yes_ascii", strofreal(isascii(`anything')))
//     if `Yes_ascii'!=1{
//         dis as text _n "Warning: Non ASCII characters found and may not display properly."
//         dis as text "You'd better manually copy the results"
//     }  
        
  *-notip
	if "`notip'" == ""{	
		dis as text "{cmd:Tips}: Text is on clipboard. Press '{cmd:`shortcut'}' to paste, ^-^"
	}

end 
*----------------------------------------- 


* version 1.1 2023/9/26 23:10
* Yujun Lian, arlionn@163.com

/* 

# Description Goal: 
  Package 'get_scihub' displays and checks the valid URLs of SCI-Hub, a 
  special website to search or browse academic papers.  
  For some reasons, the URL of SCI-Hub always change. 
  Some commonly use URLs are listed in 
  "https://lovescihub.wordpress.com/"
  Their URLs share the format as: http(s)://sci-hub.xx. 
  For example, http://sci-hub.ren/.
  
  'get_scihub' can also be used to get the PDF link of an article even though
  the URL of SCI-Hub is changing. The dynamic PDF link will be:
  http://{best URL returned by get_scihub}/{DOI}

# Methods: 
  1. copy webpage of "https://lovescihub.wordpress.com/"
  2. get the URLs using regular expression 
  3. if -check- option is specified, check the validity of URLs, and keep the 
     valid ones.
  4. if -list- option is specified, list the URLs and Speed (in seconds) in 
     Stata's Results Window. The URLs listed are clickable.
  5. The return values include: the fast URL, r(best); all URLs listed in 
     "https://lovescihub.wordpress.com/"

# Options: 
  List: list URLs which is clickable and speed (seconds) 
  Check: check the validity of URLs listed in https://lovescihub.wordpress.com/, 
         and keep only the valid ones.     
     
# Usage and Examples
  (1) display a list of valid URLs of SCI-Hub
  . get_scihub, list
  (2) check validity and list valid ones
  . get_scihub, list check
  (3) programming use
  . qui get_scihub
  . local scihub  "`r(best)'"
  . local DOI "10.1257/aer.109.4.1197"
  . view browse "`scihub'/`DOI'"  // open the PDF document 
    
* URL format: ren, wf, pk, ee, click
   sci-hub.ee | sci-hub.ren | sci-hub.ru
   sci-hub.se | sci-hub.st | sci-hub.tf | sci-hub.wf

*/


cap program drop get_scihub
program define get_scihub, rclass
version 14

  syntax [, Check List]
  
            // detail: save the full list of sci-hub host as return macros
            //   list: list the full list of sci-hub host as results

preserve    

qui {
            
*-download webpage and save as .dta            
  local lovescihub "https://lovescihub.wordpress.com/"
  
  tempfile html_text 
  cap copy "`lovescihub'" "`html_text'.txt", replace 
  if _rc{
       dis as error "Fail to connect to `lovescihub'"
       dis as error "Try http://sci-hub.ren/ or http://sci-hub.ee/"
       exit
  }

  tempvar v
  qui infix strL `v' 1-1000 using "`html_text'.txt", clear 
  
  
*-extract <http(s)://sci-hub.???/>  
  keep if strpos(`v', "://sci-hub")
  local regex "https?://sci-hub\.[a-z]{2,}"
  gen url = ustrregexs(0) if ustrregexm(`v', "`regex'") // URL of sci-hub
  duplicates drop url, force
  
 
*-check the validity of URLs, and keep valid URLs
  if "`check'" != ""{
      local N = _N
      tempfile testfn
      tempvar  IsValid 
      gen `IsValid' = 1
      gen IsValid = 1
      forvalues i = 1/`N'{
          local urli = url[`i']
          cap copy "`urli'" "`testfn'.txt", replace // Check if the urli is valid
          if _rc{  // not valid
              replace `IsValid' = 0 in `i'
          }
      }
      keep if `IsValid' == 1 
      local N = _N
      if `N' == 0{
          local solution "https://lovescihub.wordpress.com/solutions/"
          noi: dis as error "Can not find valid URL. " _c
          noi: dis as text `"See:{browse "`solution'": Possible Solutions}"'
          exit
      }
  }
  
*============ return and display =======  
  
/* Options: 
   Default: return r(best), all URLs listed in https://lovescihub.wordpress.com/
   List: list URLs which is clickable and speed (seconds) 
   Check: check the validity of URLs listed in https://lovescihub.wordpress.com/, 
          and keep only the valid ones.
*/


*-return full list of URLs 
 
   local N = _N
   return scalar N = `N'
   forvalues i = `N'(-1)1{
       return local s`i' = url[`i']
   }
  
  
*-the best (fast)  
  local best = url[1]   
  return local best = "`best'"  // the fast/best URL   
   
   
*-display the full list of URLs 
  
  if "`list'" != ""{
      
      // connect speed (seconds)
      local regex "[\d]\.[\d]{1,}(?=s)"
      gen seconds = ustrregexs(0) if ustrregexm(`v', "`regex'") 
      
      local love "https://lovescihub.wordpress.com/"
      noi: dis _col(10) "URL" _col(34) "Seconds  " _c
      noi: dis `"{browse "`love'": [Source]}"'
      
      forvalues i = 1/`N'{
          local url = url[`i']
          local sec = seconds[`i']
          noi: dis _col(3) "`i'." _col(7) `"{browse "`url'": `url'}"' _col(34) "`sec'"
      }
  }  
  
}              // quietly over   
  
restore   
  
end   
  
  
/*
  
*===== test ======
 
  get_scihub
  ret list 
  
  get_scihub, check
  ret list 
  
  clear 
  set trace on
  get_scihub, list
  get_scihub, l
  ret list   
  
*/
 
