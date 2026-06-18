{smcl}
{* 06June2026}{...}
{title:Quick Reference}

{p 8 20 2}
{hi:reduce_aigc} {hline 2} Quick reference for AIGC reduction in Word documents

{title:Syntax}

{p 8 16 2}
{hi:reduce_aigc} , {bf:input(}{it:filename}{bf:)} [{bf:output(}{it:filename}{bf:)} 
    {bf:target(}{it:#}{bf:)} {bf:intensity(}{it:#}{bf:)} 
    {bf:dict(}{it:filename}{bf:)} {bf:methods(}{it:string}{bf:)}
    {bf:language(}{it:string}{bf:)}]

{title:Key Options}

{p 8 12 2}
{bf:input(}{it:string}{bf:)} {space 4}Input .docx file {it:(required)}

{p 8 12 2}
{bf:output(}{it:string}{bf:)} {space 4}Output file {it:(default: input_reduced.docx)}

{p 8 12 2}
{bf:target(}{it:real}{bf:)} {space 4}Target similarity (0.1-0.95) {it:(default: 0.3)}

{p 8 12 2}
{bf:intensity(}{it:real}{bf:)} {space 4}Reduction intensity (0.1-0.95) {it:(default: 0.5)}

{p 8 12 2}
{bf:language(}{it:string}{bf:)} {space 4}{cmd:zh} or {cmd:en} {it:(default: zh)}

{p 8 12 2}
{bf:methods(}{it:string}{bf:)} {space 4}Comma-separated list of methods:
{space 12}{cmd:synonym} {cmd:voice} {cmd:neg} {cmd:split} 
{space 12}{cmd:order} {cmd:expand} {cmd:modifier}

{title:Quick Examples}

{p 8 12 2}
{bf:Basic (Chinese):}
{cmd:. reduce_aigc , input("mythesis.docx")}

{p 8 12 2}
{bf:Target 20% similarity:}
{cmd:. reduce_aigc , input("paper.docx") target(0.2) intensity(0.6)}

{p 8 12 2}
{bf:English document:}
{cmd:. reduce_aigc , input("essay.docx") language("en") target(0.25)}

{p 8 12 2}
{bf:Use custom synonym dictionary:}
{cmd:. reduce_aigc , input("thesis.docx") dict("mywords.json")}

{p 8 12 2}
{bf:Use only synonym and voice methods:}
{cmd:. reduce_aigc , input("doc.docx") methods("synonym,voice")}

{title:Recommended Settings for VIP (维普)}

{space 4}{bf:Target < 30%:} {cmd:target(0.25) intensity(0.6)}
{space 4}{bf:Target < 20%:} {cmd:target(0.15) intensity(0.8)}
{space 4}{bf:Target < 12%:} {cmd:target(0.10) intensity(0.9)}

{title:Requirements}

{space 4}Python packages: {cmd:python-docx} {cmd:jieba} (for Chinese)

{title:Authors}

{bf:Wu Lianghai}         {browse "mailto:agd2010@yeah.net":agd2010@yeah.net}
{bf:Wu Hanyan}           {browse "mailto:2325476320@qq.com":2325476320@qq.com}
{bf:Chen Liwen}          {browse "mailto:2184844526@qq.com":2184844526@qq.com}

{title:Version}

8.0 {space 4}06June2026

{title:See Also}

{space 4}{help reduce_aigc} for full documentation
{*}