*!2016-09-02 09:42
clear mata
version 11
mata:
class codex { //>>def class<<
	string scalar pair
	string vector del, dskips, mskips, mtypes
	string matrix pskips, keys
	real scalar key, typix
	string matrix config, dict, dicti, raw, ucs, cxs, meta, codout //>>props end<<
	
	void new()
	string vector readcode()
	void readdict()
	void nextid()
	void cat()
	void search()
	void cx()
	void xpat_dict()
	real matrix match()
	void review()
	void review2()
	string matrix compare()
	void todata()
	void todocs()
	vector plen()
	real matrix marked()
	void create()
	void rangex()
	}
class collector { //>>def class<<
	matrix arr
	real scalar rix, across, numdata
	real vector rhigh, cwide, fill, cdone
	
	void new()
	void init()
	void add()
	void next()
	matrix compose()
	}
class dataset { //>>def class<<
	real scalar wdata, wlabs, wchars
	real scalar nvars, nobs
	string scalar dtalabel, dtstamp
	string vector vnames
	string vector nlabels
	string vector sirtypes
	real vector bytes
	real vector strls
	string vector vlabrefs
	string vector formats
	real vector sortvars
	string matrix chars
	pointer rowvector data
	string vector vlabnames
	pointer vector vlabtabs //>>props end<<
	
	void new()
	void with()
	void readmem()
	void writemem()
	void readmat()
	void gen()
	void add()
	void shrink()
	void setk()
	void settypes()
	real vector varlist()
	string matrix labelsof()
	string vector charget()
	matrix getdat()
	string matrix strdat()
	void setdat()
	}
class dtareport { //>>def class
	string scalar title, rev, dscr
	string colvector notes
	
	void tochar()
	void fromchar()
	void display()
	void save()
	}
class elfs { //>>def class<<
	real scalar blist, bedit, bdrop, bsave
	string scalar ename, epath
	real scalar mapix, getix
	string vector head
	string matrix base, elf
	matrix anci //>>props end<<
	
	void new()
	void init()
	string matrix uelf()
	void button()
	string matrix get()
	virtual string matrix notfound()
	void write()
	virtual void obutton()
	virtual void list()
	}
class errtab { //>>def class<<
	pointer rowvector etabs
	real rowvector haserror //props end
	
	real scalar newtab()
	void newerr()
	void present()
	}
class ferunner { //>>def class
	string scalar doname, docode
	string vector ocode
	real scalar sl, fl
	string scalar opath
	
	void run()
	void compile()
	void grun()
	}
class htmlpgs { //>>def class<<
	matrix parts
	real scalar addix
	string scalar _nodiv, _defdiv, _na
	string scalar _div, _par, _fwjs, _fwcss, _pgjs, _pgcss, _divatts, _opix
	string scalar cpg, cdiv //>>props end<<
	
	void new()
	void page()
	void header()
	void addfw()
	void addjs()
	void addcss()
	void div()
	void place()
	void write()
	void writedivs()
	void clear()
	string matrix query()
	static string scalar base64()
	}
class htmltable { //>>def class
	string scalar pre, post, tab
	string colvector trows
	string matrix tcells, tconts
	
	void read()
	string scalar write()
	}
class models { //>>def class<<
	string rowvector mlabs
	string colvector stub
	pointer rowvector tops, rmaps, betas, ses, more
	real scalar tmax
	real rowvector types
	real scalar t_reg, t_log, t_cox, t_pois, t_stcr
	class tspoof scalar t  //>>end props<<
	
	void new()
	void add()
	void label()
	void present()
	string colvector getc()
	}
class recentle { //>>def class<<
	private real scalar msize
	private string scalar scid
	string scalar rname
	string vector rdef
	string matrix recent //>>props end<<
	
	void new()
	void init()
	void add()
	}
class recentle_data { //>>def class<<
	class recentle scalar rle
	string scalar cdsnam, odnam, listpath
	string rowvector cdsdef
	string scalar ncmd, nmode, ndir, nfile, ndetails
	
	void new()
	void get()
	void parse()
	void add()
	void window()
	void list()
	}
class recentle_proj { //>>def class
	string scalar prjdir
	string scalar on_f, off_f, oth_f
	string scalar rlenam
	string rowvector rledef
	class recentle scalar rle
	matrix oth_set //>>props end
	
	void new()
	void add()
	void get()
	string scalar existsfor()
	void list()
	void s_edit()
	void s_run()
	void oth_read()
	void oth_write()
	matrix oth_get()
	void oth_set()
	}
class spsheet { //>>def class<<
	string rowvector shnames
	pointer rowvector cnames
	pointer rowvector ctypes
	pointer rowvector sheets //>>end props<<
	
	void reset()
	void readods()
	void parseods()
	void readxml()
	void writexml()
	void setheads()
	static string scalar odsstr()
	static void unzip()
	static string matrix xmlchars()
	static string vector odsval()
	}
class sql_conn { //>>def class
	string rowvector crec
	real scalar dsn, driver, server, dbname, schema
	class recentle scalar rle
	string scalar rlenam, rledef //>>props end
	
	void new()
	string rowvector hparse()
	void merge()
	void userset()
	string scalar field()
	string scalar connstr()
	string colvector humstr()
	string scalar path()
	void get()
	void add()
	void list()
	}
class sql_meta { //>>def class
	string vector fields, types
	string colvector s_name, t_name, q_name, q_desc, q_cols, q_time, moddt, cmdfile, sql
	pointer vector data
	string scalar dest, db, home_s, home_t, home_st, nquery, predrop //>>props end
	
	void new()
	void dest()
	void todta()
	void fromdta()
	void xtosql()
	void tosql()
	void fromsql()
	void makesql()
	}
class sqldo { //>>def class<<
	real scalar swix, cix
	string scalar eol, sqlbeg, sqlend, eltmp, mmark, tmark, swkey
	string vector names, codes, tables, scals
	string matrix dtas, prv, swaps
	class sql_meta scalar sm
	class sql_conn scalar sc, writable
	class codex scalar cx
	real vector uses, doem //>>props end<<
	
	void new()
	void sqldo()
	private void include()
	private void parse()
	private void preview()
	private void exec()
	private void suse()
	}
class statgrid { //>>def class<<
	private string scalar touse, e_bound
	real matrix gixs
	string rowvector e_exp, e_func, e_body, e_btype, e_wt, e_tmp
	pointer rowvector ee_scalars
	real rowvector e_p2, ee_str
	real scalar b_n, k_n, e_n, ovmiss, cross
	string scalar defaults, ovlab
	pointer vector bys
	string rowvector by_vars, k_vars
	class dataset scalar ds //>>props end<<
	
	static string vector canon()
	void by()
	void setup()
	private void dsby()
	private real scalar get_unmiss()
	private void cross_ve()
	private string scalar enclose()
	private void sub_r()
	private void get_e()
	private string scalar btype()
	private void set_names()
	void set_flabels()
	void dseval()
	void eval()
	private static real scalar wrix()
	}
class tabel { //>>def class<<
	string matrix body
	real scalar head, stub, altrows, usewidth, padbefore, padafter
	private string matrix spchars, links
	private pointer matrix tcodes, scodes
	private scalar o_sta, o_eml, o_htm, o_dest
	private string scalar o_name, o_path
	private vector o_and
	private string vector s_head, s_stub
	string matrix s_body
	string scalar o_mode, o_scheme
	string scalar rendered
	string colvector colorsused
	
	//constants
	real scalar _span, _vline, _hline, _align, _wrap, _class
	real scalar Lnone,Lsp1,Lsp2,Lsp2min,Lminor,Lmajor, left,center,right
	private string vector cropped
	private string scalar subst1,subst2,subln1,subln2,subch,eol //>>props end<<
	
	void new()
	void set()
	string scalar defChar()
	string matrix setSpan()
	string colvector setLinks()
	void o_parse()
	void render()
	void reset()
	void present()
	private void get()
	private string vector sClasses()
	private string rowvector getAtts()
	private string vector attStyle()
	private static string scalar styleFin()
	private static string colvector charix()
	private static real scalar numix()
	}
class textidents { //>>def class
	string scalar rxchars, del //>>props end
	
	void new()
	void setdel()
	string scalar esc()
	string colvector find()
	string matrix replace()
	}
class xmlelem { //>>def class<<
	string scalar name
	string scalar content
	string vector attn
	string vector attv
	static string scalar spm, spo, nch, nnch //>>end props<<
	
	void new()
	scalar getv()
	real scalar next()
	void di()
	real scalar nnis()
	}
class dataset_dta extends dataset { //>>def class
	real vector C
	real scalar fh
	string vector vers
	string scalar stend //>>props end
	
	void new()
	string vector getversion()
	void readfile()
	void read_115m()
	void read_117()
	void read_118()
	matrix read_next()
	void writefile()
	void write_114()
	string scalar write_117()
	string scalar write_118()
	void write_next()
	void fbufput8()
	real vector fbufget8()
	void bufput6()
	real scalar bufget6()
	}
class elfs_callst extends elfs { //>>def class<<
	
	void new()
	virtual void list()
	virtual void obutton()
	virtual string matrix notfound()
	}
class elfs_colors extends elfs { //>>def class
	string vector builtins
	real scalar curR, curV, warnix
	string scalar cache //>>props end
	
	void new()
	virtual void list()
	virtual void obutton()
	string vector current()
	string matrix colorsx()
	string scalar colornote()
	}
class elfs_facts extends elfs { //>>def class<<
	
	void new()
	virtual void list()
	virtual void obutton()
	}
class elfs_grail extends elfs { //>>def class<<
	
	void new()
	virtual void list()
	virtual void obutton()
	}
class elfs_instance extends elfs { //>>def class<<
	
	void new()
	virtual void list()
	virtual void obutton()
	}
class elfs_misc extends elfs { //>>def class<<
	
	void new()
	virtual void list()
	}
class elfs_out extends elfs { //>>def class<<
	real scalar mstata, mhtml, memail //>>props end
	
	void new()
	void init()
	virtual void list()
	virtual string matrix notfound()
	virtual void obutton()
	}
class elfs_sql extends elfs { //>>def class<<
	
	void new()
	virtual void list()
	}
class elfs_startup extends elfs { //>>def class<<
	
	void new()
	virtual void list()
	virtual void obutton()
	}
class htmlplus extends htmlpgs { //>>def class<<
	string scalar _notnav, _top, _left, _toc
	string matrix bcolors //>>props end
	
	void page()
	void header()
	void div()
	void addtoci()
	void addpgbreak()
	void addcbox()
	void adddd()
	void addbuttons()
	void addimage()
	void addlog()
	void write()
	string vector tipper()
	string scalar brleft()
	}
class tspoof extends tabel { //>>def class<<
	private matrix spoofs
	private string matrix nl, vl
	real vector nl_n, vl_n //>>props end<<
	
	void new()
	void labset()
	private static string vector oneset()
	void spoofn()
	void spoofv()
	string vector dsspoof()
	string matrix getn()
	string matrix getv()
	string vector strdummy()
	string vector dummyof()
	}
end
*! 27jun2014
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:
end
 global config (`"!"#%&+-icd9"32,44"comma, space"45"dash"x"!"[]"!"!#icd9p"32,44"comma, space"45"dash"x"!"[]"!"!#cpt"32,44"comma, space"45"dash"!"!"[]"!"!#drug"32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,58,59"most symbols, space"!"!"!"!"!"[]"()class#drclass"32,44"comma, space"!"!"!"!"!"!"!#prov"32,44"comma, space"45"dash"!"!"!"!"!#stop"32,44"comma, space"45"dash"!"!"!"!"!#icd10"32,44"comma, space"45"dash"*"!"[]"!"!"')
 mata:


void codex::new() {
	config=strob_to($config)
	}

void codex::readdict(| string scalar dtype) { //>>def member<<
	class dataset_dta scalar ds
	
	dtype=firstof(dtype\config[typix,1])
	dpath=findfile("codex_"+dtype+".dta")
	if (!truish(dpath)) errel(sprintf("codex dictionary not found: %s",dtype))
	ds.with("d c")
	ds.readfile(dpath)
	map=vmap(("codex_source","codex_asof","codex_process"),selectv(ds.chars[,2],ds.chars[,1]:=="_dta","c"))
	if (truish(map)!=3) errel("codex: The dictionary file is malformed",dpath)
	dict=ds.strdat(.,.)
	dicti="As of",""\"Source",""\"Process",""
	dicti[1,2]=select(ds.chars[,3],ds.chars[,2]:=="codex_asof")
	dicti[2,2]=select(ds.chars[,3],ds.chars[,2]:=="codex_source")
	dicti[3,2]=select(ds.chars[,3],ds.chars[,2]:=="codex_process")
	}

void codex::cat(main) { //>>def member<<
	class tabel scalar t
	
	syntaxl(main,NULL,&(out="out="))
	tn=rows(config)
	t.body=J(3*tn,3,"")
	rix=rangel(1,3*tn,3)
	t.body[rix,1]=substr(config[,1],1,strlast(config[,1],":"):-1)
	for (r=1;r<=tn;r++) {
		readdict(t.body[rix[r],1])
		t.body[|rix[r],2\rix[r]+2,3|]=dicti
		}
	t.set(t._align,.,.,t.left)
	t.stub=2
	t.set(t._hline,rix:+2,.,t.Lminor)
	t.present(out)
	}

string vector codex::readcode(string scalar main) { //>>def member<<
	class dataset_dta scalar ds
	
	syntaxl(main,&(path="anything"),(&(fgrp="g:roups="),&(fids="id:s="),&(ftyp="t:ype=")),opts="maybe pg")
	if (truish(fgrp)+truish(fids)+truish(ftyp)>1) errel("Only 1 kind of filter can be specified at a time")
	
	ds.with("d c")
	if (truish(path)) ds.readfile(pcanon(path,"fex",".dta"))
	else ds.readmem()
	vc=select(ds.chars[,(1,3)],ds.chars[,2]:=="codex")
	map=vmap(("group","id","type","code"),vc[,2])
	if (truish(map)!=4) errel("codex: The selected file is not a 'codebase' {hline 2} it lacks the chars for group, id, code, type")
	im=vc[vmap(("type","groupdscr","group","iddscr","id","code"),vc[,2],"only"),1] //codedscr?
	map=vmap(im,ds.vnames[ds.varlist("*")])
	raw=ds.strdat(.,.)[,map]
	
	if (fix=truish(ftyp)+3*truish(fgrp)+5*truish(fids)) {
		raw=select(raw,asvmatch(raw[,fix],ftyp+fgrp+fids,"mult"))
		if (!length(raw)) errel(sprintf("Codex: No match on filter: %s",ftyp+fgrp+fids))
		}
	if (truish(ph=raw[,1]:=="placeholder")) {
		printf("{txt:Placeholders dropped}\n")
		raw=select(raw,!ph)
		}
	keys=dedup(raw[,1..5],(1,3,5))
	//type,groupdsc,group,iddsc,id
	key=0
	return(opts)
	}

void codex::nextid() { //>>def member<<
	class collector scalar co
	
	aset=select(raw,rowmin(raw[,(1,3,5)]:==keys[++key,(1,3,5)]))
	ntype=ocanon("Types",aset[1,1],config[,1]')
	if (ntype!=config[typix,1]) { //set type; not re-reading the dict means keeping many globals
		typix=vmap(ntype,config[,1])
		del=chars(strtoreal(tokel(config[typix,2],",")'))
		if (!truish(del)) del=char(131) //not sure this is necessary
		pair=firstof(char(strtoreal(config[typix,4]))\char(131))
		pskips=expand(columnize(config[typix,8..9]',""),2)
		dskips=cut(pskips',2)'
		pskips=select(pskips,rowmin(tru2(pskips)))
		dskips=select(dskips,rowmin(tru2(dskips)))
		mtypes=substr(config[typix,10],3)
		if (truish(mtypes)) mskips=dskips\columnize(substr(config[typix,10],1,2),"")
		else mskips=dskips
		readdict()
		}
	
	co.init()
	for (p=1;p<=rows(aset);p++) co.add(tokel(aset[p,6],del,mskips,"no")')
	ucs=strtrim(co.compose()) //user-code singles
	if (!truish(mtypes)) {
		cxs=ucs //codex codes
		meta=J(rows(cxs),1,"")
		}
	else {
		cxs=meta=expand(ucs,2)
		
		rev=toindices(marked(cxs,mtypes+"=",1))
		msk=mskips[rows(mskips),]
		cxs=expand(columnize(subinstr(cxs[,1],msk[2],""),msk[1]),2) //assumes <=1 opening mark!
		cxs[rev,]=cxs[rev,2..1]
		
		not=marked(cxs,"-")
		meta=not:*("~":+chars(colshape(runningsum(colshape(not,1)),2))) //not, to 255
		
		co.init(2,"fill(*)")
		for (r=1;r<=rows(cxs);r++) {
			co.add(tokel(cxs[r,1],del,dskips,"no")',1)
			co.add(tokel(cxs[r,2],del,dskips,"no")',2)
			}
		cxs=strtrim(co.compose((&meta,&ucs)))
		}
	if (truish(pair)) rangex()
	meta=meta:+marked(cxs,columnize(config[typix,9],"")):*"#" //literal
	cx()
	}


void codex::cx() { //>>def member<<
	//type determines allowed chars, & my def of wildcards
	//so, by type, escape regex/pattern chars
	if (anyof(("icd9","icd9p"),config[typix,1])) {
		//a final [0-9], after the dot, should be removed (searches all)
		rev=strreverse(cxs)
		simp=toindices(strpos(rev,"]9-0["):==1:&strpos(rev,"."):>5)
		if (truish(simp)) rev[simp]=substr(rev[simp],6)
		cxs=strreverse(rev)
		
		cxs=chtrim(cxs,"x") //no beg, end implicit
		cxs=cxs:+(plen(cxs):==2+(config[typix,1]=="icd9")):*"." 
		if (truish(!strpos(cxs,"."))) errel("Codex icd9 patterns must include the dot, except at the end.",ucs)
		cxs="^":+cxs
		cxs=subinstr(cxs,".","\.")
		cxs=subinstr(cxs,"x",".?")
		cxs=subinstr(cxs,"_","$") //underscore only as final (single) char!
		}
	else if (config[typix,1]=="drug") {
		cxs=strlower(cxs) //fix display of classes as upper
		replace(cxs,!strpos(meta,"#"),subinstr(cxs,char(39),""))
		}
	cxs=strlower(cxs) //gotta deal with case!!
	//if (!anyof(("icd9","icd9p"),type)) l3_cx[,/**/]=l3_cx[,/**/]:+"$"
	}

void codex::search(string scalar main) { //>>def member<<
	class tabel scalar t
	
	syntaxl(main,&(text="anything"),(&(just="j:ust="),&(out="out=")),options="ya")
	just=ocanon("Dictionary parts",just,("c:ode","d:escription"))
	dtype=ocanon("Options",strtrim(options),config[,1]')
	if (!truish(dtype)) {
		path=pathto("codex_search.txt","","fex")
		if (!truish(path)) errel("Specify something to search.")
		dtype=ftostr(path)
		}
	fowrite(pathto("codex_search.txt","inst"),dtype)
	readdict(dtype)
	if (just=="c") scols=1
	else if (just=="d") scols=2..cols(dict) //set this
	else scols=.
	x=strmatch(strlower(dict[,scols]),"*"+strlower(text)+"*") //problem with caps in code!
	t.body=cut((dtype,"",""\"Code","Description","Desc too"),1,cols(dict))\select(dict,rowmax(x))
	o=("\",".","?","*","+","(","[","^","$")
	regm=text
	for (s=1;s<=length(o);s++) regm=subinstr(regm,o[s],"\"+o[s])
	t.body=regexr(t.body,regm,t.setSpan("hi1",text))
	t.head=2
	t.set(t._span,1,1,cols(t.body))
	t.set(t._align,.,.,t.left)
	t.present(out)
	}

void codex::review(string vector moreopts) { //>>def member<<
	class tabel scalar t
	class htmlplus scalar pg
	
	optionel(moreopts,(&(poptions="pg="),&(only="only")))
	optionel(poptions,(&(path="sav:ing="),&(title="t:itle="),&(rev="r:evision="),&(dscr="d:escription="), &(proto="pr:oto")))
	title=firstof(title\"Codex Review")
	rev=firstof(rev\datetime("%tc+DDmonYY"))
	if (!proto) pg.page()
	key=0
	tocr=differ(keys[,5],"prv","ya")
	while (key<rows(keys)) {
		nextid()
		gh=firstof(keys[key,2..3]')
		ih=firstof(keys[key,4..5]')
		hsize=1+(truish(gh)&gh!=ih)
		
		hits=match()
		if (truish(hits)) {
			if (only) t.body=expand(select(dict[,1..3],rowmax(hits)),-4)
			else {
				t.body=compare(rowmax(hits),subhead=J(0,0,.))
				t.body[,1]=t.defChar(char(164),"&FilledSmallSquare;"):*tru2(t.body[,1])
				}
			if (truish(subhead)) {
				t.set(t._hline,subhead:+hsize,.,t.Lminor)
				t.set(t._class,subhead:+hsize,.,"heading")
				t.set(t._hline,cut(subhead,2):+hsize:-1,.,t.Lsp1)
				}
			}
		
		reqs=dedup((ucs,colmax(hits)':*"h"),1,2,"")
		misses=toindices(!tru2(reqs[,2]))
		reqs[misses,1]=t.setSpan("err",reqs[misses,1])
		
		h=adorn("(",keys[key,1],") ")+adorn("",ih,": ")+concat(reqs[,1],", ")
		if (hsize>1) h=gh\h
		t.body=pad(h,t.body,"\")
		
		t.head=hsize
		t.set(t._span,1..hsize,1,cols(t.body))
		t.set(t._align,1..hsize,1,t.left)
		t.set(t._class,.,1,"himk")
		t.set(t._align,.,.,t.left)
		t.altrows=1
		if (!proto) {
			if (tocr[key]) pg.addtoci(adorn("",gh,", ")+ih)
			t.o_parse("htm")
			t.render()
			pg.addcss(t.o_scheme, t.s_body)
			pg.place(t.rendered)
			t.rendered=""
			}
		else t.present("-")
		}
	
	if (!proto) {
		pg.header(title,rev,dscr)
		if (path=="") path=pathto("_html.html","inst")
		else path=pcanon(path,"file",".html")
		pg.write("",path)
		launchfile(path)
		}
	//t.body=dicti
	//if (!proto) t.body[3,]="Process","See {help codex}"
	//else t.body[3,1]=t.setLinks("title",subinstr(t.body[3,1],char(39),"&quot;"),"Process")
	//t.set(t._align,.,.,t.left)
	
	}

real matrix codex::match() { //>>def member<<
	hc=J(rows(dict),rows(cxs),1)
	for (m=1;m<=cols(cxs);m++) {
		//fix gd strlower
		h1=regexm(strlower(dict[,m/**/]),cxs[,m]') //dict column set by meta, perhaps
		if (any(strhas(meta[,m],"~"))) {
			nids=uniqrows(regexs2(meta[,m],"~(.)",1))
			nids=select(nids,tru2(nids))
			for (n=1;n<=length(nids);n++) {
				ncols=expand(toindices(strhas(meta[,m]',"~"+nids[n])),.,1)
				h1[,ncols]=J(1,length(ncols),!rowmax(h1[,ncols]))
				}
			}
		hc=hc:&h1
		}
	return(hc)
	}

string matrix codex::compare(real vector hits,|matrix subhead) { //>>def member<<
	class collector scalar co
	
	if (strpos(config[typix,1],"icd9")) {
		dl=config[typix,1]=="icd9"?4:3
		hdict=select(dict[,1],hits)
		groups=runningsum(differ(substr(hdict,1,dl-1),"prev"))
		compare=J(0,3,"")
		for (g=0;g<=max(groups);g++) {
			agr=select(hdict,groups:==g)
			ml=min(strlen(agr))-1
			if (ml>dl) while (rows(uniqrows(substr(agr,ml,1)))>1) --ml //E&V screw this
			else (ml=dl)
			do {
				cmins=uniqrows(substr(agr,1,ml--))
				chit=asvmatch(dict[,1],cmins+"*","mult") //asvmatch only returns 1 on an exact match!
				} while (ml>=dl&all(select(hits,chit)))
			compare=compare\select(hits,chit):*"#",select(dict[,1..2],chit) //widen dict
			}
		return(compare) //plus dict cols
		}
	else if (config[typix,1]=="cpt") { //narrow this
		hdict=uniqrows(substr(select(dict[,1],hits),1,3))'
		return(select(("#":*hits,dict[,1..3]),rowmax(strmatch(substr(dict[,1],1,3),hdict))))
		}
	else if (config[typix,1]=="drug") {
		path=findfile("codex_drclass.dta")
		if (!truish(path)) errel("Missing drug class dictionary")
		classes=fin_dta(path)
		co.init()
		dclass=uniqrows(select(dict[,2],hits))
		dclassd=classes[vmap(dclass,classes[,1],"only"),2]
		subhead=J(rows(dclass),1,1)
		for (d=1;d<=rows(dclass);d++) {
			allclass=dict[,2]:==dclass[d]
			compare="",dclassd[d],""\select(hits,allclass):*"#",select(dict[,1..2],allclass)
			co.add(compare)
			if (d<rows(dclass)) subhead[d+1]=sum(allclass)+1
			}
		subhead=runningsum(subhead)
		return(co.compose())
		}
	else if (config[typix,1]=="prov") {
		hdict=uniqrows(select(dict[,2],hits))'
		return(select(("#":*hits,dict[,1..3]),rowmax(strmatch(dict[,2],hdict))))
		}
	else /*if (config[typix,1]=="stop")*/ { //stop, drclass shouldn't be here
		//none yet! need empirical match!
		return(select(("#":*hits,dict),hits))
		}
	}

void codex::xpat_dict() { //>>def member<<
	class collector scalar co
	
	co.init(2,"fill(*)")
	key=0
	while (key<rows(keys)) {
		nextid()
		hits=match()
		co.add(keys[key,(1,3,5)],1)
		co.add(select(dict[,1..cols(cxs)],rowsum(hits)),2)
		}
	codout=co.compose() //probably ditch codout
	}

void codex::todata() { //>>def member<<
	class dataset scalar ds
	
	ds.gen("","type")
	ds.gen("","grp") //get these varnames from the codex, I think??
	ds.gen("","id")
	if (cols(cxs)==1) ds.gen("","code")
	else for (c=1;c<=cols(cxs);c++) ds.gen("",sprintf("code%f",c))
	ds.add(rows(codout))
	for (c=1;c<=ds.nvars;c++) *ds.data[c]=codout[,c]
	ds.settypes()
	ds.writemem()
	}

//void codex::todocs(string scalar out) { 
//class collector scalar co
//class tabel scalar t
//
//co.init(2)
//key=0
//while (key<rows(keys)) {
//	nextid()
//	hits=match()
//	co.add(keys[key,4],1)
//set/get dict descrip col
//	co.add(select(dict[,(1,3)],rowsum(hits)),2)
//	}
//t.body=co.compose()
//t.set(t._align,.,.,t.left)
//cond=cut(toindices(tru2(t.body[,1])),2):-1
//t.set(t._hline,cond,.,t.Lminor)
//alt=toindices(mod(runningsum(tru2(t.body[,1])),2))
//t.set(t._class,alt,.,"altback")
//t.present(out)
//}

void codex::todocs(string scalar out) { //>>def member<<
	class tabel scalar t
	
	//get using as folder
	cxix=pathto("./codexdocs/cxix.html")
	key=0
	while (key<rows(keys)) {
		nextid()
		hits=match()
		t.body=keys[key,1]+": "+keys[key,3],""\select(dict[,(1,2)],rowsum(hits))
		t.render() //??present doesn't render??
		t.present(sprintf("htm, u(./codexdocs/%s)",keys[key,4]))
		}
	//keys as contents
	t.body=keys
	t.present("htm, u(./codexdocs/cxix)")
	}

vector codex::plen(string vector pat,| matrix aspat) { //>>def member<<
	plen=hold=pat
	while ((plen=regexr(plen,"\[[^]]+]",char(26)))!=hold) hold=plen //make [] parameter?
	if (truish(aspat)) return(plen)
	else return(strlen(plen))
	}

real matrix codex::marked(string matrix pat, string vector mark,| real rowvector cols) { //>>def member<<
	if (!truish(mark)) return(J(rows(pat),cols(pat),0))
	if (!length(cols)) cols=.
	out=strhas(pat[,cols],mark[1],1)
	pat[,cols]=substr(pat[,cols],strlen(mark[1]):*out:+1)
	//really need to check that closing mark is present!
	if (length(mark)==2) pat[,cols]=strreverse(substr(strreverse(pat[,cols]),strlen(mark[2]):*out:+1))
	return(out)
	}

void codex::create() { //>>def member<<
	clearl() //includes chars
	vars="group","groupdscr","id","iddscr","type","code","codedscr"
	(void) st_addvar("str10",vars)
	st_varformat("code","%-30s")
	charset(vars,"codex",vars)
	}

void codex::rangex() { //>>def member<<
	class collector scalar co
	co.init(2,"fill(*)")
	for (r=1;r<=rows(cxs);r++) {
		for (c=1;c<=cols(cxs);c++) {
			if (length(range=tokel(cxs[r,c],pair,pskips))==2) {
				prefix=regexs2(range,"(.*[^0-9.])[0-9.]+$",1)
				if (prefix[1]!=prefix[2]) errel("codex range: non-numeric prefixes must match",range)
				if (any(regexm(range,"[^0-9.]$"))) errel("codex range-ends cannot include explicit wildcards (but ranges implicitly go from first to last).",range)
				//range ends can only have implicit wildcards
				num=regexs2(range,"([0-9.]+)$",1)
				dots=colmax((0,0)\strpos(strreverse(num),"."):-1)
				tdigs=max(strlen(num):-max(dots))
				//			tdigs=max(strlen(num):-1)
				num=round(strtoreal(num):*10^max(dots),1) //a bit weird; a bug?
				if (num[2]<num[1]) errel("codex range:final cannot be less than first",num)
				if (num[2]>10*num[1]) errel("codex range: range can only span 1 order of magnitude",num) //just approximate...
				num=columnize(strofreal(num[1]::num[2],sprintf("%%0%f.0f",tdigs)),"")
				
				nn=cols(num)
				ncols=1..nn
				for (cc=nn;cc>0;cc--) num=dedup(num,select(ncols,ncols:!=cc),cc,"")
				asrow=rowshape(num,1)
				mults=toindices(strlen(asrow):>1)
				for (m=1;m<=length(mults);m++) {
					fc=substr(asrow[mults[m]],1,1)
					lc=substr(asrow[mults[m]],-1)
					span=strlen(asrow[mults[m]])-1
					if (strtoreal(lc)-strtoreal(fc)==span & span>2) asrow[mults[m]]="["+fc+"-"+lc+"]"
					else asrow[mults[m]]="["+asrow[mults[m]]+"]"
					}
				num=colshape(asrow,nn)
				if (truish(dots)) num=cut(num,1,-max(dots)-1),J(rows(num),1,"."),cut(num,-max(dots))
				co.add(prefix[1]:+concat(num,"","r"),c)
				}
			else co.add(cxs[r,c],c)
			}
		}
	cxs=co.compose((&ucs,&meta))
	}

void codex::review2(|string scalar path) { //>>def member<<
	class xl scalar xls
	
	if (path=="") path=pathto("_xl.xlsx","inst")
	else path=pcanon(path,"file",".html")
	unlink(path)
	xls.create_book(path,"dummy")
	//xls.set_mode("open")
	
	key=0
	while (key<rows(keys)) {
		nextid()
		th=keys[key,1]
		gh=firstof(keys[key,2..3]')
		ih=firstof(keys[key,4..5]')
		
		hits=match()
		if (truish(hits)) {
			body=compare(rowmax(hits),subhead=J(0,0,.))
			body[,1]="selected":*tru2(body[,1])
			if (truish(subhead)) {
				//			t.set(t._hline,subhead:+hsize,.,t.Lminor)
				//			t.set(t._class,subhead:+hsize,.,"heading")
				//			t.set(t._hline,cut(subhead,2):+hsize:-1,.,t.Lsp1)
				}
			}
		else body="","-","-"
		
		reqs=dedup((ucs,colmax(hits)':*"h"),1,2,"")
		fnd=concat(select(reqs[,1],tru2(reqs[,2])),", ")
		nfnd=concat(select(reqs[,1],!tru2(reqs[,2])),", ")
		
		tab=substr(th+" "+ih,1,31)
		nono=columnize("\/*[]:?","")
		for (c=1;c<=7;c++) tab=subinstr(tab,nono[c],"-")
		xls.add_sheet(tab)
		xls.put_string(1,1,adorn("",gh,", ")+ih)
		xls.put_string(2,1,th+":")
		xls.put_string(2,2,fnd)
		xls.put_string(3,2,nfnd)
		xls.put_string(4,1,body)
		
		xls.set_fill_pattern((1,3),(1,50),"solid","200 200 200")
		xls.set_font_bold(1,(1,50),"on")
		greens=toindices(tru2(body[,1])):+3
		for (g=1;g<=length(greens);g++) xls.set_fill_pattern(greens[g],1,"solid","green")
		xls.set_number_format(3,(2,50),"[red]")
		widths=colmax(strlen(body)):+2
		for (c=1;c<=3;c++) xls.set_column_width(c,c,widths[c])
		}
	
	xls.delete_sheet("dummy")
	//xls.close_book()
	launchfile(path)
	
	}

end
//>>mosave<<

*! 27apr2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:


void collector::new() { //>>def member<
	init()
	}

//!init: ya
//!ccnt: nominal column count; defaults to 1
//!opts: [h:orz]=collect cols not rows; [n:umeric]; [f:illin=] cols to dup/fill (* for all)
void collector::init(|real scalar ccnt, string scalar opts) { //>>def member<<
	optionel(opts,(&(horz="h:orz"),&(num="n:umeric"),&(fillin="f:illin=")))
	arr=asarray_create("real",2)
	rhigh=0
	rix=1
	cwide=cdone=fill=J(1,firstof(ccnt\1),0)
	across=firstof(horz\0)
	numdata=firstof(num\0)
	if (truish(fillin)) {
		if (fillin=="*") fillc=1::length(cwide)
		else fillc=strtoreal(tokel(fillin))
		fill[fillc]=J(1,length(fillc),1)
		}
	}

//!add: add to collection
//!abit: stuff to add
//!cix: nominal column index to add to. Repeating an index starts the next row
void collector::add(matrix abit,| real scalar cix) { //>>def member<<
	cix=firstof(cix\1)
	bit=across?abit':abit
	if (cdone[cix]) next()
	rhigh=pmax(rhigh,rows(bit))
	cwide[cix]=pmax(cwide[cix],cols(bit))
	asarray(arr,(rix,cix),bit)
	cdone[cix]=1
	}

//!next: force collector to next row (/col)
void collector::next() { //>>def member<<
	if (rhigh) asarray(arr,(rix++,.),rhigh)
	rhigh=0
	cdone=cdone:*0
	}

//!compose: return entire collection
//!cos: other matrices to keep aligned with collection. If they have the same number of [n]rows as the collection, they will be dup'ed/filled to stay aligned 
matrix collector::compose(|pointer vector cos) { //>>def member<<
	if (any(cdone)) next()
	rhigh=J(1,rix-1,.)
	for (r=1;r<rix;r++) rhigh[r]=asarray(arr,(r,.))
	out=J(sum(rhigh),sum(cwide),numdata?.:"")
	r1=runningsum((1,rhigh))
	c1=runningsum((1,cwide))
	for (r=1;r<rix;r++) {
		for (c=length(cwide);c;c--) {
			rx=rows(asarray(arr,(r,c)))
			cx=cols(asarray(arr,(r,c)))
			if (rx&cx) {
				mult=fill[c]?rhigh[r]/rx:1
				if (trunc(mult)!=mult) mult=1
				if (mult>1) rx=rhigh[r]
				out[|r1[r],c1[c]\r1[r]+rx-1,c1[c]+cx-1|]=J(mult,1,asarray(arr,(r,c)))
				}
			}
		}
	for (p=1;p<=length(cos);p++) {
		co=across?(*cos[p])':(*cos[p])
		if (rows(co)==rix-1) {
			*cos[p]=J(sum(rhigh),cols(co),missingof(co))
			for (r=1;r<rix;r++) (*cos[p])[|r1[r],1\r1[r]+rhigh[r]-1,.|]=J(rhigh[r],1,co[r,])
			if (across) *cos[p]=*cos[p]'
			}
		}
	return(across?out':out)
	}
end
//>>mosave<<
*! unknown?!
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:


void dataset::new() { //>>def member<<
	nvars=nobs=0
	wdata=wlabs=wchars=0
	chars=J(0,3,"")
	}

//!with: set the status of 3 ds elements
//!elements: [d:ata] [l:abels] [c:hars] - otherwise just meta
void dataset::with(string scalar elements) { //>>def member<<
	optionel(elements,(&(d="d:ata"),&(l="l:abels"),&(c="c:hars")))
	wdata=d
	wlabs=l
	wchars=c
	if (!wchars) chars=J(0,3,"")
	if (!wdata) data=J(1,0,NULL)
	if (!wlabs) {
		vlabnames=J(1,0,"")
		vlabtabs=J(1,0,NULL)
		}
	}

//!read: create dataset obj from memory 
void dataset::readmem(|matrix clear) { //>>def member<<
	nvars=st_nvar() //this makes sure (e) is final & excluded!
	nobs=st_nobs()
	dtalabel=st_macroexpand("`"+":data l"+"'")
	dtstamp=c("current_date")+" "+substr(c("current_time"),1,5)
	
	nlabels=sirtypes=vlabrefs=formats=hold=J(1,nvars,"")
	bytes=J(1,nvars,.)
	if (nvars) {
		vnames=st_varname(1..nvars)
		for (n=1;n<=nvars;n++) {
			nlabels[n]=st_varlabel(n)
			vlabrefs[n]=st_varvaluelabel(n)
			formats[n]=st_varformat(n)
			hold[n]=st_vartype(n)
			}
		hold=othtypes(hold)
		sirtypes=hold[1,]
		bytes=strtoreal(hold[2,])
		sortvars=varlist(st_macroexpand("`"+":sortedby"+"'"))
		sortvars=sortvars,J(1,nvars-cols(sortvars),0)
		}
	
	if (wlabs) { //labels
		stata("qui label dir")
		vlabnames=tokel(st_global("r(names)"))
		if (length(vlabnames)) {
			vlabtabs=J(1,length(vlabnames),NULL)
			vals=J(0,0,.);labs=J(0,0,"")
			for (n=1;n<=length(vlabtabs);n++) {
				st_vlload(vlabnames[n],vals,labs)
				vlabtabs[n]=&(strofreal(vals),labs)
				}
			}
		}
	if (wchars) { //chars
		chars=J(0,3,"")
		evars="_dta",vnames
		for (n=1;n<=length(evars);n++) {
			c2=st_dir("char",evars[n],"*")
			chars=chars\J(rows(c2),1,evars[n]),c2,(::charget(evars[n],c2))
			}
		}
	if (wdata) {
		data=J(1,nvars,NULL)
		for (n=1;n<=nvars;n++) {
			data[n]=&el_data(.,vnames[n])
			if (truish(clear)) st_dropvar(vnames[n])
			}
		}
	}

void dataset::readmat(string rowvector vars, string matrix din) { //>>def member
	if (length(vars)!=cols(data)) errel("Number of vars doesn't match number of data columns.")
	with("data")
	nvars=length(vars)
	nobs=rows(data)
	dtalabel=""
	dtstamp=c("current_date")+substr(c("current_time"),1,5)
	vnames=vars
	sirtypes=J(1,length(vars),"s")
	bytes=colmax(strlen(data)) //doesn't handle strL
	bytes=bytes:+(bytes:==0)
	data=J(1,cols(data),NULL)
	for (d=1;d<=cols(din);d++) data[d]=&din[,d]
	nlabels=vlabrefs=J(1,nvars,"")
	formats=adorn("%-",strofreal(bytes),"s")
	sortvars=J(1,nvars,0)
	}

//!gen: generate a new variable
//!patvar: name of existing var to copy (or empty string)
//!name: varname
//!dtype: stata datatype (byte int long float double str[x]
//!nlab: name label
//!format: format
//!vlab: value label, will copy labtab on first ref
void dataset::gen(string scalar patvar,| string scalar name, string scalar dtype, string scalar nlab, string scalar format, string scalar vlab) { //>>def member<<
	if (truish(name)&truish(varlist(name,"nfok"))) errel(sprintf("Dataset: new varname ({hi:%s}) already exists: {hi:%s}",name,concat(vnames,", ")))
	
	if (truish(patvar)) {
		pattype=st_vartype(patvar)
		patnlab=st_varlabel(patvar)
		patformat=st_varformat(patvar)
		patvlab=st_varvaluelabel(patvar)
		
		patchars=st_dir("char",patvar,"*") //not sure I really want chars...
		}
	else pattype=patnlab=patformat=patvlab=""
	
	nvars=nvars+1
	name=firstof(name\patvar)
	vnames=vnames,name
	hold=othtypes(firstof(dtype\pattype))
	sirtypes=sirtypes,hold[1]
	bytes=bytes,strtoreal(hold[2])
	strls=strls,0
	nlabels=nlabels,firstof(nlab\patnlab)
	formats=formats,firstof(format\patformat\(hold[1]=="s"?"%-50s":"%12.3g"))
	data=data,&J(nobs,1,hold[1]=="s"?"":.)
	sortvars=sortvars,0
	vlnext=firstof(vlab\patvlab)
	vlabrefs=vlabrefs,vlnext
	if (truish(vlnext)&sum(vlabrefs:==vlnext)==1) {
		st_vlload(vlnext,num,str)
		if (length(num)) {
			vlabnames=vlabnames,vlnext
			vlabtabs=vlabtabs,&(strofreal(num),str)
			}
		}
	for (pc=1;pc<=length(patchars);pc++) chars=chars\name,patchars[pc],(::charget(patvar,patchars[pc]))
	}

void dataset::setk(real scalar k) { //>>def member<<
	//oughta fill with valid values? this isn't used yet!
	nvars=k
	vnames=cut(vnames,.,k,k)
	sirtypes=cut(sirtypes,.,k,k)
	bytes=cut(bytes,.,k,k)
	strls=cut(strls,.,k,k)
	nlabels=cut(nlabels,.,k,k)
	formats=cut(formats,.,k,k)
	sortvars=J(1,k+1,0)
	vlabrefs=cut(vlabrefs,.,k,k)
	data=cut(data,.,k,k)
	}

void dataset::settypes() { //>>def member<<
	for (v=1;v<=nvars;v++) {
		sb=othtypes(tinytype(*data[v]))
		sirtypes[v]=sb[1]
		bytes[v]=strtoreal(sb[2])
		if (sirtypes[v]=="s") vlabrefs[v]=""
		if (sirtypes[v]=="s"&substr(formats[v],-1)!="s") formats[v]="%20s"
		else if (sirtypes[v]!="s"&substr(formats[v],-1)=="s") formats[v]="%12.3g"
		}
	}

//!add: add empty observations
//!plusn: number to add
void dataset::add(real scalar plusn) { //>>def member<<
	for (v=1;v<=nvars;v++) *data[v]=*data[v]\J(plusn,1,missingof(*data[v]))
	nobs=nobs+plusn
	}

void dataset::writemem(|matrix keep) { //>>def member<<
	wdata=truish(keep)
	stata("qui clear")
	if (nvars) (void) st_addvar(othtypes(sirtypes,bytes),vnames)
	stata(sprintf(`"label data "%s""',dtalabel))
	
	for (n=1;n<=nvars;n++) {
		st_varlabel(n,nlabels[n])
		if (strlen(vlabrefs[n])) st_varvaluelabel(n,vlabrefs[n]) //error for strings otherwise
		st_varformat(n,formats[n])
		}
	if (any(sortvars)) stata("sort "+concat(vnames[select(sortvars,sortvars)]," "))
	
	st_addobs(nobs)
	for (n=1;n<=length(data);n++) {
		el_store(.,vnames[n],*data[n])
		if (!wdata) data[n]=NULL
		}
	
	for (n=1;n<=length(vlabnames);n++) {
		st_vlmodify(vlabnames[n],strtoreal((*vlabtabs[n])[,1]),(*vlabtabs[n])[,2])
		}
	
	for (c=1;c<=rows(chars);c++) charset(chars[c,1],chars[c,2],chars[c,3])
	}

real vector dataset::varlist(string vector pats,|string scalar options, string vector mods, matrix notfound) { //>>def member<<
	if (!nvars) {
		mods=notfound=J(1,0,"")
		return(J(1,0,.))
		}
	
	varlist=varlistk(vnames,pats,options,mods,notfound)
	return(vmap(varlist,vnames))
	}

string matrix dataset::labelsof(real scalar vix) { //>>def member<<
	if (!length(vlabnames)) return(J(0,2,""))
	if (length(found=toindices(vlabnames:==vlabrefs[vix]))) return(*vlabtabs[found])
	else return(J(0,2,""))
	}
string vector dataset::charget(string vector vars, string vector chrs) { //>>def member
	if ((lv=length(vars))>1&(lc=length(chrs))>1) errel("ds.charget: Only 1 of vars or chars can be a multiple")
	if (!lv) return(vars:*0)
	if (!lc) return(chrs:*0)
	if (lv>=lc) {
		some=select(chars[,(1,3)],chars[,2]:==chrs)
		if (!truish(some)) return(vars:*0)
		return(shapeof(lookupin(some[,2],vmap(vars,some[,1])),vars,))
		}
	else {
		some=select(chars[,(2,3)],chars[,1]:==vars)
		if (!truish(some)) return(chrs:*0)
		return(shapeof(lookupin(some[,2],vmap(chrs,some[,1])),chrs))
		}
	}

matrix dataset::getdat(real vector rows, vector cols) { //>>def member<<
	if (eltype(cols)=="real") {
		if (cols==.) vars=1..nvars
		else vars=cols
		}
	else vars=varlist(cols,"all")
	if (!length(vars)) return(J(0,0,""))
	if (any(sirtypes[vars]:=="s")&any(sirtypes[vars]:!="s")) errel("dataset.getdat() cannot reference both string and numeric variables")
	if (rows==.) rows=1::nobs
	out=J(length(rows),length(vars),missingof(*data[vars[1]]))
	for (v=1;v<=length(vars);v++) out[,v]=(*data[vars[v]])[rows]
	return(out)
	}

void dataset::setdat(real vector rows, vector cols, matrix input) { //>>def member<<
	if (eltype(cols)=="real") {
		if (cols==.) vars=1..nvars
		else vars=cols
		}
	else vars=varlist(cols,"all")
	if (!length(vars)) return(J(0,0,""))
	if (any(sirtypes[vars]:=="s")&any(sirtypes[vars]:!="s")) errel("dataset.setdat() cannot reference both string and numeric variables")
	for (v=1;v<=length(vars);v++) (*data[vars[v]])[rows]=input[,v]
	}

string matrix dataset::strdat(real vector rows, real vector cols) { //>>def member<<
	if (nobs) {
		if (rows==.) rows=1..nobs
		if (cols==.) cols=1..nvars
		out=J(length(rows),length(cols),"")
		for (c=1;c<=length(cols);c++) {
			if (sirtypes[cols[c]]=="s") out[,c]=(*data[cols[c]])[rows]
			else if (strhas(formats[cols[c]],("%t","%-t","%d","%-d"),1)) out[,c]=el_strof((*data[cols[c]])[rows]) //d possible for older versions?
			//		else if (strhas(formats[cols[c]],("%t","%-t","%d","%-d"),1)) out[,c]=strofreal((*data[cols[c]])[rows],"%20.0g") //d possible for older versions?
			else out[,c]=strofreal((*data[cols[c]])[rows],formats[cols[c]])
			}
		return(out)
		}
	else return(J(0,length(cols),""))
	}

//!shrink: drops variables
//!how: [k*]eep or [d*]rop
//!vars: var indexes
void dataset::shrink(string scalar how, real vector vars) { //>>def member<<
	vars=dedup(colshape(vars,1))
	if (substr(strtrim(how),1,1)=="k") kvars=vars
	else if (substr(strtrim(how),1,1)=="d") kvars=vmap(1..nvars,vars,"not")
	else errel("Dataset shrink must specify -drop- or -keep-")
	
	vvecs=(&vnames,&nlabels,&sirtypes,&bytes,&vlabrefs,&formats)
	if (length(data)) vvecs=vvecs,&data
	for (vv=1;vv<=cols(vvecs);vv++) {
		*vvecs[vv]=(*vvecs[vv])[kvars]
		}
	nvars=length(kvars)
	
	sortvars=sortvars[vmap(sortvars,kvars,"in")]
	sortvars=sortvars,J(1,nvars-length(sortvars),0)
	labkeep=vmap(vlabnames,vlabrefs)
	vlabnames=selectv(vlabnames,labkeep,"r")
	vlabtabs=selectv(vlabtabs,labkeep,"r")
	chars=chars[vmap(chars[,1],("_dta",vnames),"in"),]
	}

end
//>>mosave<<

*! 8dec2015
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:


void dtareport::tochar() { //>>def member
	charset("_dta","dtar",scofmat(title\dscr\rev\notes))
	}

void dtareport::fromchar() { //>>def member
	all=sctomat(charget("_dta","dtar"))
	if (cols(all)!=1|rows(all)<3) printf("{txt:No dtar info is present}\n")
	else {
		title=all[1]
		dscr=all[2]
		rev=all[3]
		notes=cut(all,4)
		}
	}

void dtareport::display() { //>>def member
	class tabel scalar t
	
	t.set(t._wrap,.,.,-3)
	t.set(t._align,.,.,t.left)
	t.set(t._hline,.,.,t.Lsp1)
	t.set(t._hline,1..2,.,t.Lnone)
	t.set(t._hline,3,.,t.Lmajor)
	t.set(t._class,1..3,.,"heading")
	t.set(t._class,1,.,"bf","pre")
	t.body=title\3*" "+rev\3*" "+dscr\notes
	t.present("v")
	}

void dtareport::save(string scalar cmd2) { //>>def member
	syntaxl(cmd2,&(fname="anything"),&(grail="el_grail=")) //feinfo not set up
	tochar()
	if (truish(grail)) charset("_dta","el_grail",scofmat(el_grail(grail)))
	path=pcanon(fname,"file","dtar")
	savel(path,"","dtar") //as odata; that's fine
	}
end
//>>mosave
*! 19dec2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:


void elfs::new() { //>>def member
	blist=0
	bedit=1
	bsave=2
	bdrop=3
	mapix=1
	getix=2
	}

void elfs::init() { //>>def member<<
	epath=pathto(sprintf("elf_%s.lmat",ename))
	if (fexists(epath)) {
		stored=fin_lmat(epath,"elfs "+ename)
		if (length(stored)==3) {
			if (*stored[1]==head & cols(*stored[2])==cols(base)) {
				elf=*stored[2]
				anci=*stored[3]
				return
				}
			}
		printf("{res:%s} {txt:does not have the correct variables. It will be ignored.}\n",pathparts(epath,(23)))
		}
	elf=J(0,cols(base),"")
	}

string matrix elfs::uelf() { //>>def member
	uelf=base\elf
	uelf=dedup(uelf[rows(uelf)::1,],1..mapix)
	uelf=uelf[rows(uelf)::1,]
	return(uelf)
	}

void elfs::button(string rowvector opts) { //>>def member
	optionel(opts,(&(edit="edit"),&(save="save"),&(del="del="),&(help="help")),opts)
	if (edit) {
		all=J(rows(base),1,"built-in"),base\J(rows(elf),1,"user"),elf
		clearl() //or preserve?
		(void) st_addvar("str":+strofreal(colmax(strlen(all))),("source",head))
		st_addobs(rows(all))
		el_store(.,.,all)
		stata("edit")
		printf(`"{txt:Don't forget to }{stata "elfs %s, save":save}"',ename)
		}
	else if (save) {
		uelf=el_data(.,head)
		uelf=selectv(uelf,tru2(uelf[,1]),"c")
		del=charsubs(uelf)
		map=vmap(concat(uelf,del,"r"),concat(base,del,"r"),"not")
		if (truish(map)) elf=uelf[map,]
		else elf=J(0,cols(head),"")
		write()
		clearl() //or restore?
		list()
		}
	else if (truish(del)) {
		elf=select(elf,elf[,1]:!=del)
		write()
		list()
		}
	else obutton(opts)
	if (help) stata(sprintf("help elfs %s",ename))
	}

string matrix elfs::get(string scalar id) { //>>def member
	uelf=uelf()
	if (truish(id)) {
		oelf=select(uelf,uelf[,1]:==id)
		if (truish(oelf)) return(cut(oelf,getix))
		
		printf("{txt:elfs %s not found:} {res:%s}\n",ename,id)
		}
	return(notfound())
	}

string matrix elfs::notfound() { //>>def member
	return(J(0,cols(base),""))
	}

void elfs::write() { //>>def member<<
	elf=dedup(elf)
	fout_lmat(epath,(&head,&elf,&anci),"elfs "+ename)
	}

void elfs::obutton(string rowvector opts) { //>>def member
	pragma unused opts
	list()
	}

void elfs::list() { //>>def member
	class tabel scalar t
	t.body=strproper(head)\base\elf
	t.head=1
	t.stub=1
	t.present("")
	}

end
//>>mosave<<
*! 11dec2014
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata: 


real scalar errtab::newtab(string scalar emsg, string rowvector headings) { //>>def member<<
	etabs=etabs,&(emsg,J(1,cols(headings),"")\"",headings)
	haserror=haserror,0
	return(length(etabs))
	}

void errtab::newerr(string matrix info,| real scalar tabix, real scalar noterr) { //>>def member<<
	if (!truish(tabix)) tabix=1
	noterr=firstof(noterr\0)
	*etabs[tabix]=*etabs[tabix]\!noterr:*J(rows(info),1,char(164)),info
	haserror[tabix]=1
	}

void errtab::present() { //>>def member<<
	class tabel scalar t
	
	for (e=1;e<=length(etabs);e++) {
		if (haserror[e]) {
			t.body=*etabs[e]
			t.head=2
			t.set(t._align,.,.,t.left)
			t.set(t._span,1,1,cols(t.body))
			t.set(t._align,1,1,t.left)
			t.set(t._class,1,.,"err")
			t.set(t._class,.,1,"err")
			t.set(t._hline,1,.,t.Lsp1)
			t.render()
			}
		}
	etabs=J(1,0,NULL)
	haserror=J(1,0,.)
	
	if (truish(t.rendered)) {
		t.present("-")
		exit()
		}
	}

end
//>>mosave<<
*! 3mar2016 -- pulled out of feinfo
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:


void ferunner::run(string vector codein, real scalar slin, real scalar flin, string scalar pathin) { //>>def member
	ocode=codein
	sl=slin
	fl=flin
	opath=pathin
	if (truish(things=regexs2(ocode,".+ +{ +//>>def (.+)",1))) compile(things)
	else {
		doname="run"
		docode=ocode
		if (!truish(st_global("fe_runplain"))) grun()
		}
	}

void ferunner::compile(string vector things) { //>>def member
	doname="compile"
	
	msave=any(regexm(ocode," *//>>mosave"))
	th1=substr(things,1,1)
	pref=suf=""
	for (t=sl;t<=fl;t++) {
		if (anyof(("f","m"),th1[t])) { //func or member
			id=regexs2(ocode[t],"[^ ]+\(",0)+")"
			sput(pref,"capture mata mata drop "+id)
			}
		else if (th1[t]=="c") { //class
			id=regexs2(ocode[t],"class +([^ ]+)",1) //dropping doesn't work :-(
			sput(pref,"clear mata") //global class examples...
			}
		if (msave & anyof(("f","c"),th1[t])) {
			mopath=tokenpath(pathparts(opath,1))
			if (strlen(cut(mopath,-1))==1) mopath[length(mopath)]=substr(id,1,1)
			//should include "complete" but it crashes...
			sput(suf,"mata mata mosave "+id+sprintf(`", dir("%s") replace"',untokenpath(mopath)))
			}
		}
	docode=pref+concat(ocode[|sl\fl|]:+eol(),"")+suf
	}


void ferunner::grun() { //>>def member
	grcmd=vec(toindices(regexm(ocode,"^ *(savel|html +write)")))
	gropt=vec(toindices(regexm(ocode,",.*out\( *htm"):&!regexm(ocode,",.*out\( *html p")))
	if (truish(grcmd)|truish(gropt)) {
		grail=J(2+length(grcmd)+length(gropt),1,"")
		grail[1]=datetime("%tc+CCYY/JJJ/HH:MM:SS")
		grail[2]=opath
		gix=3
		
		begs=regexm(ocode,("^ *(usel|collect|clearl|savel|sql +get|sql +do.*dest\( *\* *\))"))'
		sis=toindices(regexm(ocode,"^ *sqli"))
		for (s=1;s<=length(sis);s++) {
			lcmd=strtrim(cut(tokel(substr(ocode[sis[s]],strpos(ocode[sis[s]],"sqli")+4),";"),-1))
			begs[sis[s]]=substr(strlower(lcmd),1,strpos(lcmd," ")-1)=="select"
			}
		begs=1,toindices(begs)
		
		for (o=1;o<=rows(grcmd);o++) {
			comma=","*(length(tokel(ocode[grcmd[o]],","))==1)
			
			il=cut(select(begs,grcmd[o]:>=begs),-1)
			grail[gix]=concat(ocode[il..grcmd[o]],eol())
			docode[grcmd[o]]=ocode[grcmd[o]]+sprintf("%s el_grail(%s %f)",comma,grail[1],gix++) 
			}
		for (o=1;o<=rows(gropt);o++) {
			x=tokenstrip(tokel(ocode[gropt[o]]))
			ix=toindices(subinstr(x[,1],",",""):=="out") //param& only1
			comma=","*(length(tokel(x[ix,2],","))==1)
			
			il=cut(select(begs,gropt[o]:>=begs),-1)
			//when another option is missing its final paren, this can hide the problem
			grail[gix]=concat(ocode[il..gropt[o]],eol())
			x[ix,2]=x[ix,2]+sprintf("%s el_grail(%s %f)",comma,grail[1],gix++)
			hadp=!tru2(x[,4])
			x[,2]=hadp:*"(":+x[,2]:+hadp:*")"
			docode[gropt[o]]=concat(concat(x,"")," ")
			}
		st_global("el_grail",scofmat(grail))
		}
	docode=concat(docode[|sl\fl|]:+eol(),"")
	}

stata("capture mata mata drop el_grail()")
string matrix el_grail(string scalar grailopt) { //>>def func
	bits=expand(tokel(grailopt),2)
	grail=sctomat(st_global("el_grail"))
	if (truish(bits)&truish(grail)) {
		gix=strtoreal(bits[2])
		if (grail[1]==bits[1]&length(grail)>=gix) return("File Path",grail[2]\"Code",grail[gix])
		}
	
	printf("{hi:Grail info is unavailable; no grail info will be saved.}\n")
	return("Missing/unavailable")
	}

end
//>>mosave
*!unknown
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:
end
 global opix (`"!#&*+,-<div id=,opix,>*<hr id=,opixhr1,>*<p ondblclick=,fe=document.getElementById("el_grail"); if (fe.style.display=="none") fe.style.display="block"; else fe.style.display="none",>*<span id=,opixsp1,>%s</span>*<span id=,opixsp2,>rev: %s</span>*<br />%s</p>*<hr id=,opixhr2,>*</div>"')
 mata:
end
 global css (`"!"&()+7<style>(/*cssreset*/(html,body,div,span,object,iframe,h1,h2,h3,h4,h5,h6,p,blockquote,pre,abbr,address,cite,code,del,dfn,em,img,ins,kbd,q,samp,small,strong,sub,sup,var,b,i,dl,dt,dd,ol,ul,li,fieldset,form,label,legend,table,caption,tbody,tfoot,thead,tr,th,td,article,aside,canvas,details,figcaption,figure,footer,header,hgroup,menu,nav,section,summary,time,mark,audio,video {margin:0;padding:0;border:0;font-size:100%;vertical-align:baseline;background:transparent}(body{font-size: .8em;line-height:1.3;font-family:trebuchet ms,tahoma,arial,helvetica,geneva,sans-serif;margin:5px}(article,aside,details,figcaption,figure,footer,header,hgroup,menu,nav,section{display:block}(nav ul{list-style:none}(blockquote,q{quotes:none}(blockquote:before,blockquote:after,q:before,q:after{content:none}(a{margin:0;padding:0;font-size:100%;vertical-align:baseline;background:transparent}(ins{background-color:#ff9;color:#000;text-decoration:none}(mark{background-color:#ff9;color:#000;font-style:italic;font-weight:bold}(del{text-decoration:line-through}(abbr[title],dfn[title]{border-bottom:1px dotted;cursor:help}(table{border-collapse:collapse;border-spacing:0}(hr{display:block;height:1px;border:0;border-top:1px solid #ccc;margin:1em 0;padding:0;text-align:left}(input,select{vertical-align:middle}((/*opix*/(div#opix {border-left:3px solid;border-color:gray;line-height:1;margin-bottom:1em}(hr#opixhr1 {margin:3px 0; width: 4px; border-top:3px solid gray}(hr#opixhr2 {margin:3px 0; width: 40px; border-top:3px solid gray}(div#opix > p {margin-left:5px}(span#opixsp1{font-weight:bold;font-size:150%}(span#opixsp2{font-size:90%;color:gray;margin-left:10px}(/*no desc styling?*/((/*grail*/(table#el_grail {display:none}(table#el_grail td.elgleft {border-bottom:1px solid lightgray; color:gray;padding-right:1em;text-align:right}(table#el_grail td.elgright {border-bottom:1px solid lightgray}((</style>"')
 mata:
end
 global grail (`"!"#&()*<table id=)el_grail)>&<tr><td class=)elgleft)>%s</td><td class=)elgright)>%s</td></tr>&<tr><td class=)elgleft)>%s</td><td class=)elgright)>%s</td></tr>&</table>"')
 mata:


void htmlpgs::new() { //>>def member<<
	parts=asarray_create("string",3)
	asarray_notfound(parts,"") //divatts, and jswas
	addix=0
	_nodiv=char(21)
	_defdiv=_nodiv
	_na="/"
	
	_div="div"
	_par="parents"
	_fwjs="fwjs"
	_fwcss="fwcss"
	_pgjs="pgjs"
	_pgcss="pgcss"
	_divatts="divatts"
	_opix="opix"
	}

void htmlpgs::page(|string scalar pgid) { //>>def member<<
	if (truish(pgid)) printf("{txt:Page set to explicit id:} {res:%s}",pgid)
	cpg=firstof(pgid\"pg1")
	cdiv=_nodiv
	clear(cpg) //this doesn't actually allow switching
	asarray(parts,(cpg,_div,_nodiv),"")
	}

void htmlpgs::header(string scalar title, string scalar rev, string scalar dscr,|string scalar div) { //>>def member<<
	if (truish(together=(title,rev,dscr))) {
		meta=subinstr(subinstr(together,char(39),"&apos;"),char(34),"&quot;")
		meta=sprintf("<meta name='outputix' content='%s'>",concat(adorn(("t(","r(","d("),meta,")")," "))
		human=sprintf(strob_to($opix),title,rev,dscr)
		asarray(parts,(cpg,_opix,_na),(meta,human,firstof(div\_nodiv)))
		}
	//else meta=human=""
	//asarray(parts,(cpg,_opix,_na),(meta,human,firstof(div\_nodiv)))
	}

void htmlpgs::addfw(string scalar path,| matrix embed) { //>>def member<<
	if (truish(js1=findfile(path+".jel"))) asarray(parts,(cpg,_fwjs,js1),truish(embed)) //because .js files can cause everthing to be trashed in transit
	if (truish(js2=findfile(path+".js"))) asarray(parts,(cpg,_fwjs,js2),truish(embed))
	if (truish(css=findfile(path+".css"))) asarray(parts,(cpg,_fwcss,css),truish(embed))
	if (!truish(js1)&!truish(js2)&!truish(css)) errel("htmlpgs: framework not found ",path)
	}
void htmlpgs::addjs(string scalar js, |string scalar id) { //>>def member<<
	if (truish(id)) asarray(parts,(cpg,_pgjs,id),(strofreal(++addix),js))
	else {
		was=cut(asarray(parts,(cpg,_pgjs,_na)),-1)
		asarray(parts,(cpg,_pgjs,_na),(strofreal(++addix),was+eol()+js))
		}
	}
void htmlpgs::addcss(string scalar a,| string scalar b) { //>>def member<<
	if (!truish(a)) return
	if (truish(b)) asarray(parts,(cpg,_pgcss,a),(strofreal(++addix),b))
	else if (!strpos(a,"{")) asarray(parts,(cpg,_pgcss,a),(strofreal(++addix),ftostr(pcanon(a,"fex","css"))))
	else {
		parsed=chtrim(columnize(columnize(a,"}")',"{"),char((9,10,13,32)))
		for (p=1;p<=rows(parsed);p++) asarray(parts,(cpg,_pgcss,parsed[p,1]),(strofreal(++addix),parsed[p,1]+adorn(" {",parsed[p,2],"}")))
		}
	}

void htmlpgs::div(string scalar id,| string scalar parent, string scalar atts) { //>>def member<<
	if (id==""|id==_nodiv) errel("htmlpgs: div ids cannot be empty (or =nodiv)")
	if (asarray_contains(parts,(cpg,_div,id))) {
		if (strlen(parent)) printf("{txt:%s: parent() ignored}\n",id)
		if (strlen(atts)) printf("{txt:%s: atts() ignored}\n",id)
		}
	else {
		parent=firstof(parent\_nodiv)
		if (!asarray_contains(parts,(cpg,_div,parent))) errel(sprintf("Parent id not found: %s",parent))
		cpar=asarray(parts,(cpg,_par,parent))
		if (!truish(cpar)) asarray(parts,(cpg,_par,parent),id)
		else asarray(parts,(cpg,_par,parent),(cpar,id))
		asarray(parts,(cpg,_div,id),"")
		asarray(parts,(cpg,_divatts,id),atts)
		}
	cdiv=id
	}

void htmlpgs::place(string scalar body) { //>>def member<<
	asarray(parts,(cpg,_div,cdiv),asarray(parts,(cpg,_div,cdiv))+body+eol())
	}

string scalar htmlpgs::base64(string scalar data,| matrix nobreak) { //>>def member<<
	dl=strlen(data)-1
	coder=columnize(char((65..90,97..122,48..57,43,47)),"")
	c=bufio()
	out=""
	
	for (s=0;s<=dl;++s) {
		octet=bufget(c,data,s,"%1bu")
		b64=trunc(octet/4)
		pre2=(octet-b64*4)*16
		out=out+coder[b64+1]
		
		octet=++s<=dl?bufget(c,data,s,"%1bu"):0
		b64=trunc(octet/16)
		pre3=(octet-b64*16)*4
		out=out+coder[pre2+b64+1]
		
		octet=++s<=dl?bufget(c,data,s,"%1bu"):0
		b64=trunc(octet/64)
		out=out+(s>dl+1?"=":coder[pre3+b64+1])+(s>dl?"=":coder[octet-b64*64+1])
		}
	if (!truish(nobreak)) for (s=77;s<=strlen(out);s=s+78) out=substr(out,1,s-1)+char((13,10))+substr(out,s)
	return(out)
	}

void htmlpgs::write(string scalar pgid, string scalar path,|string scalar grail) { //>>def member<<
	keys=sort(asarray_keys(parts),(1..3))
	pgid=firstof(pgid\"pg1")
	keys=select(keys,keys[,1]:==pgid)
	if (!length(keys)) errel("htmlpgs: page id not found",pgid)
	
	sput(f="","<!DOCTYPE HTML>")
	sput(f,"<html><head>")
	sput(f,"<meta charset='utf-8'>")
	sput(f,"<meta http-equiv='X-UA-Compatible' content='IE=edge'>")
	
	if (truish(opix=asarray(parts,(cpg,_opix,_na)))) {
		if (truish(grail)) {
			//needs to go into _nodiv or _notnav -- set by class somehow??
			grail=subinstr(subinstr(el_grail(grail),">","&gt;"),"<","&lt;")
			grail=subinstr(grail,eol(),"<br />")
			grtext=sprintf(strob_to($grail),grail[1,1],grail[1,2],grail[2,1],grail[2,2])
			asarray(parts,(cpg,_div,_defdiv),grtext+asarray(parts,(cpg,_div,_defdiv))+eol())
			
			//unkluge this! s(=source
			opix[1]=subinstr(opix[1],"'>",sprintf(" s(%s)'>",grail[1,2]))
			}
		asarray(parts,(cpg,_div,opix[3]),opix[2]+asarray(parts,(cpg,_div,opix[3]))+eol())
		sput(f,opix[1]) //gotta escape apostraphes, others?
		}
	
	sput(f,strob_to($css))
	ks=select(keys,keys[,2]:==_fwcss)
	for (k=1;k<=rows(ks);k++) {
		if (truish(asarray(parts,ks[k,]))) sput(f,"<style>"+eol()+ftostr(ks[k,3])+eol()+"</style>"+eol())
		else sput(f,sprintf("<link rel='stylesheet' href='file:///%s'>",ks[k,3]))
		}
	ks=select(keys,keys[,2]:==_fwjs)
	for (k=1;k<=rows(ks);k++) {
		if (truish(asarray(parts,ks[k,]))) sput(f,"<script>"+eol()+ftostr(ks[k,3])+eol()+"</script>"+eol())
		else sput(f,sprintf("<script src='file:///%s'></script>",ks[k,3]))
		}
	
	res=_pgcss,"<style>","</style>"\_pgjs,"<script>","</script>"
	for (r=1;r<=2;r++) {
		ks=select(keys,keys[,2]:==res[r,1])
		if (truish(ks)) {
			for (k=1;k<=rows(ks);k++) ks[k,1..2]=asarray(parts,ks[k,])
			dt=strtoreal(ks[,1])
			cosort_((&dt,&ks),1)
			sput(f,res[r,2]+eol()+concat(ks[,2],eol())+res[r,3]+eol())
			}
		}
	
	sput(f,"</head>")
	sput(f,"<body>")
	writedivs(keys,_nodiv,f)
	sput(f,"</body></html>")
	
	if (path=="") fowrite(path=pathto("_html.html","inst"),f)
	else if (pathparts(path,1)==seattel()) fowrite(path,f)
	else fowrite(path=pcanon(path,"file",".html"),f,"v")
	}

void htmlpgs::writedivs(string matrix keys, string vector divid, string scalar f) { //>>def member<<
	f=f+"<div id='"+divid+"' "+asarray(parts,(cpg,_divatts,divid))+">"+eol()
	
	adiv=asarray(parts,(cpg,_div,divid))
	f=f+adiv+eol()
	
	cdivs=asarray(parts,(cpg,_par,divid))
	for (c=1;c<=truish(cdivs);c++) writedivs(keys,cdivs[c],f)
	f=f+"</div>"+eol()
	}

void htmlpgs::clear(|string scalar pgid) { //>>def member<<
	keys=asarray_keys(parts)
	if (truish(pgid)) keys=select(keys,keys[,1]:==pgid)
	for (k=1;k<=rows(keys);k++) asarray_remove(parts,keys[k,])
	}

string matrix htmlpgs::query(|matrix all) { //>>def member<<
	if (truish(all)) {
		keys=sort(asarray_keys(parts),(1..3))
		contents=J(rows(keys),1,"")
		for (k=1;k<=rows(keys);k++) {
			contents[k]=concat(concat(asarray(parts,keys[k,]),"-*-"),"-*")
			}
		return((keys,contents))
		}
	else {
		keys=asarray_keys(parts)
		keys=select(keys,keys[,2]:==_pgcss)
		if (truish(keys)) {
			for (k=1;k<=rows(keys);k++) keys[k,1..2]=asarray(parts,keys[k,])
			dt=strtoreal(keys[,1])
			cosort_((&dt,&keys),1)
			css=chtrim(strtrim(tokel(concat(keys[,2],""),"}")'))
			css=columnize(css,"{")
			return(css)
			}
		}
	}

end
//>>mosave<<
*! 16jul2015
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:


void htmltable::read(string scalar matter) { //>>def member
	x=expand(tokel(matter,"<table"\"</table>"),3)
	pre=x[1]
	post=x[3]
	mark=strpos(x[2],">")
	tab=strtrim(substr(x[2],1,mark-1))
	
	x=columnize(substr(x[2],mark+1),"</tr>")'
	x=cut(x,1,-2)
	mark=strpos(x,"<td")
	trows=substr(x,1,mark:-1)
	trows=columnize(columnize(trows,"<tr")[,2],">")[,1]
	x=columnize(substr(x,mark),"</td>","each")
	x=cut(x,1,-2)
	mark=strpos(x,">")
	tcells=substr(x,1,mark)
	tcells=strtrim(subinstr(subinstr(tcells,"<td",""),">",""))
	tconts=substr(x,mark:+1)
	}

string scalar htmltable::write() { //>>def member
	return(pre+"<table "+tab+">"+ concat("<tr ":+trows:+">":+concat("<td ":+tcells:+">":+tconts:+"</td>","","r"):+"</tr>","") +"</table>"+post)
	}

end
//>>mosave
*!30may2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

void models::new() { //>>def member
	t_reg=1;t_log=2;t_cox=3;t_pois=4;t_stcr=5
	tmax=0
	}

//!add: adds a model using the current ereturn
//!label: label/description for the model
void models::add(|string scalar label) { //>>def member<<
	etype=st_global("e(cmd)")
	if (!truish(etype)) errel("No estimation results found")
	typ=toindices(etype:==("regress","logistic","cox","poisson","stcrreg"))
	if (!length(typ)) errel("Estimation command not supported: %s",etype)
	
	types=types,typ
	mlabs=mlabs,label
	
	top="N",strofreal(st_numscalar("e(N)"),"%9.0f")
	if (typ==t_reg) {
		top="DV",st_global("e(depvar)")\top\"r2",strofreal(st_numscalar("e(r2)"),"%9.3g")
		more=more,&st_numscalar("e(df_r)")
		}
	else if (anyof((t_log,t_pois),typ)) {
		top="DV",st_global("e(depvar)")\top
		more=more,NULL
		}
	else if (anyof((t_cox,t_stcr),typ)) {
		top="DV",charget("_dta","st_bt")/*fail time*/\top\"N sub",strofreal(st_numscalar("e(N_sub)"))\"N fail",strofreal(st_numscalar("e(N_fail)"))\"Failure",charget("_dta","st_bd")
		if (typ==t_stcr) top=top\"Compete",st_global("e(crevent)")
		top[2,1]="N obs"
		more=more,NULL
		}
	if (truish(wtype=st_global("e(wtype)"))) top=top\wtype,st_global("e(wexp)")
	tmax=pmax(tmax,rows(top))
	tops=tops,&(top'')
	
	vars=st_matrixcolstripe("e(b)")[,2]
	bl=strpos(vars,"b.")
	vars=subinstr(vars,"b.",".")
	plus=vmap(vars,stub,"not")
	if (truish(plus)) stub=stub\vars[plus]
	rmap=vmap(vars,stub,"only")
	vars=colwords(vars,"r",2,".")
	for (p=1;p<=length(plus);p++) {
		var=vars[plus[p],2]
		if (var=="_cons") t.spoofn(var,var,0,"constant")
		else t.spoofn(var,var,0,st_varlabel(var))
		if (bl[plus[p]]) {
			if (truish(vl=st_varvaluelabel(var))) {
				st_vlload(vl,num,str)
				t.spoofv(var,(J(1,2,strofreal(num)),str))
				}
			}
		}
	rmaps=rmaps,&(rmap'')
	
	se=sqrt(diagonal(diag(st_matrix("e(V)"))))
	b=st_matrix("e(b)")'
	
	if (truish(blank=toindices(bl))) b[blank]=J(rows(blank),1,.b)
	betas=betas,&(b'')
	ses=ses,&(se'')
	}

void models::label(string scalar idlab) { //>>def member
	idlab=colwords(idlab)
	id=strtoreal(idlab[1])
	if (id<1|id>length(mlabs)) errel("No such model number",id)
	mlabs[id]=idlab[2]
	}

void models::present(|string scalar opts) { //>>def member<<
	optionel(opts,(&(inc="inc:lude="),&(nlab="nl:abels="),&(vlab="vl:abels="),&(out="out=")))
	if (truish(inc)) {
		optionel(inc,(&(ib="b:eta"),&(ip="p"),&(ip2="p2"),&(ici="ci+")))
		dcols=expand((J(1,ib,"beta"),J(1,ip,"p"),J(1,ip2,"p<"),J(1,truish(ici),("Lcb","Ucb"))),2)
		}
	else dcols="beta","p"
	dcn=length(dcols)
	mn=length(mlabs)
	if (!truish(ici)) ci=""
	else if (*ici=="1") ci="95"
	else ci=*ici
	//ci=truish(ici)?firstof(*ici\"95"):""
	
	t.labset("n",2,nlab,"l u,u")
	t.labset("v",1,vlab,"l u",1)
	
	noth=rows(stub)
	ppos=strpos(stub,".")
	dstub=stub\uniqrows(selectv(substr(stub,ppos:+1),ppos,"c"))
	noth=J(noth,1,1)\J(rows(dstub)-noth,1,0)
	which=strhas(dstub,".")
	tstub=J(rows(dstub),t.nl_n[1],"")
	if (truish(w=toindices(!which))) tstub[w,]=t.getn(dstub[w])
	if (truish(w=toindices(which))) {
		wst=columnize(dstub[w],".")'
		tstub[w,1]=t.getv(wst[2,],wst[1,])'
		}
	
	rml=any(truish(mlabs))
	thead=rml+tmax+1 //heading in html won't revert to non-bold; gotta fix
	head=J(thead,dcn*mn,"")
	bod=J(rows(dstub),cols(head),"")
	for (m=0;m<mn;m++) {
		thetop=*tops[m+1]
		thetop[,1]=thetop[,1]:+":"
		head[1,m*dcn+1]=mlabs[m+1]
		head[rml+1..rml+rows(thetop),m*dcn+1..m*dcn+2]=thetop
		for (c=1;c<=dcn;c++) bod[*rmaps[m+1],m*dcn+c]=getc(dcols[c],m+1,ci)
		head[thead,m*dcn+1..m*dcn+dcn]= subinstr(dcols,"beta",("slope","OR","HR","IRR","SHR")[types[m+1]])
		}
	head[thead,]=subinstr(subinstr(head[thead,],"Lcb","L"+ci),"Ucb","U"+ci)
	
	st2=colwords(dstub,"r",2,".")
	vars=dedup(st2[,2])
	vix=vmap(st2[,2],vars)
	if (cons=toindices(st2[,2]:=="_cons","z")) vix[cons]=.c
	cosort_((&vix,&noth,&strtoreal(st2[,1]),&st2,&tstub,&bod),1\2\3)
	
	t.body=J(thead,t.nl_n[1],""),head\tstub,bod
	t.stub=t.nl_n[1] 
	cb=cols(t.body)
	//if (truish(alt)) t.altrows=strtoreal(alt)
	if (rml) {
		t.set(t._span,1,rangel(t.stub+1,cb,dcn),dcn)
		t.set(t._hline,1,t.stub+1..cb,t.Lmajor)
		t.set(t._class,1,.,"heading")
		}
	t.set(t._hline,thead-1,t.stub+1..cb,t.Lsp1)
	t.set(t._hline,thead,.,t.Lmajor)
	t.set(t._class,thead,.,"heading")
	t.set(t._vline,.,rangel(t.stub+dcn,cb-1,dcn),t.Lminor)
	t.set(t._class,1+rml..thead-1,rangel(t.stub+1,cb,dcn),"heading")
	t.set(t._vline,.,cb,t.Lmajor)
	noth[1]=1 //to skip first line
	if (truish(!noth)) t.set(t._hline,toindices(!noth):+thead-1,.,t.Lsp1)
	il=toindices(differ(st2[,2]):&tru2(st2[,1]))
	if (truish(il)) t.set(t._hline,il:+thead,.,t.Lsp1)
	vals=toindices(tru2(st2[,1])):+thead
	t.set(t._span,vals,1,t.nl_n[1])
	t.set(t._align,1..rows(t.body),1..t.nl_n[1],t.right) //to align spanned cells...
	t.set(t._class,vals,1,"it")
	t.present(out)
	}

string colvector models::getc(string scalar ctype, real scalar m, string scalar ci) { //>>def member
	nci=strtoreal(ci)
	if (types[m]==t_reg) {
		if (ctype=="beta") cbod=*betas[m]
		else if (ctype=="p") cbod=round(2*ttail(*more[m],abs(*betas[m]:/(*ses[m]))),.001) //b:/se=t
		else if (ctype=="p<") cbod=pless(2*ttail(*more[m],abs(*betas[m]:/(*ses[m]))))
		else if (ctype=="Lcb") cbod=*betas[m]:-invttail(*more[m],(1-nci/100)/2):*(*ses[m])
		else if (ctype=="Ucb") cbod=*betas[m]:+invttail(*more[m],(1-nci/100)/2):*(*ses[m])
		}
	else {
		if (ctype=="beta") cbod=exp(*betas[m])
		else if (ctype=="p") cbod=round(2*normal(-abs(*betas[m]:/(*ses[m]))),.001) //b:/se=z
		else if (ctype=="p<") cbod=pless(2*normal(-abs(*betas[m]:/(*ses[m]))))
		else if (ctype=="Lcb") cbod=exp(*betas[m]:+invnormal((1-nci/100)/2):*(*ses[m]))
		else if (ctype=="Ucb") cbod=exp(*betas[m]:-invnormal((1-nci/100)/2):*(*ses[m]))
		}
	blank=toindices(*betas[m]:==.b)
	if (eltype(cbod)=="real") {
		cbod[blank]=J(rows(blank),1,.b)
		return(strofreal(cbod,"%9.3g"))
		}
	else {
		cbod[blank]=J(rows(blank),1,".b")
		return(cbod)
		}
	}

end
//>>mosave<<
*! 16jan2015
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:


void recentle::new() { //>>def member<<
	msize=30 //really no need to adjust
	scid="scalar"
	}

void recentle::init(string scalar nam, string vector def) { //>>def member<<
	rname=nam
	rdef=def
	if (rdef==scid) {
		path=pathto(sprintf("recentle_%s.txt",rname),"inst","fex")
		if (truish(path)) recent=ftostr(path)
		else recent=""
		}
	else {
		path=pathto(sprintf("recentle_%s.lmat",rname),"inst","fex")
		if (truish(path)) {
			stored=fin_lmat(path,"recent "+rname)
			if (length(stored)==2) {
				if (*stored[1]==def & cols(*stored[2])==cols(def)) {
					recent=*stored[2]
					return
					}
				}
			}
		recent=J(0/*1*/,cols(def),"")
		}
	}

void recentle::add(string vector next) { //>>def member<<
	if (rdef==scid) {
		recent=cut(next,-1,-1,1)
		fowrite(pathto(sprintf("recentle_%s.txt",rname),"inst"),recent)
		}
	else {
		fin=rows(recent)
		if (fin==0) recent=next
		else if (next!=recent[fin,]) recent=cut((recent\next)',-msize)'
		fout_lmat(pathto(sprintf("recentle_%s.lmat",rname),"inst"),(&rdef,&recent),"recent "+rname)
		}
	}

end
//>>mosave<<

*! 16jan2015
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:


void recentle_data::new() { //>>def member
	cdsnam="data"
	cdsdef="command","mode","directory","data","details"
	odnam="od"
	listpath="recent_dslist.lmat"
	}

void recentle_data::get(|string scalar prev,string scalar ifin, string scalar keep, string scalar pass) { //>>def member
	rle.init(cdsnam,cdsdef) //get is only cds
	if (!truish(prev)) {
		if (st_global("S_FN")!="") errel("It appears that the most recent data use command was a built-in?",st_global("S_FN"))
		arow=cut(rle.recent',-1,-1,1,"m")'
		if (ncmd=="usel") {
			if (!anyof(("usel","savel","collect"),arow[1])) errel("The {hi:current data source} is not usable by usel. Specify a file or {hi:<}.")
			}
		else if (ncmd=="savel") {
			if (!anyof(("usel","savel"),arow[1])) errel("Savel cannot use the name of the {hi:current data source}. Specify a file.")
			}
		else if (ncmd=="sql"&!anyof(("i","get"),arow[2])) errel("The {hi:current data source} is not re-usable.")
		}
	else {
		if (ncmd=="usel") {
			prevuse=cut(toindices(cut((rle.recent[,1]:=="usel":|rle.recent[,1]:=="savel"),1,-2)),-1,-1)
			}
		else if (ncmd=="sql") {
			prevuse=cut(toindices(cut((rle.recent[,1]:=="sql":&rle.recent[,2]:!="do"),1,-2)),-1,-1)
			}
		if (!truish(prevuse)) errel("No (valid) previous data source available.")
		arow=rle.recent[prevuse,]
		}
	ncmd=arow[1]
	nmode=arow[2]
	ndir=arow[3]
	nfile=arow[4]
	ndetails=sctomat(arow[5])
	
	if (ncmd!="sql") {
		ndetails=expand(ndetails,3,1)
		prev=ndir+nfile
		ifin=ndetails[1]
		keep=ndetails[2]
		pass=ndetails[3]
		}
	}

void recentle_data::parse(string scalar path,|string scalar ifin, string scalar keep, string scalar pass) { //>>def member
	npath=pathparts(pcanon(path,"file",".dta"),(1,23,3))
	ndir=npath[1]
	nfile=npath[2]
	ext=npath[3]
	if (ext==".dta"|ext==".dtar") nmode="dta"
	else if (ext==".csv"|ext==".txt") nmode="delim" //is this 12 or 13?
	else if ((ext==".xl"|ext==".xls"|ext==".xlsx")&c("stata_version")>=13) nmode="exc"
	else nmode="sttr"
	ndetails=(ifin,keep,pass)
	path=ndir+nfile
	}

void recentle_data::add(|matrix other) { //>>def member
	st_global("S_FN","")
	rle.init((truish(other)?odnam:cdsnam),cdsdef) //both use cdsdef
	rle.add((ncmd,nmode,ndir,nfile,scofmat(ndetails)))
	
	if (!truish(other)) window()
	}

void recentle_data::window() { //>>def member
	class elfs_misc scalar elf
	
	wt=elf.get("Stata appID")+elf.get("wformat")
	if (anyof(("usel","savel"),ncmd)) {
		tdir=tokenpath(ndir)
		fbits=pathparts(nfile,(2,3))
		wt=subinstr(wt,"%c","")
		while (regexm(wt,"%p-([1-9])")) {
			wt=regexr(wt,"%p-[1-9]",untokenpath(cut(tdir,-strtoreal(regexs(1))))+dirsep())
			}
		while (regexm(wt,"%p([1-9])")) {
			wt=regexr(wt,"%p[1-9]",untokenpath(cut(tdir,1,strtoreal(regexs(1))))+dirsep())
			}
		wt=subinstr(wt,"%p",ndir)
		wt=subinstr(wt,"%f",fbits[1])
		wt=subinstr(wt,"%e?",fbits[2]==".dta"?"":fbits[2])
		wt=subinstr(wt,"%e",fbits[2])
		}
	else {
		wt=regexr(wt,"%p[1-9-]*","")
		wt=subinstr(wt,"%f","")
		wt=regexr(wt,"%e\??","")
		wt=subinstr(wt,"%c",adorn("-|",ncmd+adorn(" ",nmode),"|-"))
		//		if (ncmd=="clearl") wt=wt+" -|CLEARED|-"
		//		else if (ncmd=="sql") wt=wt+sprintf(" -|sql %s|-",nmode)
		}
	
	wt=subinstr(wt,"%i",st_global("EL_INST"))
	stata(sprintf(`"window man maintitle "%s""',wt))
	}

void recentle_data::list(|matrix other) { //>>def member
	class tabel scalar t
	
	rle.init((truish(other)?odnam:cdsnam),cdsdef) //both use cdsdef
	
	dtkey=datetime("%tc+DDmonYY_HH:MM:SS")
	fout_lmat(pathto(listpath,"inst"),(&dtkey,&rle.recent))
	t.body=rle.recent[,1..4]
	dcmd=(`""cdl "',`""sql p "')[1:+(t.body[,1]:=="sql")]'
	t.body[,3]=t.setLinks("stata","stata ":+dcmd:+t.body[,3]:+char(34),t.body[,3])
	t.body[,4]=t.setLinks("stata","matacmd "+char((96,34))+ "rerecent(":+strofreal(1::rows(t.body)):+","+char(34)+dtkey+char((34,41,34,39)),t.body[,4])
	t.body="Command","Mode","Path","Data"\t.body
	t.head=1
	t.set(t._vline,.,.,t.Lmajor)
	t.set(t._align,.,.,t.left)
	t.present("-")
	}	

//!type: stata
//!clearl: clear data
stata("capture mata mata drop clearl()")
void clearl() { //>>def func
	class recentle_data scalar rld
	st_dropvar(.)
	rld.ncmd="clearl"
	rld.nmode=rld.ndir=rld.nfile=rld.ndetails=""
	rld.add()
	}

//!type: stata
//!usel: use
//!path_k_if: path,keep,ifin
//!pass: translation parmeters
//!pub: public
//!isdta: is dta format
stata("capture mata mata drop usel()")
void usel(string scalar path,| string scalar ifin, string scalar keep, string scalar pass) { //>>def func
	class dataset_dta scalar ds
	class recentle_data scalar rld
	
	rld.ncmd="usel"
	if (path==""|path=="<") rld.get(path,ifin,keep,pass)
	else rld.parse(path,ifin,keep,pass)
	
	if (anyof(("delim","exc"),rld.nmode)) {
		if (rld.nmode=="delim") stata(sprintf(`"import delim "%s", clear %s"',path,pass))
		else fin_xl(path,pass)
		if (truish(keep)) stata(sprintf("keep %s",varlist(keep,"nfok")))
		}
	else {
		if (rld.nmode=="dta") use=path
		else /*sttr*/ callst(path,use=st_tempfilename(),pass)
		if (!fexists(use)) errel("File not found:",use)
		if (!truish(keep)) stata(sprintf(`"capture use %s using "%s", clear"',ifin,use))
		else {
			vars=concat(varlistex(use,keep,"nfok")," ")
			if (truish(vars)) stata(sprintf(`"capture use %s %s using "%s", clear"',vars,ifin,use))
			else stata("clear")
			}
		if (c("rc")==610) {
			printf("{txt:possible too-new format error; re-reading}\n")
			ds.with("d l c")
			ds.readfile(use)
			if (truish(keep)) ds.shrink("k",ds.varlist(use,"nfok"))
			ds.writemem()
			}
		else if (c("rc")) errel(sprintf("File read error: %f",c("rc")),use\ifin)
		}
	rld.add()
	}

//!type: stata
//!savel: save
//!path: file path
//!pass: translation parameters
//!pub: public
//!fmode: dta=dta format, or sub=subset of data
stata("capture mata mata drop savel()")
void savel(string scalar path,| string scalar pass, matrix odata) { //>>def func
	class recentle_data scalar rld
	
	if (path=="") {
		rld.get(path)
		path=pathparts(path,12)+".dta"
		}
	rld.ncmd="savel"
	rld.parse(path)
	
	optionel(pass,&(vers="vers:ion="),pass)
	old=truish(vers)?("old",sprintf("v(%s)",vers)):("","emptyok")
	if (rld.nmode=="dta"|rld.nmode=="sub") stata(sprintf(`"save%s "%s", replace %s"',old[1],path,old[2]))
	else if (rld.nmode=="delim") stata(sprintf(`"export delim "%s", replace %s"',path,pass)) //gotta add tab/delim for txt
	else if (rld.nmode=="exc") fout_xl(path,expand(pass,1))
	else {
		stata(sprintf(`"qui save%s "%s", replace %s"',old[1],save=st_tempfilename(),old[2]))
		callst(save,path,pass)
		}
	rld.add(odata)
	}

stata("capture mata mata drop rerecent()")
void rerecent(real scalar ix, string scalar dtkey) { //>>def func
	class recentle_data scalar rld
	class sql_conn scalar sc
	
	wasrec=fin_lmat(pathto(rld.listpath,"inst","fex"))
	if (*wasrec[1]!=dtkey) errel("Recent Data Source links only work from the last list created.")
	redo=(*wasrec[2])[ix,]
	if (redo[1]=="sql") {
		sc.userset(redo[3])
		sql_dnload(redo[(2,4)],redo[5],sc)
		}
	else {
		details=expand(sctomat(redo[5]),3)
		usel(concat(redo[(3,4)],""),details[1],details[2],details[3])
		}
	}

end
//>>mosave<<

*! 26jan2016
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata: 

void recentle_proj::new() { //>>def member
	on_f="PROJECT SETTINGS.do"
	off_f="PROJECT SETTINGS off.do"
	oth_f="PROJECT SETTINGS.lmat2"  //keep up with ext decisions!
	rlenam="project"
	rledef="directory"
	}

void recentle_proj::s_edit(|matrix off) { //>>def member
	get()
	if (!truish(prjdir)) {
		if (truish(off)) errel("No current project to set OFF for.")
		fowrite(prjdir+on_f,"*project settings auto-write"+eol())
		}
	else if (truish(off)&!fexists(prjdir+off_f)) fowrite(prjdir+off_f,"*project settings auto-write"+eol())
	launchfile(prjdir+(truish(off)?off_f:on_f))
	}

void recentle_proj::s_run(|matrix off) { //>>def member
	get()
	runner=prjdir+(truish(off)?off_f:on_f)
	if (fexists(runner)) stata(sprintf(`"run "%s""',runner))
	}

void recentle_proj::add(string scalar npath) { //>>def member
	rle.init(rlenam,rledef)
	cdir=cut(rle.recent',-1,-1,1,"m")'
	prjdir=existsfor(npath)
	if (prjdir!=cdir) {
		oth_read()
		if (fexists(cdir+off_f)) stata(sprintf(`"run "%s""',cdir+off_f))
		if (truish(prjdir)) stata(sprintf(`"run "%s""',prjdir+on_f))
		}
	rle.add(prjdir)
	printf("{txt:project: }{res:%s}\n",prjdir)
	}

void recentle_proj::get(|matrix prev) { //>>def member
	rle.init(rlenam,rledef)
	ix=-1-truish(prev)
	prjdir=cut(rle.recent,ix,ix,1)
	oth_read()
	}

string scalar recentle_proj::existsfor(string scalar rfrom) { //>>def member
	bits=tokenpath(firstof(rfrom\pwd()))
	ml=length(bits)
	paths=J(ml,1,"")
	for (p=1;p<=ml;p++) paths[p]=untokenpath(bits[1..ml+1-p])	
	paths=concat(paths,";")
	return(pathparts(findfile(on_f,paths),1))
	}

void recentle_proj::list() { //>>def member
	class tabel scalar t
	rle.init(rlenam,rledef)
	t.body="Recent Projects"\t.setLinks("stata",`"stata "cdl "':+rle.recent[,1]:+",p":+char(34),rle.recent[,1])
	t.head=1
	t.set(t._vline,.,.,t.Lmajor)
	t.set(t._align,.,.,t.left)
	t.present("-")
	}

void recentle_proj::oth_read() { //>>def member
	if (fexists(prjdir+oth_f)) {
		oth_set=*fin_lmat(prjdir+oth_f)
	//	/**/oth_set="flat not array"
	//	show(oth_set,"test oth_read")
	//	if (eltype(oth_set)=="struct") show(asarray(oth_set,"testing"),"test oth read as array")
		}
	else {
		oth_set=asarray_create()
		asarray_notfound(oth_set,"nokey")
		}
	}

void recentle_proj::oth_write() { //>>def member
	fout_lmat(prjdir+oth_f,&oth_set,"project settings")
	}

matrix recentle_proj::oth_get(string scalar key) { //>>def member
	return(asarray(oth_set,key))
	}

void recentle_proj::oth_set(string scalar key, matrix aset) { //>>def member
	if (truish(key)) asarray(oth_set,key,aset)
	}

end
//>>mosave
*! 8apr2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:


void spsheet::reset() { //>>def member<<
	sheets=cnames=ctypes=sheets=J(1,0,NULL)
	}

void spsheet::readods(string scalar path,| string scalar readnames) { //>>def member<<
	f1=st_tempfilename()
	stata(sprintf(`"copy "%s" %s"',pcanon(path,"fex","ods"),f1))
	pcanon(f1,"fex")
	tdir=pathparts(f1,1)
	unzip(tdir,f1,"content.xml")
	hold=cut(columnize(ftostr(tdir+"content.xml"),"<table:table "),2)
	unlink(tdir+"content.xml")
	
	if (args()<3) readnames="*" 
	rnames=odsval(hold,"table:name","XXX")
	hits=toindices(asvmatch(rnames,readnames))
	hold=hold[hits]
	shnames=rnames[hits]
	cnames=J(1,length(hits),NULL)
	sheets=J(1,length(hits),NULL)
	//sheets=onesheet(length(hold))
	for (s=1;s<=length(sheets);s++) {
		t=columnize(hold[s],"<table:table-row")' 
		t=regexr(t,"<text:s[^/]*/>"," ") //doesn't preserve space runs; hope slashes are not allowed (need to repeat?)
		sheets[s]=&J(0,0,"")
		errepeat=0
		for (j=1;j<=rows(t);j++) {
			rrepeat=strtoreal(odsval(t[j],"table:number-rows-repeated","0"))
			if (strpos(t[j],"<text:p>")) {
				r=columnize(t[j],"<table:table-cell") 
				cells=J(1,0,"") 
				for (k=2;k<=cols(r);k++) { 
					crepeat=strtoreal(odsval(r[k],"table:number-columns-repeated","1"))
					if (strpos(r[k],"<text:p>")) co=columnize(columnize(r[k],"<text:p>")[2],"</text:p>")[1]
					else co="" 
					while (regexm(co,"</?text:span[^>]*>")) co=regexr(co,"</?text:span[^>]*>","") //strip out sub-cell formatting
					cells=cells,J(1,crepeat,co)
					} 
				cells=cells[1..max(toindices(strlen(cells)))] 
				cells=J(max((rrepeat,1)),1,cells)
				if (errepeat) *sheets[s]=*sheets[s]\J(errepeat,cols(*sheets[s]),"")
				*sheets[s]=pad(*sheets[s],cells,"\")
				errepeat=0 //looks like there was a typo here: erepeat instead of errepeat
				}
			else errepeat=errepeat+rrepeat
			}
		*sheets[s]=xmlchars(strtrim(*sheets[s]),"fromxml")
		}
	}

string scalar spsheet::odsstr(string scalar path) { //>>def member<<
	f1=st_tempfilename()
	stata(sprintf(`"copy "%s" %s"',pcanon(path,"fex","ods"),f1))
	tdir=pathparts(f1,1)
	unzip(tdir,f1,"content.xml")
	hold=ftostr(tdir+"content.xml")
	unlink(tdir+"content.xml")
	return(hold)
	}

void spsheet::parseods(string scalar body,| string scalar readnames) { //>>def member<<
	class xmlelem scalar xlm
	class collector scalar co
	
	reset()
	if (args()<3) readnames="*"
	(void) xlm.next(body,"office:spreadsheet")
	body=xlm.content
	while (xlm.next(body,"table:table")) {
		if (asvmatch(xlm.getv("name"),readnames)) {
			tbod=xlm.content
			co.init()
			k=0
			while(xlm.next(tbod,"table:table-column")) {
				k=k+firstof(xlm.getv("table:number-columns-repeated",1)\1)
				}
			rn=0
			while(xlm.next(tbod,"table:table-row")) {
				if (strpos(xlm.content,"<text:p")) {
					rr=firstof(xlm.getv("table:number-rows-repeated",1)\1)
					trow=xlm.content
					srow=J(1,k,"")
					i=1
					while(xlm.next(trow,"table:table-cell")) {
						cr=firstof(xlm.getv("table:number-columns-repeated",1)\1)
						(void) xlm.next(ctext=xlm.content,"text:p")
						ctext=xlm.content //need to strip style spans
						srow[i..i+cr-1]=J(1,cr,ctext)
						i=i+cr
						}
					co.add(J(rr,1,srow))
					}
				}
			sheets=sheets,&(co.compose())
			}
		}
	}

void spsheet::readxml(string scalar path,| string scalar readnames) { //>>def member<<
	if (args()<3) readnames="*" 
	hold=cut(columnize(ftostr(pcanon(path,"fex","xml")),"<Worksheet "),2)
	rnames=substr(hold,10,strpos(hold,">")-11)
	hits=toindices(asvmatch(rnames,readnames))
	hold=hold[hits]
	shnames=rnames[hit]
	cnames=J(1,length(hits),NULL)
	sheets=J(1,length(hits),NULL)
	for (s=1;s<=length(hold);s++) { 
		t=columnize(hold[s],"<Row")' 
		sheets[s]=&J(0,0,"")
		for (j=2;j<=rows(t);j++) { 
			if (substr(t[j],2,9)=="ss:Index=") {  
				x=columnize(t[j],`"""')[2] 
				*sheets[s]=*sheets[s]\J(strtoreal(x)-rows(*sheets[s])-1,cols(*sheets[s]),"") 
				} 
			r=columnize(t[j],"<Cell") 
			cells=J(1,0,"") 
			for (k=2;k<=cols(r);k++) { 
				if (substr(r[k],2,9)=="ss:Index=") {  
					x=columnize(r[k],`"""')[2] 
					cells=cells,J(1,strtoreal(x)-cols(cells)-1,"") 
					} 
				if (strpos(r[k],"<Data")) { 
					a=columnize(columnize(r[k],"</Data>")[1],">")
					cells=cells,("",a[cols(a)])[1+(cols(a)>1)]
					} 
				else if (strpos(r[k],"<ss:Data")) { 
					a=columnize(columnize(r[k],"</ss:Data>")[1],">")
					cells=cells,("",a[cols(a)])[1+(cols(a)>1)]
					} 
				else cells=cells,"" 
				} 
			if (j==2) sheets[s]=cells 
			else *sheets[s]=pad(*sheets[s],cells,"\") 
			} 
		*sheets[s]=xmlchars(*sheets[s],"fromxml") 
		}
	}

void spsheet::writexml(string scalar path) { //>>def member<<
	path=pcanon(path,"fnew","xml")
	q=`"""' 
	f=""
	sput(f,`"<?xml version="1.0"?>"') 
	sput(f,`"<?mso-application progid="Excel.Sheet"?>"') 
	sput(f,`"<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" xmlns:x="urn:schemas-microsoft-com:office:excel" xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">"') 
	
	sput(f,`"<Styles><Style ss:ID="s77">"') 
	sput(f,`"<Borders> <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/> </Borders>"') 
	sput(f,`"<Interior ss:Color="#CCFFCC" ss:Pattern="Solid"/>"') 
	sput(f,"</Style></Styles>") 
	
	for (s=1;s<=length(sheets);s++) {
		sheet=xmlchars(*cnames[s]\*sheets[s],"toxml")
		sput(f,"<Worksheet ss:Name="+q+shnames[s]+q+">") 
		sput(f,`"<Table x:FullColumns="1" x:FullRows="1""') 
		sput(f,"ss:ExpandedRowCount="+q+strofreal(rows(sheet))+q) 
		sput(f,"ss:ExpandedColumnCount="+q+strofreal(cols(sheet))+q+">")
		for(r=1;r<=rows(sheet);r++) { 
			sput(f,"<Row>") 
			for(c=1;c<=cols(sheet);c++) { 
				sput(f,"<Cell",0) 
				if (r==1&rows(*cnames[s])) sput(f,`" ss:StyleID="s77""',0) 
				sput(f,`"><Data ss:Type="String">"'+sheet[r,c]+"</Data></Cell>") 
				} 
			sput(f,"</Row>") 
			} 
		sput(f,"</Table>") 
		sput(f,"</Worksheet>") 
		} 
	sput(f,"</Workbook>") 
	fowrite(path,f)
	} 

void spsheet::setheads(|rowvector shuse) { //>>def member<<
	if (!length(shuse)) shs=1..length(sheets)
	else if (eltype(shuse)=="string") shs=vmap(shuse,shnames,"in")
	else shs=shuse
	for (s=1;s<=length(shs);s++) {
		cnames[s]=&(cut(*sheets[s]',.,1)')
		*sheets[s]=cut(*sheets[s]',2)'
		}
	}

void spsheet::unzip(string scalar tdir, string scalar archive, string scalar file) { //>>def member<<
	cmd=cat(pathto("unzip_path.txt","","fex"))
	if (!truish(cmd)) errel("No unzip command defined")
	cmd=subinstr(subinstr(subinstr(cmd,"%tdir",tdir),"%archive",archive),"%file",file)
	stata("shell "+cmd)
	}

string matrix spsheet::xmlchars(string matrix in, string scalar direction) { //>>def member<<
	if (!length(in)) return(in)
	thesubs="&","&amp;"\">","&gt;"\"<","&lt;"\ `"""',"&quot;"\"'","&apos;"\"--","&#45;-"\char(10),"&#10;" 
	dir=direction=="toxml"?(1,2):(2,1) 
	out=in 
	for (i=1;i<=rows(thesubs);i++) out=subinstr(out,thesubs[i,dir[1]],thesubs[i,dir[2]])
	return(out) 
	}

string vector spsheet::odsval(string vector text, string scalar key,| string scalar def) { //>>def member<<
	found=strpos(text,key)
	if (any(found)) {
		next=substr(text,found:+strlen(key):+1)
		next=substr(next,strpos(next,`"""'):+1)
		next=substr(next,1,strpos(next,`"""'):-1)
		return(next)
		}
	else return(J(rows(text),cols(text),args()==3?def:""))
	}

end
//>>mosave<<

*!7dec2015
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:


void sql_conn::new() { //>>def member
	rlenam="sqlp"
	rledef="dsn","driver","server","database","schema"
	crec=J(1,cols(rledef),"")
	dsn=1;driver=2;server=3;dbname=4;schema=5
	}

string rowvector sql_conn::hparse(string scalar hstr) { //>>def member
	class elfs_sql scalar elf
	
	out=J(1,cols(rledef),"")
	if (!truish(hstr)) return(out)
	
	syntaxl(hstr,&(spec="anything"),&(drv="d:river="))
	drv=adorn("{",firstof(drv\elf.get("Default driver")),"}")
	
	if (strpos(spec,":")) {
		spec=strtrim(tokel(spec,":"))
		if (truish(spec[1])) {
			if (!strpos(spec[1],".")) out[dsn]=spec[1]
			else  {
				out[driver]=drv
				out[server]=spec[1]
				}
			}
		spec=spec[2]
		}
	spec=strtrim(expand(tokel(spec,"."),2))
	if (truish(spec[1])) out[dbname]=spec[1]
	if (truish(spec[2])) out[schema]=spec[2]
	return(out)
	}

void sql_conn::merge(string rowvector newr) { //>>def member
	class elfs_sql scalar elf
	
	get()
	if (truish(newr[dsn])) {
		crec[dsn]=newr[dsn]
		crec[driver]=crec[server]=""
		if (!truish(newr[dbname])) { //get default
			stata("capture log close")
			stata(sprintf("qui log using %s, replace text",sqllog=pathto("_sql.log","i")))
			stata(sprintf(`"odbc query %s"',crec[dsn]))
			stata("qui log close")
			//		printf(eol(7))
			newr[dbname]=strlower(substr(cat(sqllog)[3],13))
			}
		}
	else if (truish(newr[driver]+newr[server])) {
		if (truish(newr[(driver,server,dbname)])!=3) errel("SQL conn: A driver or server was specified without specifying all of: driver, server, dbname")
		crec[dsn]=""
		crec[driver]=newr[driver]
		crec[server]=newr[server]
		}
	if (truish(newr[dbname])) {
		crec[dbname]=newr[dbname]
		if (!truish(newr[schema])) newr[schema]=elf.get("Default schema")
		}
	if (truish(newr[schema])) crec[schema]=newr[schema]
	}

void sql_conn::userset(|string scalar usepath) { //>>def member
	if (usepath=="<") get("prev")
	else merge(hparse(usepath))
	}

string scalar sql_conn::field(string scalar field) { //>>def member
	return(lookupin(crec,toindices(field:==rledef)))
	}

string scalar sql_conn::connstr() { //>>def member
	if (!truish(crec[dbname])) get()
	if (truish(crec[dbname])) {
		if (truish(crec[dsn])) return(concat(concat((rledef\crec)[,(dsn,dbname)]',"="),";"))
		else if (truish(crec[(driver,server)])==2) {
			cstr=concat(concat((rledef\crec)[,(driver,server,dbname)]',"="),";")
			cstr=adorn(char(34),cstr,";trusted_connection=yes"+char(34))
			return(cstr)
			}
		}
	errel("SQL conn doesn't contain sufficient info",crec)
	}

string colvector sql_conn::humstr(|string matrix usethese) { //>>def member
	if (!truish(usethese)) {
		if (!truish(crec[dbname])) get()
		usethese=crec
		}
	out=J(rows(usethese),1,"")
	for (u=1;u<=rows(usethese);u++) {
		if (truish(usethese[u,dsn])) out[u]=usethese[u,dsn]+":"+usethese[u,dbname]+"."+usethese[u,schema]
		else if (truish(usethese[u,server])&truish(usethese[u,driver])) out[u]=usethese[u,server]+":"+usethese[u,dbname]+"."+usethese[u,schema]+", "+adorn("driver(",chtrim(usethese[u,driver],("{","}")),")")
		}
	return(out)
	}

string scalar sql_conn::path(|string matrix curcon) { //>>def member
	out=crec
	if (truish(curcon)) {
		if (out[dsn]==curcon[dsn]|(out[server]==curcon[server]&out[driver]==curcon[driver])) {
			out[1..3]=J(1,3,"")
			if (out[dbname]==curcon[dbname]) out[4]=""
			}
		}
	out[server]=adorn("[",out[server],"]")
	return(concat(out[(server,dbname,schema)],"."))
	}

void sql_conn::get(|matrix prev) { //>>def member
	rle.init(rlenam,rledef)
	ix=-1-truish(prev)
	crec=cut(rle.recent',ix,ix,1,"m")'
	}

void sql_conn::add() { //>>def member
	class tabel scalar t
	
	rle.init(rlenam,rledef)
	rle.add(crec)
	t.body=select((strproper(rledef)\crec),tru2(crec))'
	if (!length(t.body)) printf("{txt:No sql path set}\n")
	else {
		t.set(t._align,.,2,t.left)
		t.set(t._class,.,1,"heading")
		t.present("-")
		}
	}

void sql_conn::list() { //>>def member
	class tabel scalar t
	
	rle.init(rlenam,rledef)
	t.body=humstr(rle.recent)
	t.body="Recent SQL Paths"\t.setLinks("stata",`"stata "sql p "':+t.body:+char(34),t.body)
	t.head=1
	t.set(t._align,.,.,t.left)
	t.present("-")
	}

end
//>>mosave

*! 24jun2015
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:


void sql_meta::new() { //>>def member
	fields="s_name","t_name","q_name","q_desc","q_cols","q_time","mod","cmdfile","sql"
	types=adorn("varchar(",strofreal((100,100,100,1000,1000,10,50,200)),")"),"varchar(max)"
	data=&s_name,&t_name,&q_name,&q_desc,&q_cols,&q_time,&moddt,&cmdfile,&sql
	for (d=1;d<=9;d++) *data[d]=""
	home_s="meta"
	home_t="qs"
	home_st=home_s+"."+home_t
	q_name=nquery="&empty;"
	
	predrop="delete from @@home from @@home  AA left join information_schema.tables BB on AA.@@schema=BB.table_schema and AA.@@table=BB.table_name where BB.table_name is null; delete from @@home where @@schema='%s' and @@table='%s'"
	predrop=subinstr(predrop,"@@home",home_st)
	predrop=subinstr(predrop,"@@schema",fields[1])
	predrop=subinstr(predrop,"@@table",fields[2])
	}

void sql_meta::makesql() { //>>def member
	sql_submit(sql_ischema(home_s)+sprintf("if object_id('%s') is null create table %s (%s)",home_st,home_st,concat(concat(fields\types," ","c"),",")))
	}

void sql_meta::dest(string scalar dpath) { //>>def member
	parts=sql_rparts(dpath,(1,2,3,123))
	db=parts[1]+"."
	s_name=J(length(s_name),1,parts[2])
	t_name=J(length(t_name),1,parts[3])
	dest=parts[4]
	}

void sql_meta::todta() { //>>def member
	if (qn=rows(*data[1])) {
		qix=strofreal(1..rows(*data[1])) //for merged tables with mult q
		for (d=cols(data);d;d--) charset("_dta","sql_":+fields[d]:+qix,*data[d])
		}
	else for (d=cols(data);d;d--) charset("_dta","sql_":+fields[d]:+"1","") //??
	}
void sql_meta::fromdta() { //>>def member
	qix=1
	while (truish(charget("_dta","sql_"+fields[1]+strofreal(qix+1)))) {
		++qix
		}
	qix=strofreal(1..qix)
	for (d=cols(data);d;d--) *data[d]=charget("_dta","sql_":+fields[d]:+qix)
	}

void sql_meta::tosql(|matrix merge) { //>>def member<<
	makesql()
	qcols=sql_submit(sprintf("select column_name from information_schema.columns where table_schema='%s' and table_name='%s'",home_s,home_t))[,2]'
	if (qcols!=fields) errel("names don't match",pad(qcols,fields,"\"))
	
	if (truish(merge)) {
		if (uniqs(s_name)>1|uniqs(t_name)>1|uniqs(q_name)>1) errel("Can't merge a merged table...") //hmmm
		prdr=predrop+sprintf(" and %s='%s'",fields[3],q_name[1])
		}
	else prdr=predrop
	sql_submit(sprintf(prdr,s_name[1],t_name[1]))
	if (truish(t_name)/**/) {
		//no sprintf because of long query text
		itext="insert into "+home_st+" values"
		qn=rows(*data[1])
		for (q=1;q<=qn;q++) {
			itext=itext+" ("
			for (d=1;d<cols(data);d++) {
				itext=itext+char(39)+(*data[d])[q]+char(39)+","
				}
			itext=itext+char(39)+subinstr(sql[q],char(39),char((39,39)))+char(39)+")"+(q<qn)*","
			}
		sql_submit(itext)
		}
	}

void sql_meta::fromsql(string scalar source) { //>>def member
	sandt=sql_rparts(source,(2,3))
	sql_dnload("bkgrnd",sprintf("if object_id('%s') is not null select * from %s where %s='%s' and %s='%s' else select 'zip' a",home_st,home_st,fields[1],sandt[1],fields[2],sandt[2]))
	if (st_nvar()>1&st_nobs()) {
		if (varlist("*")!=fields) errel("qs field mismatch")
		for (d=1;d<=cols(data);d++) *data[d]=el_data(.,d)
		}
	else {
		db=sql_rparts(source,1)+"." //too weird, gotta fix 
		s_name=sandt[1]
		t_name=sandt[2]
		q_name=nquery
		q_desc="none/na"
		q_cols=q_time=moddt=cmdfile=sql=""
		}
	}
end
//>>mosave
*! 17apr2014
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:


void sqldo::new() { //>>def member<<
	eol=char(10)
	sqlbeg="*"+"---sql:"
	sqlend=eol+"*"+"---/sql"
	eltmp=".el_tmp_"
	mmark="^g:"
	tmark="^t:"
	}

void sqldo::sqldo(string scalar main) { //>>def member<<
	class elfs_misc scalar elf
	class collector vector co
	
	syntaxl(main,&(fname="anything"),(&(only="o:nly="),&(onot="not="),&(path="p:ath="), &(dest="d:estination="),&(merge="merge="),&(swap="s:wap="), &(prev="pre:view"),&(test="test"),&(upload="up:load=")))
	if (truish(dest)+truish(merge)>1) errel("destintation and merge cannot both be specified")
	sc.userset(path)
	writable.userset(path)
	if (truish(upload)) {
		writable.userset(upload)
		if (!truish(writable.field("server"))) errel("upload() requires a sql path with a server, rather than a dsn")
		}
	if (truish(merge)) {
		merge=strtrim(tokel(merge,":"))
		if (cols(merge)!=2) errel("Merge must specify {it:table}{hi:}{it:query-name}")
		}
	only=expand(tokel(only,":"),-2) //wrapid=o[1], tables=o[2]
	
	if (truish(fname)) sqlspec=sm.cmdfile=pcanon(fname,"fex","do")
	else {
		sqlspec=pcanon(st_macroexpand(elf.get("fromEditor path")))
		fe=cat(sqlspec)[4]
		sm.cmdfile=substr(fe,strpos(fe,":"):+1)
		if (!truish(sm.cmdfile)) sm.cmdfile="source file not found"
		}
	
	swix=cix=0
	swkey=""
	co=collector(3)
	co[1].init()
	co[2].init(2,"fill(*)")
	co[3].init(3,"fill(*)")
	include(co,"",sqlspec+adorn(",swap(",swap,")"),only[1])
	text=co[1].compose()
	swaps=expand(co[2].compose(),3)
	prv=expand(co[3].compose(),4)
	parse(text,only[2],onot,test)
	sm.q_name=sm.nquery
	sm.dest(firstof(dest\names[cut(pad(toindices(doem:&uses),toindices(doem:&!uses),"\"),-1,-1),1]))
	preview()
	
	doix=toindices(doem:&!uses)
	if (truish(doix)) {
		sm.sql=adorn("with "+eol,concat(concat((names[doix,1],codes[doix,1])," as ("+eol,"r"),"),"+2*eol),")"+eol) //codes[,1] to conform with names when empty
		tfin_from=cut(names[doix,1],-1)
		}
	else {
		tfin_from=(writable.path()!=sc.path()?writable.path():sc.field("schema")) +eltmp+sql_rparts(names[cut(toindices(uses:&doem),-1),1],3)
		}
	if (sm.t_name!="*") {
		tfin_into="into "+sm.dest
		sm.sql=sql_ischema(sm.s_name,sc)+sprintf("if object_id('%s','U') is not null drop table %s;\n",sm.dest,sm.dest)+sm.sql
		}
	else tfin_into=""
	sm.sql=sm.sql+sprintf("\nselect * %s from %s",tfin_into,tfin_from)
	
	if (prev) sql_print(sm.sql)
	else exec(merge)
	}

void sqldo::include(class collector vector co, string scalar astname, string scalar sqlspec,| string matrix wrapid) { //>>def member<<
	class textidents scalar ti
	bits=expand(tokel(sqlspec,","),2)
	optionel(bits[2],(&(dir="d:ir="),&(swap="s:wap=")))
	if (truish(mdefs=tokenstrip(tokel(swap))[,1..2])) {
		if (any(!tru2(mdefs))) errel("Some tag definitions are off",macdefs)
		if (sum(strpos(mdefs[,1],tmark):+strpos(mdefs[,1],mmark)):!=rows(mdefs)) errel(sprintf("tags must begin with %s or %s",tmark,mmark),mdefs)
		}
	
	path=pcanon(untokenpath((st_macroexpand(dir),bits[1])),"fex","sql")
	text=eol+ftostr(path)
	text=subinstr(text,char((13,10)),eol)
	text=subinstr(text,char(13),eol)
	while (regexm(text,sprintf(eol+"[%s]+",char((9,32))))) text=subinstr(text,regexs(0),eol)
	while (regexm(text,3*eol+"+")) text=subinstr(text,regexs(0),2*eol)
	while (regexm(text,sprintf("%s--[^%s]*%s",eol,eol,eol))) text=subinstr(text,regexs(0),eol)
	
	if (length(wrapid)) { //orig call
		bits=""
		if (regexm(text,"\"+sqlbeg+" *"+wrapid+" *,([^"+eol+"]+)"+eol)) sm.q_desc=regexs(1)
		while (regexm(text,"\"+sqlbeg+" *"+wrapid+"( .*)?"+eol)&(fin=strpos(text,sqlend))) {
			beg=strpos(text,regexs(0))
			abit=substr(text,beg+1,fin-beg)
			bits=bits+substr(abit,strpos(abit,eol)/*+1*/)
			text=substr(text,fin+strlen(sqlend))
			}
		if (!truish(bits)) errel("No sql found in file.",path)
		text=substr(bits,2) //skip 1st eol
		}
	else text=substr(text,2)
	
	if (substr(text,-2)==2*eol) text=substr(text,1,strlen(text)-1)
	text=tokel(text,2*eol)'
	//text=select(text,substr(text,1,2):!="--") //commented lines
	text=colwords(text,"",2,eol)
	if (any(substr(text[,1],1,3):!="^t=")) errel("Tables missing identifiers",text[,1])
	if (truish(astname)) text[rows(text),1]=astname
	
	++swix
	swkey=swkey+char(swix)
	if (truish(mdefs)) {
		co[2].add(char(swix),1)
		co[2].add(mdefs,2)
		}
	for (r=1;r<=rows(text);r++) {
		if (substr(text[r,2],1,5)=="^ssc=") include(co,text[r,1],substr(text[r,2],6))
		else {
			++cix
			co[1].add(text[r,])
			if (truish(found=ti.find(text[r,2],("","(\^t:|\^g:)[a-zA-Z0-9_.]+","")))) {
				co[3].add(swkey,1)
				co[3].add(strofreal(cix),2)
				co[3].add(J(1,2,found),3)
				}
			}
		}
	swkey=substr(swkey,1,strlen(swkey)-1)
	}

void sqldo::parse(string matrix text,string scalar only, string scalar onot, real scalar test) { //>>def member
	class textidents scalar ti
	if (test) text[,2]=subinstr(subinstr(text[,2],"/*test:",""),":test*/","")
	else {
		while (length(hix=toindices(hits=strpos(text[,2],"/*test:")))) {
			text[hix,2]=substr(text[hix,2],1,hits[hix]:-1):+substr(text[hix,2],strpos(text[hix,2],":test*/"):+7)
			}
		text[,2]=subinstr(text[,2],2*eol,eol) //or more?
		}
	
	names=strtrim(colwords(substr(text[,1],4/*^t=*/),"",2,",")) //inc desc
	//gotta do something to match all tables that were part of an SSC!!
	doem=asvmatch(names[,1],firstof(only\"*")):&!asvmatch(names[,1],onot)
	if (!truish(doem)) errel("No tables selected for execution.")
	codes=text[,2]
	
	clines=tokel(concat(codes,eol),eol)
	onleft=regexs2(clines," on  *([^=]+)=",1)
	onright=regexs2(clines,sprintf(" on  *[^=]+= *([^ %s]+)",eol),1)
	uhoh=toindices(tru2(onleft):&onleft:==onright)
	if (truish(uhoh)) errel("Join on identical field",clines[uhoh])
	
	if (any(uses=strhas(codes,"^use=",1):+2:*strhas(codes,"^codex=",1))) {
		for (u=1;u<=rows(codes);u++) {
			if (doem[u]) {
				if (uses[u]==2) {
					syntaxl(codes[u],&(path="anything"),(&(cxids="tag=")),fopts="filteropts")
					path=substr(path,8)
					codes[u]=concat((path,fopts),",")
					cx.readcode(codes[u])
					cxids=firstof(cxids\mmark+"cxids") //cxids defined!
					if (substr(cxids,1,3)!=mmark) cxids=mmark+cxids
					swaps=swaps\"",cxids,concat(dedup(cx.keys[,5]),",")
					prv=prv\"",strofreal(u),cxids,""
					}
				else if (uses[u]) {
					syntaxl(codes[u],(&(path="anything"),&(ifin="ifin")),&(keep="k:eep="))
					codes[u]=concat((substr(path,6),ifin,keep),";","e")
					}
				}
			}
		}
	
	if (truish(swaps)) _sort(swaps,1)
	if (truish(prv)) {
		for (s=rows(swaps);s;s--) {
			hits=toindices(strpos(prv[,1],swaps[s,1]):&prv[,4]:==swaps[s,2])
			if (truish(hits)) prv[hits,4]=J(length(hits),1,swaps[s,3])
			else if (truish(swaps[s,1])) errel("A specified swap was not found",swaps[s,2])
			}
		}
	for (s=1;s<=rows(prv);s++) {
		if (truish(prv[s,1])) { /*leave cxids alone*/
			cix=strtoreal(prv[s,2])
			mark=strhas(prv[s,3],tmark,1)?tmark:mmark
			has=strhas(prv[s,4],mark,1)
			r=substr(prv[s,4],1+has*strlen(mark))
			if (mark==tmark&has) {
				tline=toindices(doem[1..cix]:*names[1..cix,1]:==r)
				if (!truish(tline)) r=sql_rparts(r,23)
				else if (uses[tline]) r=writable.path(sc.crec)+eltmp+r
				}
			codes[cix]=ti.replace(codes[cix],("",ti.esc(prv[s,3]),""),r)
			prv[s,4]=r
			}
		}
	}

void sqldo::preview() { //>>def member<<
	class tabel scalar t
	
	if (any(uses)) {
		uix=toindices(uses)
		nlines=doem[uix]:*t.defChar("{c 164}",""),expand(names[uix,],3)
		tags=lookupin(prv[,3],vmap(uix,strtoreal(prv[,2])))
		dtas=expand(columnize(columnize(codes[uix],";","each")[,1],",")[,1],-3)
		t.body="UPLOADS","","",""\"","Name","Description",""\"","","dta","codex tag"\riffle(nlines\(dtas,tags),length(uix),"rows")
		
		t.head=3
		t.set(t._wrap,.,4,0)
		t.set(t._span,1,1,4)
		t.set(t._align,.,.,t.left)
		t.set(t._align,1,1,t.left)
		t.set(t._class,.,1,"hi1")
		t.render()
		}
	if (rows(names)>truish(uses)) {
		dprv=select(prv,tru2(prv[,1]))
		tix=strtoreal(dprv[,2])
		nix=toindices(!uses)
		nlines=doem[nix]:*t.defChar("{c 164}",""),expand(names[nix,],3)
		sorter=tix,J(rows(tix),1,1)\nix,J(rows(nlines),1,0)
		t.body=expand(dprv[,3..4],-4)\nlines
		cosort_((&sorter,&t.body),(1,1\1,2))
		t.body="TABLES","","",""\"","Name","Description",""\"","","tag","result"\t.body
		t.head=3
		t.set(t._wrap,.,4,0)
		dlines=toindices(tru2(t.body[,1]))
		tlines=toindices(!tru2(t.body[,1]))
		t.body[tlines,3]="  ":+t.body[tlines,3]
		t.set(t._span,dlines,3,2)
		t.set(t._class,.,3,"weaker")
		t.set(t._span,1,1,4)
		t.set(t._span,2,3,2) 
		t.set(t._align,1..rows(t.body),1..cols(t.body),t.left)
		t.set(t._class,.,1,"hi1")
		t.render()
		}
	t.present("-")
	
	printf("{txt:Destination: }")
	if (sm.t_name=="*") printf("{hi:Stata}\n")
	else {
		printf("{hi:%s}\n",sm.dest)
		if (sm.q_name!=sm.nquery) printf("{hi:%s}\n",adorn(": ",sm.q_name))
		}
	printf("\n")
	}

void sqldo::exec(string vector merge) { //>>def member<<
	printf("\n"+datetime()+"\n")
	timer_clear(1)
	timer_on(1)
	
	for (u=1;u<=rows(uses);u++) if (doem[u]&uses[u]) suse(u)
	
	if (sm.t_name=="*") sql_dnload(("do",pathparts(sm.cmdfile,23)),sm.sql,sc)
	else sql_submit(sm.sql,sc)
	timer_off(1)
	
	seconds=timer_value(1)[1]
	if (seconds>=3600) sm.q_time=strofreal(seconds*1000,"%tC+hH:MM:SS")
	else if (seconds>60) sm.q_time=strofreal(seconds*1000,"%tC+mm:SS")
	else sm.q_time=strofreal(trunc(seconds))
	sm.moddt=datetime()
	
	if (cols(merge)==2) sqlmerge(merge,sm)
	else if (sm.t_name=="*") sm.todta()
	else sm.tosql()
	
	sql_submit(sprintf("declare @droppers varchar(1000); select @droppers=coalesce(@droppers+';','')+' drop table '+table_schema+'.'+table_name from information_schema.tables where table_schema='%s' and table_name like '%s%%';exec(@droppers)",writable.field("schema"),subinstr(eltmp,".","")))
	}

void sqldo::suse(real scalar ix) { //>>def member<<
	if (uses[ix]==2) { //codex
		cx.readcode(codes[ix])
		cx.xpat_dict()
		cx.todata()
		}
	else {
		bits=tokel(codes[ix],";")
		if (bits[1]!="*") usel(bits[1],bits[2],bits[3])
		//else do ifin keep!
		}
	
	sql_upload(eltmp+sql_rparts(names[ix,1],3),writable)
	}

end
//>>mosave<<
*! 22dec2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

string vector statgrid::canon() { //>>def member<<
	return("Mean","Var","SD","Sum","Med","P","Min","Max","True","N","Uniq","Nobs")
	}

void statgrid::by(string vector byopts) { //>>def member
	if (!length(byopts)) byopts=""
	bys=J(length(byopts),1,NULL)
	for (b=1;b<=length(bys);b++) bys[b]=&varlist(byopts[b])
	by_vars=varlist(concat(byopts," "))
	}

void statgrid::setup(string scalar explist, string scalar ifin,|matrix newvars) { //>>def member<<
	settouse(touse,ifin)
	dsby()
	cross_ve(explist)
	sub_r()
	get_e()
	set_names(newvars)
	}

void statgrid::dsby() { //>>def member<<
	ds.with("data labels")
	if (rows(bys)>1) {
		ds.vlabnames="overall_statgrid"
		ovmiss=get_unmiss()
		ovlab=strofreal(ovmiss),"|Overall|"
		ds.vlabtabs=&ovlab
		}
	b_n=length(by_vars)
	for (bv=1;bv<=b_n;bv++) {
		ds.gen(by_vars[bv])
		if (rows(bys)>1) {
			if (truish(ds.vlabrefs[bv])) {
				mix=toindices(ds.vlabrefs[bv]:==ds.vlabnames)
				*ds.vlabtabs[mix]=*ds.vlabtabs[mix]\ovlab
				}
			else  ds.vlabrefs[bv]=ds.vlabnames[1]
			}
		}
	}

void statgrid::cross_ve(string scalar expsin) { //>>def member<<
	(void) tokel(expsin,":","",each)
	if (cut(each,2)==":") expsin="VxF("+expsin+")"
	if (!any(strpos(expsin,"("))) {
		(void) varlist(expsin,"nfok","",notfound)
		if (!truish(notfound)) expsin="VxF("+expsin+")"
		}
	
	explist=tokel(expsin)
	eaches=regexm(explist,"^VxF\(")
	e_exp=k_vars=J(1,0,"")
	for (e=1;e<=length(explist);e++) {
		if (!eaches[e]) {
			e_exp=e_exp,enclose(explist[e])
			k_vars=k_vars,""
			}
		else {
			each=expand(tokel(tokenstrip(explist[e])[,2],":"),2)
			vlist=varlist(each[1],"all")'
			if (!truish(vlist)) errel("Variables missing",explist[e])
			if (truish(each[2])) bits=tokel(each[2])
			else bits=tokel(defaults)
			if (!truish(bits)) errel("No functions specified")
			eexps=J(1,0,"")
			for (b=1;b<=length(bits);b++) eexps=eexps,enclose(bits[b])
			eexps=subinstrf(eexps,"#v","#V")
			eexps=stritrim(eexps)
			eexps=subinstrf(subinstrf(eexps,"()","(#V)"),"( )","(#V)")
			eexps=subinstrf(subinstrf(eexps,"(,","(#V,"),"( ,","(#V,")
			e_exp=e_exp,rowshape(subinstrf(eexps,"#V",vlist),1) //e1(v1) e2(v1) e1(v2) e2(v2)...
			k_vars=k_vars,rowshape(J(1,length(eexps),vlist),1)
			}
		}
	if (!length(e_exp)) errel("No expressions specified")
	e_bound=charsubs(e_exp)
	
	k_n=length(e_exp)
	cross=(eaches==1)*length(vlist)
	}
string scalar statgrid::enclose(string scalar exp) { //>>def member<<
	bf=tokenfunc(exp,canon())
	if (cols(bf)==1&truish(bf[2,1])) return(exp)
	if (substr(exp,1,1)!="("|substr(exp,-1)!=")") return(sprintf("nofunc(%s)",exp))
	else return("nofunc"+exp)
	}

void statgrid::sub_r() { //>>def member<<
	for (k=1;k<=k_n;k++) {
		rf=tokenfunc(e_exp[k],("Rsum","Rmean","Rmin","Rmax","Rtrue","Rn","Rvars"))
		rfhit=toindices(rf[2,])
		for (h=1;h<=cols(rfhit);h++) {
			f=rfhit[h]
			vl=varlist(rf[1,f])
			if (rf[2,f]=="Rsum") rf[1,f]="("+concat(vl,"+")+")"
			else if (rf[2,f]=="Rmean") rf[1,f]="(("+concat(vl,"+")+")/"+strofreal(length(vl))+")"
			else if (rf[2,f]=="Rmin") rf[1,f]="min("+concat(vl,",")+")"
			else if (rf[2,f]=="Rmax") rf[1,f]="max("+concat(vl,",")+")"
			else if (rf[2,f]=="Rtrue") rf[1,f]="("+concat("(":+vl:+"<.&":+vl:+"!=0)","+")+")"
			else if (rf[2,f]=="Rn") rf[1,f]="("+concat("(":+vl:+"<.","+")+")"
			else if (rf[2,f]=="Rvars") rf[1,f]=strofreal(length(vl))
			}
		e_exp[k]=concat(rf[1,],"")
		}
	}

void statgrid::get_e() { //>>def member<<
	e_body=e_func=J(1,k_n,"")
	for (k=1;k<=k_n;k++) {
		bf=tokenfunc(e_exp[k],(canon(),"nofunc")) //should be correct by the time it gets here!
		e_body[k]=bf[1]
		e_func[k]=bf[2]
		}
	e_n=0
	if (any(e_func:!="Nobs":&!tru2(e_body))) errel("Missing function body(s)",e_exp)
	while (length(e_body)>e_n) {
		plusf=tokenfunc(e_body[++e_n],canon())
		true=toindices(tru2(plusf[2,]))
		if (length(true)) {
			e_body=e_body,plusf[1,true]
			e_func=e_func,plusf[2,true]
			e_exp=e_exp,concat(plusf[2..1,true],"(","c"):+")"
			}
		}
	e_wt=e_btype=J(1,e_n,"")
	e_p2=J(1,e_n,.)
	e_tmp=st_tempname(e_n)
	
	for (e=1;e<=e_n;e++) {
		syntaxl(e_body[e],&(pbod="anything"),(&(pwt="w:eight="), &(pname="n:ame="),&(pnlab="nl:abel="),&(pform="f:ormat="),&(pdesc="d:escription=")),omore="ok")
		//suppose nlab & desc should not both be specified
		
		e_btype[e]=btype(pbod)
		if (e_btype[e]=="var"&e<=k_n) k_vars[e]=pbod
		e_body[e]=pbod
		e_wt[e]=pwt
		if (e_func[e]=="Med") {
			e_func[e]="P" //just because the name is created with p2, aargh!
			e_p2[e]=50
			}
		if (e_func[e]=="P") {
			if (truish(omore)) {
				e_p2[e]=trunc(strtoreal(omore))
				if (e_p2[e]<1|e_p2[e]>99) errel("percentiles must be between 1 and 99")
				}
			else e_p2[e]=50
			}
		else if (e_func[e]=="True"|e_func[e]=="Nobs") { //orig default is set to . instead of 1 for use in naming, later
			if (truish(omore)) {
				optionel(omore,(&(opct="%"),&(oprp="/")))
				if (opct&oprp) errel("% and / cannot both be specified")
				e_p2[e]=2*opct+3*oprp
				}
			else e_p2[e]=1
			}
		else if (anyof(("Min","Max"),e_func[e])) {
			if (truish(omore)) {
				e_p2[e]=trunc(strtoreal(omore))
				if (e_p2[e]<0|!truish(e_p2[e])) errel("Min/Max quntifier must be positive")
				}
			else e_p2[e]=1
			}
		
		if (e<=k_n) {
			if (truish(_st_varindex(pform))) {
				pform=charget(pform,"@form")
				vlab=charget(pform,"@vlab")
				}
			else {
				if (!truish(pform)) {
					if (anyof(("N","Uniq","Nobs"),e_func[e])) pform="%12.0gc"
					else if (e_func[e]=="True"&e_p2[e]==1) pform="%12.0gc"
					else if (e_btype[e]!="var") pform="%12.3gc"
					else  {
						if ((vf=charget(e_body[e],"@form"))!="%9.0g") pform=vf
						else pform="%12.3gc"
						}
					}
				if (e_btype[e]=="var"&anyof(("Med","P","Min","Max"),e_func[e])) vlab=charget(e_body[e],"@vlab")
				else vlab=""
				}
			ds.gen(k_vars[e],sprintf("%s@%f",pname,e),"",firstof(pnlab\pdesc\"@"),pform,vlab)
			}
		}
	}

void statgrid::set_names(|matrix newvars) { //>>def member
	names=cut(ds.vnames,b_n+1)
	names=firstof(substr(names,1,strpos(names,"@"):-1)\k_vars)
	names=names,J(1,truish(newvars),varlist("*"))
	crash=1..k_n
	fixes=(strlower(e_func[crash])\ subinstr(strofreal(e_p2[crash]),".","")\ e_wt[crash]\ strofreal(crash:+truish(newvars)*st_nvar()))
	for (f=1;f<=rows(fixes);f++) {
		fresh=J(1,k_n,0)
		for (i=1;i<=length(crash);i++) {
			fresh[crash[i]]=sum(names[crash[i]]:==names)
			}
		crash=toindices(fresh:>1:|names[1..k_n]:=="")
		names[crash]=concat(names[crash]\fixes[f,crash],"_","c")
		}
	ds.vnames[b_n+1..b_n+k_n]=names[1..k_n]
	}
void statgrid::set_flabels() { //>>def member
	nf=e_func[1..k_n]:=="nofunc"
	med=(e_func:=="P":&e_p2:==50)[1..k_n]
	ntr=toindices((e_func:=="Nobs":|e_func:=="True")[1..k_n])
	ftweak=e_func[1..k_n]:*!nf:*!med:+"()":*nf:+"Med":*med
	p2tweak=strofreal(e_p2[1..k_n]):*!med
	recode_(p2tweak,("1","n"\"2","%"\"3","/"))
	
	if (truish(ixs=toindices(k_vars:==""))) ds.nlabels[b_n:+ixs]=firstof(subinstr(ds.nlabels[b_n:+ixs],"@","")\subinstr(e_exp[ixs],"nofunc(","("))
	if (truish(vsets=uniqrows(select(k_vars,truish(k_vars))'))) {
		for (v=1;v<=rows(vsets);v++) {
			ixs=toindices(k_vars:==vsets[v])
			flabs=firstof(subinstr(ds.nlabels[b_n:+ixs],"@","")\ftweak[ixs])
			crash=1..length(flabs)
			fixes=subinstr(p2tweak[ixs],".","")\ e_wt[ixs]\strofreal(ixs)
			for (f=1;f<=rows(fixes);f++) {
				fresh=J(1,length(ixs),0)
				for (i=1;i<=length(crash);i++) {
					fresh[crash[i]]=sum(flabs[crash[i]]:==flabs)
					}
				crash=toindices(fresh:>1)
				flabs[crash]=concat(flabs[crash]\fixes[f,crash],",","c")
				}
			ds.nlabels[b_n:+ixs]=flabs
			}
		}
	}

string scalar statgrid::btype(string scalar obod) { //>>def member<<
	hasvar=0
	bod=e_bound+obod+e_bound
	while (regexm(bod,"[^_a-zA-Z][_a-zA-Z][_a-zA-Z0-9]*[^_a-zA-Z0-9(]")) {
		potvar=regexs(0)
		bod=substr(bod,strpos(bod,potvar)+strlen(potvar))
		potvar=substr(potvar,2,strlen(potvar)-2)
		if (hasvar=truish(varlist(potvar,"nfok"))) break
		}
	if (!hasvar) return("scalar")
	if (strtrim(potvar)==strtrim(obod)) {
		obod=varlist(obod)
		return("var")
		}
	return("exp")
	}

void statgrid::dseval() { //>>def member<<
	//if any non-scalar results, error
	sctest=tokenfunc(selectv(cut(e_body,1,k_n),cut(e_func,1,k_n):=="nofunc","r"),canon())
	sctest=select(sctest[1,],sctest[2,]:=="")
	for (sc=length(sctest);sc>0;sc--) {
		if (btype(sctest[sc])!="scalar") errel("Expressions outside of C-functions cannot include variables",sctest[sc])
		}
	
	if (!length(bys)) bys=&""
	for (b=1;b<=length(bys);b++) {
		eval(*bys[b])
		gn=rows(gixs)
		ds.nobs=ds.nobs+gn
		for (k=1;k<=ds.nvars;k++) {
			if (/*stat*/k>b_n) {
				if (/*init*/b==1) {
					if (ee_str[k-b_n]) {
						*ds.data[k]=J(0,1,"")
						ds.formats[k]="%20s"
						}
					else *ds.data[k]=J(0,1,.)
					}
				appdata=*ee_scalars[k-b_n]
				}
			else if (/*byvar*/any(ds.vnames[k]:==*bys[b])) appdata=el_data(gixs[,1],ds.vnames[k])
			else if (/*other byvar*/ds.sirtypes[k]=="s") appdata=J(gn,1,concat(ovlab," "))
			else /*other byvar*/appdata=J(gn,1,ovmiss)
			*ds.data[k]=*ds.data[k]\appdata //do this without \?
			}
		*bys[b]=gn
		}
	ds.settypes()
	}

void statgrid::eval(string vector by) { //>>def member<<
	if (truish(by)) stata(sprintf("qui egen int %s=group(%s) %s, missing",grpvar=st_tempname(),concat(by," "),adorn("if ",touse)))
	else grpvar=touse
	direc=truish(by)?"":"-"
	if (truish(grpvar)) {
		stata("gsort "+direc+grpvar)
		x=st_data(.,grpvar,touse)
		gixs=toindices(differ(x,"prev","true"))
		gixs=gixs,(cut(gixs',2)':-1\length(x))
		}
	else gixs=(1,st_nobs())
	
	
	temps=J(0,1,"")
	scalr=st_tempname() //should move these or clean them up, duplicated by margins
	if (truish(e_wt)) (void) st_addvar("byte",selector=st_tempname())
	ee_exp=e_exp;ee_body=e_body;ee_func=e_func
	ee_scalars=J(1,e_n,NULL)
	ee_str=J(1,e_n,.)
	
	for (e=e_n;e>=1;e--) {
		if (ee_func[e]=="done") continue
		if (ee_func[e]=="Nobs") {
			ee_str[e]=0
			r=gixs[,2]:-gixs[,1]:+1
			if (e_p2[e]>1/*%,prop*/) r=r/cut(gixs[,2],-1)
			if (e_p2[e]==2/*%*/) r=r*100
			ee_scalars[e]=&(r'')
			skipfunc=1
			}
		else {
			stata(sprintf("scalar %s=%s",scalr,ee_body[e]))
			ee_str[e]=length(st_strscalar(scalr))&anyof(("Med","P","Min","Max"),ee_func[e]) //str funcs
			ee_scalars[e]=&J(rows(gixs),1,ee_str[e]?"":.)
			skipfunc=length(st_strscalar(scalr))&anyof(("Mean","Var","SD","Sum","True"),ee_func[e])
			}
		if (!skipfunc) {
			cwt=e_wt[e]*!missing(_st_varindex(e_wt[e]))
			dosort=any(strmatch(ee_func[e],("Med"\"P"\"Max"\"Min")))
			
			if (e_btype[e]!="scalar") {
				if (truish(cwt)) stata(sprintf("qui replace %s=!mi(%s,%s)",selector,ee_body[e],cwt))
				if (e_btype[e]=="var") evar=ee_body[e] //rename evar!!
				else {
					if (e>k_n) evar=st_tempname()
					else evar=e_tmp[e]
					temps=temps\evar //temp needs to be dropped before multiple evals
					(void) st_addvar(ee_str[e]?"str10":"double",evar,1) //nofill? try...
					}
				}
			
			for (g=1;g<=rows(gixs);g++) {
				for (e2=e_n;e2>e;e2--) {
					if (ee_str[e2]) st_strscalar(e_tmp[e2],(*ee_scalars[e2])[g])
					else st_numscalar(e_tmp[e2],(*ee_scalars[e2])[g])
					}
				if (e_btype[e]=="exp") {
					stata(sprintf("qui replace %s=%s %s in %s",evar,ee_body[e],adorn("if ",grpvar),concat(gixs[g,],"/")))
					}
				if (ee_func[e]=="nofunc") {
					//scalar should only be relevant for obs, not vars; I think it works! depends on obs.dataset error for non-scalar exps
					(*ee_scalars[e])[g]=el_data(gixs[g,1],evar,0)
					continue
					}
				
				weight=rsw=extent=1
				if (e_btype[e]=="scalar") {
					stata(sprintf("scalar %s=%s",scalr,ee_body[e]))
					data=ee_str[e]?st_strscalar(scalr):st_numscalar(scalr)		
					}
				else if (truish(cwt)) {
					data=el_data(gixs[g,],evar,selector)
					weight=st_data(gixs[g,],cwt,selector)
					if (dosort) {
						o=order(data,1)
						data=data[o]
						weight=weight[o]
						rsw=runningsum(weight)
						extent=rsw[length(rsw)]
						}
					}
				else {
					data=el_data(gixs[g,],evar,0)
					if (dosort) {
						_sort(data,1)
						extent=length(data)
						}
					}
				
				if (!length(data)) (*ee_scalars[e])[g]=ee_str[e]?"":.
				else if (ee_func[e]=="Mean") (*ee_scalars[e])[g]=mean(data,weight)
				else if (ee_func[e]=="Var") (*ee_scalars[e])[g]=variance(data,weight)
				else if (ee_func[e]=="SD") (*ee_scalars[e])[g]=sqrt(variance(data,weight))
				else if (ee_func[e]=="Sum") (*ee_scalars[e])[g]=sum(data:*weight)
				else if (ee_func[e]=="N") (*ee_scalars[e])[g]=sum(tru2(data,"z"):*weight)
				else if (ee_func[e]=="Uniq") (*ee_scalars[e])[g]=rows(uniqrows(select(data,weight)))
				else if (ee_func[e]=="True") {
					r=sum((data:!=0):*weight) //no missing, here
					if (e_p2[e]>1/*%,prop*/) r=r/(r+sum((data:==0):*weight))
					if (e_p2[e]==2/*%*/) r=r*100
					(*ee_scalars[e])[g]=r
					}
				else if (ee_func[e]=="Max") {
					if (e_p2[e]>extent) (*ee_scalars[e])[g]=missingof(data)
					else (*ee_scalars[e])[g]=data[wrix(extent-e_p2[e]+1,rsw)]
					}
				else if (ee_func[e]=="Min") {
					if (e_p2[e]>extent) (*ee_scalars[e])[g]=missingof(data)
					else (*ee_scalars[e])[g]=data[wrix(e_p2[e],rsw)]
					}
				else {
					q=e_p2[e]*extent/100+1
					wrix=wrix(floor(q),rsw)
					if (wrix==1) (*ee_scalars[e])[g]=data[wrix]
					else if (trunc(q)!=q|data[wrix]==data[wrix-1]) (*ee_scalars[e])[g]=data[wrix]
					else if (ee_str[e]) (*ee_scalars[e])[g]=data[wrix-1]+"//"+data[wrix]
					else (*ee_scalars[e])[g]=mean(data[|wrix-1\wrix|])
					}
				}
			}
		//	set this scalar so it exists
		if (e>k_n) {
			if (ee_str[e]) st_strscalar(e_tmp[e],(*ee_scalars[e])[1])
			else st_numscalar(e_tmp[e],(*ee_scalars[e])[1])
			}
		//update columns for resolved stats
		if (e_btype[e]=="exp") {
			hits=toindices(ee_body:==ee_body[e])
			ee_exp[hits]=subinstr(ee_exp[hits],ee_body[e],evar) //??
			ee_body[hits]=J(1,length(hits),evar)
			}
		done=ee_exp[e]
		hits=toindices(ee_exp:==done)
		ee_func[hits]=ee_exp[hits]=J(1,length(hits),"done")
		ee_scalars[hits]=J(1,length(hits),ee_scalars[e])
		/**/ee_str[hits]=J(1,length(hits),ee_str[e])
		ee_body=subinstr(ee_body,done,e_tmp[e])
		ee_exp=subinstr(ee_exp,done,e_tmp[e])
		
		if (length(temps)) {
			done=!rowsum(strpos(ee_exp,temps))
			if (sum(done)) {
				st_dropvar(select(temps,done)')
				temps=selectv(temps,!done,"c")
				}
			}
		}
	}

real scalar statgrid::wrix(real scalar rawrix, real vector rsw) { //>>def member<<
	if (rsw==1) return(rawrix)
	return(1+sum(rawrix:>rsw))
	}

real scalar statgrid::get_unmiss() { //>>def member<<
	used=J(0,1,.)
	sv=somevars(by_vars,"n")
	for (v=length(sv);v>0;v--) {
		settouse(tu2,sprintf("if %s>.",sv[v]),touse)
		used=used\uniqrows(el_data(.,sv[v],tu2))
		}
	sv=somevars(by_vars,"s")
	for (v=length(sv);v>0;v--) {
		settouse(tu2,sprintf(`"if strmatch(%s,".?")"',sv[v]))
		used=used\uniqrows(strtoreal(el_data(.,sv[v],tu2)))
		}
	used=uniqrows(used)
	
	if (rows(used)>=26) errel("There are no unused missing values to use")
	all=(.a,.b,.c,.d,.e,.f,.g,.h,.i,.j,.k,.l,.m,.n,.o,.p,.q,.r,.s,.t,.u,.v,.w,.x,.y,.z)
	for (a=1;a<=26;a++) if (!anyof(used,all[a])) return(all[a])
	errel("unexpectedly ran out of missing values")
	}

end
//>>mosave<<
*! 22aug2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.2
mata:
end
 global hybcorners (`"!"%()*+!% % % %&#x2502;% %&#x250C;%&#x2514;%&#x251C;% %&#x2510;%&#x2518;%&#x2524;%&#x2500;%&#x252C;%&#x2534;%&#x253C;"')
 mata:
end
 global hybvl (`"!"%()*+!% %  %   % &#x2502; % &#x2502; "')
 mata:
end
 global hybhl (`"!"%()*+!% %<xx>%<xxx>%&#x2500;%&#x2500;"')
 mata:
end
 global stacorners (`"!"#%&()!# # # #*# #{c TLC}#{c BLC}#{c LT}# #{c TRC}#{c BRC}#{c RT}#*#{c TT}#{c BT}#{c +}#{c |}# # #{c 166}#{c -}# # #-"')
 mata:
end
 global stavl (`"!"#%&()!# #  #   # {c 166} # {c |} "')
 mata:
end
 global stahl (`"!"#%&()!# #<xx>#<xxx>#-#{c -}"')
 mata:


void tabel::new() { //>>def member<<
	_span=5; _vline=1; _hline=2; _align=3; _wrap=4; _class=6
	Lnone=0; Lsp1=1; Lsp2=2; Lsp2min=-1; Lminor=4; Lmajor=5
	left=1; center=2; right=3
	subch=char(154)
	subst1=char(134); subst2=char(135)
	subln1=char(150); subln2=char(151)
	//eol=eol() //will this need fiddling? have been assuming char(10)...
	eol=char(10) //can get non-os appropriate line breaks, so switch everything to 10
	cropped="{c 191}","&#191;"
	o_sta=o_eml=o_htm=0
	reset()
	}

void tabel::set(real scalar type, real vector rows, real vector cols, val,| string scalar pend) { //>>def member<<
	if (type==_class) {
		if (eltype(val)!="string"|orgtype(val)=="matrix") errel("_class values must be string vectors",val)
		trimmed=strtrim(val)
		for (r=1;r<=length(rows);r++) {
			for (c=1;c<=length(cols);c++) {
				if (pend=="") asarray(tcodes,(_class,rows[r],cols[c]),trimmed)
				else if (pend=="pre") asarray(tcodes,(_class,rows[r],cols[c]),(trimmed,asarray(tcodes,(_class,rows[r],cols[c]))))
				else if (pend=="post") asarray(tcodes,(_class,rows[r],cols[c]),(asarray(tcodes,(_class,rows[r],cols[c])),trimmed))
				}
			}
		}
	else {
		if (eltype(val)!="real"|orgtype(val)!="scalar") errel("non-_class values must be real scalars",val)
		//	if (type==_span&val==0) errel("Span cannot be set to zero")
		for (r=1;r<=length(rows);r++) {
			for (c=1;c<=length(cols);c++) {
				asarray(tcodes,(type,rows[r],cols[c]),val)
				}
			}
		}
	}

void tabel::get(matrix mat, real scalar type, real scalar r, real scalar c) { //>>def member<<
	val=asarray(tcodes,(type,r,c))
	if (length(val)) mat[r,c]=J(missing(r)?rows(mat):1,missing(c)?cols(mat):1,val)
	}

string vector tabel::sClasses(string vector classes) { //>>def member<<
	wscheme=vmap(classes,s_stub,"in")
	if (length(wscheme)) classes[wscheme]=o_scheme:+"_":+classes[wscheme] //o_scheme goes with s_stub
	return(adorn(" ",concat(classes," ")))
	}

//!defChar: define special mode-specific characters; must render as a single character for horizontal spaceing to work correctly
//!sta: stata character
//!hyb: hybrid (& optionally html) char
//!htm: html char if different from hyb
//!R: string code for the set of characters (decoded in render)
string scalar tabel::defChar(string scalar sta, string scalar eml,| string scalar htm) { //>>def member<<
	if (htm=="") htm=eml
	spchars=spchars\sta,eml,htm
	return(subch+charix(rows(spchars)))
	}

//!setSpan: style text within a cell
//!classes: classes to style text with
//!text: stuff to style
//!R: styled text (styled once rendered)
string matrix tabel::setSpan(string scalar classes, string matrix text) { //>>def member<<
	cix=asarray(scodes,tstyle=strtrim(classes))
	if (!length(cix)) asarray(scodes,tstyle,cix=charix(asarray_elements(scodes)+1))
	return(subst1+cix:+text:+subst2)
	}

//!setLinks: make text into hyperlinks
//!header: 'stata' and/or html attribute name(s) - eg, 'href' 'title'
//!info: link functional info
//!text: link display text
string colvector tabel::setLinks(string rowvector header, string matrix info, string colvector text) { //>>def member<<
	//do much error checking...
	if (!rows(text)) return(J(0,1,""))
	info=tru2(text):*info
	stcol=toindices(header:=="stata")
	if (truish(stcol)) colorsused=colorsused\"link" //!!
	htmcols=toindices(header:!="stata")
	nr=rows(links)+1::rows(links)+rows(text)
	links=links\J(rows(text),2,"")
	if (length(stcol)) links[nr,1]=adorn("{",info[,stcol],":")
	if (length(htmcols)) {
		links[nr,2]=adorn("<a ",concat(adorn(header[,htmcols]:+char((61,39)),info[,htmcols],char(39))," ","r"),">")
		}
	somelink=rowmax(tru2(info))
	return(somelink:*(subln1:+charix(nr,2)):+text:+somelink:*subln2)
	}

string rowvector tabel::getAtts(real scalar r, real scalar c) { //>>def member<<
	classes=asarray(tcodes,(_class,r,c))
	if (!length(classes)) return(J(1,cols(s_head),"")) //could present, empty, classes be an issue?
	tocompose=J(cn=length(classes),cols(s_head),"")
	for (cl=1;cl<=cn;cl++) {
		if (!length(found=select(s_body,s_stub:==classes[cl]))) {
			printf("{txt:Class '%s' not found}\n",classes[cl])
			continue
			}
		tocompose[cn-cl+1,]=found //order??
		}
	return(firstof(tocompose,"row"))
	}

string vector tabel::attStyle(string matrix atts,| matrix unadorned) { //>>def member<<
	if (!sum(strlen(atts))) return(J(rows(atts),1,""))
	if (o_sta)  return(concat(adorn("{",atts,":"),""))
	out=concat(lookupin(s_head,(1..cols(atts)):*(strlen(atts):>0)):+adorn(":",atts,";"),"")
	if (length(unadorned)) return(out)
	return(adorn("<span style='",out,"'>"))
	}

string scalar tabel::styleFin(string scalar style) { //>>def member<<
	if (!strlen(style)) return("")
	else if (substr(style,1,5)=="<span") return("</span>")
	else if (substr(style,1,2)=="<a") return("</a>")
	else if (substr(style,1,1)=="{") return("}"*strcount(style,"{"))
	else errel("style does not begin correctly",style)
	}

string colvector tabel::charix(real colvector ix,|matrix two) { //>>def member<<
	if (any(ix:<1:|ix:>58^args())) errel("Table element index out of range",ix)
	if (length(two)) return(concat(chars(64:+(trunc(ix:/59),mod(ix,59))),""))
	else return(chars(64:+ix))
	}
real scalar tabel::numix(string scalar ix) { //>>def member<<
	if (strlen(ix)>2) errel("Table element index ("+ix+") too long")
	num=ascii(ix):-64
	if (any(num:<(2-cols(num)):|num:>58)) errel("Table element index ("+ix+") out of range")
	if (cols(num)==2) return(num[1]*59+num[2])
	else return(num)
	}


//!o_parse: parse & set tabel display options
//!option: as described in outopt.sthlp, with the addition of main parameter [-] defining output to results
void tabel::o_parse(string scalar option) { //>>def member<<
	class elfs_out scalar elf
	syntaxl(option,&(main="anything"),(&(o_scheme="sch:eme="),&(styles="sty:les=")),o_and="more")
	
	o_dest=ocanon("Out(to)",strtrim(main),("-","r:esults","v:iewer","htm:l file","html p:age","m:ata"))
	if (o_dest=="html p") {
		if (!truish(findexternal("el_htmlpgs"))) {
			printf("{hi:Existing html pages not found; output below}")
			o_dest="r"
			}
		}
	if (o_dest=="-"|o_dest=="") o_dest="r" //not sure where blank may come from
	email=html=0
	if (o_dest=="htm") optionel(o_and,&(email="email"),o_and)
	if (o_dest=="m") optionel(o_and,(&(email="email"),&(html="html")),o_and)
	
	o_sta=o_dest=="v"|o_dest=="r"|(o_dest=="m"&!email&!html)
	o_eml=email
	o_htm=o_dest=="html p"|(o_dest=="htm"&!email)|(o_dest=="m"&html&!email)
	o_mode=select(("stata","email","html"),(o_sta,o_eml,o_htm))
	
	elf.init(select((elf.mstata,elf.memail,elf.mhtml),(o_sta,o_eml,o_htm)))
	scheme=elf.get(o_scheme)
	if (o_scheme=="") o_scheme="S" //need an actual name, after get
	if (truish(styles)) {
		if (!strpos(styles,"{")) styles=ftostr(pcanon(styles,"fex","css"))
		scheme=dedup(chtrim(columnize(columnize(styles,"}")',"{"),chars((9,10,13,32)))\scheme,1)
		}
	
	if (o_htm) {
		s_stub=subinstr(scheme[,1],".","")
		scheme[,1]=subinstr(scheme[,1],".","."+o_scheme+"_")
		s_body=concat(scheme[,1]:+" {":+scheme[,2]:+"}"," ")
		}
	else {
		s_head=uniqrows(strtrim(columnize(colshape(columnize(scheme[,2],";"),1),":")[,1]))
		s_head=select(s_head,strlen(s_head))'
		s_stub=strtrim(scheme[,1])
		s_body=J(rows(s_stub),cols(s_head),"")
		for (r=1;r<=rows(s_body);r++) {
			thisone=strtrim(columnize(columnize(scheme[r,2],";")',":"))
			s_body[r,vmap(thisone[,1],s_head)]=thisone[,2]'
			}
		}
	}

void tabel::render() { //>>def member<<
	if (o_sta+o_eml+o_htm!=1) o_parse("-")
	if (!length(body)) {
		reset()
		return
		}
	rb=rows(body)
	cb=cols(body)
	
	//********span, borders, align, wrap
	spans=J(rb,cb,1)
	vlines=J(rb,cb,Lsp2)
	hlines=J(rb,cb,Lnone)
	aligns=J(rb,cb,right)
	wraps=J(rb,cb,.)
	set(_class,.,.,"body","pre") // deal with class constants
	all4=(&vlines,&hlines,&aligns,&wraps)
	for (a=1;a<=4;a++) get(*all4[a],a,.,.)
	if (head) {
		hlines[head,]=J(1,cb,Lmajor)
		set(_class,1..head,.,"heading","pre")
		}
	if (stub) {
		vlines[,stub]=J(rb,1,Lmajor)
		set(_class,.,1..stub,"heading","pre")
		}
	for (c=1;c<=cb;c++) {
		for (a=1;a<=4;a++) get(*all4[a],a,.,c)
		}
	//when the stub causes rows above the col variable, the col lines can show, mistakenly!
	for (r=1;r<=rb;r++) {
		for (a=1;a<=4;a++) get(*all4[a],a,r,.)
		for (c=cb;c>=1;c--) {
			get(spans,_span,r,c)
			if ((skip=spans[r,c]-1)>0) spans[r,c+1..c+skip]=J(1,skip,0)
			else if (skip<0) spans[r,c]=1
			if (spans[r,c]>1) aligns[r,c]=center
			for (a=1;a<=4;a++) get(*all4[a],a,r,c)
			if (wraps[r,c]!=.&aligns[r,c]!=left) wraps[r,c]=0
			}
		}
	
	//***other mode links
	if (length(fill=toindices(!strlen(links[,1])))) links[fill,1]=J(length(fill),1,"{matacmd html link (does not function in stata):")
	if (length(fill=toindices(!strlen(links[,2])))) links[fill,2]=J(length(fill),1,"<a title='stata link (does not function in html)'>")
	//*** character subs
	body=subinstr(subinstr(body,(char((13,10))),char(10)),char(13),char(10))
	if (!o_sta) {
		body=subinstr(subinstr(body,"<",defChar("<","&lt;")),">",defChar(">","&gt;"))
		body=subinstr(body,char(10),"<br>")
		}
	//*** alt lines
	_editvalue(vlines,Lsp2min,o_sta?Lsp2:Lminor)
	_editvalue(hlines,Lsp2min,o_sta?Lsp1:Lminor)
	
	//***render htm
	if (o_htm) {
		spanstyles=asarray_keys(scodes),J(asarray_elements(scodes),1,"")
		for (ix=1;ix<=rows(spanstyles);ix++) {
			spanstyles[ix,2]=asarray(scodes,spanstyles[ix,1])
			spanstyles[ix,1]=sClasses(tokens(spanstyles[ix,1]))
			}
		spanstyles=sort(spanstyles,2)[,1]
		spanstyles=adorn("<span class='",spanstyles,"'>")
		
		saligns=sClasses("alignl"),sClasses("alignc")
		shlines=sClasses("hsp"),sClasses("hsp"),"",sClasses("hminor"),sClasses("hmajor")
		svlines=sClasses("vminor"),sClasses("vmajor")
		smisc=sClasses("unpadR"),sClasses("unpadL"),sClasses("altback")
		
		rbody=subinstr(body,eol,"<br />")
		for (ix=1;ix<=rows(spchars);ix++) rbody=subinstr(rbody,subch+charix(ix),spchars[ix,3])
		for (ix=1;ix<=rows(spanstyles);ix++) rbody=subinstr(rbody,subst1+charix(ix),spanstyles[ix]) /**/
		rbody=subinstr(rbody,subst2,"</span>")
		links[,2]=subinstrf(links[,2],"<a ",sprintf("<a class='%s' ",strtrim(sClasses("link"))))
		for (ix=1;ix<=rows(links);ix++) rbody=subinstr(rbody,subln1+charix(ix,2),links[ix,2])
		rbody=subinstr(rbody,subln2,"</a>")
		
		rendered=rendered+sprintf("<div style='height:%fem'></div><table class='%s'>\n",padbefore,sClasses("tbase")) //class name
		for (r=1;r<=rb;r++) {
			rendered=rendered+sprintf("<tr>\n")
			for (c=1;c<=cb;c++) {
				classes=sClasses(asarray(tcodes,(_class,.,.)))
				vlspan=vlines[r,c+spans[r,c]-1]
				if (aligns[r,c]!=right) classes=classes+saligns[aligns[r,c]] //uses literal value
				if (hlines[r,c]) classes=classes+shlines[hlines[r,c]]
				if (vlspan>=Lminor) classes=classes+svlines[vlspan-3]
				else if (vlspan<=Lsp1) classes=classes+smisc[1]
				if (c>1) if (vlines[r,c-1]==Lnone) classes=classes+smisc[2]
				if (altrows & r>head & mod(trunc((r-head-1)/altrows),2)) classes=classes+smisc[3]
				if (r>head|c<=stub) classes=classes+sClasses(asarray(tcodes,(_class,.,c)))
				if (c>stub|r<=head) classes=classes+sClasses(asarray(tcodes,(_class,r,.)))
				classes=adorn("class='",strtrim(classes+sClasses(asarray(tcodes,(_class,r,c)))),"'")
				colspan=spans[r,c]==1?"":sprintf(" colspan='%f'",spans[r,c])
				rendered=rendered+sprintf("<td %s%s>%s</td>",classes,colspan,rbody[r,c])
				c=c+spans[r,c]-1
				}
			rendered=rendered+sprintf("</tr>\n")
			}
		rendered=rendered+sprintf("</table><div style='height:%fem'></div>\n",padafter)
		reset()
		return
		}
	//***end render htm
	
	//***line recoding
	recode_(hlines,(Lsp2,Lsp1))
	replace(hlines,hlines:==Lnone:&hlines:<rowsum(hlines),Lsp1)
	vlwidths=colmin((colmax(vlines)\J(1,cb,3)))
	if (cb>1) replace(vlines,(spans[,2..cb],J(rb,1,1)):==0,vlwidths)
	replace(vlines,vlines:<vlwidths,vlwidths)
	
	//***widths
	//add min & max, maybe decrease vlines when compressed?
	rbody=subinstr(subinstr(subinstr(body,subch,""),subst2,""),subln2,"") //regexr bug wont match last char
	while (any(regexm(rbody,subst1+"."))) rbody=regexr(rbody,subst1+".","")
	while (any(regexm(rbody,subln1+".."))) rbody=regexr(rbody,subln1+"..","")
	cellsize=colshape(rowmax(strlen(columnize(colshape(rbody,1),eol))),cb)
	
	remain=(missing(usewidth)?c("linesize")-1:usewidth)-sum(vlwidths)-1 //-1 is left space
	if (remain<cb) errel("Tabel: Too many columns for the page width.")
	span=0
	widths=J(1,cb,0)
	do {
		span=span+1
		tcols=toindices(colmax(spans:==span))
		sizes=colmax((spans:==span):*cellsize)[tcols]
		order=order(sizes',1)
		if (span==1) {
			for (c=1;c<=length(tcols);c++) {
				widths[tcols[order[c]]]=min((sizes[order[c]],trunc(remain/(length(sizes)+1-c))))
				remain=remain-widths[tcols[order[c]]]
				}
			}
		else { //for multi-cols, additional space needs to be parcelled out to single cols
			topaligns=firstof(aligns,"row") //should never be 0 or .
			for (c=1;c<=length(tcols);c++) {
				subcols=tcols[order[c]]..tcols[order[c]]+span-1
				subwidth=sum(widths[subcols])+sum(vlwidths[cut(subcols,1,-2)])
				excess=pmin(trunc(remain/(length(tcols)+1-c)),pmax(0,sizes[order[c]]-subwidth))
				if (excess) {
					if (topaligns[subcols[1]]==center) {
						widths[subcols]=widths[subcols]:+trunc(excess/cols(subcols)):+((1..cols(subcols)):<=mod(excess,cols(subcols)))
						}
					else {
						lr=topaligns[subcols[1]]==left?span:1
						widths[subcols[lr]]=widths[subcols[lr]]+excess
						}
					remain=remain-excess
					}
				}
			}
		} while (remain & max(spans)>span)
	
	//***cell attributes
	attab=getAtts(.,.)
	s_n=cols(s_body)
	atrows=J(rb,s_n,"")
	atcols=J(cb,s_n,"")
	atcells=J(rb*cb,s_n,"")
	alt=select(s_body,s_stub:=="alt")
	for (c=1;c<=cb;c++) atcols[c,]=getAtts(.,c)
	for (r=1;r<=rb;r++) {
		atrows[r,]=getAtts(r,.)
		altr=altrows>1&r>head&mod(trunc((r-head-1)/altrows),2)?alt:J(0,s_n,"")
		for (c=1;c<=cb;c++) {
			atcells[(r-1)*cb+c,]=firstof(getAtts(r,c)\(c>stub|r<=head?atrows[r,]:J(0,s_n,""))\ (r>head|c<=stub?atcols[c,]:J(0,s_n,""))\altr\attab)
			}
		}
	cellstyles=colshape(attStyle(atcells),cb)
	
	//***span attributes
	atspans=J(asarray_elements(scodes),cols(s_head)+1,"")
	i=0
	for (loc=asarray_first(scodes); loc!=NULL; loc=asarray_next(scodes, loc)) {
		classes=tokens(asarray_key(scodes,loc))
		tocompose=J(length(classes),cols(s_head),"")
		for (cl=1;cl<=length(classes);cl++) {
			if (!length(found=select(s_body,s_stub:==classes[cl]))) {
				printf("{txt:Class '%s' not found in scheme}\n",classes[cl])
				continue
				}
			tocompose[cl,]=found //order??
			}
		atspans[++i,]=asarray_contents(scodes,loc),firstof(tocompose,"row")
		}
	atspans=sort(atspans,1)[,2..cols(atspans)] //drop cix column...
	spanstyles=attStyle(atspans)
	
	//***color warning
	if (o_sta) { //what to do about hyb??
		c=toindices(s_head:=="tstyle")
		colorsused=uniqrows(colorsused\atcells[,c]\atspans[,c])
		colorsused=select(colorsused,strlen(colorsused))
		}
	
	//*** lines
	corners=o_eml?strob_to($hybcorners):strob_to($stacorners)
	vlchars=o_eml?strob_to($hybvl):strob_to($stavl)
	hlchars=o_eml?strob_to($hybhl):strob_to($stahl)
	hlafter=cb>1?(hlines[,2..cb],J(rb,1,0)):0
	vlafter=rb>1?(vlines[2..rb,]\J(1,cb,0)):0
	if (o_eml) {
		maxl=Lminor-1:+((hlines:==Lmajor):|(hlafter:==Lmajor):|(vlines:==Lmajor):|(vlafter:==Lmajor))
		cornix=rowmax(hlines:>0):*((mod(vlwidths,2)):*
		(8:*(hlines:>maxl):+4:*(hlafter:>maxl):+2:*(vlines:>maxl):+(vlafter:>maxl):+1):+1:+17:*(maxl:==Lminor))
		lcolors=attStyle(select(s_body,s_stub:=="Lminor"))\attStyle(select(s_body,s_stub:=="Lmajor"))
		corners=adorn(lcolors[1],corners,"</span>")\adorn(lcolors[2],corners,"</span>")
		vlchars[5..6]=adorn(lcolors,vlchars[5..6],"</span>")
		hlchars[5..6]=adorn(lcolors,hlchars[5..6],"</span>")
		}
	else {
		cornix=rowmax(hlines:>0):*((mod(vlwidths,2)):*
		(8:*(hlines:>=Lminor):+4:*(hlafter:>=Lminor):+2:*(vlines:>=Lminor):+(vlafter:>=Lminor):+1):+1)
		cornix=(cornix:==5):*(18:+2:*(vlines:==Lminor):+(vlafter:==Lminor)):+
		(cornix:==14):*(22:+2:*(hlines:==Lminor):+(hlafter:==Lminor)):+
		(cornix:!=5:&cornix:!=14):*cornix
		lstyle=attStyle(select(s_body,s_stub:=="line"))
		vlchars=adorn(lstyle,vlchars,styleFin(lstyle))
		}
	vlines=lookupin(vlchars,vlines:+1)
	hlines=lookupin(hlchars,hlines[,1]:+1):+concat((widths:+(vlwidths:>1)):*lookupin(hlchars,hlines:+1):+lookupin(corners,cornix):+(vlwidths:>1):*lookupin(hlchars,hlafter:+1),"","r")
	if (o_sta) hlines=adorn(lstyle,hlines,styleFin(lstyle))
	
	//***generate
	//outside text (*) for hyb is somehow necessary for copy-paste to email
	if (o_eml) rendered=rendered+sprintf("*<table><tr><td><pre style='line-height: 100%%; margin: 0; font-weight: normal; font-style: normal; text-decoration: none; padding-top: %fem;padding-bottom:%fem; %s'>", padbefore,padafter,attStyle(select(s_body,s_stub:=="ground"),"unadorned"))
	else rendered=rendered+eol(padbefore) //+"{ul_off}"
	bits=subch,subst1,subln1,subst2,subln2,eol
	for (r=1;r<=rb;r++) {
		allcols=J(1,cb,NULL)
		maxr=0
		rwidths=widths
		for (c=1;c<=cb;c=c+spans[r,c]) {
			if (spans[r,c]>1) rwidths[c]= sum(widths[c..c+spans[r,c]-1])+sum(vlwidths[c..c+spans[r,c]-2])
			orig=body[r,c]
			style=fin=""
			nlines=J(0,1,"")
			nw=J(0,2,.)
			newline=1
			n=0
			while (strlen(orig)|!n) {
				if (newline) {
					nlines=nlines\(strlen(style)?style:"")
					indent=(newline==1)*(wraps[r,c]>0)*(wraps[r,c])-(newline==2)*(wraps[r,c]<0)*(wraps[r,c])
					nw=nw\indent,0
					newline=0
					n=rows(nlines)
					}
				allpos=strpos(orig,bits)
				pos=min(select(allpos,allpos))
				if (missing(pos)) pos=strlen(orig)
				posix=toindices(pos:==allpos)
				if (rwidths[c]-sum(nw[n,])<pos-(posix==4|posix==5|posix==6)) {
					//if (rwidths[c]-sum(nw[n,])<pos-(posix==4|posix==5)) {
					if (wraps[r,c]==.) {
						nlines[n]=nlines[n]+substr(orig,1,rwidths[c]-nw[n,2]-1)+cropped[1+o_eml]
						nw[n,2]=rwidths[c]
						orig=""
						}
					else {
						nom=rwidths[c]-sum(nw[n,])
						spc=strlast(substr(orig,1,nom)," ")
						dsh=strlast(substr(orig,1,nom),"-")
						if (spc<nom&dsh<nom) goodspot=max((spc,dsh))
						else goodspot=min((spc,dsh,nom))
						dropspace=substr(orig,goodspot,1)==" "
						nlines[n]=nlines[n]+substr(orig,1,goodspot-dropspace)
						nw[n,2]=nw[n,2]+goodspot-dropspace
						orig=substr(orig,goodspot+1)
						newline=2
						}
					if (strlen(style)) nlines[n]=nlines[n]+fin
					}
				else if (posix==6/*eol*/) {
					nlines[n]=nlines[n]+substr(orig,1,pos-1)
					nw[n,2]=nw[n,2]+pos-1
					orig=substr(orig,pos+1)
					newline=1
					if (strlen(style)) nlines[n]=nlines[n]+fin
					}
				else if (posix==1/*ch*/) {
					nlines[n]=nlines[n]+substr(orig,1,pos-1)+spchars[numix(substr(orig,pos+1,1)),1+o_eml]
					nw[n,2]=nw[n,2]+pos
					orig=substr(orig,pos+2)
					}
				else if(posix==2|posix==3/*st1,ln1*/) {
					if (strlen(style)) errel("style in a style should not happen...")
					if (posix==2) style=spanstyles[numix(substr(orig,pos+1,1))]
					else style=links[numix(substr(orig,pos+1,2)),1+!o_sta]
					fin=styleFin(style)
					nlines[n]=nlines[n]+substr(orig,1,pos-1)+style
					nw[n,2]=nw[n,2]+pos-1
					orig=substr(orig,pos+posix)
					}
				else if (posix==4|posix==5/*st2,ln2*/) {
					if (!strlen(style)) errel("style end withough current style should not happen...")
					nlines[n]=nlines[n]+substr(orig,1,pos-1)+fin
					nw[n,2]=nw[n,2]+pos-1
					orig=substr(orig,pos+1)
					style=fin=""
					}
				else { //end of str...
					nlines[n]=nlines[n]+orig
					nw[n,2]=nw[n,2]+pos
					orig=""
					}
				}
			maxr=pmax(maxr,n)
			nlines=cellstyles[r,c]:+nlines:+styleFin(cellstyles[r,c])
			nlines=" ":*nw[,1]:+nlines
			space=J(n,1,0),ceil(x=(rwidths[c]:-rowsum(nw)):/2),floor(x),J(n,1,0)
			align=aligns[r,c] /*uses left=1,center=2,right=3*/
			nlines=" ":*rowsum(space[,1..align]):+nlines:+" ":*rowsum(space[,align+1..4])
			allcols[c]=&(nlines'')
			}
		onerow=J(maxr,1,select(rwidths,spans[r,]):*" ")
		oc=0
		for (c=1;c<=cb;c=c+spans[r,c]) onerow[1..rows(*allcols[c]),++oc]=*allcols[c]
		onerow=onerow:+select(vlines[r,(1..cb):+spans[r,]:-1],spans[r,])
		rendered=rendered+concat(adorn(" ",concat(onerow,"","r"),eol),"")+adorn("",hlines[r],eol)
		}
	rendered=rendered+(o_eml?sprintf("</span></pre>\n</td></tr></table>*"):eol(padafter))
	reset()
	}
void tabel::reset() { //>>def member<<
	body=J(0,0,"")
	head=stub=altrows=0;usewidth=.
	padbefore=padafter=1
	spchars=J(0,3,"")
	tcodes=asarray_create("real",3)
	asarray_notfound(tcodes,J(1,0,""))
	scodes=asarray_create()
	links=J(0,2,"")
	}

//!present: display tabel, somewhere
//!outopt: if string, outopt will be sent to o_parse; if real, existing o_params are used.
void tabel::present(scalar outopt) { //>>def member<<
	pointer (class htmlpgs scalar) scalar pages
	class elfs_colors scalar elf
	
	if (eltype(outopt)=="string") o_parse(outopt)
	
	if (!strlen(rendered)&!length(body)) {
		body="Nothing to display"
		set(_class,.,.,"heading")
		}
	render()
	if (o_sta) rendered=rendered+elf.colornote(o_dest=="v",colorsused)
	
	if (o_dest=="m") {
		optionel(o_and,&(o_mata="!v:ariable="))
		rmexternal(o_mata)
		mem=crexternal(o_mata)
		*mem=rendered
		printf("{txt:Output sent to mata:%s}\n",o_mata)
		}
	else if (o_dest=="r") {
		printf(subinstr(subinstr(rendered,"%","%%",.),"\","\\")) //% and \ function in printf.
		//	display command has bug
		}
	else if (o_dest=="v") {
		optionel(o_and,(&(vn="n:ame="),&(append="app:end")))
		view=firstof(vn\"_new")
		if (st_isname(view)) {
			path=pathto("_toview.smcl","inst")
			name=view
			}
		else if (strlen(view)) {
			path=pathto(pcanon(view,"f",".smcl"))
			name=pathparts(path,2)
			}
		fowrite(path,rendered,append?"a":"ow")
		stata(sprintf(`"view "%s"%s"',path,adorn("##|",name)))
		}
	else if (o_dest=="html p") {
		pages=valofexternal("el_htmlpgs")
		pages->place(rendered)
		pages->addcss(o_scheme,s_body)
		printf("{txt:Output included with html pages}\n")
		}
	else { //htm
		optionel(o_and,(&(title="t:itle="),&(rev="rev="),&(desc="d:escription="), &(use="u:sing="),&(sav="sav:ing="),&(ms="ms"),&(feinfo="el_grail=")))
		if (ms&truish(ext=pathparts(use,3))) fowrite(pathto("ms_htm.txt"),ext)
		else if (ms&truish(ext=pathto("ms_htm.txt","","fex"))) ext=ftostr(ext) //will error if blank is stored...
		else ext=".html" 
		if (truish(sav)) sav=pcanon(sav,"file dcn",ext)
		else if (truish(use)) sav=pcanon(use,"file dcn",ext) //deprecated but not gone
		
		pages=&(htmlpgs())
		pages->page()
		pages->header(title,rev,desc)
		pages->place(rendered)
		if (!o_eml) pages->addcss(o_scheme,s_body)
		pages->write("",sav,feinfo)
		
		if (ms&!o_eml) {
			page=ftostr(sav)
			styles=columnize(columnize(s_body,"}")',"{")
			classes=strtrim(substr(styles[,1],strpos(styles[,1],"."):+1))
			atts=styles[,2]:+";":*(substr(styles[,2],-1):!=";")
			newcls=""
			i=0
			while (regexm(page,"class='( *[^-][^']*)'")) {
				those=regexs(1)
				page=subinstr(page,"class='"+those+"'","class='-wp"+strofreal(++i)+"'")
				found=vmap(tokens(those),classes,"only")
				if (length(found)) newcls=newcls+".-wp"+strofreal(i)+" {"+concat(atts[found]," ")+"}"+eol()
				}
			page=subinstr(page,"</style>",newcls+"</style>")
			fowrite(sav=pathparts(sav,12)+ext,page)
			}
		launchfile(sav)
		}
	rendered=""
	}

end
//>>mosave<<
*! 9oct2015
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11

mata:

void textidents::new() { //>>def member
	rxchars=".[{}()*+?|^$\"
	}

string scalar textidents::esc(string scalar in) { //>>def member
	rxv=columnize(rxchars,"")
	out=in
	for (r=length(rxv);r;r--) out=subinstr(out,rxv[r],"\"+rxv[r])
	return(out)
	}

void textidents::setdel(string matrix in, string rowvector fspec) { //>>def member
	if (length(fspec)!=3) errel("textidents:findspec must be 3 cells")
	check=rowshape(in,1),fspec
	del=charsubs(check,1,ascii(rxchars))
	}

string matrix textidents::replace(string matrix text, string vector fspec, string scalar r,|matrix hits) { //>>def member
	setdel(text,fspec)
	text=del:+text:+del
	
	hits=0
	f=adorn("(",fspec[1],")")+fspec[2]+adorn("(",fspec[3],")")
	rtype=1+truish(fspec[1])+2*truish(fspec[3])
	while (any(regexm(text,f))) {
		++hits
		if (rtype==1) text=regexr(text,f,r)
		else if (rtype==2) text=regexr(text,f,regexs(1)+r)
		else if (rtype==3) text=regexr(text,f,r+regexs(1))
		else /*4*/ text=regexr(text,f,regexs(1)+r+regexs(2))
	//	text=regexr(text,f,regexs(1)+r+regexs(2))
		}
	text=subinstr(text,del,"")
	return(text)
	}

string colvector textidents::find(string matrix in, string vector fspec) { //>>def member
	class collector scalar co
	co.init()
	
	setdel(in,fspec)
	text=del+concat(rowshape(in,1),del)+del
	
	f=fspec[1]+"("+fspec[2]+")"+fspec[3]
	while (regexm(text,f)) {
		co.add(regexs(1))
		mark=regexs(0)
		text=substr(text,strpos(text,mark)+strlen(mark))
		}
	return(dedup(expand(co.compose(),1)))
	}
end
//>>mosave
*! 30sep2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:


void xmlelem::new() { //>>def member
	sp=char(32)+char(9)+char(10)+char(13)
	spm="["+sp+"]+"
	spo="["+sp+"]*"
	nch=`"[^='"<>/"'+sp+"]"
	nnch=`"[='"<>/"'+sp+"]"
	}

scalar xmlelem::getv(string scalar name,| matrix toreal) { //>>def member<<
	out=lookupin(attv,toindices(attn:==name,"z"))
	return(truish(toreal)?strtoreal(out):out)
	}

real scalar xmlelem::nnis(string scalar blob, string scalar test) { //>>def member<<
	if (!truish(blob)|!truish(test)) return(0)
	nname=regexs2(blob,"<("+this.nch+"+)"+this.nnch,1)
	return(nname==test)
	}

real scalar xmlelem::next(string scalar blob,| string scalar target) { //>>def member<<
	if (!truish(blob)) return(0)
	name=content=""
	attn=attv=J(0,1,"")
	start="<"+target
	if (!(st=strpos(blob,start))) return(0)
	blob=substr(blob,st+1)
	name=regexs2(blob,"("+nch+"+)"+spo,1)
	blob=substr(blob,strlen(name)+1)
	while (regexm(blob,"^"+spm+"("+nch+"+)"+spo+"="+spo+`"(['"])"')) {
		attn=attn\regexs(1)
		qt=regexs(2)
		blob=substr(blob,strlen(regexs(0))+1)
		q2=strpos(blob,qt)
		attv=attv\substr(blob,1,q2-1)
		blob=substr(blob,q2+1)
		}
	st2s=strpos(blob,("?>","/>",">")) //? is for xml def, kluge
	st2=min(select(st2s,st2s))
	if (st2!=st2s[3]) {
		content=""
		blob=substr(blob,3)
		}
	else {
		blob=substr(blob,st2+1)
		d=1
		while (d) {
			hit=regexm(blob,"(<|</)"+name+nnch)
			if (!hit) errel("No closing tag: "+name)
			m=strpos(blob,regexs(0))
			content=content+substr(blob,1,m-1)
			blob=substr(blob,m)
			d=d-(regexs(1)=="<"?-1:1)
			if (d) {
				content=content+regexs(0)
				blob=substr(blob,strlen(regexs(0))+1)
				}
			}
		blob=substr(blob,strpos(blob,">")+1)
		}
	//show((name,content\attn,attv),"elem")
	while (regexm(blob,"^</[^>]+>")) {
		blob=substr(blob,strlen(regexs(0))+1)
		}
	//show(blob,"left")
	return(1)
	}

void xmlelem::di() { //>>def member<<
	show((name,content\attn,attv))
	}

end
//>>mosave<<

*!9jun2015
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

void dataset_dta::new() { //>>def member
	C=bufio()
	stend=char(0)
	}

string vector dataset_dta::getversion(string scalar filename) { //>>def member<<
	svs="113","v8"\"114","v10"\"115","v12"\"117","v13"\"118","v14"
	filepath=pcanon(filename,"fex","dta")
	
	fid=fopen(filepath,"r") //onerr
	test=fread(fid,28)
	fvers=fread(fid,3)
	fclose(fid)
	if (test!="<stata_dta><header><release>") {
		fvers=strofreal(ascii(substr(test,1,1)))
		svers=select(svs[,2],fvers:==svs[,1])
		if (truish(svers)) return((svers,fvers))
		else return(("Unusable file version (v12-)",fvers,"error"))
		}
	else {
		svers=select(svs[,2],fvers:==svs[,1])
		if (truish(svers)) return((svers,fvers))
		else return(("Unusable file version (v13+)",test+fvers,"error"))
		}
	}

void dataset_dta::readfile(string scalar filename,| string scalar pass) { //>>def member<<
	filepath=pcanon(filename,"fex","dta")
	if (pathparts(filepath,3)==".dta"|pass=="isdta") use=filepath
	else { //translate
		use=st_tempfilename()
		trans=recode(pathparts(filepath,3),(".xls",".xl"\".xlsx",".xl"\".csv",".txt"))
		optionel(pass,&(metamatch="metamatch"),pass)
		pass=expand(pass,1)
		if (trans==".xl") {
			optionel(pass,&(wcolor="col:ors"),pass)
			pass=expand(pass,1)
			if (!wdata) { // do 1 row
				stata(sprintf(`"qui import exc "%s", describe"',filepath)) //mfs
				mf=regexs2(st_global("r(range_1)"),":([A-Z]+)",1) //get nobs from this!
				pass=pass+sprintf(" cellra(A1:%s2)",mf)
				}
			pass=expand(pass,1)
			if (wcolor) pass=pass+(wdata?sprintf(" color(%s)",xlmread(filepath)):" dcolor")+metamatch*" allcolor"
			
			sput(script="",sprintf(`"mata: fin_xl("%s","%s")"',filepath,pass))
			sput(script,sprintf(`"save "%s", replace emptyok"',use))
			// sput(script,sprintf(`"mata: savel("%s","","","dta")"',use))
			callstata(script,"log")
			}
		else if (trans==".txt") {
			if (!wdata) pass=pass+" rowr(1:2)"
			sput(script="",sprintf(`"import delim "%s", clear %s"',filepath,pass))
			sput(script,sprintf(`"save "%s", replace emptyok"',use))
			// sput(script,sprintf(`"mata: savel("%s","","","dta")"',use))
			callstata(script,"log")
			}
		else {
			if (!wdata) pass=pass+" where(_rownum<2)"
			callst(filepath,use,pass)
			}
		}
	
	vers=getversion(use)
	if (length(vers)>2) errel(vers[1],vers[2])
	fv=strtoreal(vers[2])
	
	fh=fopen(use,"r")
	if (fv<=115) read_115m()
	else if (fv==117) read_117()
	else if (fv==118) read_118()
	fclose(fh)
	if (!wdata&truish(trans)) nobs=.e //set nobs, fsize here?
	}

void dataset_dta::writefile(string scalar filepath) { //>>def member<<
	path=pcanon(filepath,"file",".dta")
	unlink(path)
	
	nomvers=trunc(firstof(strtoreal(st_global("el_dsvers"))\c("stata_version")))
	if (nomvers<9|nomvers>14) errel("Unknown file version to write:",nomvers)
	fh=fopen(path,"w") //onerr
	rmexternal("fh")
	g=crexternal("fh")
	*g=fh
	if (nomvers<13) write_114()
	else if (nomvers==13) err=write_117()
	else if (nomvers==14) err=write_118()
	fclose(fh)
	if (truish(err)) errel(err)
	}

void dataset_dta::read_115m() { //>>def member
	dtavers=fbufget(C,fh,"%1bu") //data format v9=113, v10=114, v12=115
	bufbyteorder(C,fbufget(C,fh,"%1bu")) //byteorder, 1 or 2
	(void) fbufget(C,fh,"%1bu") //filetype
	(void) fbufget(C,fh,"%1bu") //unused
	nvars=fbufget(C,fh,"%2bu") //nvars
	nobs=fbufget(C,fh,"%4bu") //nobs
	dtalabel=fbufget(C,fh,"%81s") /*dataset label, 0term*/
	dtstamp=fbufget(C,fh,"%18s") /*date/time, 0term*/
	
	bytes=fbufget(C,fh,"%1bu",nvars)
	sirtypes=substr("sir",1:+(bytes:>250):+(bytes:>=254),1)
	bytes=editvalue(editvalue(editvalue(editvalue(editvalue(bytes,251,1),252,2),253,4),254,4),255,8)
	vnames=fbufget(C,fh,"%33s",nvars)
	sortvars=fbufget(C,fh,"%2bu",nvars)
	(void) fbufget(C,fh,"%2bu") //sort terminator
	if (dtavers<=113) formats=fbufget(C,fh,"%12s",nvars)
	else formats=fbufget(C,fh,"%49s",nvars)
	vlabrefs=fbufget(C,fh,"%33s",nvars)
	nlabels=fbufget(C,fh,"%81s",nvars)
	
	data=J(1,nvars,NULL)
	vlabnames=J(1,0,"")
	vlabtabs=J(1,0,NULL)
	chars=J(0,3,"")
	
	if (wchars|wdata|wlabs) {
		achar=fbufget(C,fh,"%1bu")
		acharlen=fbufget(C,fh,"%4bu")
		while (achar+acharlen) {
			chars=chars\fbufget(C,fh,"%33s"),fbufget(C,fh,"%33s"),fbufget(C,fh,sprintf("%%%fs",acharlen-66)) //varname, charname, contents --fix for contents longer than 244
			achar=fbufget(C,fh,"%1bu")
			acharlen=fbufget(C,fh,"%4bu")
			}
		
		if (!wdata) { //skip data, but fseek can't go over ~2g (32bit stata)
			fseek(fh,nobs*(sum(bytes)),0) //not read data
			}
		else { //got to enable specifying vars/obs
			offsets=runningsum(bytes)
			w=offsets[nvars]
			offsets=0,cut(offsets,1,-2)
			B=fbufget(C,fh,"%"+strofreal(w)+"S",nobs)
			bfmts="%":+strofreal(bytes)+subinstr(subinstr(sirtypes,"i","b"),"r","z")
			for (k=1;k<=nvars;k++) {
				if (nobs) {
					acol=substr(B,offsets[k]+1,bytes[k])
					astr=nobs*bytes[k]*"@"
					for (n=1;n<=nobs;n++) _substr(astr,acol[n],(n-1)*bytes[k]+1)
					data[k]=&(bufget(C,astr,0,bfmts[k],nobs)')
					}
				else data[k]=&J(0,1,sirtypes[k]=="s"?"":.)
				}
			}
		
		if (wlabs) {
			fseek(fh,4,0) //length
			n=0
			while (fstatus(fh)==0) {
				aname=fbufget(C,fh,"%33s")
				if (fstatus(fh)) break
				fseek(fh,3,0) //empty
				entries=fbufget(C,fh,"%4bu")
				ttot=fbufget(C,fh,"%4bu")
				tlens=fbufget(C,fh,"%4bu",entries)'
				vlabnames=vlabnames,aname
				vlabtabs=vlabtabs,&J(entries,2,"")
				(*vlabtabs[++n])[,1]=strofreal(fbufget(C,fh,"%4bs",entries)',"%10.0f")
				*vlabtabs[n]=(*vlabtabs[n])[order(tlens,1),]
				_sort(tlens,1)
				for (i=1;i<entries;i++) tlens[i]=tlens[i+1]-tlens[i]
				tlens[entries]=ttot-tlens[entries]
				for (i=1;i<=entries;i++) (*vlabtabs[n])[i,2]=fbufget(C,fh,sprintf("%%%fs",tlens[i]))
				fseek(fh,4,0) //length
				}
			}
		}
	}

void dataset_dta::read_117() { //>>def member
	read_next("<stata_dta")
	read_next("<header")
	if ((tvers=read_next("release","%3s"))!="117") errel("Unknown dataset format: "+tvers)
	bo=read_next("byteorder","%3s")
	bufbyteorder(C,(bo=="MSF")+2*(bo=="LSF")) //assume something else will error
	nvars=read_next("K","%2bu")
	nobs=read_next("N","%4bu")
	dtal=read_next("<label","%1bu")
	dtalabel=read_next("label>",sprintf("%%%fs",dtal))
	dtal=read_next("<timestamp","%1bu") /*0 or 17*/
	dtstamp=read_next("timestamp>","%17s")
	(void) read_next("header>")
	map=rowshape(read_next("map","%4bu",28),14)
	map=map[,bufbyteorder(C)]:*2^32:+map[,3-bufbyteorder(C)]
	bytes=read_next("variable_types","%2bu",nvars)
	strls=bytes:==32768
	strlixs=toindices(strls)
	sirtypes=length(bytes)?substr("sri",1:+(bytes:>32768):+(bytes:>=65528),1):J(1,0,"")
	bytes=recode(bytes,(32768,8\65526,8\65527,4\65528,4\65529,2\65530,1))
	vnames=read_next("varnames","%33s",nvars)
	sortvars=read_next("sortlist","%2bu",nvars+1)
	sortvars=cut(sortvars,.,toindices(!sortvars)[1]-1)
	formats=read_next("formats","%49s",nvars)
	vlabrefs=read_next("value_label_names","%33s",nvars)
	nlabels=read_next("variable_labels","%81s",nvars)
	
	data=J(1,nvars,NULL)
	vlabnames=J(1,0,"")
	vlabtabs=J(1,0,NULL)
	chars=J(0,3,"")
	
	if (wchars) {
		fseek(fh,map[9],-1)
		(void) read_next("<characteristics")
		achar=read_next("?ch")
		while (achar) {
			acharlen=fbufget(C,fh,"%4bu")
			chars=chars\fbufget(C,fh,"%33s",2),read_next("ch>",sprintf("%%%fs",acharlen-66))
			achar=read_next("?ch")
			}
		(void) read_next("characteristics>")
		}
	if (wdata) { //got to enable specifying vars/obs
		fseek(fh,map[10],-1)
		read_next("<data")
		if (nvars) {
			offsets=runningsum(bytes)
			w=offsets[nvars]
			offsets=0,cut(offsets,1,-2)
			B=fbufget(C,fh,"%"+el_strof(w)+"S",nobs)
			data=J(1,nvars,NULL)
			bfmts="%":+strofreal(bytes)+subinstr(subinstr(sirtypes,"i","b"),"r","z")
			bfmts[strlixs]=J(1,sum(strls),"%8S")
			for (k=1;k<=nvars;k++) {
				if (nobs) {
					acol=substr(B,offsets[k]+1,bytes[k])
					astr=nobs*bytes[k]*"@"
					for (n=1;n<=nobs;n++) _substr(astr,acol[n],(n-1)*bytes[k]+1)
					data[k]=&(bufget(C,astr,0,bfmts[k],nobs)')
					}
				else data[k]=&J(0,1,sirtypes[k]=="s"?"":.)
				}
			}
		read_next("data>")
		if (length(strlongs=toindices(strls))) {
			read_next("<strls")
			for (o=1;o<=nobs;o++) {
				for (vs=1;vs<=length(strlongs);vs++) {
					v=strlongs[vs]
					vo=bufget(C,(*data[v])[o],0,"%4bu",2)
					if (!any(vo)) (*data[v])[o]=""
					else if (vo==(v,o)) { //gso
						fseek(fh,12,0) //3 GSO, 4v, 4o, 1type
						gsol=fbufget(C,fh,"%4bu")
						(*data[v])[o]=fbufget(C,fh,sprintf("%%%fS",gsol))
						}
					else if (vo[2]<o|(vo[2]==o&vo[1]<v)) (*data[v])[o]=(*data[vo[1]])[vo[2]]
					else errel("Forward read error in STRLS")
					}
				}
			}
		}
	bytes[strlixs]=J(1,sum(strls),.)
	
	if (wlabs) {
		fseek(fh,map[12],-1)
		n=0
		read_next("<value_labels")
		alab=read_next("?lbl")
		while (alab) {
			fseek(fh,4,0) //length
			aname=fbufget(C,fh,"%33s")
			fseek(fh,3,0) //empty
			entries=fbufget(C,fh,"%4bu")
			ttot=fbufget(C,fh,"%4bu")
			tlens=fbufget(C,fh,"%4bu",entries)'
			vlabnames=vlabnames,aname
			vlabtabs=vlabtabs,&J(entries,2,"")
			(*vlabtabs[++n])[,1]=strofreal(fbufget(C,fh,"%4bs",entries)',"%10.0f")
			*vlabtabs[n]=(*vlabtabs[n])[order(tlens,1),]
			_sort(tlens,1)
			for (i=1;i<entries;i++) tlens[i]=tlens[i+1]-tlens[i]
			tlens[entries]=ttot-tlens[entries]
			for (i=1;i<=entries;i++) (*vlabtabs[n])[i,2]=fbufget(C,fh,sprintf("%%%fs",tlens[i]))
			(void) read_next("lbl>")
			alab=read_next("?lbl")
			}
		}
	}

void dataset_dta::read_118() { //>>def member
	(void) read_next("<stata_dta")
	(void) read_next("<header")
	if ((tvers=read_next("release","%3s"))!="118") errel("Unknown dataset format: "+tvers)
	bo=read_next("byteorder","%3s")
	bufbyteorder(C,(bo=="MSF")+2*(bo=="LSF")) //assume something else will error
	nvars=read_next("K","%2bu")
	nobs=read_next("N","%8bu")
	dtal=read_next("<label","%2bu")
	dtalabel=read_next("label>",sprintf("%%%fs",dtal))
	dtal=read_next("<timestamp","%1bu") /*0 or 17*/
	dtstamp=read_next("timestamp>","%17s")
	(void) read_next("header>")
	map=rowshape(read_next("map","%4bu",28),14)
	map=map[,bufbyteorder(C)]:*2^32:+map[,3-bufbyteorder(C)]
	bytes=read_next("variable_types","%2bu",nvars)
	strls=bytes:==32768
	strlixs=toindices(strls)
	sirtypes=length(bytes)?substr("sri",1:+(bytes:>32768):+(bytes:>=65528),1):J(1,0,"")
	bytes=recode(bytes,(32768,8\65526,8\65527,4\65528,4\65529,2\65530,1))
	vnames=read_next("varnames","%129s",nvars)
	sortvars=read_next("sortlist","%2bu",nvars+1)
	sortvars=cut(sortvars,.,toindices(!sortvars)[1]-1)
	formats=read_next("formats","%57s",nvars)
	vlabrefs=read_next("value_label_names","%129s",nvars)
	nlabels=read_next("variable_labels","%321s",nvars)
	
	data=J(1,nvars,NULL)
	vlabnames=J(1,0,"")
	vlabtabs=J(1,0,NULL)
	chars=J(0,3,"")
	
	if (wchars) {
		fseek(fh,map[9],-1)
		(void) read_next("<characteristics")
		achar=read_next("?ch")
		while (achar) {
			acharlen=fbufget(C,fh,"%4bu")
			chars=chars\fbufget(C,fh,"%129s",2),read_next("ch>",sprintf("%%%fs",acharlen-258))
			achar=read_next("?ch")
			}
		(void) read_next("characteristics>")
		}
	if (wdata) { //got to enable specifying vars/obs
		fseek(fh,map[10],-1)
		read_next("<data")
		if (nvars) {
			offsets=runningsum(bytes)
			w=offsets[nvars]
			offsets=0,cut(offsets,1,-2)
			B=fbufget(C,fh,"%"+el_strof(w)+"S",nobs)
			data=J(1,nvars,NULL)
			bfmts="%":+strofreal(bytes)+subinstr(subinstr(sirtypes,"i","b"),"r","z")
			bfmts[strlixs]=J(1,sum(strls),"%8S")
			for (k=1;k<=nvars;k++) {
				if (nobs) {
					acol=substr(B,offsets[k]+1,bytes[k])
					astr=nobs*bytes[k]*"@"
					for (n=1;n<=nobs;n++) _substr(astr,acol[n],(n-1)*bytes[k]+1)
					data[k]=&(bufget(C,astr,0,bfmts[k],nobs)')
					}
				else data[k]=&J(0,1,sirtypes[k]=="s"?"":.)
				}
			}
		read_next("data>")
		if (length(strlongs=toindices(strls))) {
			read_next("<strls")
			for (n=1;n<=nobs;n++) {
				for (sl=1;sl<=length(strlongs);sl++) {
					k=strlongs[sl]
					v=bufget(C,(*data[k])[n],0,"%2bu")
					o=bufget6((*data[k])[n],2)
					if (!v&!o) (*data[k])[n]=""
					else if (v==k&o==n) { //gso
						fseek(fh,16,0) //3 GSO, 4v, 8o, 1type
						gsol=fbufget(C,fh,"%4bu")
						(*data[k])[n]=fbufget(C,fh,sprintf("%%%fS",gsol))
						}
					else if (o<n|(o==n&v<k)) (*data[k])[n]=(*data[v])[o]
					else errel("Forward read error in STRLS")
					}
				}
			}
		}
	bytes[strlixs]=J(1,sum(strls),.)
	
	if (wlabs) {
		fseek(fh,map[12],-1)
		n=0
		read_next("<value_labels")
		alab=read_next("?lbl")
		while (alab) {
			fseek(fh,4,0) //length
			aname=fbufget(C,fh,"%129s")
			fseek(fh,3,0) //empty
			entries=fbufget(C,fh,"%4bu")
			ttot=fbufget(C,fh,"%4bu")
			tlens=fbufget(C,fh,"%4bu",entries)'
			vlabnames=vlabnames,aname
			vlabtabs=vlabtabs,&J(entries,2,"")
			(*vlabtabs[++n])[,1]=strofreal(fbufget(C,fh,"%4bs",entries)',"%10.0f")
			*vlabtabs[n]=(*vlabtabs[n])[order(tlens,1),]
			_sort(tlens,1)
			for (i=1;i<entries;i++) tlens[i]=tlens[i+1]-tlens[i]
			tlens[entries]=ttot-tlens[entries]
			for (i=1;i<=entries;i++) (*vlabtabs[n])[i,2]=fbufget(C,fh,sprintf("%%%fs",tlens[i]))
			(void) read_next("lbl>")
			alab=read_next("?lbl")
			}
		}
	}

void dataset_dta::write_114() { //>>def member
	fbufput(C,fh,"%1bu",114) //format v10
	fbufput(C,fh,"%1bu",byteorder()) //byteorder
	fbufput(C,fh,"%1bu",1) //filetype
	fbufput(C,fh,"%1bu",1) //unused?
	fbufput(C,fh,"%2bu",nvars) //nvars
	fbufput(C,fh,"%4bu",nobs) //nobs, always known?
	fbufput(C,fh,"%81s",dtalabel+stend) //dataset label
	fbufput(C,fh,"%18s",datetime()+stend) //date/time
	
	types=bytes:*(sirtypes:=="s"):+(sirtypes:=="i"):*(250:+bytes:-(bytes:==4)):+ (sirtypes:=="r"):*(253:+bytes:/4)
	fbufput(C,fh,"%1bu",types)
	fbufput(C,fh,"%33s",vnames) //stend?
	fbufput(C,fh,"%2bu",expand(sortvars,nvars))
	fbufput(C,fh,"%2bu",0) //end sort
	fbufput(C,fh,"%49s",formats) //:+stend
	fbufput(C,fh,"%33s",vlabrefs) // value label refs
	fbufput(C,fh,"%81s",nlabels)
	
	for (c=1;c<=rows(chars);c++) {
		fbufput(C,fh,"%1bu",1) //write 1=this is a char
		fbufput(C,fh,"%4bu",66+strlen(chars[c,3])+1) //length of char
		fbufput(C,fh,"%33s",chars[c,1]) //var name  stend??
		fbufput(C,fh,"%33s",chars[c,2]) //char name
		fwrite(fh,chars[c,3]+stend)
		}
	fbufput(C,fh,"%1bu",0); fbufput(C,fh,"%4bu",0) //0s end chars
	offsets=runningsum(bytes)
	w=offsets[nvars]
	offsets=0,cut(offsets,1,-2)
	//offsets=0,offsets[1..nvars-1]
	if (nobs&w) {
		B=nobs*w*char(0) //total mem of data
		bfmts="%":+strofreal(bytes)+subinstr(subinstr(sirtypes,"i","b"),"r","z") //b alone is stata
		for (n=1;n<=nobs;n++) {
			for (k=1;k<=nvars;k++) {
				bufput(C,B,(n-1)*w+offsets[k],bfmts[k],(*data[k])[n])
				}
			}
		fwrite(fh,B)
		}
	
	for (l=1;l<=length(vlabnames);l++) {
		labtab=*vlabtabs[l]
		fbufput(C,fh,"%4bu",8*((r=rows(labtab))+1)+sum(txtlen=strlen(labtab[,2]))+r) //length of label table 
		fbufput(C,fh,"%33s",vlabnames[l])
		fbufput(C,fh,"%3s","") //padding
		fbufput(C,fh,"%4bu",r) //number of entries
		fbufput(C,fh,"%4bu",sum(txtlen)+r) //length of txt plus terminators?
		fbufput(C,fh,"%4bu",0\runningsum(txtlen)[1..r-1]:+(1::r-1)) //txt offsets
		fbufput(C,fh,"%4bs",strtoreal(labtab[,1])) //values /must be sorted
		for (lt=1;lt<=r;lt++) fwrite(fh,labtab[lt,2]+stend) //terminators?
		}
	}

string scalar dataset_dta::write_117() { //>>def member
	map=0
	write_next(map,"<stata_dta")
	write_next(map,"<header")
	write_next(map,"release","%3s","117")
	write_next(map,"byteorder","%3s",("MSF","LSF")[byteorder()])
	write_next(map,"K","%2bu",nvars)
	write_next(map,"N","%4bu",wdata*nobs)
	write_next(map,"label","%1bu+",dtalabel)
	write_next(map,"timestamp","%1bu+",c("current_date")+" "+substr(c("current_time"),1,5)) //needs to be 17 chars
	write_next(map,"header>")
	write_next(map,"map","%112S",102*char(0))
	vts=editmissing(bytes,32768):+(sirtypes:=="r") //probably should change mi for strls
	subs=toindices(sirtypes:!="s")
	vts[subs]=recode(vts[subs],(9,65526\5,65527\4,65528\2,65529\1,65530))
	write_next(map,"variable_types","%2bu",vts)
	write_next(map,"varnames","%33s",vnames)
	write_next(map,"sortlist","%2bu",(sortvars,J(1,nvars-length(sortvars)+1,0)))/**/
	write_next(map,"formats","%49s",formats)
	write_next(map,"value_label_names","%33s",vlabrefs)
	write_next(map,"variable_labels","%81s",nlabels)
	write_next(map,"<characteristics")
	for (c=1;c<=rows(chars);c++) {
		l3=strlen(chars[c,3])
		B=(66+l3+1)*char(0)
		bufput(C,B,0,"%33s",chars[c,1..2])
		bufput(C,B,66,sprintf("%%%fs",l3),chars[c,3])
		write_next(map,"ch","%4bu+",B)
		//		write_next(map,"ch",sprintf("%%%fs+",66+l3),B)
		}
	write_next(map,"characteristics>")
	write_next(map,"<data")
	if (wdata) {
		strls=bytes:>=.
		offsets=runningsum(editmissing(bytes,8))
		w=offsets[nvars]
		offsets=0,cut(offsets,1,-2)
		if (nobs&w) {
			B=nobs*w*char(0) //total mem of data
			bfmts="%":+strofreal(bytes)+subinstr(subinstr(sirtypes,"i","b"),"r","z") //b alone is stata
			for (n=1;n<=nobs;n++) {
				for (k=1;k<=nvars;k++) {
					if (strls[k]) bufput(C,B,(n-1)*w+offsets[k],"%4bu",(k,n):*((*data[k])[n]!=""))
					else bufput(C,B,(n-1)*w+offsets[k],bfmts[k],(*data[k])[n])
					}
				}
			fwrite(fh,B)
			}
		}
	write_next(map,"data>")
	write_next(map,"<strls")
	for (n=1;n<=wdata*nobs;n++) {
		for (k=1;k<=nvars;k++) {
			if (strls[k]) {
				if ((*data[k])[n]!="") {
					fbufput(C,fh,"%3s","GSO")
					fbufput(C,fh,"%4bu",(k,n))
					fbufput(C,fh,"%1bu",129) //?? safer
					fbufput(C,fh,"%4bu",strlen((*data[k])[n]))
					fwrite(fh,(*data[k])[n])
					}
				}
			}
		}
	write_next(map,"strls>")
	write_next(map,"<value_labels")
	for (l=1;l<=length(vlabnames);l++) {
		write_next(map,"<lbl")
		labtab=*vlabtabs[l]
		fbufput(C,fh,"%4bu",8*((r=rows(labtab))+1)+sum(txtlen=strlen(labtab[,2]))+r) //length of label table 
		fbufput(C,fh,"%33s",vlabnames[l])
		fbufput(C,fh,"%3s","") //padding
		fbufput(C,fh,"%4bu",r) //number of entries
		fbufput(C,fh,"%4bu",sum(txtlen)+r) //length of txt plus terminators?
		fbufput(C,fh,"%4bu",0\runningsum(txtlen)[1..r-1]:+(1::r-1)) //txt offsets
		fbufput(C,fh,"%4bs",strtoreal(labtab[,1])) //values /must be sorted
		for (lt=1;lt<=r;lt++) fwrite(fh,labtab[lt,2]+stend) //terminators?
		write_next(map,"lbl>")
		}
	write_next(map,"value_labels>")
	map=map\ftell(fh)
	write_next(map,"stata_dta>")
	map=map\ftell(fh)
	fseek(fh,map[2]+5,-1)
	fbufput8(map)
	return((length(map)!=14)*"Error writing file (map)")
	}

string scalar dataset_dta::write_118() { //>>def member
	map=0
	write_next(map,"<stata_dta")
	write_next(map,"<header")
	write_next(map,"release","%3s","118")
	write_next(map,"byteorder","%3s",("MSF","LSF")[byteorder()])
	write_next(map,"K","%2bu",nvars)
	write_next(map,"N","%8bu",wdata*nobs)
	write_next(map,"label","%2bu+",dtalabel)
	write_next(map,"timestamp","%1bu+",c("current_date")+" "+substr(c("current_time"),1,5)) //needs to be 17 chars
	write_next(map,"header>")
	write_next(map,"map","%112S",102*char(0))
	vts=editmissing(bytes,32768):+(sirtypes:=="r") //probably should change mi for strls
	subs=toindices(sirtypes:!="s")
	vts[subs]=recode(vts[subs],(9,65526\5,65527\4,65528\2,65529\1,65530))
	write_next(map,"variable_types","%2bu",vts)
	write_next(map,"varnames","%129s",vnames)
	write_next(map,"sortlist","%2bu",(sortvars,J(1,nvars-length(sortvars)+1,0)))/**/
	write_next(map,"formats","%57s",formats)
	write_next(map,"value_label_names","%129s",vlabrefs)
	write_next(map,"variable_labels","%321s",nlabels)
	write_next(map,"<characteristics")
	for (c=1;c<=rows(chars);c++) {
		l3=strlen(chars[c,3])
		B=(258+l3+1)*char(0)
		bufput(C,B,0,"%129s",chars[c,1..2])
		bufput(C,B,258,sprintf("%%%fs",l3),chars[c,3])
		write_next(map,"ch","%4bu+",B)
		}
	write_next(map,"characteristics>")
	write_next(map,"<data")
	if (wdata) {
		strls=bytes:>=.
		offsets=runningsum(editmissing(bytes,8))
		w=offsets[nvars]
		offsets=0,cut(offsets,1,-2)
		if (nobs&w) {
			B=nobs*w*char(0) //total mem of data
			bfmts="%":+strofreal(bytes)+subinstr(subinstr(sirtypes,"i","b"),"r","z") //b alone is stata
			for (n=1;n<=nobs;n++) {
				for (k=1;k<=nvars;k++) {
					if (strls[k]) {
						bufput(C,B,(n-1)*w+offsets[k],"%2bu",k*((*data[k])[n]!=""))
						bufput6(B,(n-1)*w+offsets[k]+2,"%6bu",n*((*data[k])[n]!=""))
						}
					else bufput(C,B,(n-1)*w+offsets[k],bfmts[k],(*data[k])[n])
					}
				}
			fwrite(fh,B)
			}
		}
	write_next(map,"data>")
	write_next(map,"<strls")
	for (n=1;n<=wdata*nobs;n++) {
		for (k=1;k<=nvars;k++) {
			if (strls[k]) {
				if ((*data[k])[n]!="") {
					fbufput(C,fh,"%3s","GSO")
					fbufput(C,fh,"%4bu",k)
					fbufput8(n)
					fbufput(C,fh,"%1bu",129) //?? safer
					fbufput(C,fh,"%4bu",strlen((*data[k])[n]))
					fwrite(fh,(*data[k])[n])
					}
				}
			}
		}
	write_next(map,"strls>")
	write_next(map,"<value_labels")
	for (l=1;l<=length(vlabnames);l++) {
		write_next(map,"<lbl")
		labtab=*vlabtabs[l]
		fbufput(C,fh,"%4bu",8*((r=rows(labtab))+1)+sum(txtlen=strlen(labtab[,2]))+r) //length of label table 
		fbufput(C,fh,"%129s",vlabnames[l])
		fbufput(C,fh,"%3s","") //padding
		fbufput(C,fh,"%4bu",r) //number of entries
		fbufput(C,fh,"%4bu",sum(txtlen)+r) //length of txt plus terminators?
		fbufput(C,fh,"%4bu",0\runningsum(txtlen)[1..r-1]:+(1::r-1)) //txt offsets
		fbufput(C,fh,"%4bs",strtoreal(labtab[,1])) //values /must be sorted
		for (lt=1;lt<=r;lt++) fwrite(fh,labtab[lt,2]+stend) //terminators?
		write_next(map,"lbl>")
		}
	write_next(map,"value_labels>")
	map=map\ftell(fh)
	write_next(map,"stata_dta>")
	map=map\ftell(fh)
	fseek(fh,map[2]+5,-1)
	fbufput8(map)
	return((length(map)!=14)*"Error writing file (map)")
	}

matrix dataset_dta::read_next(string scalar mark,| string scalar format, real scalar count) { //>>def member
	if (substr(mark,1,1)=="?") {
		fmark=fbufget(C,fh,sprintf("%%%fS",strlen(mark)+1))
		if (fmark=="<"+substr(mark,2)+">") return(1)
		fseek(fh,-strlen(mark)-1,0)
		return(0)
		}
	if (open=substr(mark,1,1)=="<") mark=substr(mark,2)
	if (close=substr(mark,-1)==">") mark=substr(mark,1,strlen(mark)-1)
	if (!close) {
		fmark=fbufget(C,fh,sprintf("%%%fS",strlen(mark)+2))
		if (fmark!="<"+mark+">") errel(sprintf("dta file read error: found %s instead of <%s>",fmark,mark))
		}
	if (truish(format)) {
		if (count==0) content=strlower(substr(format,3,1))=="s"?J(1,0,""):J(1,0,.)
		else if (format=="%8bu") content=fbufget8(count)
		else if (truish(count)) content=fbufget(C,fh,format,count)
		else content=fbufget(C,fh,format)
		}
	//if (truish(format)) content=truish(count)?fbufget(C,fh,format,count):fbufget(C,fh,format)
	if (!open) {
		fmark=fbufget(C,fh,sprintf("%%%fS",strlen(mark)+3))
		if (fmark!="</"+mark+">") errel(sprintf("dta file read error: found %s instead of </%s>",fmark,mark))
		}
	return(content)
	}

void dataset_dta::write_next(real colvector map, string scalar mark,| string scalar format, matrix data) { //>>def member
	if (any(subinstr(subinstr(mark,"<",""),"<",""):==("map", "variable_types", "varnames", "sortlist", "formats", "value_label_names", "variable_labels", "characteristics", "data", "strls", "value_labels"))) map=map\ftell(fh)
	if (!strpos(mark,">")) fwrite(fh,subinstr("<"+mark+">","<<","<"))
	if (length(data)) {
		if (format=="%8bu") fbufput8(data)
		else if (!strpos(format,"+")) fbufput(C,fh,format,data)
		else {
			len=strlen(data)
			fbufput(C,fh,subinstr(format,"+",""),len)
			fbufput(C,fh,sprintf("%%%fS",len),data) //was lower s...
			}
		}
	if (!strpos(mark,"<")) fwrite(fh,subinstr("</"+mark+">",">>",">"))
	}

void dataset_dta::fbufput8(real colvector num) { //>>def member
	bo=("hilo","lohi")[bufbyteorder(C)]
	corder=bo=="hilo"?(1,2):(2,1)
	twoby4=J(length(num),2,.)
	twoby4[,corder[1]]=trunc(num/2^32)
	twoby4[,corder[2]]=num:-twoby4[,corder[1]]:*2^32
	fbufput(C,fh,"%4bu",twoby4)
	}

real vector dataset_dta::fbufget8(real scalar len) { //>>def member
	bo=("hilo","lohi")[bufbyteorder(C)]
	corder=bo=="hilo"?(1,2):(2,1)
	len=firstof(1\len)
	twoby4=fbufget(C,fh,"%4bu",len,2)
	eight=twoby4[,corder[1]]:*2^32:+twoby4[,corder[2]]
	return(eight)
	}

void dataset_dta::bufput6(string scalar B, real scalar offset, real scalar num) { //>>def member
	D=bufio()
	bufbyteorder(D,1)
	hi2=trunc(num/2^32)
	low4=num:-hi2*2^32
	six=6*char(0)
	bufput(D,six,0,"%2bu",hi2)
	bufput(D,six,2,"%4bu",low4)
	if (bufbyteorder(C)==2) six=strreverse(six)
	bufput(D,B,offset,"%6S",six)
	}

real scalar dataset_dta::bufget6(string scalar B, real scalar offset) { //>>def member
	D=bufio()
	bufbyteorder(D,1)
	six=bufget(D,B,offset,"%6S")
	if (bufbyteorder(C)==2) six=strreverse(six)
	twobits=bufget(D,2*char(0)+six,0,"%4bu",2)
	num=twobits[1]*2^32+twobits[2]
	return(num)
	}

end
//>>mosave
*! 3mar2016
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:


void elfs_callst::new() { //>>def member<<
	base=
	"read-sas-fmts","N","Read user formats from a SAS datafile (Y/N)"\
	"cat-absence-ok","Y","continue if no format file"\
	"read-fmt-name","%ipath%/formats.sas7bcat","Name of SAS format datafile"\
	"write-sas-fmts","Y","Write Proc Format program for SAS (Y/N)"\
	"write-fmt-name","%opath%\%oname%.sas","Filename for Proc Format program"\
	"delimiter-wr","tab","Delimiter - ASCII write (autosense,comma,tab,space,semicolon)"\
	"wks-blank-rows","skip","On Worksheet Blank Rows (stop,skip,use)"\
	"var-case-cs","lower",""
	head="name","value","description"
	ename="callst"
	getix=1
	init()
	}

void elfs_callst::list() { //>>def member<<
	class tabel scalar t
	
	t.body=expand(expand(base\elf,-4),5)
	t.body[1,1]="Built-in"
	if (truish(elf)) t.body[rows(base)+1,1]="User"
	
	pref="stata elfs "+ename+", "
	t.body[,5]=t.setLinks("stata",adorn(pref+"del(",t.body[,2],")"),"Delete":*((1::rows(t.body)):>rows(base)))
	t.body="Source",strproper(head),""\t.body
	
	t.head=1
	t.stub=1
	t.set(t._align,.,.,t.left)
	t.set(t._class,2..rows(base)+1,.,"weaker")
	t.set(t._hline,rows(base)+1,.,t.Lminor)
	t.set(t._hline,rows(t.body),.,t.Lmajor)
	t.set(t._vline,.,cols(t.body)-1,t.Lmajor)
	t.present("")
	printf(`"{txt:elfs callst:} {stata "elfs callst, edit":Edit All}\n"')
	printf("{txt:StatTransfer path is:} ")
	printf(`"{stata "elfs callst, setpath":%s}\n"',truish(anci)?anci:"{it:empty}")
	}

void elfs_callst::obutton(string vector opts) { //>>def member
	if (opts=="setpath") {
		stata(`"capture window fopen stpath "Where is StatTransfer?" "StatTransfer|st.exe""')
		anci=st_global("stpath")
		write()
		}
	list()
	}

string matrix elfs_callst::notfound(|matrix ignore) { //>>def member
	//not sure this is a wise use...
	return(concat(uelf()[,1..2],char(9),"r"))
	}

end
//>>mosave<<
*! 19dec2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:
end
 global colors (`" !"#%&(r1!txt!0!255!0!0!0"r1!res!0!255!255!0!0"r1!err!255!0!0!0!0"r1!inp!255!255!255!0!0"r1!hi!255!255!0!0!0"r1!link!255!128!64!0!0"r1!bg!0!0!0!0!0"r2!txt!128!0!255!0!0"r2!res!0!255!255!0!0"r2!err!255!0!0!0!0"r2!inp!255!255!255!0!0"r2!hi!255!255!0!0!0"r2!link!255!128!64!0!0"r2!bg!0!0!0!0!0"r3!txt!255!0!128!0!0"r3!res!0!255!255!0!0"r3!err!255!0!0!0!0"r3!inp!255!255!255!0!0"r3!hi!255!255!0!0!0"r3!link!255!128!64!0!0"r3!bg!0!0!0!0!0"v1!txt!0!0!0!0!0"v1!res!0!128!128!0!0"v1!err!255!0!0!1!0"v1!inp!0!0!255!0!0"v1!hi!64!192!0!0!0"v1!link!255!128!64!0!0"v1!bg!255!255!255!0!0"v2!txt!0!0!0!0!0"v2!res!0!128!128!0!0"v2!err!255!0!0!1!0"v2!inp!0!0!255!0!0"v2!hi!64!192!0!0!0"v2!link!255!128!64!0!0"v2!bg!235!255!235!0!0"v3!txt!0!0!0!0!0"v3!res!0!128!128!0!0"v3!err!255!0!0!1!0"v3!inp!0!0!255!0!0"v3!hi!64!192!0!0!0"v3!link!255!128!64!0!0"v3!bg!255!235!235!0!0"')
 mata:
end
 global stcolors (`" !"#%&(standard!txt!0!0!0!0!0!0"standard!res!0!0!0!bf!0!0"standard!err!255!0!0!0!0!0"standard!inp!0!0!0!bf!0!0"standard!hi!0!0!0!bf!0!0"standard!link!0!0!255!0!0!0"standard!bg!255!255!255!0!0!0"studio!txt!0!0!0!0!0!1"studio!res!0!0!160!0!0!1"studio!err!255!0!0!0!0!1"studio!inp!0!0!0!bf!0!1"studio!hi!0!0!0!bf!0!1"studio!link!0!0!255!0!ul!1"studio!bg!255!255!255!0!0!1"classic!txt!0!255!0!0!0!2"classic!res!255!255!0!0!0!2"classic!err!255!0!0!0!0!2"classic!inp!255!255!255!0!0!2"classic!hi!255!255!255!bf!0!2"classic!link!0!255!255!0!0!2"classic!bg!0!0!0!0!0!2"desert!txt!0!0!0!0!0!3"desert!res!128!0!0!0!0!3"desert!err!255!0!0!0!0!3"desert!inp!0!0!0!bf!0!3"desert!hi!0!0!0!bf!0!3"desert!link!0!0!255!0!0!3"desert!bg!255!255!251!0!0!3"mountain!txt!0!0!0!0!0!4"mountain!res!0!80!0!0!0!4"mountain!err!255!0!0!0!0!4"mountain!inp!0!0!0!bf!0!4"mountain!hi!0!0!0!bf!0!4"mountain!link!0!0!255!0!0!4"mountain!bg!255!255!255!0!0!4"ocean!txt!0!0!0!0!0!5"ocean!res!48!80!80!0!0!5"ocean!err!255!0!0!0!0!5"ocean!inp!0!0!0!bf!0!5"ocean!hi!0!0!0!bf!0!5"ocean!link!0!0!255!0!0!5"ocean!bg!239!247!255!0!0!5"simple!txt!64!64!64!0!0!6"simple!res!0!0!0!0!0!6"simple!err!255!0!0!0!0!6"simple!inp!0!0!0!bf!0!6"simple!hi!0!0!0!bf!0!6"simple!link!0!0!255!0!0!6"simple!bg!255!255!255!0!0!6"')
 mata:
end
 global colorsvbs (`"#%*-/45Const HKCU = &H80000001-strComputer = "."-Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & _ -strComputer & "\root\default:StdRegProv")-Set FSO = CreateObject("Scripting.FileSystemObject")-Set regres=FSO.CreateTextFile("colorsget.txt")--Sub getem(strKeyPath,subkey)-wtypes=Array("\Results","\Viewer")-tsubs=Array("_1","_2","_3")-pens=Array("blue","bold","green","red","ul")-For Each wtype in wtypes-oReg.GetStringValue HKCU, strKeyPath+subkey+wtype+"\Facename", "",v1-oReg.GetStringValue HKCU, strKeyPath+subkey+wtype+"\schemetype", "",v2-regres.Writeline (subkey+";"+wtype+";_0;"+v1+";"+v2)-For Each ts in tsubs-For Each pen in pens-oReg.GetStringValue HKCU, strKeyPath+subkey+wtype+ts+"\pen_"+pen, "",v1-regres.Writeline (subkey+";"+wtype+";"+ts+";"+pen+";"+v1)-Next-Next-Next-End Sub--strKeyPath = "Software\Stata\StataVERS\MultipleWInPrefs\"-oReg.EnumKey HKCU, strKeyPath, arrSubKeys-For Each subkey In arrSubKeys-getem strKeyPath, subkey-Next"')
 mata:


void elfs_colors::new() { //>>def member<<
	ename="colors"
	base=strob_to($stcolors)[,1..7]
	builtins=dedup(base[,1])
	base=strob_to($colors)\base
	head="scheme","tstyle","red","green","blue","bold","ul"
	getix=2
	mapix=2
	anci=&.,&.,&"off"
	curR=1;curV=2;warnix=3
	cache="ccolors_el"
	}

void elfs_colors::list() { //>>def member<<
	class htmlpgs scalar hp
	class tabel scalar t
	
	fonts=current()
	hp.page()
	hp.addcss("body {background-color:#EEEEEE} p.p1 {border-bottom:1px solid; margin:1em; margin-bottom:0;padding-right:1em} p.p2 {border-left:1px solid; margin: 1em;margin-top:0;padding-left: 1em;padding-right:2em} td.ctype {font-size:1.33em} td.cnote {align:center;color:red}")
	ttype=("text","result","error","input","hilite","link")
	elrows=truish(vmap(base[,1],builtins,"not"))
	for (tt=1;tt<=4;tt++) {
		hp.place(sprintf("<hr><table><tr><td class='ctype'>%s Colors</td></tr><tr>",("Current","User","EL","Stata")[tt]))
		if (tt==1) prefs=pad(("Results"),*anci[curR],",")\pad(("Viewer"),*anci[curV],",")
		else if (tt==2) prefs=elf
		else if (tt==3) prefs=cut(base',1,elrows)'
		else if (tt==4) prefs=cut(base',elrows+1)'
		i=1
		while (i<=rows(prefs)) {
			sname=prefs[i,1]
			if (tt==1) font=adorn("font-family:",lookupin(fonts,(i==1)+2*(i==8)))
			else font=""
			hp.addcss(sprintf(".%s {color:#%s; background-color:#%s; %s} ", sname,concat(tohexff(prefs[i,3..5]),""),concat(tohexff(prefs[i+6,3..5]),""),font))
			hp.place(sprintf("<td class='%s'><p class='p1'>%s</p><p class='p2'>",sname,sname))
			for (j=1;j<=6;j++) {
				hp.addcss("."+sname+prefs[i,2]+" {color:#"+tohexff(prefs[i,3])+tohexff(prefs[i,4])+tohexff(prefs[i,5])+";"+ (strtoreal(prefs[i,6])?"font-weight:bold;":"")+ (strtoreal(prefs[i,7])?"text-decoration:underline} ":"} "))
				hp.place(sprintf("<span class='%s%s'>%s</span><br />",sname,prefs[i++,2],ttype[j]))
				}
			hp.place("</td>")
			i=i+1
			}
		if (tt==1) {
			cn1=uniqs(cut(*anci[1],2),"dups")?"Colors are not all distinct":""
			cn2=uniqs(cut(*anci[2],2),"dups")?"Colors are not all distinct":""
			hp.place(sprintf("</tr><tr><td class='cnote'>%s</td><td class='cnote'>%s</td>",cn1,cn2))
			}
		hp.place("</tr></table>")
		}
	hp.write("",path=pathto("colors.html"))
	launchfile(path)
	
	t.body=dedup(base[,1])
	rb=rows(t.body)+1
	t.body=t.body\dedup(elf[,1])
	t.body=expand(expand(t.body,4),-5)
	t.body[1,1]="Built-in"
	if (truish(elf)) t.body[rb,1]="User"
	
	pref="stata elfs "+ename+", "
	t.body[,3]=t.setLinks("stata",adorn(pref+"set(R,",t.body[,2],")"),J(rows(t.body),1,"Use for Results"))
	t.body[,4]=t.setLinks("stata",adorn(pref+"set(V,",t.body[,2],")"),J(rows(t.body),1,"Use for Viewer"))
	t.body[,5]=t.setLinks("stata",adorn(pref+"del(",t.body[,2],")"), "Delete":*tru2(t.body[,2]):*((1::rows(t.body)):>=rb))
	t.body="Source","Scheme","","",""\t.body
	t.head=1
	t.stub=1
	t.set(t._align,.,.,t.left)
	t.set(t._class,2..rows(base)+1,.,"weaker")
	t.set(t._hline,rb,.,t.Lminor)
	t.set(t._vline,.,(2,3,4),t.Lminor)
	t.set(t._hline,rows(t.body),.,t.Lmajor)
	t.present("-")
	printf(`"{txt:elfs Colors:} {stata "elfs colors, edit":Edit All}\n"')
	printf(`"{stata "elfs colors, add(R)":Save Current Results} {txt:to elf}\n"')
	printf(`"{stata "elfs colors, add(V)":Save Current Viewer} {txt:to elf}\n"')
	warns=*anci[warnix]=="off"?("off","on"):("on","off")
	printf(`"{txt:Color Warning is {res:%s}.} {stata "elfs colors, warn(%s)":Set to %s}\n"',warns[1],warns[2],warns[2])
	}

void elfs_colors::obutton(string vector opts) { //>>def member
	optionel(opts,(&(warn="warn="),&(setc="set="),&(add="add=")))
	
	if (truish(setc)) {
		setc=tokel(setc,",")
		which=ocanon("Colors set",setc[1],("R:esults","V:iewer"),"max")
		whichn=toindices(which:==("Results","Viewer"))
		init()
		*anci[whichn]=get(setc[2])
		
		cset=colorsx(*anci[whichn])
		pens=cset[,1]
		cset=concat(cut(cset,2),",")
		vers=strofreal(c("stata_version"),"%2.0f")
		s1="HKCU\Software\Stata\Stata"+vers+"\MultipleWinPrefs\__i0\"+which
		sput(vb="","Dim wsh")
		sput(vb,`"set wsh=wscript.createobject("wscript.shell")"')
		sput(vb,sprintf(`"wsh.RegWrite "%s\schemetype\","9""',s1))
		for (p=1;p<=5;p++) {
			sput(vb,sprintf(`"wsh.RegWrite "%s_3\pen_%s\","%s""',s1,pens[p],cset[p]))
			}
		fowrite(path=pathto("_colorset.vbs","inst"),vb)
		
		stata(`"window man prefs save "__i0""') //woudn't expect concurrent use, but all instances would be saving here...
		launchfile(path,"w")
		stata("window man close viewer _all") //bug; shouldn't be necessary
		stata(`"window man prefs load "__i0""')
		
		write()
		}
	else if(truish(add)) {
		if (add=="V") {
			toadd=curV
			scheme="Current Viewer"
			}
		else {
			toadd=curR
			scheme="Current Results"
			}
		elf=elf\J(rows(*anci[toadd]),1,scheme),*anci[toadd]
		write()
		}
	else if (truish(warn)) {
		*anci[warnix]=warn
		write()
		}
	list()
	}

string vector elfs_colors::current() { //>>def member
	init()
	
	//anci=&.,&.,&"off"
	stata(`"window man prefs save "__i0""') //figure out how to delete this... &deal with the name
	vers="Stata"+strofreal(c("stata_version"),"%2.0f")
	localized=strob_to($colorsvbs)
	localized=subinstr(localized,"StataVERS",vers)
	localized=subinstr(localized,"colorsget.txt",cget=pathto("_colorsget.txt"))
	fowrite(vbpath=pathto("_colorsget.vbs","inst"),localized)
	unlink(cget)
	wrtime=datetime(".")
	launchfile(vbpath)
	while (datetime(".")-wrtime<1500) {
		//wait
		}
	info=columnize(cat(cget),";")
	info=select(info[,2..5],info[,1]:=="__i0") //results 0,1..3x5; viewer 0,1..3x5
	skixs=strtoreal(substr(info[,2],2)):+4:*(info[,1]:=="\Viewer")
	//face=1,3; 17,3
	skn=strtoreal(info[1,4])+1
	if (skn<=7) *anci[curR]=select(cut(base,2),base[,1]:==builtins[skn])
	else *anci[curR]=colorsx(select(info[,3..4],skixs:==skn-7))
	skn=strtoreal(info[17,4])+1
	if (skn<=7) *anci[curV]=select(cut(base,2),base[,1]:==builtins[skn])
	else *anci[curV]=colorsx(select(info[,3..4],skixs:==skn-3))
	
	rmexternal(cache) //in case of reach
	mem=crexternal(cache)
	*mem=anci
	write()
	return(info[(1,17),3])
	}

string matrix elfs_colors::colorsx(string matrix in) { //>>def member
	stubel=("txt"\"res"\"err"\"inp"\"hi"\"link"\"background")
	stubst=("blue"\"bold"\"green"\"red"\"ul") //cols=bg,res,txt,??,err,inp,link,hi
	unknown=("255"\"0"\"255"\"0"\"0") //unknown column ins stata color regs
	if (in[,1]==stubst) {
		a=stubel,columnize(cut(in,2),",")[(4,3,1,2,5),(3,2,5,6,8,7,1)]'
		a[,5]=subinstr(a[,5],"1","bf")
		a[,6]=subinstr(a[,6],"1","ul")
		return(a)
		}
	else {
		a=cut(in,2)[(7,2,1,3,4,6,5),(3,4,2,1,5)]'
		a=subinstr(subinstr(a,"bf","1"),"ul","1")
		a=stubst,a[,(1..3)],unknown,a[,(4..7)]
		return(a)
		}
	}

string scalar elfs_colors::colornote(real scalar viewer, string vector used) { //>>def member
	if (c("os")!="Windows") return("")
	mem=findexternal(cache) //get from memory, if possible
	wind=1+viewer
	if (truish(mem)) anci=*mem
	else {
		init()
		if (!truish(*anci[wind])) (void) current()
		}
	if (*anci[warnix]=="off") return("")
	
	cused=(*anci[wind])[vmap((*anci[wind])[,1],used,"in"),2..4]
	if (uniqs(cused,"dups")) {
	//if (rows(uniqrows(cused))<rows(cused)) {
		return(sprintf("{txt}You do not appear to have distinct colors for %s, as used in the prior output.\nSee {help elfs colors}\n",concat("{":+used:+":this}"," and ")))
		}
	return("")
	}

end
//>>mosave<<

*! 3mar2016
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:
end
 global facts (`"!#&*+,/StataDataFile#.dta#StataData.ico#usel#Stata Dataset&StataFoDataFile#.sas7bdat .sav#StataFoData.ico#usel#Stata Foreign Data&StataReportFile#.dtar#StataReport.ico#usel#Stata Report Data&StataMoFile#.mo#StataMo.ico#!#Stata Mo&StataMlibFile#.mlib#StataMlib.ico#!#Stata Mlib&StataLmatFile#.lmat .lmat2#StataLmat.ico#!#Stata Lmat&jEditFile#.do .ado .mata .txt .sthlp#jfile.ico#""C:\Program Files (x86)\Java\jre1.8.0_65\bin\javaw.exe"" -jar ""C:\Programs2\jEdit51\jedit.jar"" -reuseview ""%1""#jEdit File"')
 mata:
end
 global uselvbs (`"!#&*,-/set shell = WScript.createObject("WScript.Shell")*a= shell.AppActivate("%s")*wscript.sleep 100*shell.sendkeys "{TAB}usel "+Wscript.Arguments.Item(0)+"{ENTER}""')
 mata:


void elfs_facts::new() { //>>def member<<
	base=strob_to($facts)
	head="name","extension","icon","open","desc"
	ename="facts"
	getix=1
	init()
	}

void elfs_facts::list() { //>>
	class tabel scalar t
	
	t.body=expand(expand(base\elf,-6),8)
	t.body[1,1]="Built-in"
	if (truish(elf)) t.body[rows(base)+1,1]="User"
	
	pref="stata elfs "+ename+", "
	t.body[,7]=t.setLinks("stata",adorn(pref+"set(",t.body[,2],")"),J(rows(t.body),1,"Set"))
	t.body[,8]=t.setLinks("stata",adorn(pref+"del(",t.body[,2],")"),"Delete":*((1::rows(t.body)):>rows(base)))
	t.body="Source",strproper(head),"",""\t.body
	
	t.head=1
	t.stub=1
	t.set(t._align,.,.,t.left)
	t.set(t._class,2..rows(base)+1,.,"weaker")
	t.set(t._hline,rows(base)+1,.,t.Lminor)
	t.set(t._hline,rows(t.body),.,t.Lmajor)
	t.set(t._vline,.,cols(t.body)-2,t.Lmajor)
	t.present("")
	printf(`"{txt:elfs misc:} {stata "elfs facts, edit":Edit All}"')
	}

void elfs_facts::obutton(string vector opts) { //>>def member
	class elfs_misc scalar elf
	
	ext=2;icon=3;open=4;desc=5
	optionel(opts,&(set="set="))
	if (truish(set)) {
		onef=get(set)
		
		sput(s="","Dim WshShell")
		sput(s,`"Set WshShell = WScript.CreateObject("WScript.Shell")"')
		sput(s,sprintf(`"WshShell. RegWrite "HKCU\Software\Classes\%s\","%s""',onef[1],onef[desc]))
		if (truish(onef[icon])) sput(s,sprintf(`"WshShell. RegWrite "HKCU\Software\Classes\%s\DefaultIcon\", "%s","REG_EXPAND_SZ""',onef[1],findfile(onef[icon])))
		if (onef[open]=="usel") {
			fowrite(uselpath=pathto("usel.vbs"),sprintf(strob_to($uselvbs),elf.get("Stata appID")))
			sput(s,sprintf(`"WshShell. RegWrite "HKCU\Software\Classes\%s\Shell\Open\Command\", "wscript.exe ""%s"" ""%%1"" ","REG_EXPAND_SZ""',onef[1],uselpath))
			}
		else if (truish(onef[open])) {
			sput(s,sprintf(`"WshShell. RegWrite "HKCU\Software\Classes\%s\Shell\Open\Command\", "%s","REG_EXPAND_SZ""',onef[1],onef[open]))
			}
		exts=tokel(onef[ext])
		for (e=1;e<=length(exts);e++) {
			sput(s,sprintf(`"WshShell. RegWrite "HKCU\Software\Classes\%s\", "%s""',exts[e],onef[1]))
			}
		fowrite(regset=pathto("stata reg settings.vbs"),s)
		launchfile(regset)
		}
	list()
	}

end
//>>mosave

*! 3mar2016
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:


void elfs_grail::new() { //>>def member<<
	base="Stata appID","."\"wformat","%i %f%e?%c"\"fromEditor path",char(96)+":environment USERPROFILE'/appdata/roaming/jedit/stata/doit.do"\"dobreak","*---"
	head="name","setting"
	ename="misc"
	getix=2
	init()
	}

void elfs_grail::list() { //>>def member<<
	class tabel scalar t
	
	t.body=expand(expand(base\elf,3),-4)
	t.body[1,1]="Built-in"
	if (truish(elf)) t.body[rows(base)+1,1]="User"
	
	pref="stata elfs "+ename+", "
	t.body[,4]=t.setLinks("stata",adorn(pref+"del(",t.body[,2],")"),"Delete":*((1::rows(t.body)):>rows(base)))
	t.body="",strproper(head),""\t.body
	
	t.head=1
	t.stub=1
	t.set(t._align,.,.,t.left)
	t.set(t._class,2..rows(base)+1,.,"weaker")
	t.set(t._hline,rows(base)+1,.,t.Lminor)
	t.set(t._hline,rows(t.body),.,t.Lmajor)
	t.set(t._vline,.,cols(t.body)-1,t.Lmajor)
	t.present("")
	printf(`"{txt:elfs misc:} {stata "elfs misc, edit":Edit All}"')
	}

void elfs_grail::obutton(string vector opts) { //>>def member
	class dataset_dta scalar ds
	optionel(opts,&(read="read=*"))
	
	if (truish(read)) {
		//syntaxl(st_local("0"),&(path="using"))
		if (!truish(path)) grail=sctomat(charget("_dta","el_grail"))
		else {
			ds.with("c")
			ds.readfile(pcanon(path))
			grail=select(ds.chars[,3],ds.chars[,1]:=="_dta":&ds.chars[,2]:=="el_grail")
			if (length(grail)) grail=sctomat(grail)
			}
		
		if (length(grail)!=4) {
			printf("{txt:No fromEditor info found}\n")
			return
			}
		grail[,1]=adorn(">>",grail[,1],"<<")
		grail=concat(concat(grail,eol()),eol(2))
		fowrite(path=pathto("grailinfo.do","i"),grail)
		launchfile(path)
		return
		}
	list()
	}

end
//>>mosave<<
*! 22nov2013 --as instancereg
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:
end
 global iscript (`"#%&/015Set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2")/Set colProcess = objWMIService.ExecQuery ("Select * from Win32_Process where Name=1StataMP-64.exe1")/Set objIfile = CreateObject("Scripting.FileSystemObject").CreateTextFile("instances.txt",true,false)/For Each objProcess in colProcess/objProcess.GetOwner uname, udomain/if uname <> "" then/objIfile.WriteLine(Cstr(objProcess.ProcessID)+","+Cstr(objProcess.CreationDate))/end if/Next"')
 mata:


void elfs_instance::new() { //>>def member<<
	base="1","1","instance_1"\"2","2","instance_2"\"3","3","instance_3"
	head="precedence","id","prefence set name"
	ename="instance"
	getix=2
	init()
	}

void elfs_instance::list() { //>>def member<<
	class tabel scalar t
	
	t.body=expand(expand(base\elf,-4),5)
	t.body[1,1]="Built-in"
	if (truish(elf)) t.body[rows(base)+1,1]="User"
	
	pref="stata elfs "+ename+", "
	t.body[,5]=t.setLinks("stata",adorn(pref+"del(",t.body[,2],")"),"Delete":*((1::rows(t.body)):>rows(base)))
	t.body="",strproper(head),""\t.body
	
	t.head=1
	t.stub=1
	t.set(t._align,.,.,t.left)
	t.set(t._class,2..rows(base)+1,.,"weaker")
	t.set(t._hline,rows(base)+1,.,t.Lminor)
	t.set(t._hline,rows(t.body),.,t.Lmajor)
	t.set(t._vline,.,cols(t.body)-1,t.Lmajor)
	t.present("")
	printf(`"{txt:elfs instance:} {stata "elfs instance, edit":Edit All}"')
	}

void elfs_instance::obutton(string vector opts) { //>>def member
	optionel(opts,(&(iset="set"),&(iget="get")))
	if (iset|iget) {
		class tabel scalar t
		class recentle_data scalar rld
		
		if (c("mode")=="batch") return
		
		iscript=subinstr(subinstr(strob_to($iscript),"instances.txt",itxt=pathto("instances.txt")),"Stata.exe",stataexe())
		//unlink(pathof("instances.txt")) //maybe deleting old ones will help?
		fowrite(cpath=pathto("instances.vbs"),iscript)
		launchfile(cpath,"wait direct") //mf isn't waiting/reading
		//stata("shell "+cpath)
		inow=cat(itxt)
		regpath=pathto("instancereg.txt")
		
		if (iget) {
			if (fexists(regpath)) reg=sctomat(ftostr(regpath))
			else reg=J(0,2,"")
			imap=vmap(inow,reg[,2])
			regd=recode(lookupin(reg[,1],imap),("","?unknown?"))
			t.body="Instances"\regd
			t.head=1
			t.set(t._hline,rows(t.body),.,t.Lmajor)
			t.present("-")
			if (toindices((iid=st_global("EL_INST")):==regd[,1],"z")) printf("{txt:This is instance} {res:%s}.",iid)
			else if (truish(iid)) printf("{txt:This instance is not registered, but is somehow named} {res:%s}.",iid)
			else printf("{txt:This instance is not registered.}")
			}
		else if (iset) {
			if (length(inow)==1) {
				iid=get("1")
				reg=iid[1],inow
				}
			else {
				if (fexists(regpath)) reg=sctomat(ftostr(regpath))
				else reg=J(0,2,"")
				
				if (truish(oldid=st_global("EL_INST"))) errel(sprintf("This instance already has an id (%s).",oldid))
				imap=vmap(inow,reg[,2])
				if (sum(!imap)>1) errel("Instances must be registered starting from the first one...")
				if (!sum(!imap)) errel("There don't seem to be any unregistered instances...")
				
				reg=reg[vmap(reg[,2],inow,"in"),]
				uelf=uelf()
				idmap=vmap(uelf[,2],reg[,1],"not")
				if (!length(idmap))  errel("All defined instances are in use.")
				iid=uelf[idmap[1],2..3]
				reg=reg\iid[1],select(inow,!imap)
				}
			
			fowrite(regpath,scofmat(reg))
			st_global("EL_INST",iid[1])
			rld.ncmd="ireg"
			rld.get()
			rld.add()
			if (truish(iid[2])) stata("window man prefs load "+iid[2])
			printf("{txt:This is instance }{res:%s}\n",st_global("EL_INST"))
			}
		return
		}
	list()
	}
end

//>>mosave

*! 3mar2016
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:


void elfs_misc::new() { //>>def member<<
	base="Stata appID","."\"wformat","%i %f%e?%c"\"fromEditor path",char(96)+":environment USERPROFILE'/appdata/roaming/jedit/stata/doit.do"\"dobreak","*---"
	head="name","setting"
	ename="misc"
	getix=2
	init()
	}

void elfs_misc::list() { //>>def member<<
	class tabel scalar t
	
	t.body=expand(expand(base\elf,3),-4)
	t.body[1,1]="Built-in"
	if (truish(elf)) t.body[rows(base)+1,1]="User"
	
	pref="stata elfs "+ename+", "
	t.body[,4]=t.setLinks("stata",adorn(pref+"del(",t.body[,2],")"),"Delete":*((1::rows(t.body)):>rows(base)))
	t.body="",strproper(head),""\t.body
	
	t.head=1
	t.stub=1
	t.set(t._align,.,.,t.left)
	t.set(t._class,2..rows(base)+1,.,"weaker")
	t.set(t._hline,rows(base)+1,.,t.Lminor)
	t.set(t._hline,rows(t.body),.,t.Lmajor)
	t.set(t._vline,.,cols(t.body)-1,t.Lmajor)
	t.present("")
	printf(`"{txt:elfs misc:} {stata "elfs misc, edit":Edit All}"')
	}

end
//>>mosave<<
*! 19dec2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:
end
 global outstata (`" !"#%&(st!heading!tstyle:txt"st!body!tstyle:res"st!hi1!tstyle:inp"st!hi2!tstyle:hi"st!himk!plusface:bf"st!weaker!tstyle:txt"st!other!tstyle:inp"st!err!tstyle:err"st!bf!plusface:bf"st!it!plusface:it"st!ul!text-decoration:ul"st!alt!plusface:it"st!line!tstyle:txt"st!nottext!tsytle:res"')
 mata:
end
 global outhtml (`"!"%&()*ht".tbase"font-family: trebuchet ms, sans-serif ; font-size: small; border-collapse: collapse; border-left: solid;border-right:solid;border-bottom:solid; border-width: 1px;  border-color:#AACCDD%ht".body"padding-left: .75em; padding-right: .75em; vertical-align: top; text-align: right;%ht".alignl"text-align: left%ht".alignc"text-align: center%ht".alignr"text-align: right%ht".hsp"padding-bottom: 1em%ht".hminor"border-bottom: solid; border-bottom-width: 1px; border-bottom-color:  #BBDDEE%ht".hmajor"border-bottom: solid; border-bottom-width: 2px; border-bottom-color:#AACCDD%ht".vminor"border-right: solid; border-right-width: 1px; border-right-color:  #BBDDEE%ht".vmajor"border-right: solid; border-right-width: 2px; border-right-color:#AACCDD%ht".unpadL"padding-left: 0%ht".unpadR"padding-right: 0%ht".altback"background-color: #F4FAFF%ht".heading"font-weight: bold%ht".hi1"background-color:yellow%ht".hi2"color: white;background-color:#7799AA%ht".himk"color:dodgerblue%ht".weaker"color: #888888%ht".other"color: #2222EE%ht".err"color:red; font-weight:bold%ht".bf"font-weight: bold%ht".it"font-style: italic%ht".ul"text-decoration: underline%ht".link"text-decoration: none; color: inherit; background-color: #BBFFBB%ht".link:hover"background-color: #FFAA00%ht".nottext"color:#AACCDD"')
 mata:
end
 global outemail (`"!"%&()*hy"ground"background-color:white;font-family:COnsolas,Lucida Sans Typewriter, monospace;font-size: small%hy"heading"color:black;font-weight: bold%hy"body"color:black%hy"hi1"background-color:yellow%hy"hi2"color:red%hy"himk"color:dodgerblue%hy"weaker"color:#888888%hy"other"color:#2222EE%hy"err"color:red; font-weight:bold%hy"bf"font-weight:bold%hy"it"font-style:italic%hy"ul"text-decoration:underline%hy"alt"font-style: italic%hy"link"color:#FF8040%hy"Lminor"color:#AACCDD%hy"Lmajor"color:#BBDDEE%hy"nottext"color:#AACCDD"')
 mata:
//note for hyb, & users: some fonts (Lucida Console) don't maintain spacing with bold
//note for html, self: need to add a link style!!


void elfs_out::new() { //>>def member
	mstata=1
	mhtml=2
	memail=3
	head="scheme","class","attributes"
	getix=2
	mapix=2
	}

void elfs_out::init(real scalar mode) { //>>def member<<
	if (mode==mstata) {
		base=strob_to($outstata)
		ename="outstata"
		}
	else if (mode==mhtml) {
		base=strob_to($outhtml)
		ename="outhtml"
		}
	else if (mode==memail) {
		base=strob_to($outemail)
		ename="outemail"
		}
	else errel("Unknown elfs out mode")
	super.init()
	}

void elfs_out::list() { //>>def member<<
	class tabel scalar t
	
	rb=rows(base)+1
	t.body=expand(expand(base\elf,5),-6)
	t.body[1,1]="Built-in"
	if (truish(elf)) t.body[rb,1]="User"
	on=differ(t.body[,2],"prev","true")
	t.body[,2]=t.body[,2]:*on
	
	pref="stata elfs "+subinstr(ename,"_","")+", "
	t.body[,5]=t.setLinks("stata",adorn(pref+"def(",t.body[,2],")"),"Set Default":*tru2(t.body[,2]))
	if (orgtype(anci)!="scalar"|eltype(anci)!="string") anci=base[1,1]
	ancix=pmax(1,toindices(t.body[,2]:==anci,"z"))
	t.body[ancix,5]=t.setSpan("hi1","Default")
	t.body[,6]=t.setLinks("stata",adorn(pref+"del(",t.body[,2],")"),"Delete":*tru2(t.body[,2]):*((1::rows(t.body)):>=rb))
	t.body="Source",strproper(head),"",""\t.body
	
	t.head=1
	t.stub=1
	t.set(t._class,2..rows(base)+1,.,"weaker")
	t.set(t._hline,rb,.,t.Lminor)
	t.set(t._hline,rows(t.body),.,t.Lmajor)
	t.set(t._vline,.,4,t.Lmajor)
	t.set(t._align,.,.,t.left)
	t.set(t._wrap,.,.,0)
	t.present("-")
	printf(`"{txt:elfs outstata:} {stata "elfs outs, edit":Edit All}"')
	}

void elfs_out::obutton(string vector opts) { //>>def member
	optionel(opts,&(setdef="def="))
	if (truish(setdef)) {
		anci=setdef
		write()
		}
	list()
	}

string matrix elfs_out::notfound() { //>>def member
	uelf=uelf()
	if (orgtype(anci)!="scalar"|eltype(anci)!="string") anci=base[1,1]
	ancix=pmax(1,toindices(uelf[,1]:==anci,"z")[1])
	return(cut(select(uelf,uelf[,1]:==uelf[ancix,1]),getix))
	}

end
//>>mosave<<
*! 18mar2016
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:


void elfs_sql::new() { //>>def member<<
	base="Default driver","sql server"\"Default schema","Dflt"\"Default owner","u%db%"
	head="name","setting"
	ename="sql"
	getix=2
	init()
	}

void elfs_sql::list() { //>>def member<<
	class tabel scalar t
	
	t.body=expand(expand(base\elf,3),-4)
	t.body[1,1]="Built-in"
	if (truish(elf)) t.body[rows(base)+1,1]="User"
	
	pref="stata elfs "+ename+", "
	t.body[,4]=t.setLinks("stata",adorn(pref+"del(",t.body[,2],")"),"Delete":*((1::rows(t.body)):>rows(base)))
	t.body="",strproper(head),""\t.body
	
	t.head=1
	t.stub=1
	t.set(t._align,.,.,t.left)
	t.set(t._class,2..rows(base)+1,.,"weaker")
	t.set(t._hline,rows(base)+1,.,t.Lminor)
	t.set(t._hline,rows(t.body),.,t.Lmajor)
	t.set(t._vline,.,cols(t.body)-1,t.Lmajor)
	t.present("")
	printf(`"{txt:elfs sql:} {stata "elfs sql, edit":Edit All}"')
	}

end
//>>mosave<<
*! 10mar2016
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:


void elfs_startup::new() { //>>def member<<
	base="instance","off"\"cdl","off"\"fromEditor","off"
	head="startup","on/off"
	ename="startup"
	getix=2
	init()
	}

void elfs_startup::list() { //>>def member<<
	class tabel scalar t
	
	t.body=expand(expand(base\elf,3),-4)
	t.body[1,1]="Built-in"
	if (truish(elf)) t.body[rows(base)+1,1]="User"
	
	pref="stata elfs "+ename+", "
	t.body[1..rows(base),4]=t.setLinks("stata", adorn(pref+"on(",t.body[1..rows(base),2],")"),J(rows(base),1,"Turn On"))
	if (truish(elf)) t.body[rows(base)+1..rows(t.body),4]=t.setLinks("stata", adorn(pref+"del(",t.body[rows(base)+1..rows(t.body),2],")"),J(rows(elf),1,"Delete"))
	t.body="Source",strproper(head),""\t.body
	
	t.head=1
	t.stub=1
	t.set(t._align,.,.,t.left)
	t.set(t._class,2..rows(base)+1,.,"weaker")
	t.set(t._hline,rows(base)+1,.,t.Lminor)
	t.set(t._hline,rows(t.body),.,t.Lmajor)
	t.set(t._vline,.,cols(t.body)-1,t.Lmajor)
	t.present("")
	}

void elfs_startup::obutton(string vector opts) { //>>def member
	optionel(opts,&(on="on="))
	if (truish(on)) {
		elf=elf\on,"on"
		write()
		}
	list()
	}

end
//>>mosave<<
*!unknown
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:
end
 global mincss (`"!"&+<=?#top {position:fixed; width:98%; left: 5px; top: 5px;z-index:10/*necessary for nav to be above not*nav*/}+#left {position:fixed; height:98%; left: 5px; overflow-y:auto; padding-right:16px; overflow-x:visible}++.btn_base {font-family: verdana, sans-serif ;font-size: small; font-weight: bold; border: 1px solid #333333; margin: .3em; padding: .2em;  cursor: pointer; zoom: 1; position: relative; border-radius:.5em}+.btn_low1 {background-color: #99DDFF}+.btn_low1:hover {background-color: yellow}+.btn_hi1 {background-color: #BBFFBB}+.tip {position: absolute; display:none; border: 2px solid black; padding: .2em; background-color: yellow;font-weight:normal;font-family:trebuchet ms, sans-serif; z-index:10}+.cbox_label {font-family: trebuchet ms, sans-serif;font-weight: bold}++nav {margin: 0 0 3.5em 1em;position: relative}+nav a, nav li {color:#4b545f; text-decoration: none; font-weight:bold;}+nav li {background:#AACCDD;/*padding:.3em .7em;*/}+nav a, nav > ul > li  {display:inline-block;padding:.3em .7em;}+#menu.off {float:left; border: 1px solid #4b545f; box-shadow: 4px 4px 2px rgba(0,0,0,.4); border-radius: 3px;}+#menu.on {float:left; border: 1px solid #4b545f; border-width: 1px 0 1px 1px; box-shadow: 4px 4px 2px rgba(0,0,0,.4) inset; border-radius: 3px 0 0 3px;}+nav ul ul {border: 1px solid #4b545f; box-shadow: 0px 0px 6px; border-radius: 3px;display: none;float:left}+nav ul ul li {border-bottom: 1px solid #575f6a;}+nav ul ul li:hover {background: #4b545f;}+nav ul ul li:hover a {color: white;}++p.bitsp {width:40em; margin-bottom:2em}"')
 mata:
end
 global minjs (`"#%&4789window.onload= function() {4	var top=document.getElementById(8top8)4	var left=document.getElementById(8left8)4	var defdiv=document.getElementById(8not*nav8)4	if (top||left) {4		defdiv.style.position=8fixed84		defdiv.style.overflow=8auto84		defdiv.style.top=83px84		defdiv.style.right=83px84		defdiv.style.bottom=83px84		defdiv.style.left=83px84		if (top) {4			defdiv.style.top=top.offsetHeight+10+8px84			defdiv.style.borderTop=81px dotted gray84			if (left) left.style.top=defdiv.style.top4		}4	if (left) {4		left.style.width=left.offsetWidth-16+8px8 //16 for scroll bar, should fix4		defdiv.style.left=left.offsetWidth+10+8px84		defdiv.style.borderLeft=81px dotted gray84	}4	}4	4	if ((menu=document.getElementsByTagName("NAV")).length) {4		menu=menu[0].firstChild4		menu.firstChild.onmouseenter=function() {this.nextSibling.style.display=8block8;this.className=8on8}4		menu.onmouseleave=function() {this.children[1].style.display=8none8;this.firstChild.className=8off8}4		menu.onclick=function() {this.children[1].style.display=8none8;this.firstChild.className=8off8}4	}4	4	elems = document.getElementsByTagName(8div8);4	for(i=0;i<elems.length;i++) {4		if ((si=elems[i].getAttribute(8showif8))!=null) {4			blocks.push(elems[i]);4			conds.push(si);4		}4	}4	redisplay();4}444function redisplay() {4	for (i=0;i<blocks.length;i++) {4		now=eval(conds[i])?8block8:8none84		if (blocks[i].style.display!=now) blocks[i].style.display=now; //don8t know if it8s faster to check or not...4	}4}44function rev_rbutton(cname,val,me) {4	controls[cname]=val;4	redisplay();4	spans=me.parentNode.getElementsByTagName(8span8);4	btnbase=8btn_base btn_low8+controls[cname+"_ix"]4	btnhi=8btn_base btn_hi8+controls[cname+"_ix"]4	for (i=0;i<spans.length;i++) {4		if (spans[i].className==btnhi) spans[i].className=btnbase;4	}4	me.className=btnhi;4}44function rev_cbox(cname,me) {4	controls[cname]=me.checked?8yes8:8no84	redisplay();4}44function rev_dropdown(cname,me) {4	controls[cname]=me.options[me.selectedIndex].text;4	redisplay();4}44blocks = [];4conds= [];4controls=new Object();4//for each control, controls.xxx=8yyy8;444function tipon(item) {4	tip=item.nextSibling4	tip.style.display=8inline84	tip.style.top=item.offsetTop4	tip.style.left=item.offsetLeft+25+8px84}4function tipoff(item) {4	item.nextSibling.style.display=8none84}"')
 mata:


void htmlplus::page(|string scalar pgid) { //>>def member<<
	super.page(pgid)
	_notnav="not*nav"
	_defdiv=_notnav
	_toc="toc" //gotta fix padding etc so click on whole li works (not just a)
	_top="top"
	_left="left"
	super.div(_top)
	super.div(_notnav)
	asarray(parts,(cpg,_toc,_na),J(0,1,""))
	addcss("mincss",strob_to($mincss))
	addjs(strob_to($minjs),"minjs")
	bcolors=J(0,3,"") //should be page specific
	}

void htmlplus::header(string scalar title, string scalar rev, string scalar dscr) { //>>def member<<
	super.header(title,rev,dscr,_top)
	}

void htmlplus::div(string scalar id,| string scalar parent, string scalar atts) { //>>def member<<
	if (anyof((_top,_left),id)) {
		if (truish(parent)|strhas(atts,"showif=",1)) {
			printf("{txt}div-ids {hi:top} and {hi:left} are pre-defined, and cannot have a parent() or showif() specified")
			parent=atts=""
			}
		}
	else parent=firstof(parent\_notnav)
	super.div(id,parent,atts)
	}

void htmlplus::addtoci(string scalar text) { //>>def member<<
	toc=asarray(parts,(cpg,_toc,_na))\text
	asarray(parts,(cpg,_toc,_na),toc)
	place(sprintf("<span class='tcsm' id='tcsm%f'></span>",rows(toc)))
	place(sprintf("<p class='toci'>%s</p>",text)) //in case I want to handle markers & text separately
	}

void htmlplus::addcbox(string scalar cbname, string scalar disp, string scalar tip, real scalar iyes) { //>>def member
	cboxdef=`"<label class='cbox_label' %s>%s&#x202F;<input type='checkbox' %s onClick='rev_cbox("%s",this)' /></label>%s&#x2003;%s"'
	tip=tipper(tip)
	place(sprintf(cboxdef,tip[1],disp,"checked"*iyes,cbname,tip[2],brleft()))
	addjs(sprintf(`"controls.%s="%s"\n"',cbname,"yes"*iyes))
	}

void htmlplus::adddd(string scalar drname, string matrix choices) { //>>def member
	dropd=sprintf(`"<select onchange='rev_dropdown("%s",this)'>"',drname)
	ichoice=toindices(substr(choices[2,],1,1):=="i","z")
	if (!ichoice) ichoice=1 //becasue dd will show that way anyway
	for (ch=1;ch<=cols(choices);ch++) {
		init=(ch==ichoice)*"selected='selected'"
		dropd=dropd+sprintf(`"<option %s>%s</option>"',init,choices[1,ch])
		}
	dropd=dropd+"</select>"
	place(dropd)
	addjs(sprintf(`"controls.%s="%s"\n"',drname,choices[1,ichoice]))
	}

void htmlplus::addbuttons(string scalar bname, string matrix buttons,| real scalar ibut, string vector colors) { //>>def member
	if (truish(colors)) {
		bcolors=bcolors\colors //more parsimonius to give all dups the same ix...
		ix=rows(bcolors)+1
		}
	else ix=1
	butdef=`"<span class='btn_base btn_%s%f' onclick='rev_rbutton("%s","%s",this)'%s>%s</span>%s"'
	for (b=1;b<=rows(buttons);b++) {
		tip=tipper(buttons[b,2])
		init=b==ibut?"hi":"low"
		place(sprintf(butdef,init,ix,bname,buttons[b,1],tip[1],buttons[b,1],tip[2]+brleft()))
		}
	js=""
	if (truish(ibut)) sput(js,sprintf("controls.%s='%s'\n",bname,buttons[ibut,1]))
	sput(js,sprintf("controls.%s_ix='%f'",bname,ix))
	addjs(js)
	}

void htmlplus::addimage(string scalar type, string scalar body,| string scalar tip) { //>>def member<<
	tip=tipper(tip)
	div=asarray(parts,(cpg,_div,cdiv))
	img=sprintf("<img %s src='data:image/%s;base64,\n",tip[1],type)+ base64(body)+"'>"
	// <div class='imhold'><img></div>
	//some kind of problem with images after toc or something
	asarray(parts,(cpg,_div,cdiv),div+img+tip[2]+eol())
	}

void htmlplus::addlog(string scalar commands, string scalar logpath) { //>>def member
	log="<div class='command'>"
	log=log+sprintf("<p>%s</p>",commands)
	log=log+"<PRE>"+ftostr(logpath)+"</PRE>"
	log=log+"</div>"
	place(log)
	}

void htmlplus::addpgbreak() { //>>def member
	place("<div style='page-break-after:always'></div>")
	}

void htmlplus::write(string scalar pgid, string scalar path,|string scalar gcembed) { //>>def member<<
	if (truish(tcs=asarray(parts,(cpg,_toc,_na)))) {
		addcss("p.toci {padding-left:.5em;font-size:1.2em;color:#4b545f;background:#F2F7FA;}")
		addcss("p.toci::before {content: '\27a4'}")
		sput(menu="","<nav><ul><li id='menu' class='off'>Go To &#10148;</li><ul>")
		for (i=1;i<=rows(tcs);i++) {
			sput(menu,sprintf("<li><a href='#tcsm%f'>%s</a></li>",i,tcs[i]))
			}
		sput(menu,"</ul></ul></nav>")
		div(_top)
		place(menu)
		}
	if (truish(bcolors)) { //bcolors is global instead of page based, at the moment. Switch to page array ix & it can be unique also
		for (b=1;b<=rows(bcolors);b++) {
			bcss=".btn_":+("low","low","hi"):+strofreal(b+1)
			bcss[,2]=bcss[,2]:+":hover"
			bcss=bcss:+ " {background-color:":+bcolors[b,]:+"}"
			}
		addcss(concat(concat(bcss," ")," "))
		}
	super.write(pgid,path,gcembed)
	}

string scalar htmlplus::brleft() { //>>def member
	return(cdiv=="left"?"<br>":"")
	}

string vector htmlplus::tipper(string scalar tip) { //>>def member
	return((truish(tip)*" onmouseover='tipon(this)' onmouseout='tipoff(this)' ",adorn("<span class='tip'>",tip,"</span>")))
	}

end
//>>mosave<<

*!30aug2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:


void tspoof::new() { //>>def member<<
	spoofs=asarray_create("string",2)
	nl=J(0,4,"")
	vl=J(0,2,"")
	}

string vector tspoof::strdummy(string vector names,| string vector chars) { //>>def member<<
	out=names
	for (n=1;n<=length(names);n++) {
		if (st_isstrvar(names[n])) {
			(void) st_addvar("long",dn=st_tempname())
			out[n]=dn
			st_sview(V=.,.,names[n])
			st_store(.,dn,encode(V,key=1))
			stata("qui compress "+dn)
			for (c=1;c<=length(chars);c++) charset(dn,chars[c],charget(names[n],chars[c]))
			
			spoofv(dn,(key,J(rows(key),1,"")))
			spoofn(dn,names[n],"string",charget(names[n],"@nlab"))
			}
		}
	return(out)
	}

string vector tspoof::dummyof(string vector names,| string vector chars) { //>>def member<<
	out=names
	for (n=1;n<=length(names);n++) {
		if (substr(names[n],1,2)!="__") { //assuming temps are already dummies or equivalent
			(void) st_addvar("byte",dn=st_tempname())
			out[n]=dn
			st_varvaluelabel(dn,st_varvaluelabel(names[n]))
			for (c=1;c<=length(chars);c++) charset(dn,chars[c],charget(names[n],chars[c]))
			
			spoofn(dn,names[n],strvars(names[n]),charget(names[n],"@nlab"))
			}
		}
	return(out)
	}

string vector tspoof::dsspoof(class dataset scalar ds,| string scalar dsid) { //>>def member<<
	dsid=firstof(dsid\"ds@")
	spnames=dsid:+strofreal(1..ds.nvars)
	for (i=1;i<=ds.nvars;i++) {
		asarray(spoofs,(spnames[i],"name"),ds.vnames[i])
		asarray(spoofs,(spnames[i],"str"),ds.sirtypes[i]=="s")
		asarray(spoofs,(spnames[i],"label"),ds.nlabels[i])
		asarray(spoofs,(spnames[i],"format"),ds.formats[i])
		asarray(spoofs,(spnames[i],"labref"),ds.vlabrefs[i])
		if (truish(spvals=ds.labelsof(i))) asarray(spoofs,(spnames[i],"vals"),(spvals[,1],spvals))
		}
	if (rows(ds.chars)) {
		chm=vmap(ds.chars[,1],ds.vnames,"both")
		for (ch=1;ch<=rows(chn);ch++) {
			asarray(spoofs,(dsid+strofreal(chm[ch,1]),"@"+ds.chars[ch,2]),ds.chars[ch,3])
			}
		}
	return(spnames)
	}

//!spoofv: set values/labels to display
//!names: var or clone names to set values for. If not cloned, name will be added as 'labels only'
//!news: 3 columns: [orig value, display value, display label]; matrix is added to labels for all specified vars.
void tspoof::spoofv(string vector names, string matrix news) { //>>def member<<
	asarray_notfound(spoofs,J(0,3,""))
	for (n=1;n<=length(names);n++) {
		olds=asarray(spoofs,(names[n],"vals"))
		map=vmap(olds[,1],news[,1],"not")
		asarray(spoofs,(names[n],"vals"),olds[map,]\news)
		}
	}

//!spoofn: set name/type/label to display
//!name: var or clone name (to look up)
//!dname: name to display
//!isstr: display type string (otherwise numeric)
//!dlab: display label
void tspoof::spoofn(string scalar name, string scalar dname, | matrix isstr, string scalar dlab) { //>>def member<<
	if (truish(dname)) asarray(spoofs,(name,"name"),dname)
	if (truish(isstr)) asarray(spoofs,(name,"str"),1)
	if (truish(dlab)) asarray(spoofs,(name,"label"),dlab)
	}

//!vars: get variable names, types, labels
//!names: varnames to look up
//!ix: label segment
//!spo: 'spoof only' (u or l) returns results before applying nl option; ie returns u or l 
//!R: 2 column matrix: col1=(marked)display names, col2=label
string matrix tspoof::getn(string vector names,| real scalar ix, string scalar spo) { //>>def member<<
	ix=firstof(ix\1)
	if (!length(names)) return(J(0,nl_n[ix],""))
	dnames=dlabs=J(length(names),1,"")
	dstrs=J(length(names),1,0)
	asarray_notfound(spoofs,"")
	for (n=1;n<=length(names);n++) {
		dnames[n]=firstof(asarray(spoofs,(names[n],"name"))\names[n])
		dstrs[n]=firstof(truish(asarray(spoofs,(names[n],"str")))\strvars(names[n]),.,0)
		dlabs[n]=asarray(spoofs,(names[n],nl[ix,3]))
		if (!truish(dlabs[n])&truish(_st_varindex(names[n]))) {
			shit=nl[ix,3]=="label"?"@nlab":substr(nl[ix,3],2)
			dlabs[n]=charget(names[n],shit)
			}
		}
	if (truish(spo)) return(spo=="u"?dnames:dlabs)
	
	tp1=`"matacmd MoreInfo(" "'
	tp2=`" ")"'
	if (nl[ix,1..2]==("u","-")) out=dnames
	else {
		haslab=tru2(dlabs)
		lnames=any(haslab)?setSpan("ul",dnames):dnames
		if (nl[ix,1..2]==("l","-")) out=!haslab:*lnames:+dlabs
		else if (nl[ix,1..2]==("u","^")) out=setLinks(("stata","title"),(adorn(tp1,dlabs,tp2),dlabs),dnames)
		else if (nl[ix,1..2]==("l","^")) {
			uofl=dnames:*haslab
			out=setLinks(("stata","title"),(adorn(tp1,uofl,tp2),uofl) ,dlabs:+!haslab:*lnames)
			}
		else if (nl[ix,2]==",") out=nl[ix,1]=="u"?(dnames,dlabs):(dlabs,dnames)
		else if (nl[ix,1]=="u") out=lnames:+adorn(": ",dlabs)
		else out=adorn("",dlabs,": "):+lnames
		}
	if (any(marks=dstrs:*(nl[ix,4]!="no"))) {
		mcol=1+(nl[ix,1..2]==("l",","))
		out[,mcol]=marks:* setLinks(("stata","title"),(`"matacmd MoreInfo(" string variable ")"',"string variable"),"*") :+out[,mcol]
		}
	return(out)
	}

//!vals: get values for several variables
//!names: relevant variables
//!values: ds values (can be string or real); data cols match variable cols
//!ix: label segment
//!spo: 'spoof only' (u or l) returns results before applying nl option
//!R: matrix with 1 or 2 cols per supplied name
string matrix tspoof::getv(string rowvector names, matrix values,| real scalar ix, string scalar spo) { //>>def member<<
	ix=firstof(ix\1)
	if (!length(names)|!length(values)) return(J(0,length(names),""))
	//if (!length(names)|!length(values)) return(J(0,vl_n[ix],""))
	unl=lab=J(rows(values),cols(values),"")
	vreal=eltype(values)=="real"
	strvars=strvars(names)
	asarray_notfound(spoofs,J(0,3,""))
	for (n=1;n<=length(names);n++) {
		if (!truish(fmt=asarray(spoofs,(names[n],"format")))) fmt=st_varformat(names[n])
		dt=anyof(("t","d"),substr(fmt,2,1)) | anyof(("-t","-d"),substr(fmt,2,2))
		unset=substr(fmt,-3)==".0g"
		
		rvals=vreal?values[,n]:strtoreal(values[,n])
		if (strvars[n]) unl[,n]=values[,n]
		else if (!dt) unl[,n]=strofreal(rvals,unset?"%12.3gc":fmt)
		else unl[,n]=strofreal(rvals)
		
		if (dt) lab[,n]=strofreal(rvals,fmt)
		lref=st_isname(names[n])?st_varvaluelabel(names[n]):asarray(spoofs,(names[n],"labref"))
		if (truish(lref)) lab[,n]=firstof(st_vlmap(lref,rvals)'\lab[,n]')'
		
		if(length(svals=asarray(spoofs,(names[n],"vals")))) {
			map=vmap(subinstr(unl[,n],",",""),svals[,1],"both")
			if (length(map)) {
				unl[map[,1],n]=svals[map[,2],2]
				lab[map[,1],n]=svals[map[,2],3]
				}
			}
		}
	if (truish(spo)) return(spo=="u"?unl:lab)
	
	tp1=`"matacmd MoreInfo(" "'
	tp2=`" ")"'
	if (vl[ix,]==("u","-")) return(unl)
	unl=colshape(unl,1)
	lab=colshape(lab,1)
	if (vl[ix,]==("l","-")) out=firstof((lab,unl)')
	else if (vl[ix,]==("u","^")) out=setLinks(("stata","title"),(adorn(tp1,lab,tp2),lab),unl)
	else if (vl[ix,]==("l","^")){
		uofl=unl:*tru2(lab)
		out=setLinks(("stata","title"),(adorn(tp1,uofl,tp2),uofl),firstof((lab,unl)')')
		}
	else {
		out=vl[ix,1]=="u"?unl,lab:lab,unl
		if (vl[ix,2]=="+") out=concat(out,"= ","r") //customize
		}
	return(rowshape(out,rows(values)))
	}

//!labset: set the nl/vl display settings
//!type: n or v
//!size: # of label segments the table can use
//!lin: user label option
//!ldef: default option
//!singles: vector of 0/1 to force concatenation for segments
void tspoof::labset(string scalar type, real scalar size, string scalar lin,| string scalar ldef, real vector singles) { //>>def member<<
	nlvl=type=="n"?(&nl):(&vl)
	ddef=type=="n"?("u","-","label","m"):("l",",") //not good that label here & below must match literals elsewhere
	*nlvl=expand(*nlvl,.,size)
	lin=expand(tokel(lin,","),size)
	ldef=expand(tokel(ldef,","),size)
	for (r=1;r<=size;r++) (*nlvl)[r,]=firstof(oneset(type,lin[r])\oneset(type,ldef[r])\ddef)
	singles=expand(vec(singles),.,size)
	replace(*nlvl,*nlvl:==",":&singles:==1,"+")
	if (type=="n") nl_n=1:+(nl[,2]:==",")
	else vl_n=1:+(vl[,2]:==",")
	}

string vector tspoof::oneset(string scalar type, string scalar opt) { //>>def member<<
	isn=type=="n"
	set=J(1,isn?4:2,"")
	if (isn) optionel(opt,(&(oul="u:nlabeled","l:abeled+"),&(ot="t:ip"),&(nomark="nom:ark")))
	else optionel(opt,(&(oul="u:nlabeled","l:abeled"),&(ot="t:ip")))
	set[1]=substr(expand(oul[2,],1)[1],1,1)
	if (truish(set[1])) {
		if (ot) set[2]="^"
		else set[2]=("-",",")[cols(oul)]
		}
	if (isn) {
		ol=select(oul[1,],oul[2,]:=="labeled")
		if (truish(ol)&ol!="1") set[3]="@"+ol
		else set[3]="label"
		set[4]="no"*nomark
		}
	return(set)
	}

end
//>>mosave<<

*! 10dec2010

* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.1
mata:

//!type: string
//!adorn: add to existing strings
//!pre: prefix for each cell
//!body: to affix to
//!post: suffix for each cell
//!R: affixed strings
stata("capture mata mata drop adorn()")
string matrix adorn(string vector pre, string matrix body, |string vector post) { //>>def func<<
	if (!length(pre)) pre=""
	if (!length(post)) post=""
	yes=strlen(body):>=1
	return(yes:*pre:+body:+yes:*post)
	}

end
//>>mosave<<
*!unknown but version 10.1!
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: search
//!asvmatch: varlist type search on matrix
//!bodyin: to search in
//!pat: pattern to search for (*,?,~)
//!options: [det:ails] [no:abbrev] [m:ulti]
//!R: real vector of hits on bodyin, if [details] returns matrix of hits, [bodyin]across by [pat] down
stata("capture mata mata drop asvmatch()")
real matrix asvmatch(string vector bodyin, string vector pat,| string scalar options) { //>>def func<<
	//optionel now uses asvmatch! breaks
	details=strpos(options,"det")
	noab=strpos(options,"no")
	multi=strpos(options,"mult")
	//optionel(options,(&(details="det:ails"),&(noab="no:abbrev"),&(multi="m:ulti")))
	if (!truish(bodyin)|!truish(pat)) return(details?J(length(pat),length(bodyin),0):J(rows(bodyin),cols(bodyin),0))
	//if (!any(truish((bodyin)))|!any(truish((pat)))) return(details?J(length(pat),length(bodyin),.):J(rows(bodyin),cols(bodyin),0))
	pat=tokenpair(tokel(pat),"-")'
	rp=rows(pat)
	pat1=truish(pat[,2])?vec(pat):pat[,1]
	pat=concat(pat,"-")
	pat1=pat1:+!strlen(pat1):*charsubs(pat1,1)
	body=rowshape(bodyin,1)
	tildes=strpos(pat1,"~")
	stars=strpos(pat1,"*"):|strpos(pat1,"?")
	if (any(tildes :& stars)) errel("~ may not be combined with * or ? ",pat)
	pat2=pat1
	if (!noab) pat2[ab]=pat2[ab=toindices(!stars:&!tildes)]:+"*"
	x=J(rows(pat1),cols(body),0)
	for (p=rows(x);p;p--) {
		if (!any(x[p,]=pat1[p]:==body)) x[p,]=strmatch(body,pat2[p]):&(substr(body,1,2):!="__":|substr(pat2[p],1,2)=="__")
		}
	if (!multi&length(multis=toindices(rowsum(x):>1:&!stars))) errel("Ambiguous abbreviations",pat1[multis])
	if (rows(x)>rp) {
		for (p=rp;p;p--) {
			if (truish(x[p+rp,])) {
				maxindex(x[p,]:|x[p+rp,],1,hit,junk)
				x[|p,hit[1]\p,cut(hit,-1)|]=J(1,cut(hit,-1)-hit[1]+1,1)
				}
			}
		}
	if (!details) return(shapeof(colmax(x[|1,1\rp,.|]),bodyin))
	else return(x[|1,1\rp,.|])
	}

end
//>>mosave<<
*! 20dec2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: trans
//!bound: set min and/or max for a matrix, by scalar, vector, matarix
//!in: to bound
//!lower: lower limit of returned values
//!upper: upper limit of returned values
//!R: in, with all out-of-bounds values replaced with min/max
stata("capture mata mata drop bound()")
real matrix bound(real matrix in, real matrix lower, real matrix upper) { //>>def func<<
	out=colshape(in,1)
	if (lower!=.) {
		l1=colshape(J(rows(in),cols(in),1):*lower,1)
		out=rowmax((out,l1))
		}
	if (upper!=.) {
		u1=colshape(J(rows(in),cols(in),1):*upper,1)
		out=rowmin((out,u1))
		}
	return(colshape(out,cols(in)))
	}

end
//>>mosave<<
*! 29oct2010
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
*! moved 16jan2015
version 11.1
mata:


//!type: stata
stata("capture mata mata drop callst()")
void callst(string scalar source,| string scalar dest, string scalar config) { //>>def func<<
	class elfs_callst scalar elf
	
	if (strlen(source)+strlen(dest)==0) errel("callst: A source and/or destination must be specified")
	if (!fexists(elf.anci)) errel("Could not find StatTransfer. Use {stata elfs callst} to set the path.")
	cmd=adorn("set ",elf.get(""))
	
	copyopts="-y "
	ftypes=""
	if (strlen(config)) {
		t=tokeninit(" ","","()")
		tokenset(t,config)
		while ((which = tokenget(t)) != "") {
			param=tokenget(t)
			if (strlen(param)<3) printf("One of the {cmd:config()} suboptions ("+which+") is missing\n")
			param=substr(param,2,strlen(param)-2)
			if (anyof(("set","keep","drop","where"),which)) cmd=cmd\which+" "+param
			else if (which=="type" & ftypes=="") ftypes=param
			else if (which=="copy" & copyopts=="-y ") copyopts=copyopts+param
			else printf("Unknown or duplicate {cmd:config()} suboption ("+which+")\n") 
			}
		}
	
	ftypes=columnize(ftypes," ")
	if (!strlen(source)) errel("callst: missing source filename")
	source=pcanon(source,"fex",".dta")
	//if (length(ftypes)==1) { //isn't this always true??
	if (anyof((".dta",".tmp"),pathparts(source,3))) ftypes="stata/se",ftypes
	else ftypes=ftypes,"stata/se"
	//	}
	if (dest=="") {
		if (ftypes[1]!="stata/se") dest=pathparts(source,12)+".dta"
		else if (strlen(ftypes[2])) dest=pathparts(source,12)+".xxx"
		else errel("No destination type info")
		}
	else dest=pcanon(dest,"file")
	
	cmd=cmd\sprintf("COPY %s %s %s %s %s",ftypes[1],adorn(char(34),source,char(34)),ftypes[2], adorn(char(34),dest,char(34)), copyopts)\"quit"\" "
	fowrite(cmdfile=pathto("_callst.stcmd","inst"),concat(cmd,eol()))
	stata(sprintf(`"shell "%s" "%s""',elf.anci,cmdfile))
	if (strlen(dest)&!fexists(dest)) errel("File was not translated successfully ")
	}
end
//>>mosave<<
*! 3apr2015
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:
//!type: stata
//!callstata: launch stata in batch mode to run a script
//!script: stata code
//!log: log will be deleted unless this is truish
stata("capture mata mata drop callstata()")
void callstata(string scalar script,|matrix log) { //>>def func<<
	logpath=pathto("callstata.log","inst")
	scrpath=pathto("callstata.do","inst")
	//script=sprintf(`"mata: cdl("%s")"',seattel())+eol()+script
	fowrite(scrpath,script)
	unlink(logpath)
	cd=pwd()
	chdir(seattel())
	stata(sprintf("shell "+char(34)+pcanon(c("sysdir_stata"))+stataexe()+char(34)+" /e /q do "+char(34)+scrpath+char(34)))
	if (!truish(log)) unlink(logpath)
	chdir(cd)
	}
end
//>>mosave<<
*! 3oct2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.1
mata: 

//!type: stata
stata("capture mata mata drop catdata()")
real scalar catdata(scalar var) { //>>def func<<
	if (st_isstrvar(var)) return(1)
	if (!strlen(lab=st_varvaluelabel(var))) return(0) 
	st_vlload(lab,vals,labs) 
	if (length(vals)) return(!missing(vals[1])) 
	else return(0)
	} 

end 
//>>mosave<<
*! feb62016
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
* new edition of an old command
version 11

mata:

//!type: stata
//!cdl: change working and project directories
//!mode: [<] or [d] or nothing
//!path: working directory to change to
//!proj: flag to set project dir
stata("capture mata mata drop cdl()")
void cdl(string scalar mode,| string scalar path, matrix proj) { //>>def func
	class tabel scalar t
	class recentle scalar rle
	class recentle_data scalar rld
	class recentle_proj scalar prj
	
	rle.init("cdl",("directory","details"))
	
	if (mode=="list") {
		t.body="Recent Working Directories"\t.setLinks("stata",`"stata "cdl "':+rle.recent[,1]:+char(34),rle.recent[,1])
		t.head=1
		t.set(t._vline,.,.,t.Lmajor)
		t.set(t._align,.,.,t.left)
		t.present("-")
		return
		}
	
	if (mode=="d") {
		rld.get()
		path=rld.ndir
		}
	else if (mode=="<") path=cut(rle.recent[,1],-2,-2,1)
	else if (truish(path)) path=pcanon(path,"dir")
	else if (!truish(rle.recent)) path=pwd()
	else path=cut(rle.recent[,1],-1)
	rle.add((path,mode))
	
	//stata doesn't update status bar from chdir, so might as well use stata(cd) for all
	stata(sprintf(`"qui cd "%s""',path))
	printf("{txt:working: }{res:%s}\n",path)
	
	if (truish(proj)) prj.add(path)
	}
end
//>>mosave
*!13dec2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:
//!type: stata
//!charget: get variable characteristic; only 1 of vars & chars can be a vector
//!vars: variables to look up
//!chname: characteristic name to look up; @dat for dataset label, @nlab @form, @vlab
//!R: characteristics or labels
stata("capture mata mata drop charget()")
string vector charget(vector vars, string vector chars) { //>>def func<<
	if ((lv=length(vars))>1&(lc=length(chars))>1) errel("charget: Only 1 of vars or chars can be a multiple")
	out=lv>1?vars:*0:chars:*0
	
	svars=eltype(vars)=="string"?vars:st_varname(vars)
	(void) varlist(selectv(svars,svars:!="_dta","r"))
	schar=substrf(chars,1,5)
	
	for (c=1;c<=lc;c++) {
		for (v=1;v<=lv;v++) {
			o=pmax(c,v)
			if (svars[v]=="_dta"&substr(schar[c],1,1)=="@"/*lab*/) out[o]=st_macroexpand(char(96)+":data l'")
			else if (schar[c]=="@nlab") out[o]=st_varlabel(svars[v])
			else if (schar[c]=="@vlab") out[o]=st_varvaluelabel(svars[v])
			else if (schar[c]=="@form") out[o]=st_varformat(svars[v])
			else if (schar[c]=="@type") out[o]=st_vartype(svars[v])
			//else if more
			else out[o]=st_global(svars[v]+"["+chars[c]+"]")
			}
		}
	return(out)
	}

//!type: stata
//!charget: set variable characteristic; only 1 of vars & chars can be a vector
//!vars: variables to set
//!chname: characteristic name to look up; @dat for dataset label, @nlab, @form, @vlab
//!contents: text to set as chars or labels
stata("capture mata mata drop charset()")
void charset(vector vars, string vector chars, string vector contents) { //>>def func<<
	if ((lv=length(vars))>1&(lc=length(chars))>1) errel("charget: Only 1 of vars or chars can be a multiple")
	if (length(contents)==1) contents=J(1,pmax(lv,lc),contents)
	
	svars=eltype(vars)=="string"?vars:st_varname(vars)
	(void) varlist(selectv(svars,svars:!="_dta","r"))
	schar=substrf(chars,1,5)
	
	for (c=1;c<=lc;c++) {
		for (v=1;v<=lv;v++) {
			o=pmax(c,v)
			if (svars[v]=="_dta"&substr(schar[c],1,1)=="@"/*lab*/) stata(sprintf(`"label data `"%s"'"',contents[o]))
			else if (schar[c]=="@nlab") st_varlabel(svars[v],contents[o])
			else if (schar[c]=="@vlab") st_varvaluelabel(svars[v],contents[o])
			else if (schar[c]=="@form") st_varformat(svars[v],contents[o])
			//else if more as necessary; cannot set type
			else st_global(svars[v]+"["+chars[c]+"]",contents[o])
			}
		}
	}

end
//>>mosave<<



*!unknown v10.1
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata: 

//!type: trans
stata("capture mata mata drop chars()")
string matrix chars(real matrix nums, | real scalar offset) { //>>def func<<
	if (args()<2) offset=0
	out=J(rows(nums),cols(nums),"")
	for (r=1;r<=rows(nums);r++) {
		for (c=1;c<=cols(nums);c++) {
			out[r,c]=char(nums[r,c]+offset)
			}
		}
	return(out)
	}

end 
//>>mosave<<
*! 17sep2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: string
//!charsubs: find unused characters to use as markers
//!body: text to search
//!needed: the count of substitution to return
//!exclude: chars (such as line breaks) to exclude as markers
//!R: a vector of unused characters
stata("capture mata mata drop charsubs()")
string rowvector charsubs(string matrix body,| real scalar needed, real vector exclude) { //>>def func<<
	needed=firstof(needed\1)
	back=J(1,needed,"")
	i=0
	j=1
	while (i<needed) {
		while (j<256&(any(strhas(body,char(j)))|any(j:==exclude))) ++j
		if (j==256) errel("Can't find substitution/control characters")
		else back[++i]=char(j++)
		}
	return(back)
	}
end
//>>mosave<<
*! 12mar2014
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: string
//!chtrim: trim leading/trailing characters
//!body: to trim from
//!btrims: characters to trim; defaults to 10 & 13 (lf & cr)
//!R: trimmed matrix
stata("capture mata mata drop chtrim()")
string matrix chtrim(string matrix body,| string vector btrims) { //>>def func<<
	if (!length(body)) return(body)
	if (length(btrims)) trims=rowshape(btrims,1)
	else trims=chars((10,13))
	rb=rows(body)
	out=colshape(body,1)
	while (length(hits=toindices(rowmax(strmatch(substr(out,1,1),trims))))) out[hits]=substr(out[hits],2)
	out=strreverse(out)
	while (length(hits=toindices(rowmax(strmatch(substr(out,1,1),trims))))) out[hits]=substr(out[hits],2)
	return(rowshape(strreverse(out),rb))
	}
end
//>>mosave<<
*!9jan2015
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: stata
//!cmdvars: set chars or drop vars, for vars left by commands
//!vars: truish vars means set var[el_cmdvar]=cmds
//!cmds: 1cmd with vars to set; else drop cmdvar or all cmdvars
stata("capture mata mata drop cmdvars()")
void cmdvars(|string vector vars, string vector cmds) { //>>def func<<
	if (truish(vars)) { //set
		if (length(cmds)!=1) errel("cmdvars: if vars are specified, exactly 1 cmd must be specified",pad(vars,cmds,"\"))
		charset(vars,"el_cmdvar",cmds)
		}
	else {
		vars=varlist("*")
		varcmds=charget(vars,"el_cmdvar")
		if (truish(varcmds)) {
			//indexes weren't working, I suspect because of temp vars
			if (truish(cmds)) st_dropvar(select(vars,varcmds:==cmds))
	//		if (truish(cmds)) st_dropvar(vmap(varcmds,cmds,"in"))
			else st_dropvar(select(vars,tru2(varcmds)))
	//		else st_dropvar(toindices(varcmds))
			}
		}
	}
end
//>>mosave<<
*! 15dec2010 
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
*! 23jan2015
version 11
mata:

//!type: stata
//!colllect: concatenate datasets
//!paths: filepaths
//!ifin: ifin
//!app: append to data in memory
//!keep: keep varlist
//!pass: to other filehandlers
//!test: show plan only, don't exec
stata("capture mata mata drop colllect()")
void colllect(string scalar paths, string scalar ifin, real scalar app, string scalar keep, string scalar pass, matrix test) { //>>def func
	class dataset_dta scalar all, ds
	class tabel scalar t
	class recentle_data scalar rld
	
	parts=columnize(paths,";")
	files=J(app,1,"")
	for (p=1;p<=length(parts);p++) files=files\multipath(parts[p],".dta")
	files=uniqrows(files)
	if (length(files)==0) errel(sprintf("No files found: %s\n",concat(parts,";")))
	
	vrfile=""
	keep=firstof(keep\"*")
	allnf=tokel(keep)
	t.body="id","Notes"
	dsvixs=allvixs=J(rows(files),1,NULL)
	allnames=J(0,1,"")
	nobs=0
	
	ds.with("lab char")
	copass=pass //pass is messed with in ds and fin
	for (f=1;f<=rows(files);f++) {
		if (truish(files[f])) ds.readfile(files[f],pass=copass)
		else {
			ds.readmem()
			if (truish(cvar=varofchar("el_cmdvar","collect"))) ds.shrink("drop",ds.varlist(cvar))
			}
		dsvixs[f]=&ds.varlist(keep,"all nfok",mods=("(first)","->"),dsnf)
		allnf=allnf[vmap(allnf,dsnf,"in")]
		mods=strtrim(subinstrf(mods,"->",""))
		dsnns=firstof(mods\ds.vnames[*dsvixs[f]])'
		allnames=dedup(allnames\dsnns)
		allvixs[f]=&vmap(dsnns,allnames)
		nobs=nobs+ds.nobs
		for (dv=1;dv<=length(dsnns);dv++) {
			aix=(*allvixs[f])[dv]
			dix=(*dsvixs[f])[dv]
			if (!anyof(all.vnames,dsnns[dv]))  all.gen("",dsnns[dv],othtypes(ds.sirtypes[dix],ds.bytes[dix]), ds.nlabels[dix],ds.formats[dix],ds.vlabrefs[dix])
			else {
				///sbfmerge
				ix=aix
				sirtype=ds.sirtypes[dix]
				bytes=ds.bytes[dix]
				format=ds.formats[dix]
				
				ntypes=("i1","i2","i4","r4","r8")
				sbytes=(3,5,10,7,16)
				if (all.sirtypes[ix]==""&sirtype!="") { //initial, redundant now?
					all.sirtypes[ix]=sirtype
					all.bytes[ix]=bytes
					all.formats[ix]=format
					}
				else if (all.sirtypes[ix]==sirtype&all.bytes[ix]<bytes) { //+ larger of same type
					all.bytes[ix]=bytes
					all.formats[ix]=format
					}
				else if (all.sirtypes[ix]=="i"&sirtype=="r") { //int to real
					all.sirtypes[ix]="r"
					all.bytes[ix]=max((all.bytes[ix]*2,bytes))
					all.formats[ix]=format
					}
				else if (all.sirtypes[ix]=="r"&sirtype=="i") { //real + larger int
					all.bytes[ix]=max((all.bytes[ix],bytes*2))
					}
				else if (all.sirtypes[ix]=="s"&sirtype!="s") { //string + larger num
					y=select(sbytes,sirtype+strofreal(bytes):==ntypes)
					all.bytes[ix]=max((all.bytes[ix],y))
					all.formats[ix]=sprintf("%%-%fs",all.bytes[ix])
					}
				else if (all.sirtypes[ix]!="s"&sirtype=="s") { //num to string
					"ya"
					all.sirtypes[ix]="s"
					y=select(sbytes,all.sirtypes[ix]+strofreal(all.bytes[ix]):==ntypes)
					all.bytes[ix]=max((y,bytes))
					all.formats[ix]=sprintf("%%-%fs",all.bytes[ix])
					*all.data[ix]=J(0,1,"") //data is always empty here...
					}
				///sbfmerge
				
				if (!truish(all.nlabels[aix])) all.nlabels[aix]=ds.nlabels[dix]
				if (truish(all.vlabrefs[aix])) {
					if (all.sirtypes[aix]=="s") all.vlabrefs[aix]=""
					}
				else if (all.sirtypes!="s") all.vlabrefs[aix]=ds.vlabrefs[dix]
				if (truish(all.vlabrefs[aix]) & !any(all.vlabnames:==all.vlabrefs[aix])) {
					dsvl=toindices(ds.vlabnames:==all.vlabrefs[aix])
					if (truish(dsvl)) {
						all.vlabnames=all.vlabnames,ds.vlabnames[dsvl]
						all.vlabtabs=all.vlabtabs,ds.vlabtabs[dsvl]
						}
					}
				}
			if (truish(chars=select(ds.chars,ds.chars[,1]:==dsnns[dv]))) all.chars=all.chars\chars
			}
		if (truish(chars=select(ds.chars,ds.chars[,1]:=="_dta"))) all.chars=all.chars\chars
		
		t.body=t.body\strofreal(f),files[f]
		t.body=t.body\"","kept "+t.setLinks("stata",sprintf(`"view %s"%s"##%f%s"',char((96,34)),pathto("_collect.smcl"),f,char((34,39))),sprintf("%f of %f vars",length(dsnns),ds.nvars))
		if (uniqs(select(mods,tru2(mods))',"dups")) t.body=t.body\"!","mult vars renamed to one"
		if (anyof(dsnns,"long")) t.body=t.body\"!","varname='long' not allowed"
		sput(vrfile,sprintf("{marker %f}{ul:%s}",f,files[f]))
		vref=ds.vnames
		vref[*dsvixs[f]]=adorn("{hi:",vref[*dsvixs[f]],"}")
		sput(vrfile,sprintf("{pstd}%s{p_end}\n",concat(vref," ")))
		}
	
	fowrite(pathto("_collect.smcl"),vrfile)
	t.head=1
	t.set(t._align,.,2,t.left)
	t.set(t._wrap,.,2,0)
	t.set(t._vline,.,.,t.Lmajor)
	t.set(t._hline,toindices(substr(t.body[,2],1,5):=="kept "),.,t.Lmajor)
	t.set(t._class,err=toindices(t.body[,1]:=="!"),.,"err")
	t.render()
	if (truish(allnf)) {
		t.body="Not Found:",concat(allnf," ")
		t.set(t._class,1,1,"heading")
		t.set(t._align,1,2,t.left)
		t.render()
		}
	t.present("-")
	if (any(err)) errel("problems...")
	if (test) return
	
	fbits=recode(pathends(files),("","data in memory"))
	all.vlabnames=all.vlabnames,"collectidlab" //ds version of vlabnames??
	all.vlabtabs=all.vlabtabs,&(strofreal(1::rows(files)),fbits)
	all.gen("",fid="_file","byte","collect file id","%3.0f","collectidlab")
	all.chars=dedup(all.chars,(1,2))
	
	ds.with("data")
	if (!truish(files[1])) ds.readmem()
	all.writemem()
	cmdvars("_file","collect")
	
	if (truish(nobs)) st_addobs(nobs) //missing for all foreign files at this point
	beg=1
	for (f=1;f<=rows(files);f++) {
		printf("file %f\n",f)
		if (truish(*allvixs[f])) {
			if (truish(files[f])) ds.readfile(files[f],pass=copass+" metamatch") //to match previous vars, xl
			if (ds.nobs) {
				if ((xtra=beg+ds.nobs-1-st_nobs())>0) st_addobs(xtra) //nobs was estimate 
				for (c=1;c<=length(*allvixs[f]);c++) {
					if (all.sirtypes[(*allvixs[f])[c]]=="s"&ds.sirtypes[(*dsvixs[f])[c]]!="s") tostore=el_strof(*ds.data[(*dsvixs[f])[c]])
					else tostore=*ds.data[(*dsvixs[f])[c]]
					el_store(beg::beg+ds.nobs-1,st_varname((*allvixs[f])[c]),tostore)
					}
				el_store(beg::beg+ds.nobs-1,fid,J(ds.nobs,1,f))
				beg=beg+ds.nobs
				}
			}
		}
	if (beg<=st_nobs()) st_dropobsin((beg,st_nobs()))
	
	rld.ncmd="collect"
	if (!app) {
		rld.parse(files[1],ifin,keep,pass)
		rld.add()
		}
	for (f=2;f<=rows(files);f++) {
		rld.parse(files[f],ifin,keep,pass)
		rld.add("other")
		}
	}
end
//>>mosave<<
*!unknown v10.1
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata: 

//!type: parse
//!columnize: expand a matrix by parsing each column on a scalar
//!orig: matrix to parse
//!delimiter: as stated
//!each: if specified, empty delimited columns are retained
//!R: each original column parsed out, originals remain aligned
stata("capture mata mata drop columnize()")
matrix columnize(matrix orig, |string scalar delimiter, matrix each) { //>>def func<<
	if (!length(orig)) return(orig)
	if (eltype(orig)=="string") if (!any(strlen(orig))) return(orig)
	if (args()==1) delimiter=" " 
	
	if (eltype(orig)=="real") return(strtoreal(columnize(strofreal(orig),"")))
	
	if (delimiter=="") {
		rlen=rowsum(strlen(orig))
		copy=J(rows(orig),max(rlen),"")
		for (r=1;r<=rows(copy);r++) if (rlen[r]) copy[r,1..rlen[r]]=chars(ascii(concat(orig[r,],"")))
		return(copy)
		}
	
	copy=orig:+delimiter
	bits=asarray_create("real") 
	ix=0
	dlen=strlen(delimiter)
	while (sum(strlen(copy))) { 
		pos=strpos(copy,delimiter)
		asarray(bits,++ix,substr(copy,1,pos:+dlen:-1))
		copy=substr(copy,pos:+dlen)
		}
	parsed=J(rows(orig),cols(orig)*ix,"")
	for (c=1;c<=ix;c++) parsed[,rangel(c,cols(parsed),ix)]=asarray(bits,c)
	keep=truish(each)?0:dlen
	parsed=parsed[,toindices(colmax(strlen(parsed):>keep))]
	parsed=subinstrf(parsed,delimiter,"")
	
	return(parsed) 
	} 

end 
//>>mosave<<
*! 19jun2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.2
mata:

//!type: parse
//!colwords: parse a specified number of columns starting left or right
//!in: to parse
//!right: [r] causes right-parsing, otherwise left
//!cols: number of result columns, 2 by default
//!del: delimiter, space by default
//!R: parsed columns
stata("capture mata mata drop colwords()")
string matrix colwords(string colvector in,| string scalar right, real scalar cols, string scalar del) { //>>def func<<
	//this needs to be modernized to make use of tokel
	if (!length(in)) return(in)
	if (args()<3) cols=2
	if (args()<4) del=" "
	if (cols<2) return(in)
	
	text=right=="r"?strreverse(in):in
	text=columnize(text,del)
	//text=columnize(text,del,"",ya) //no idea where the hell this came from
	if (cols(text)<cols) text=text,J(rows(text),cols-cols(text),"")
	else if (cols(text)>cols) text=text[,1..cols-1],concat(text[,cols..cols(text)],del)
	if (right=="r") text=strreverse(text[,cols(text)..1])
	return(text)
	}
end
//>>mosave<<

	
*!unknown
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata: 

//!type: string
//!concat: concatenate matrix to vector or vector scalar
//!input: stuff to concat
//!del: delimiter
//!opts: r=concat rows to scalars, c=concat cols, e=delimit each cell
stata("capture mata mata drop concat()")
string matrix concat(matrix input, string scalar del,| string scalar options) { //>>def func<<
	if ((rs=strpos(options,"r"))&(cs=strpos(options,"c"))) errel("concat: only one of 'r' or 'c' can be specified")
	if (!length(input)) { //oh the klugosity!
		if (rs) return(J(rows(input),1,""))
		if (cs) return(J(1,cols(input),""))
		return("") //this should really go away
		}
	next=el_strof(input)
	if (swap=(cs|(!rs&cols(next)==1))) next=next'
	out=next[,1]
	if (strpos(options,"e")) {
		next=del:+next
		for (c=2;c<=cols(next);c++) out=out:+next[,c]
		}
	else {
		pos=tru2(next)
		for (c=2;c<=cols(next);c++) out=out:+tru2(out):*pos[,c]:*del:+next[,c]
		}
	return(swap?out':out)
	} 

end 
//>>mosave<<
*! 27jan2014
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: config
//!cosort_: sort multiple matrices (rows) in place, using the same interdependent order
//!datas: matrices to sort, including any just for order
//!keys: 2-col: 1st=ix in pointer; 2nd=col in matrix (optional, def=1). Either number can be neg for desc sort. (sign not working?!)
stata("capture mata mata drop cosort_()")
void cosort_(pointer vector datas, real matrix keys) { //>>def func<<
	n=rows(keys)
	if (cols(keys)==1) keys=keys,J(n,1,1)
	sorter=J(rows(*datas[1]),n,.)
	for (k=1;k<=n;k++) {
		if (eltype(*datas[keys[k,1]])=="real") sorter[,k]=(*datas[keys[k,1]])[,keys[k,2]]
		else sorter[,k]=encode((*datas[keys[k,1]])[,keys[k,2]],.,"blankfirst") //if bf isn't always right, need another param
		}
	perm=order(sorter,(1..n):*sign(keys[,1]'):*sign(keys[,2]'))
	for (d=1;d<=length(datas);d++) *datas[d]=(*datas[d])[perm,]
	//for (d=1;d<=length(datas);d++) _collate(*datas[d],perm)
	}
end
//>>mosave<<
*!unknown v10.1
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata: 

//!type: numeric
stata("capture mata mata drop counters()")
real vector counters(real scalar first, | real scalar last, real vector pat) { //>>def func<<
	if (args()==1) return(first)
	
	stringer=strlen(strofreal((first,last)))
	size=max(stringer)
	out=J(1,size-stringer[1],0),ascii(strofreal(first)):-48
	final=J(1,size-stringer[2],9),ascii(strofreal(last)):-48
	stringer=strlen(strofreal(pat))
	if (args()<3) pattern=J(1,size-1,(0\9)),(1\4)
	else pattern=J(1,size-stringer[1],0),ascii(strofreal(pat[1])):-48\J(1,size-stringer[2],9),ascii(strofreal(pat[2])):-48
	r=rows(out)
	while (strtoreal(concat(strofreal(out[r,]),""))<min((strtoreal(concat(strofreal(final),"")), strtoreal(concat(strofreal(pattern[2,]),""))))) {
		out=out\out[r,]
		r=rows(out)
		c=cols(out)
		do {
			out[r,c]=mod(out[r,c]+1,pattern[2,c]+1)
			if (out[r,c]==0) out[r,c]=pattern[1,c]
			c=c-1
			} while (out[r,c+1]==pattern[1,c+1] & c>=1)
		} 
	return(strtoreal(concat(strofreal(out),"")))
	}

end 
//>>mosave<<



*!unknown
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.1
mata:

//!type: select
//!cut: select a cut of a matrix or vector
//!in: matrix to cut
//!first: beginning index (col for mat); neg counts back from end; 
//!last: ending index (col for mat); neg counts back from end;
//!expand: expand to n cols after cut; adds cols on right, on left for -expand
//!min: 'matrix in', meaning cut cols, even for a colvect
//!R: subvector or matrix; 0 in cut direction if first>size or last<-size (or 0)
stata("capture mata mata drop cut()")
matrix cut(matrix in, real scalar first,| real scalar last, real scalar expand, matrix min) { //>>def func<<
	expand=firstof(expand\0)
	cv=(cols(in)<2&rows(in)>cols(in)&!truish(min))
	out=cv?in':in
	max=cols(out)
	f2=truish(first)?pmax(first+(first<0)*(max+1),1):1
	l2=pmin(max,last+(last<0)*(max+1))
	if (l2==0|-l2>max|f2>max|f2>l2) {
		return(J(!cv*rows(in)+cv*abs(expand),cv+!cv*abs(expand),missingof(in)))
		}
	if (!rows(out)) out=J(0,pmax(l2-f2+1,abs(expand)),missingof(in))
	else out=expand(out[|1,f2\rows(out),l2|],expand)
	return(cv?out':out)
	}

end
//>>mosave<<
*! 23may2014
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: trans
//!datetime: get datetime in a convenient format
//!format: standard format string or [.]
//!R: . returns numeric Clock; if no format string: %tc+DDmonYY_HH:MM
stata("capture mata mata drop datetime()")
scalar datetime(|string scalar format) { //>>def func<<
	num=Clock(c("current_date")+" "+c("current_time"),"DMYhms")
	if (format==".") return(num)
	else if (format=="") return(strofreal(num,"%tc+CCYY-NN-DD_HH:MM"))
	else return(strofreal(num,format))
	}
end
//>>mosave<<
*! unknown v10.1
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata: 

//!type: trans
stata("capture mata mata drop dedup()")
matrix dedup(matrix body,| real rowvector key, real rowvector keep, string scalar del) { //>>def func<<
	if (!length(body)) return(body)
	if (args()<4) del=", "
	if (args()<2) key=1..cols(body)
	ck=cols(key)
	k=length(keep)>0
	if (k&eltype(body)!="string") _error("3rd & 4th parameters can only be specified with a string matrix")
	out=body
	for (i=1;i<=rows(out);i++) { 
		if (sum(match=rowsum(out[,key]:==out[i,key]):==ck)>1) {
			if (k) out[i,keep]=concat(select(out[,keep],match),del,"c")
			out=select(out,!match:|e(i,length(match))') 
			} 
		}
	return(out)
	}

end 
//>>mosave<<
*! 9nov2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.1
mata:
//!type: search
//!differ: Mark cells that differ from next/previous
//!in: vector to evaluate
//!before: flag to evaluate relative to previous rather than next
//!itrue: flag to set 'outside' cell to true rather than false
//!R: t/f for every cell of {in}
stata("capture mata mata drop differ()")
real vector differ(vector in,| matrix before, matrix itrue) { //>>def func<<
	if (!length(in)) return(J(rows(in),cols(in),0))
	if (length(in)==1) return(truish(itrue))
	b=truish(before)
	i=truish(itrue)
	return(shapeof(J(b,1,i)\colshape(in[|1\length(in)-1|]:!=in[|2\length(in)|],1)\J(!b,1,i),in))
	}
end
//>>mosave<<
*! 27feb2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.1
mata:

//!type: paths
stata("capture mata mata drop direl()")
string colvector direl(string scalar dirname, string scalar filetype, string scalar pattern, | real scalar prefix) { //>>def func<<
	if (!length(choices=dir(dirname,filetype,""))) return(J(0,1,""))
	match=strmatch(strlower(choices),strlower(pattern))
	return(selectv(dir(dirname,filetype,"",prefix),match,"c"))
	}
end
//>>mosave<<
*! 3nov2010
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.1
mata:

//!type: paths
stata("capture mata mata drop dirsep()")
string scalar dirsep() { //>>def func<<
	return(select(("/",":","\"),c("os"):==("Unix","MacOSX","Windows")))
	}

end
//>>mosave<<
*! 15dec2010
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.1
mata:

//!type: file
stata("capture mata mata drop diskFileSize()")
real vector diskFileSize(string vector paths) { //>>def func<<
	//paths should already be validated!
	paths=subinstr(paths,char(34),"") //just in case
	retfile=pathto("_dfsize.txt","inst")
	sput(cmd="","Dim FSO, File, fsizes")
	sput(cmd,`"Set FSO = CreateObject("Scripting.FileSystemObject")"')
	sput(cmd,sprintf(`"Set fsizes=FSO.CreateTextFile("%s")"',retfile))
	for (p=1;p<=length(paths);p++) {
		sput(cmd,sprintf(`"Set File = FSO.GetFile("%s")"',paths[p]))
		sput(cmd,"fsizes.Writeline ( File.Size)")
		}
	fowrite(cmdfile=pathto("_dfsizes.vbs","inst"),cmd)
	stata("shell "+cmdfile)
	return(strtoreal(cat(retfile)))
	}

end
//>>mosave<<
*! 26may2015
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.1
mata:

//!type: trans
//!doofstr: exclude problematic chars from do files (control characters, line feeds, macro chars)
//!str: to fix
//!R: ok for do files
stata("capture mata mata drop doofstr()")
string scalar doofstr(string scalar str) { //>>def func<<
	replace=(1..31,36,39,96)
	hits=select(replace,strpos(str,chars(replace)))
	mark=charsubs(str,1,(replace,34))
	subs=mark:+strofreal(hits):+mark
	out=str
	hits=chars(hits)
	for (h=1;h<=length(hits);h++) out=subinstr(out,hits[h],subs[h])
	return(mark+out)
	}

//!type: trans
//!dotostr: restore do-safe string to actual string
//!strsafe: doofstr version
//!R: original version
stata("capture mata mata drop dotostr()")
string scalar dotostr(string scalar dosafe) { //>>def func<<
	mark=substr(dosafe,1,1)
	out=substr(dosafe,2)
	while (regexm(out,mark+"([0-9]+)"+mark)) {
		ch=regexs(1)
		out=subinstr(out,mark+ch+mark,char(strtoreal(ch)))
		}
	return(out)
	}

end
//>>mosave<<
*! 16mar2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:
//!type: stata
//!el_data: return either numeric or string data
//!i: obs
//!j: vars
//!select: selectvar
//!R: requested data
stata("capture mata mata drop el_data()")
matrix el_data(real matrix i, rowvector j,|scalar select) { //>>def func<<
	if (!truish(j)) j=1..st_nvar()
	jstr=length(somevars(j,"s"))
	if (!st_nobs()) return(J(0,length(j),jstr?"":.))
	//if (!length(j)) errel("el_data: varnames required")
	if (!jstr) return(st_data(i,j,select))
	else if (jstr!=length(j)) errel("el_data: cannot mix string and numeric vars")
	else return(st_sdata(i,j,select))
	}

//!type: stata
//!el_data: return one datapoint, string or numeric
//!i: obs
//!j: var ix
//!R: requested data
stata("capture mata mata drop el_data_()")
matrix el_data_(real scalar i, real scalar j) { //>>def func<<
	if (st_isnumvar(j)) return(_st_data(i,j))
	else return(_st_sdata(i,j))
	}

//!type: stata
//!el_store: store either numeric or string data
//!i: obs
//!j: vars
//!a: data to store, or (if b is present) selectvar
//!b: data to store
stata("capture mata mata drop el_store()")
void el_store(real matrix i, rowvector j,matrix a,| matrix b) { //>>def func<<
	if (!truish(j)) j=1..st_nvar()
	jn=length(somevars(j,"n"))
	if (jn&jn!=length(j)) errel("el_store: cannot mix string and numeric vars")
	mstr=(args()==4?eltype(b):eltype(a))=="string"
	if (mstr&jn|!(mstr|jn)) errel("el_store: mata str/num must match stata str/num")
	
	if (args()==4) {
		for (v=1;v<=cols(j);v++) promote(tinytype(b[,v]),j[v]) 
		mstr?st_sstore(i,j,a,b):st_store(i,j,a,b)
		}
	else {
		for (v=1;v<=cols(j);v++) promote(tinytype(a[,v]),j[v]) 
		mstr?st_sstore(i,j,a):st_store(i,j,a)
		}
	}

//!type: stata
//!el_sdata: return all data as a string matrix
//!i: obs
//!j: varnames
//!select: selectvar
//!R: requested data
stata("capture mata mata drop el_sdata()")
matrix el_sdata(real matrix i, rowvector j,|scalar select) { //>>def func<<
	if (!truish(j)) j=1..st_nvar()
	jstr=vmap(somevars(j,"s"),j)
	jnum=vmap(somevars(j,"n"),j)
	if (length(jstr)) sdata=st_sdata(i,j[jstr],select)
	if (length(jnum)) {
		ndata=el_strof(st_data(i,j[jnum],select))
	//	x=st_data(i,j[jnum],select) //are you fucking kidding me?
	//	ndata=length(x)?strofreal(x,"%20.0g"):strofreal(x)
		}
	out=J(max((rows(sdata),rows(ndata))),cols(j),"")
	if (length(jstr)) out[,jstr]=sdata
	if (length(jnum)) out[,jnum]=ndata
	return(out)
	}

end
//>>mosave<<
*! 28apr2015
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: string
//!el_strof: return string version of string or numeric data
//!in: data
//!R: string
stata("capture mata mata drop el_strof()")
string matrix el_strof(matrix in) { //>>def func<<
	if (eltype(in)=="string") return(in)
	if (eltype(in)!="real") errel("el_strof: can only return string of string or real")
	if (!length(in)) return(J(rows(in),cols(in),""))
	
	return(strofreal(in,"%20.0g")) //best translation!
	}
end
//>>mosave<<
*! 27mar2014
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:
//!type: stata
//!el_view: return either numeric or string view
//!V: variable to be view
//!i: obs
//!j: varnames
//!select: selectvar
stata("capture mata mata drop el_view()")
void el_view(matrix V, real matrix i, rowvector j,|scalar select) { //>>def func<<
	if (!truish(j)) j=1..st_nvar()
	jstr=length(somevars(j,"s"))
	if (!st_nobs()) V=J(0,length(j),jstr?"":.) //won't be a view, though?
	//if (!length(j)) errel("el_view: variable refs required")
	jstr=length(somevars(j,"s"))
	if (!jstr) st_view(V=.,i,j,select) //init is only needed for interactive call
	else if (jstr!=length(j)) errel("el_data: cannot mix string and numeric vars")
	else st_sview(V=.,i,j,select)
	}

end
//>>mosave<<
*! 1feb2014
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:
//!type: stata
//!el_vlmap: get formatted/labeled values
//!name: varname to look up
//!vals: to map
//!R: mapped values; empty if name does not exist
stata("capture mata mata drop el_vlmap()")
string vector el_vlmap(string scalar name, real vector vals) { //>>def func<<
	if (!truish(varlist(name))) return(J(rows(vals),cols(vals),""))
	fmtd=strofreal(vals,st_varformat(name))
	lname=st_varvaluelabel(name)
	vlabd=st_vlmap(lname,vals)
	haslab=tru2(vlabd)
	return(vlabd:*haslab:+fmtd:*!haslab)
	}

end
//>>mosave<<
*!unknown
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata: 

//!type: trans
//!encode: gen real colvector from string
//!orig: to encode
//!key: returns 2col string matrix col1=sorted num, col2=orig str
//!wmiss: code missing string as 1 instead of missing
//!R: orig encoded as num
stata("capture mata mata drop encode()")
real vector encode(string colvector orig,| matrix key, matrix wmiss) { //>>def func<<
	o=order(orig,1)
	s=orig[o]
	d=differ(s,1,1)
	coded=runningsum(d)
	if (s[1]==""&!truish(wmiss)) coded=editvalue(coded:-1,0,.)
	key=strofreal(select(coded,d)),select(s,d)
	return(coded[order(o,1)])
	}

//!type: trans
//!encode2: encode multiple string matrices
//!sms: vector of string matrices; returned as encoded real matrices
//!R: list of distinct string values (in the proper index spot)
stata("capture mata mata drop encode2()")
string vector encode2(pointer vector sms) { //>>def func<<
	if (!length(sms)) return(J(0,1,""))
	pl=length(sms)
	sizes=J(pl,2,0)
	for (i=1;i<=pl;i++) sizes[i,]=length(*sms[i]),cols(*sms[i])
	all=J(sum(sizes[,1]),1,"")
	j=0
	for (i=1;i<=pl;i++) {
		if (sizes[i,1]) all[j+1..j+sizes[i,1]]=colshape(*sms[i],1)
		j=j+sizes[i,1]
		}
	back=encode(all,k,1) //m as 1 because findd will have a:-b, need non-missing
	j=0
	for (i=1;i<=pl;i++) {
		if (sizes[i,1]) sms[i]=&colshape(back[j+1..j+sizes[i,1]],sizes[i,2])
		else sms[i]=&strtoreal(*sms[i])
		j=j+sizes[i,1]
		}
	return(k[,2])
	//return(cut(k[,2],2*(k[1,2]=="")))
	}
	

end
//>>mosave<<
*!unknown
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.1
mata:

//!type: trans
stata("capture mata mata drop eol()")
string scalar eol(|real scalar mult) { //>>def func<<
	if (mult==.| mult<0) mult=1
	return(mult*((c("os")=="Windows")*char(13)+char(10)))
	}

end
//>>mosave<<
*! 27oct2010
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.1
mata: 

//!type: debug
//!errel: exit with error. trace_el=el turns on traceback
//!errtxt: text to display
//!details: data to display below text
//!errnum: error number to use
stata("capture mata mata drop errel()")
void errel(string vector errtxt, | matrix details, real scalar errnum) { //>>def func<<
	if (args()<3) errnum=77
	displayas("err")
	display(errtxt)
	if (args()>1) show(details)
	if (truish(st_global("el_trace"))) _error(errnum)
	exit(errnum)
	}

end
//>>mosave<<
*! 8apr2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: config
//!expand: set min # of rows & colums; neg mins specify expansion up/left
//!in: matrix to alter
//!minr: (-)min rows
//!minc: (-)min columns;
//!R: in,expanded and filled with missing. If an input is specified with no expansions, it'll be expanded to a scalar
stata("capture mata mata drop expand()")
matrix expand(matrix in, real scalar minc,| real scalar minr) { //>>def func<<
	_editmissing(minr,0)
	_editmissing(minc,0)
	out=J(pmax(rows(in),abs(minr)),pmax(cols(in),abs(minc)),missingof(in))
	if (length(in)) {
		a=1+(minr<0)*(rows(out)-rows(in))
		b=1+(minc<0)*(cols(out)-cols(in))
		c=minr<0?rows(out):rows(in)
		d=minc<0?cols(out):cols(in)
		out[|a,b\c,d|]=in
		}
	return(out)
	}
end
//>>mosave<<
*! revised from version 1.0.0  01nov2004
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
*! 3nov2010
version 11.1
mata:

//!type: file
stata("capture mata mata drop fexists()")
real scalar fexists(string scalar filepath) { //>>def func<<
	if (filepath=="") return(0)
	if ((fd = _fopen(filepath, "r")) >= 0) {
		fclose(fd) 
		return(1) 
		}
	return(0)
	}

end
//>>mosave<<
*!unknown separated 9jun2015
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: file
//!fin_dta: read datafile into string matrix
//!path: filepath of dta file
//!varnames: if a var is supplied, it will return varnames. If not empty, vars read will be limited
//!R: data as string matrix
stata("capture mata mata drop fin_dta()")
string matrix fin_dta(string scalar path,|string vector varnames) { //>>def func<<
	class dataset_dta scalar ds
	ds.with("data")
	ds.readfile(path)
	vars=ds.varlist(varnames,"all")
	varnames=ds.vnames[vars]
	return(ds.strdat(.,vars))
	}

end
//>>mosave
*! 10apr2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: file
//!fin_lmat: read lmat file
//!path: to read
//!errtext: id info for error messages
//!R: data
stata("capture mata mata drop fin_lmat()")
pointer vector fin_lmat(string scalar path,| string scalar errtext) { //>>def func<<
	if (c("stata_version")>=14) fn=pcanon(regexr(strtrim(path),"\.lmat$",".lmat2"),"fex","lmat2")
	else fn=pcanon(path,"fex","lmat")
	if ((fh = _fopen(fn, "r"))<0) _error(603,"file "+fn+" could not be opened for input\n")
	out=J(1,0,NULL)
	do {
		out=out,&_fgetmatrix(fh)
		if (fstatus(fh)<-1) {
			errprintf("lmat: error reading %s from file %s\n", errtext, fn) 
			fclose(fh)
			exit(692)
			}
		} while (!fstatus(fh))
	fclose(fh)
	return(cut(out,1,-2))
	}
end
//>>mosave<<

*! 1feb2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: file
//!fin_sttr_html: read in a StatTransfer HTML table
//!path: path to file to read
//!heads returns column headers
//!R: parsed file
stata("capture mata mata drop fin_sttr_html()")
string matrix fin_sttr_html(string scalar path,| string vector heads) { //>>def func<<
	a=ftostr(pcanon(path,"fex",".html"))
	a=substr(a,strpos(a,">")+1)
	a=substr(a,strpos(a,">")+1)
	a=subinstr(a," ALIGN=RIGHT","")
	a=subinstr(a," ALIGN=LEFT","")
	a=subinstr(a,"<TR> ","")
	a=columnize(a,"<BR></TD>"+eol())'
	heads=columnize(substr(a[1,],strpos(a[1,],"<TH>")),"<TH> ")
	body=columnize(a[2..rows(a)-1,],"<TD> ")
	return(body)
	}
end
//>>mosave<<
*! 24nov2014
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
if (c(stata_version)>=13) {
version 13
mata:

//!type: file
//!fin_xl: import from excel file
//!path: file path
//!pass: options for portel_xl; col:ors+filepath, dcolor=create dummy color columns, allcolor=create color columns for all data columns
stata("capture mata mata drop fin_xl()")
void fin_xl(string scalar path,| string scalar pass) { //>>def func<<
	class xl scalar xlf
	sufvl="_vl"
	suftc="_tc"
	sufbc="_bc"
	
	optionel(pass,(&(wcolor="col:ors+"),&(dcolor="dcolor"),&(allcolor="allcolor"),&(non="non:names"),&(ncase="case=")),pass)
	pass=expand(pass,1)
	first=truish(non)?"":"first"
	ncase=truish(ncase)?ncase:"case(l)"
	
	pp=pathparts(path,(12,3))
	xls=pp[2]==".xls"
	if (!fexists(path=pcanon(pp[1]+(xls?".xls":".xlsx")))) {
		if (!fexists(pcanon(pp[1]+(xls?".xlsx":".xls")))) errel("Excel file not found",path)
		path=pcanon(pp[1]+(xls?".xlsx":".xls"))
		}
	stata(sprintf(`"import exc "%s", clear %s %s %s"',path,first,ncase,pass))
	
	vars=varlist("*")
	//nvars=somevars(varlist("*"),"n")
	vlvars=vmap(vars,vars:+sufvl):*strvars(vars)
	//vlvars=vmap(subinstrf(somevars(varlist(nvars:+sufvl,"nfok"),"s"),sufvl,""),nvars,"only")
	if (truish(vlvars)) {
		for (vl=1;vl<=length(vlvars);vl++) {
			if (vlvars[vl]) {
				nvar=vars[vlvars[vl]]
				//			nvar=nvars[vlvars[vl]]
				both=uniqrows(el_sdata(.,(nvar,nvar+sufvl)))
				if (rows(uniqrows(both[,1]))<rows(both)) errel("A number cannot map to more than one label")
				st_vlmodify(nvar+"_xl",strtoreal(both[,1]),both[,2])
				st_varvaluelabel(nvar,nvar+"_xl")
				st_dropvar(nvar+sufvl)
				}
			}
		}
	
	xlf.load_book(path)
	sheets=xlf.get_sheets()
	if (length(sheets)>1&length(csheet=toindices(sheets:=="characteristics"))==1) {
		xlf.set_sheet("characteristics")
		stata(sprintf(`"qui import exc "%s", describe"',path)) //motherfuckers
		range=tokel(st_global(sprintf("r(range_%f)",csheet)),":")
		mf=strtoreal(regexs2(range[2],"[0-9]+",0))
		vars=varlist("*")
		sheet=xlf.get_string((1,mf),(1,length(vars)+2))
		vars="_dta",varlist(cut(sheet[1,],3),"nfok","",nf="")
		if (truish(nf)) errel("Some characteristics refer to non-existent variables",sheet[1,])
		for (c=2;c<=mf;c++) charset(vars,sheet[c,1],cut(sheet[c,],2))
		}
	
	if (dcolor) { //dummy color columns, for meta only
		vars=varlist("*")
		if (truish(vars)) { //here??
			vix=st_addvar("byte",vars:+sufbc)
			charset(vix,"@nlab","cell color of ":+vars)
			vix=st_addvar("byte",vars:+suftc)
			charset(vix,"@nlab","text color of ":+vars)
			}
		}
	else if (wcolor) {
		optionel(pass,(&(dsheet="sh:eet="),&(rng="cellra:nge=")))
		//still gotta use sheet & range in vbs
		if (*wcolor=="1") ctextpath=xlmread(path)
		else ctextpath=*wcolor
		xlcolors=strtoreal(cut(columnize(cat(ctextpath),",")',2))'
		//	xlcolors=strtoreal(cut(columnize(cat(cget),",")',2))'
		vn=st_nvar()
		if (cols(xlcolors)!=2*(vn-sum(vlvars))) {
			stata(`"di "color columns did not match""')
			printf("{err:Colors were not read:} {txt:Color columns (%f) did not match variables (%f)}",cols(xlcolors)/2,vn-sum(vlvars))
			return
			}
		if (rows(xlcolors)!=st_nobs()) {
			stata(`"di "color rows did not match""')
			printf("{err:Colors were not read:} {txt:Color rows did not match observations}")
			return
			}
		xlcolors=select(xlcolors,vec(J(2,1,!vlvars))') //nonvlvars
		bcolors=xlcolors[,rangel(1,vn*2,2)]
		tcolors=xlcolors[,rangel(2,vn*2,2)]
		vars=varlist("*")
		cvars=allcolor?st_varindex(vars):toindices(colmax(bcolors:!=16777215))
		if (truish(cvars)) {
			vix=st_addvar("long",vars[cvars]:+sufbc)
			charset(vix,"@nlab","cell color of ":+vars[cvars])
			el_store(.,vix,bcolors[,cvars])
			}
		cvars=allcolor?st_varindex(vars):toindices(colmax(tcolors:!=0))
		if (truish(cvars)) {
			vix=st_addvar("long",vars[cvars]:+suftc)
			charset(vix,"@nlab","text color of ":+vars[cvars])
			el_store(.,vix,tcolors[,cvars])
			}
		}
	}

end
//>>mosave<<
}
else {
version 11
mata:
void fin_xl() { 
	errel("fin_xl requires stata v13")
	}
end
}
*! 5dec2014
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: stata
//!finds: find data from class dataset
//!kvlist: key var list
//!bb: class dataset
//!ifin: ifin
//!cvlist: copy var list
//!flags: d:istinct, comp:lement, exp:and, one:find, orep:lace, picky, isdta, priv:ate
//!pass: for external file handlers
stata("capture mata mata drop findds()")
void findds(string scalar kvlist, class dataset scalar bb,| string scalar ifin, string vector cvlist, string vector flags, string scalar pass) { //>>def func
	//general problem that this uses tempvars, which will not be dropped if this is called from mata
	class errtab scalar et
	class tabel scalar t
	
	if (bb.nobs==0) {
		printf("{txt:No data in external file}\n")
		return
		}
	optionel(flags,(&(distinct="d:istinct"),&(comp="comp:lement"),&(expand="exp:and"),&(onef="one:find"), &(norep="norep:lace"),&(picky="picky"),&(isdta="isdta"),&(priv="priv:ate")))
	
	kvars=varlist(kvlist,"",kpair="pair(=)")
	cvars=bb.varlist(cvlist,"nfok",cpair="pair(->)")
	//cvars=cvars[,vmap(bb.vnames[cvars[1,]],firstof(cut(kvars',2)'\kvars[,1]),"not")]
	bb.shrink("k",(bb.varlist(firstof(kpair\kvars)),cvars)) //this is destructive, but think it's used for var order
	cvars=bb.varlist(cvlist,"nfok",cpair="pair(->)")
	cvnk=vmap(bb.vnames[cvars],firstof(kpair\kvars),"not")
	cvars=cvars[cvnk]
	cpair=cpair[cvnk]
	bbdata=J(bb.nobs,bb.nvars,.)
	
	aacvs=firstof(cpair\bb.vnames[cvars])
	
	aadrop=varlist(aacvs,"nfok noab")
	if (truish(aadrop)&norep) errel("Existing variables would be replaced",aadrop)
	aavars=aanvars=varlist(kvars[1,]),aacvs
	ovars=varlist("*")[vmap(varlist("*"),aavars,"not")]
	kn=cols(kvars)
	vn=bb.nvars
	settouse(touse,ifin)
	el_view(hasobs=.,.,aavars[1],touse)
	if (!length(hasobs)) {
		printf("{txt:No observations selected}\n")
		return
		}
	
	(void) et.newtab("Could not convert keyvar to numeric",("Data","Variable"))
	for (v=1;v<=kn;v++) {
		if (st_isstrvar(aavars[v])) {
			if (bb.sirtypes[v]!="s") {
				stata(sprintf("qui gen double %s=real(%s)",aatmp=st_tempname(),aavars[v]))
				stata(sprintf("qui count if mi(%s) & !mi(%s)",aatmp,aavars[v]))
				if (st_numscalar("r(N)")) et.newerr(("Current",aavars[v]))
				aanvars[v]=aatmp
				}
			}			
		else if (bb.sirtypes[v]=="s") {
			err1=_strtoreal(*bb.data[v],ndat)
			if (err1) et.newerr(("External",bb.vnames[v]))
			bbdata[,v]=ndat
			bb.sirtypes[v]="sn" //!
			}
		}
	et.present()
	
	strvars=J(1,0,NULL)
	aastr=toindices(strvars(aanvars[1..kn]))
	bbstr=toindices(bb.sirtypes:=="s")
	if (truish(aastr)) strvars=strvars,&strstd(el_data(.,aavars[aastr],touse),picky)
	//if (truish(aastr)) strvars=strvars,&picky(picky,el_data(.,aavars[aastr],touse))
	if (truish(bbstr)) strvars=strvars,&strstd(bb.strdat(.,bbstr),picky)
	skey=encode2(strvars)
	if (truish(bbstr)) bbdata[,bbstr]=*strvars[cols(strvars)]
	if (truish(aastr)) {
		nvars=J(2,cols(*strvars[1]),"")
		nvars[1,]=st_tempname(cols(nvars))
		for (v=1;v<=cols(nvars);v++) nvars[2,v]=tinytype((*strvars[1])[,v])
		(void) st_addvar(nvars[2,],nvars[1,])
		el_store(.,nvars[1,],touse,*strvars[1])
		aanvars[aastr]=nvars[1,]
		}
	for (v=1;v<=vn;v++) if (!strpos(bb.sirtypes[v],"s")) bbdata[,v]=*bb.data[v]
	//bb.data=NULL // I want to use it again!
	
	stata(sprintf("qui sort %s",touse+" "+concat(cut(aanvars,1,kn)," ")))
	if (distinct) bbdata=uniqrows(bbdata)
	else _sort(bbdata,1..kn)
	el_view(aakdat,.,aanvars[1..kn])
	dontuse=truish(touse)?sum(!el_data(.,touse)):0
	aam=0\toindices(colsum(cut(aakdat',2+dontuse,.,.,"m"):!=cut(aakdat',1+dontuse,-2,.,"m")))'\rows(aakdat)-dontuse
	aam=aam:+dontuse
	bbm=0\toindices(colsum(cut(bbdata[,1..kn]',2,.,.,"m"):!=cut(bbdata[,1..kn]',1,-2,.,"m")))'\rows(bbdata)
	aan=rows(aam)
	bbn=rows(bbm)
	aamap=J(st_nobs(),3,0)
	bbadd=1::rows(bbdata)
	aai=bbi=2
	while (aai<=aan&bbi<=bbn) {
		if (aakdat[aam[aai],]==bbdata[bbm[bbi],1..kn]) {
			aaix=aam[aai-1]+1::aam[aai++]
			bmult=bbm[bbi]-bbm[bbi-1]
			aamap[aaix,]=aaix,J(rows(aaix),1,(bbm[bbi],bmult))
			bbix=bbm[bbi-1]+1::bbm[bbi]
			bbadd[bbix]=J(bmult,1,0)
			}
		else if (firstof(bbdata[bbm[bbi],1..kn]:-aakdat[aam[aai],],.,0)<0) bbi++
		else aai++
		}
	
	aamap=select(aamap,aamap[,1])
	cmdvars("","findd")
	(void) st_addvar(tinytype(aamap[,3]),fnd="_found")
	cmdvars(fnd,"findd")
	stata(sprintf("qui replace %s=0",fnd))
	if (truish(touse)) {
		stata(sprintf("qui replace %s=.e if! %s",fnd,touse))
		st_dropvar(touse) //think it's done here
		}
	el_store(aamap[,1],fnd,aamap[,3])
	
	//actual return values set after other stata commands
	rcomptot=truish(bbadd)
	radd= vn>kn?concat(aavars[vmap(aavars[kn+1..vn],aadrop,"not"):+kn]," "):""
	rrep=concat(aadrop," ")
	
	if (!priv) {
		t.body="Find on:",concat(aavars[1..kn]," ")\"Add:",radd\"Replace:",rrep
		t.set(t._class,.,1,"heading")
		t.set(t._align,.,2,t.left)
		t.set(t._wrap,.,.,0)
		t.render()
		
		tfreq=freq(fnd)[,(2,1)]
		tfreq=tfreq,tfreq[,1]:*tfreq[,2]
		many=toindices(tfreq[,2]:>1:&tfreq[,2]:<.)
		if (!expand) tfreq[many,3]=tfreq[many,1]
		t.body=J(6+pmax(rows(many),1),4,"")
		tr=rows(t.body)
		t.body[1,2..4]="n"+char(10)+"then",fnd,"n"+char(10)+"now"
		t.body[(2..5,tr-1,tr),1]="Excluded"\"Found None"\"Found One"\"Found Many"\"Complement"\"Total"
		if (tfreq[rows(tfreq),2]==.e) {
			tfreq[rows(tfreq),3]=tfreq[rows(tfreq),1]
			t.body[2,2..4]=strofreal(tfreq[rows(tfreq),],"%12.0gc")
			}
		if (tfreq[1,2]==0) {
			tfreq[1,3]=tfreq[1,1]
			t.body[3,2..4]=strofreal(tfreq[1,],"%12.0gc")
			}
		if (truish(bit=select(tfreq,tfreq[,2]:==1))) t.body[4,2..4]=strofreal(bit,"%12.0gc")
		if (truish(many)) t.body[5..tr-2,2..4]=strofreal(tfreq[many,],"%12.0gc")
		t.body[tr-1,2]="("+strofreal(rcomptot,"%12.0gc")+")"
		if (comp) t.body[tr-1,3..4]=".c",strofreal(rcomptot,"%12.0gc")
		t.body[tr,(2,4)]=strofreal(colsum(tfreq[,(1,3)]):+(0,comp*rcomptot),"%12.0gc")
		t.head=1
		t.stub=1
		t.set(t._class,tr-1,2,"heading")
		t.set(t._hline,rows(t.body)-1,.,t.Lmajor)
		t.present("-")
		}
	
	if (onef&rows(uniqrows(aamap[,2]))<rows(aamap)) errel(sprintf("More than one record found the same match. Examine duplicates on (%s) where %s>1",concat(aavars[1..kn]," "),fnd))
	bbmlt=select(aamap,aamap[,3]:>1):-(0,0,1)
	if (!expand&vn>kn&rows(bbmlt)) errel(sprintf("%f records had %s>1",rows(bbmlt),fnd))
	bbadd=comp?select(bbadd,bbadd):J(0,1,0)
	
	if (truish(aadrop)) st_dropvar(aadrop)
	if (vn>kn) {
		(void) st_addvar(othtypes(bb.sirtypes[kn+1..vn],bb.bytes[kn+1..vn]),aavars[kn+1..vn])
		stata(sprintf("order %s, last",fnd))
		}
	for (v=1;v<=kn;v++) if (aanvars[v]!=aavars[v]) {
		stata(sprintf("qui destring %s, replace",aavars[v]))
		st_dropvar(aanvars[v]) //mata won't drop tempvars
		}
	arows=st_nobs():+(1,rows(bbadd))
	st_addobs(rows(bbadd)+expand*sum(bbmlt[,3]))
	if (rows(bbadd)) stata(sprintf("qui replace %s=.c in %f/%f",fnd,arows[1],arows[2]))
	
	sdec=bb.sirtypes:=="s"
	for (v=kn+1;v<=vn;v++) {
		tostore=sdec[v]?lookupin(skey,bbdata[aamap[,2],v]):bbdata[aamap[,2],v]
		el_store(aamap[,1],aavars[v],tostore)
		}
	if (truish(bbadd)) {
		for (v=1;v<=vn;v++) {
			tostore=sdec[v]?lookupin(skey,bbdata[bbadd,v]):bbdata[bbadd,v]
			el_store(arows,aavars[v],tostore)
			}
		}
	if (expand&truish(bbmlt)) {
		mrs=st_nobs()+1,.
		for (m=rows(bbmlt);m>=1;m--) {
			mrs=mrs[1]:-(bbmlt[m,3],1)
			el_store(mrs,fnd,J(bbmlt[m,3],1,bbmlt[m,3]+1))
			for (v=1;v<=kn;v++) el_store(mrs,aavars[v],J(bbmlt[m,3],1,el_data(bbmlt[m,1],aavars[v])))
			for (v=1;v<=cols(ovars);v++) el_store(mrs,ovars[v],J(bbmlt[m,3],1,el_data(bbmlt[m,1],ovars[v])))
			for (v=kn+1;v<=vn;v++) {
				tostore=sdec[v]?lookupin(skey,bbdata[bbmlt[m,2]-bbmlt[m,3]..bbmlt[m,2]-1,v]):bbdata[bbmlt[m,2]-bbmlt[m,3]..bbmlt[m,2]-1,v]
				el_store(mrs,aavars[v],tostore)
				}
			}
		}
	fndvals=uniqrows(el_data(.,fnd))
	//if (rows(fndvals)-(cut(fndvals,-1)==.e)==1) st_dropvar(fnd)
	
	//consider making this general somehwere else
	if (vn>kn) lnames=vlabnames(aavars[kn+1..vn],bb.vlabrefs[kn+1..vn])
	for (v=kn+1;v<=vn;v++) { 
		ochars=select(bb.chars[,2..3],bb.chars[,1]:==bb.vnames[v])
		charset(aavars[v],"@nlab"\"@form"\ochars[,1],bb.nlabels[v]\bb.formats[v]\ochars[,2])
		labs=bb.labelsof(v)
		if (truish(labs)) {
			charset(aavars[v],"@vlab",lnames[v-kn])
			st_vlmodify(lnames[v-kn],strtoreal(labs[,1]),labs[,2])
			}
		}
	stata(sprintf("qui sort %s",concat(cut(aavars,1,kn)," ")))
	
	st_rclear()
	st_numscalar("r(complement)",rcomptot)
	st_global("r(added)",radd)
	st_global("r(replaced)",rrep)
	}

//!type: stata
//!finddta: find data from physical file
//!kvlist: key var list
//!bbpath: external filepath
//!ifin: ifin
//!cvlist: copy var list
//!flags: d:istinct, comp:lement, exp:and, one:find, orep:lace, picky, isdta, priv:ate
//!pass: for external file handlers
stata("capture mata mata drop finddta()")
void finddta(string scalar kvlist, string scalar bbpath,| string scalar ifin, string vector cvlist, string vector flags, string scalar pass) { //>>def func
	class dataset_dta scalar bb
	class recentle_data scalar rld
	
	optionel(flags,&(isdta="isdta"),flags)
	bb.with("d l c")
	bb.readfile(pcanon(bbpath,"file",".dta"),isdta?"isdta":pass)
	findds(kvlist,bb,ifin,cvlist,expand(flags,1),pass)
	
	rld.ncmd="findd"
	rld.parse(bbpath,kvlist,ifin,pass)
	rld.add("other")
	}

end
//>>mosave<<
*! 16aug2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.1
mata:
//!type: select
//!firstof: select first non-empty bit
//!input: stuff to select from
//!row: if present, specifies that an entire first row should be returned
//!empty: the value to treat as empty; defaults to 'missing'
//!R: for matrix inputs: a row conatining the first non-empty cell in each column. For vector inputs, the first non-empty cell, unless [row] is set, in which case rowvectors return themselves.
stata("capture mata mata drop firstof()")
vector firstof(matrix input,| scalar row, matrix empty) { //>>def func<<
	str=eltype(input)=="string"
	if (!length(empty)) empty=missingof(input)
	else if (eltype(input)!=eltype(empty)) errel("firstof: element types of arguments must match.")
	if (strpos(orgtype(input),"vector")&!truish(row)) next=colshape(input,1)
	else next=input
	if (str) {
		if (strlen(empty)) comp=strlen(subinstr(next:+char(26):*(next:==""),empty,""))
		else comp=strlen(next)
		}
	else if (empty!=0) comp=recode(next,(0,(empty==1?2:1)\empty,0))
	else comp=next
	out=J(1,cols(next),empty)
	for (c=1;c<=cols(next);c++) {
		x=select(next[,c],comp[,c])
		if (length(x)) out[c]=x[1]
		}
	return(out)
	}
end
//>>mosave<<
*! 10apr2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: file
//!fout_lmat: write mata matrices
//!path: path, ext optional
//!data: to be written
//!errtext: id info in case of error
stata("capture mata mata drop fout_lmat()")
void fout_lmat(string scalar path, pointer vector data,| string scalar errtext) { //>>def func<<
	fn=pcanon(path,"f","lmat")
	if (c("stata_version")>=14) fn=regexr(fn,"\.lmat$",".lmat2")
	if (_unlink(fn)<0) _error(693,"file "+fn+" could not be replaced\n")
	if ((fh = _fopen(fn, "w"))<0) _error(603,"file "+fn+" could not be opened for output\n")
	for (d=1;d<=length(data);d++) {
		if (_fputmatrix(fh,*data[d])<0) {
			errprintf("lmat: error writing %s to file %s\n",errtext,fn) 
			fclose(fh)
			unlink(fn)
			exit(693)
			}
		}
	fclose(fh)
	}
end
//>>mosave<<
*! 24nov2014
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
if (c(stata_version)>=13) {
version 13
mata:
end
 global writecolor (`"!#&*+,-Set objExcel = CreateObject("Excel.Application")*objExcel.DisplayAlerts = 0*objExcel.Workbooks.open "%%xlspath%%"**Set csheet = objExcel.ActiveWorkbook.Worksheets(1)*%%loops%%*objExcel.ActiveWorkbook.SaveAs "%%xlspath%%"*objExcel.Quit"')
 mata:
end
 global wloop (`"!"#&*+-For row = 2 to %%nobs%%&csheet.cells(row,%f).%s.color=csheet.cells(row,%f).value&Next&csheet.Columns(%f).delete"')
 mata:

//!type: file
//!fout_xl: export to excel file
//!path: file path
//!pass: stata export params, el= add pass to el
stata("capture mata mata drop fout_xl()")
void fout_xl(string scalar path,| string scalar pass) { //>>def func<<
	class xl scalar xlf
	class dataset scalar ds
	sufvl="_vl"
	suftc="_tc"
	sufbc="_bc"
	
	optionel(pass,(&(wcolor="c:olors"),&(xls="xls"), &(da="date:string="),&(mi="miss:ing="),&(lo="locale=")))
	ds.with("l c")
	ds.readmem()
	dnames=ds.vnames
	if (truish(labd=toindices(ds.vlabrefs))) { //add vl tvars, and varnames for xl data
		dnames[labd]=dnames[labd]:+" ":+dnames[labd]:+sufvl
		dnames=tokel(dnames)
		vlabs=st_tempname(ln=length(labd))
		for (v=1;v<=ln;v++) {
			stata(sprintf("decode %s, gen(%s)",ds.vnames[labd[v]],vlabs[v]))
			stata(sprintf("order %s, after(%s)",vlabs[v],ds.vnames[labd[v]]))
			}
		}
	//chars, excluding color vars & vl vars
	if (wcolor) { //get vmaps for color vars in xl file
		bc=vmap(dnames:+sufbc,dnames,"both")
		tc=vmap(dnames:+suftc,dnames,"both")
		chvars="_dta",ds.vnames[vmap(ds.vnames,(dnames[bc[,2]],dnames[tc[,2]]),"not")]
		}
	else chvars="_dta",ds.vnames
	chars="@nlab"\"@form"\uniqrows(ds.chars[,2])
	chsheet=J(rows(chars),cols(chvars),"")
	for (c=1;c<=length(chars);c++) chsheet[c,]=charget(chvars,chars[c])
	//drop empty ones?
	
	path=pathparts(path,12)+(xls?".xls":".xlsx")
	p2=adorn("date(",da,") ")+adorn("miss(",mi,") ")+adorn("locale(",lo,")")
	stata(sprintf(`"export exc "%s", replace first(var) nolabel sheet(data) %s"',path,p2))
	xlf.load_book(path)
	if (truish(labd)) xlf.put_string(1,1,dnames)
	xlf.add_sheet("characteristics")
	xlf.put_string(1,2,chvars)
	xlf.put_string(2,1,chars)
	xlf.put_string(2,2,chsheet)
	
	if (wcolor) {
		script=subinstr(strob_to($writecolor),"%%xlspath%%",path)
		aloop=subinstr(strob_to($wloop),"%%nobs%%",strofreal(st_nobs()+1))
		types=J(rows(bc),1,"Interior")\J(rows(tc),1,"Font")
		cols=bc\tc
		cosort_((&types,&cols),(2,2))
		loops=""
		for (l=rows(types);l>0;l--) sput(loops,sprintf(aloop,cols[l,1],types[l],cols[l,2],cols[l,2]))
		
		script=subinstr(script,"%%loops%%",loops)
		fowrite(vbpath=pathto("_xlcolors.vbs"),script)
		stata("shell "+vbpath)
		}
	
	}
end
//>>mosave<<
}
else {
version 11
mata:
void fout_xl() { 
	errel("fout_xl requires stata v13")
	}
end
}

*!unknown v10.1
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
if (c(stata_version)>=14) {
	global dchar=uchar(183)
	}
else global dchar=char(183)


version 11
mata:

//!type: file
//!fowrite: write to disk
//!path: file path
//!matter: stuff to write
//!mode: ow|a|v; defaults to ow; (overwrite, append, version)
stata("capture mata mata drop fowrite()")
void fowrite(string scalar path, string scalar matter, | string scalar mode) { //>>def func<<
	//class giantrobot scalar gr
	
	mode=firstof(mode\"ow")
	if (!anyof(("a","ow","v"),mode)) errel("write mode must be ow (overwrite), a (append), or v (version)")
	path=pcanon(path,"fexists"*(mode=="a"))
	if (mode=="a") f=fopen(path,"a")
	else {
		if (mode=="v"&fexists(path)) {
			pp=pathparts(path,(2,3))
			dt=subinstr(subinstr(datetime()," ","  "),":","$dchar"/*char(183)*/)
			stata(sprintf(`"shell ren "%s" "%s [%s]%s""',path,pp[1],dt,pp[2]))
	//		stata(sprintf(`"copy "%s" "%s [%s]%s""',path,pp[1],dt,pp[2]))
			}
		unlink(path)
		f=fopen(path,"w")
		}
	//gr.mark(f,gr.forclosing)
	e1=_fwrite(f,matter)
	e2=_fclose(f)
	if (e1|e2) {
		rmexternal("errfile")
		ef=crexternal("errfile")
		*ef=f
		}
	if (e1) errel("There was a problem writing to the file ("+path+")")
	if (e2) errel("There was a problem closing the file ("+path+")")
	}

end
//>>mosave<<
*! 26apr2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.1
mata:

//!type: stata
//!freq: crosstab frequencies of vars
//!varlist: vars to tabulate
//!touse: varname
//!zeros: 1=expand to include zeros for final (column) var; other true=expand to include all var combos
//!weight: varname of freq weight variable
stata("capture mata mata drop freq()")
real matrix freq(string vector varlist, | string scalar touse, real scalar zeros, string scalar weight) { //>>def func<<
	d=st_data(.,varlist,touse)
	if (haswt=strlen(weight)) w=st_data(.,weight,touse)
	if (rows(d)==0) return(J(0,cols(d)+1,.))
	dc=cols(d)
	if (haswt) { //I am so unsure about speed implications...
		o=order(d,1..dc)
		d=d[o,]
		w=w[o]
		}
	else _sort(d,1..dc)
	
	stub=uniqrows(d)
	freqs=J(rows(stub),1,0)
	
	d=d\!d[rows(d),]
	start=f=1
	if (haswt) { //again, what's the speed diff?
		for(i=2;i<=rows(d);i++) {
			if (d[i,]!=d[i-1,]) {
				freqs[f++]=sum(w[start..i-1])
				start=i
				}
			}
		}
	else {
		for(i=2;i<=rows(d);i++) {
			if (d[i,]!=d[i-1,]) {
				freqs[f++]=i-start
				start=i
				}
			}
		}
	
	if (!truish(zeros)) return((stub,freqs))
	else {
		st2=uniqrows(stub[,dc])
		if (zeros==1) st2=pairs(uniqrows(stub[,1..dc-1]),st2)
		else for (c=dc-1;c>=1;c--) st2=pairs(uniqrows(stub[,c]),st2)
		fr2=editmissing(lookupin(freqs,vmap(concat(strofreal(st2,"%13.0f"),"-"),concat(strofreal(stub,"%13.0f"),"-"))),0)
		//should have some kind of error message if the number is more than 13 places?
		return((st2,fr2))
		}
	}

end
//>>mosave<<
*! unknown
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.1
mata:

//!type: file
stata("capture mata mata drop ftostr()")
string scalar ftostr(string scalar path,| real scalar k) { //>>def func<<
	fh  = _fopen(path, "r")
	if (fh<0) {
		printf("{err:*}{txt:file not found: %s}\n",path)
		return("")
		}
	out=fread(fh,1000*firstof(k\10000))
	fclose(fh)
	if (!length(out)) out=""
	return(out)
}

end
//>>mosave<<
*!6may2015
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: numeric
//!gcdist: great circle distance
//!latlon1: 2col matrix of lat/lon in digital degrees
//!latlon2: 2col matrix of lat/lon in digital degrees
//!R: col vector of distances in miles
stata("capture mata mata drop gcdist()")
real vector gcdist(real matrix latlon1, real matrix latlon2) { //>>def func<<
	rlatlon1=latlon1*c("pi")/180
	rlatlon2=latlon2*c("pi")/180
	hdif=(rlatlon2:-rlatlon1)/2
	a = sin(hdif[,1]):^2:+cos(rlatlon1[,1]):*cos(rlatlon2[,1]):*sin(hdif[,2]):^2
	c = 2*asin(rowmin((J(rows(a),1,1),sqrt(a)))) //rowmin deals with rounding error for near-antipodal points
	d = /*radius of earth in miles*/3959*c
	return(d)
	}

end
//>>mosave<<
*! 3dec2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:
//!type: gears
//!inst_name: return instanced file name or prefs name
//!fname: file name; empty for prefs name
//!switch: 1/0 do or don't add id (to file)
//!R: adjusted file name, or prefs name
stata("capture mata mata drop inst_name()")
string scalar inst_name(|string scalar fname, real scalar yn) { //>>def func<<
	iid=st_global("EL_INST")
	if (truish(fname)) {
		if (yn==0|iid==""|iid=="1") return(fname)
		else return(fname+"_"+iid)
		}
	else return("")
	}
end
//>>mosave<<
*! 16may2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: config
//!kaleid: rowshape by super-column
//!field: to arrange
//!h: seq cols to chunk
//!v: chunks to row down
//!rev: reverse
//!R: re-arranged matrix
stata("capture mata mata drop kaleid()")
matrix kaleid(matrix field, real scalar h, real scalar v,|matrix rev) { //>>def func<<
	if (h<1|v<2) return(field)
	if (truish(rev)) {
		if (rows(field)<2|cols(field)<1) return(field)
		a=riffle(rangel(1,cols(field)*v,h),cols(field)/h,"r")
		b=rowshape((0..h-1):+J(1,h,a),1)
		return(colshape(field,cols(field)*v)[,b])
		}
	else {
		if (rows(field)<1|cols(field)<2) return(field)
		a=riffle(rangel(1,cols(field),h),v,"r")
		b=rowshape((0..h-1):+J(1,h,a),1)
		return(rowshape(field[,b],rows(field)*v))
		}
	}
end
//>>mosave<<

*! 19nov2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:
//!type: file
//!launchfile: launch another file in os
//!path: filepath; a little klugy, but in can include: ","parameter
//!opts: w:ait, d:irect; no direct=invoke explorer.exe)
stata("capture mata mata drop launchfile()")
void launchfile(string scalar path,| string scalar opts) { //>>def func<<
	//many problems with network drive polling. Including explicit explorer seems to do it
	//don't know about other os'es!
	//printf(path)
	ospath=subinstr(path,"/",dirsep())
	if (c("os")=="MacOSX") stata("shell open "+ospath)
	else if (c("os")=="Windows") {
		if (truish(st_global("el_fkluge"))) opts="w d" //fixes no vpn connection!
		optionel(opts,(&(wait="w:ait"),&(direct="d:irect")))
		cmd=wait?"shell":"winexec"
		launcher=!direct?"explorer.exe":""
		stata(sprintf(`"%s  %s "%s""',cmd,launcher,ospath))
		}
	else printf("don't know a generic launch command for linux")
	}
end
//>>mosave<<

*! 15aug2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: select
//!lookupin: get values from a vector, using indices stored in a matrix. out-of-range indices return missing.
//!ref: the vector of lookup-values
//!ixs: the indices into <ref>
//!R: matrix of <ixs> dimensions, holding values from <ref>, or missing.
stata("capture mata mata drop lookupin()")
matrix lookupin(vector ref, real matrix ixs) { //>>def func<<
	ixs1=editmissing(ixs,0)
	ixs1=colshape(ixs1:*(ixs1:>0):*(ixs1:<=length(ref)):+1,1)
	ref1=missingof(ref),rowshape(ref,1)
	return(colshape(ref1[ixs1],cols(ixs)))
	}
end
//>>mosave<<
*! 6dec2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: gears
stata("capture mata mata drop MoreInfo()")
void MoreInfo(string scalar nothing) { //>>def func<<
	if (nothing=="Press Again") printf("{txt}These links merely serve as the basis for informational 'tooltips'.\nIdeally, clicking the links wouldn't do anything, but this is as close as I can get.")
	else printf(`"{txt:Please do not press {matacmd MoreInfo("Press Again"):this button} again}"')
	}
end
//>>mosave<<
*! 28aug2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: search
//!mimiss: return a missing value that's not used in the submitted matrix
//!data: matrix to search
//!R: unused (numeric format) extended missing value; eg: .a or ".a"
stata("capture mata mata drop mimiss()")
scalar mimiss(matrix data) { //>>def func<<
	str=eltype(data)=="string"
	test=colshape(str?strtoreal(data):data,1)
	test=uniqrows(select(test,test:>.))
	if (length(test)>=26) errel("There are no unused missing values to use")
	all=(.a,.b,.c,.d,.e,.f,.g,.h,.i,.j,.k,.l,.m,.n,.o,.p,.q,.r,.s,.t,.u,.v,.w,.x,.y,.z)
	for (a=1;a<=26;a++) if (!anyof(test,all[a])) return(str?strofreal(all[a]):all[a])
	errel("unexpectedly ran out of missing values")
	}
end
//>>mosave<<
*! unknown v10.1
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata: 

//!type: numeric
//!mod1: cycle between 1 & n (rather than 0&n-1)
//!data: numbers to mod
//!mod: max result
//!R: data<=mod =data; >mod = data-mod
stata("capture mata mata drop mod1()")
real vector mod1(real vector data, real scalar mod) { //>>def func<<
	if (!all(data)) _error(77,"Input for mod1 cannot be 0")
	out=mod(data,mod)
	_editvalue(out,0,mod)
	return(out)
	}

end 
//>>mosave<<
*! 29oct2010
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.1
mata:

//!type: paths
stata("capture mata mata drop multipath()")
string vector multipath(string scalar input,| defext) { //>>def func<<
	//this isn't completely working: ext screws with regex for filename, and 
	ipath=strtrim(strlower(subinstr(input,char(34),"")))
	if (ipath=="") ipath="."
	
	if (args()==2 & pathsuffix(ipath)=="") ipath=ipath+(substr(defext,1,1)=="."?"":".")+defext
	parts=tokenpath(ipath)
	abs=pathisabs(parts[1])|(c("os")=="Windows" & regexm(parts[1],"^[a-zA-Z]:$")) //crazy
	if (!abs) parts=tokenpath(pwd()),parts
	parts=select(parts,parts:!=".") //dir now returns mixed case
	//parts=strlower(select(parts,parts:!=".")) //dir returns only lowercase! need to do something to preserve case
	while (length(back=toindices(parts:==".."))) parts=parts[1..back[1]-2],cut(parts,back[1]+1)
	//notback=parts:!=".."
	//parts=strlower(select(parts,notback:&(subvec(notback,(2,.)),1)))
	last=parts[1]
	for (i=2;i<=cols(parts);i++) { 
		next=J(0,1,"")
		for (r=1;r<=rows(last);r++) {
			if (substr(parts[i],1,6)=="regex("&substr(parts[i],-1)==")") {
				all=direl(last[r],i==cols(parts)?"files":"dirs","*") //til they fix dir
				found=select(all,regexm(all,substr(parts[i],7,strlen(parts[i])-8)))
				for (fr=1;fr<=rows(found);fr++) found[fr]=pathjoin(last,found[fr])
				}
			else found=direl(last[r],i==cols(parts)?"files":"dirs",parts[i],1) //ditto
			if (length(found)) next=next\found
	//		else  errel("Not found: "+pathjoin(last[r],parts[i])) //had this off for some reason...
			// off because not finding a entry with wildcards is ok. Should fix for wildcards/none...
			}
		last=next
		}
	
	return(next)
	}

end
//>>mosave<<
*! 1may2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: numeric
//!multix: transforms sequential index into multiplied, right-shifted index
stata("capture mata mata drop multix()")
real vector multix(real vector in, real scalar mult,| real scalar offset) { //>>def func<<
	offset=firstof(offset\0)
	return(shapeof(rowshape(J(1,mult,vec((in:-1):*mult)):+(1..mult):+offset,1),in))
	}
end
//>>mosave<<
*! 7nov2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.1
mata:
//!type: numeric
stata("capture mata mata drop numl()")
real vector numl(string scalar numopt,|string scalar constraints) { //>>def func<<
	//no reason to reprogram, yet...
	stata("numlist "+char(34)+numopt+char(34)+adorn(",",constraints))
	return(strtoreal(columnize(st_global("r(numlist)")," ")))
	}
end
//>>mosave<<
*! 21jan2011
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.1
mata:

//!type: parse
//!ocanon: return (validated) (canonical) option words
//!desc: description of words being checked, for error msgs
//!in: vector of possibly abbreviated words
//!candef: vector of permitted words & abbrevs (colon marking minimal abbreviation)
//!options: [max] returns max instead of abbrevs; [nfok] prevents notfound errors. If notfleeting, notfound vect are returned
//!R: canonical words
stata("capture mata mata drop ocanon()")
string vector ocanon(string scalar desc, string vector in, string rowvector candef,| matrix options) { //>>def func<<
	if (truish(options)) {
		maxback=strpos(options,"max") //don't feel comfortable using optionel in here
		nfok=strpos(options,"nfok")
		}
	else maxback=nfok=0
	
	cpos=strpos(candef,":"):-1
	canmax=subinstr(candef,":","")
	errlist=concat(adorn("{ul:",substr(canmax,1,cpos),"}"):+substr(canmax,cpos:+1):+canmax:*(cpos:<1)," ")
	canon=firstof(substr(canmax,1,cpos)\canmax)
	if (rows(uniqrows(canon'))<cols(canon)) errel("ocanon: canon not distinct")
	perm=order(strlen(canon'):+.5*tru2(cpos'),1)
	wcol=tru2(cpos):*"*"
	
	test=tru2(in)
	out=nf=in:*0
	c=length(canon)
	while (c&any(test)) {
		cix=perm[c--]
		hit=test:&strmatch(in,canon[cix]+wcol[cix])
		if (any(hit)) {
			valid=in:==substr(canmax[cix],1,strlen(in))
			out=out:+(hit:&valid):*(maxback?canmax[cix]:canon[cix])
			nf=nf:+(hit:&!valid):*in
			test=test:&!hit
			}
		}
	if (any(test)) nf=nf:+test:*in
	if (truish(nf)&!nfok) errel(sprintf("[oc] %s must be one of: %s\n",desc,errlist))
	options=nf
	return(out)
	}

end
//>>mosave<<
*! 21jan2011
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.1
mata:

//!type: parse
//!optionel: read options from a string vector
//!uspec: user specified options
//!pass: return vars&defs for allowable options: &(var="def"); def=  !a:bc=+ ; where ! is mandatory, : marks minimal abbreviation, = is mandatory parameter, + is optional parameter. * at end allows multiple (same) options
//!remainder: truish content here means extra material is allowed, and returned in this var.
//!R: variables pointed to in optsin are 0/1, or string, or (NULL or pointer to string) for +. vect spec returns 2row matrix: r1=content, r2=optname. spec'd alone for plus or vect is ->"1"
stata("capture mata mata drop optionel()")
void optionel(string vector uspec, pointer vector pass,|matrix remainder) { //>>def func<<
	if (pass==NULL) {
		remainder=uspec
		return
		}
	
	uopts=expand(tokel(uspec),1)
	uhasp=strpos(uopts,"("):&strpos(uopts,")")
	uopts=tokenstrip(uopts)
	if (truish(uopts[,3])|any(tru2(uopts[,2]):&!tru2(uopts[,1]))) errel("Options must be of the form {hi:xxx} or {hi:xxx(yyy)}")
	uonam=uopts[,1]':+uopts[,4]'
	uopar=uopts[,2]'
	ucpar=uopar:+"1":*!uhasp
	
	dopts=J(0,1,"")
	prows=J(length(pass),1,NULL)
	for (p=1;p<=length(pass);p++) {
		dopts=dopts\vec(*pass[p])
		prows[p]=&(rows(dopts)-length(*pass[p])+1..rows(dopts))
		}
	dmand=strpos(dopts,"!")
	dopts=subinstr(dopts,"!","")
	dmay=strpos(dopts,"+")
	dopts=subinstr(dopts,"+","")
	dyn=!strpos(dopts,"="):&!dmay
	dopts=subinstr(dopts,"=","")
	dmulti=strhas(dopts,"*")
	dopts=subinstr(dopts,"*","")
	donam=ocanon("option definitions",subinstr(dopts,":",""),dopts',"max") //checks consistency
	
	uonam=ocanon("options",uonam,dopts',nf="max "+truish(remainder)*"nfok") //not allowed caught here
	remainder=selectv(nf:+adorn("(",uopar,")"),tru2(nf),"r")
	match=asvmatch(uonam,donam,"det no mult")
	for (d=1;d<=rows(dopts);d++) {
		if (dmand[d]&!rowmax(match[d,])) errel(sprintf("Option required: %s",dopts[d]))
		if (!dmulti[d]&sum(match[d,])>1) errel(sprintf("Multiple options specified: %s",dopts[d]))
		dwithp=select(uhasp,match[d,])
		if (dyn[d]&any(dwithp)) errel(sprintf("Option does not take paramters: %s",dopts[d]))
		if (!dyn[d]&!dmay[d]&length(dwithp)&!all(dwithp)) errel(sprintf("Option requires parameters: %s",dopts[d]))
		}
	for (p=1;p<=length(pass);p++) {
		*pass[p]=selectv(ucpar,colmax(match[*prows[p],]),"r")
		if (length(*prows[p])>1) *pass[p]=*pass[p]\selectv(uonam,colmax(match[*prows[p],]),"r")
		else {
			if (!length(*pass[p])) {
				if (dmay[p]) *pass[p]=NULL
				else if (!dmulti[p]) *pass[p]=expand(*pass[p],1,1)
				}
			else if (dmay[p]) *pass[p]=&(*pass[p]'')
			if (dyn[p]) *pass[p]=editmissing(strtoreal(*pass[p]),0)
			}
		}
	}

end
//>>mosave<<
*! 20mar2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:
//!type: stata
//!othtypes: switches between stata dtypes & ds dtypes
//!intypes: st types, or s/i/r
//!inbytes: for ds intypes, # of bytes; string or real
//!R: rowvector if returning st, 2 row matrix otherwise: r1=s/i/r, r2=bytes
stata("capture mata mata drop othtypes()")
string matrix othtypes(string rowvector intypes,| rowvector inbytes) { //>>def func<<
	if (length(inbytes)) {
		if (length(intypes)!=length(inbytes)) errel("othtypes: data type vectors must be the same length")
		out=J(1,length(intypes),"")
		bytes=eltype(inbytes)=="real"?strofreal(inbytes):inbytes
		if (length(tix=toindices(intypes:=="s"))) out[tix]=recode("str":+bytes[tix],("str.","strL"))
		if (length(tix)<length(intypes)) {
			tix=toindices(intypes:!="s")
			out[tix]=lookupin(("byte","int","long","float","double"), vmap(intypes:+bytes,("i1","i2","i4","r4","r8"))[tix])
			}
		}
	else {
		tmap=vmap(substr(intypes,1,3),("byt","int","lon","flo","dou","str"))
		out=J(2,length(intypes),"")
		out[1,]=lookupin(("i","i","i","r","r","s"),tmap)
		out[2,]=lookupin(("1","2","4","4","8",""),tmap)
		if (length(str=toindices(tmap:==6))) out[2,str]=substr(intypes[str],4)
		}
	return(out)
	}
end
//>>mosave<<

*! 1apr2016
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

stata("capture mata mata drop overmeta()")
void overmeta(string scalar path) { //>>def func
	class dataset_dta scalar ds
	
	ds.with("l c")
	ds.readfile(path)
	stvars=varlist("*")
	stata(sprintf("order %s",concat(lookupin(ds.vnames,vmap(stvars,ds.vnames))," ")))
	//label extra vars as unknown
	stvars=varlist("*")
	map=vmap(ds.vnames,stvars)
	//message?
	for (n=1;n<=ds.nvars;n++) {
		if (map[n]) {
			st_varlabel(map[n],ds.nlabels[n])
			if (strlen(ds.vlabrefs[n])) st_varvaluelabel(map[n],ds.vlabrefs[n]) //error for strings otherwise
			st_varformat(map[n],ds.formats[n])
			if (st_vartype(map[n])=="double"&ds.bytes[n]==4) stata(sprintf("recast float %s",ds.vnames[n]))
			}
		chars=select(ds.chars,ds.chars[,1]:==ds.vnames[n])
		if (truish(chars)) charset(ds.vnames[n],chars[,2],chars[,3])
		}
	for (n=1;n<=length(ds.vlabnames);n++) {
		st_vlmodify(ds.vlabnames[n],strtoreal((*ds.vlabtabs[n])[,1]),(*ds.vlabtabs[n])[,2])
		}
	charset("_dta","@lab",ds.dtalabel)
	}

end
*! 3oct2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.1
mata: 

//!type: config
//!pad: compose two matrices, filling in with empty
//!a: left/top matrix
//!b: right/bottom matrix
//!op: operator: [,] or [\]
//!rev: flag to reverse alignment (bottom for [,]; right for [\])
//!R: single composed matrix
stata("capture mata mata drop pad()")
matrix pad(matrix a, matrix b, string scalar op,| matrix rev) { //>>def func<<
	if (op==",") {
		exp=pmax(rows(a),rows(b))*(-1)^truish(rev)
		return(expand(a,.,exp),expand(b,.,exp))
		}
	else {
		exp=pmax(cols(a),cols(b))*(-1)^truish(rev)
		return(expand(a,exp)\expand(b,exp))
		}
	} 

end 
//>>mosave<<
*! 20jun2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.2
mata:

//!type: config
//!pages: chunk a vector into 2-way (display) pages
//!text: to chunk
//!icsp: extra space to figure in for each cell; def=1
//!height: max lines per page; def=c(pagesize)-3
//!R: pointers to each string matrix page
stata("capture mata mata drop pages()")
pointer rowvector pages(string vector text,| real scalar icsp, real scalar height) { //>>def func<<
	psize=firstof(height\c("pagesize")-3)
	sized=colshape((vec(text)\J(psize-mod1(length(text),psize),1,"")),psize)'
	widths=colmax(strlen(sized)):+firstof(icsp\1)
	pages=J(1,0,NULL)
	b=c=1
	while (c<cols(sized)) {
		if (sum(widths[b..c+1])<c("linesize")) c=c+1
		else {
			pages=pages,&sized[,b..c]
			b=++c
			}
		}
	pages=pages,&sized[,b..c]
	return(pages)
	}

end
//>>mosave<<

*! unknown
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.1
mata:

//!type: numeric
//!pairs: match every row in a with every row in b
//!a: matrix a
//!b: matrix b
//!R: matrix ra*rb rows, ca+cb cols
stata("capture mata mata drop pairs()")
matrix pairs(matrix a, matrix b) { //>>def func<<
	if (!length(a)&!length(b)) return(J(pmax(rows(a),rows(b)),0,missingof(a)))
	if (!length(b)) return(a)
	if (!length(a)) return(b)
	return(colshape(J(1,rows(b),a),cols(a)),J(rows(a),1,b))
	}

end
//>>mosave<<
*! 1aug2014, from collect
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: paths
//!pathends: return only enough of path to ensure uniqueness
//!paths: entire paths
//!R: ends
stata("capture mata mata drop pathends()")
string colvector pathends(string colvector paths) { //>>def func<<
	bits=columnize(strreverse(paths),dirsep())
	d=1
	while (rows(uniqrows(bits[,1..d]))<rows(bits)) ++d
	return(strreverse(concat(cut(bits,1,d,.,"m"),dirsep(),"r")))
	}
end
//>>mosave<<
*! 17sep2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.1
mata: 

//!type: paths
//!pathparts: parse filepaths into constituents (& repeat...)
//!paths: to parse
//!spec: elements of paths are 1=dirs, 2=filename, 3=ext. each cell in spec is a 1-3 digit number, specifying which elements for that cell.
//!R: 1 row/path, 1 col/spec-cell
stata("capture mata mata drop pathparts()")
string matrix pathparts(string colvector paths, | real vector spec) { //>>def func<<
	if (!length(paths)) return(paths)
	paths=subinstr(paths,"/",dirsep()) //think this is ok...
	elements=J(rows(paths),3,"") 
	for (i=1;i<=rows(paths);i++) { 
		if (strlen(ext=pathsuffix(paths[i]))) { 
			pathsplit(paths[i],a="",b="") 
			elements[i,1]=a
			elements[i,2]=pathrmsuffix(b) 
			elements[i,3]=ext
			} 
		else if (strpos(paths[i],dirsep())) {
			elements[i,1]=substr(paths[i],1,x=strlast(paths[i],dirsep()))
			elements[i,2]=pathrmsuffix(substr(paths[i],x+1))
			elements[i,3]=pathsuffix(paths[i])
			}
		else elements[i,2]=paths[i]
		} 
	elements[,1]=elements[,1]:+dirsep():*(strlen(elements[,1]):&substr(elements[,1],-1):!=dirsep())
	if (args()==1) return(elements)
	
	if (any(regexm(strofreal(spec),"[^123]"))) errel("Parts of pathparts can only include digits 1,2,3",spec)
	out=J(rows(elements),cols(spec),"")
	for (c=1;c<=cols(spec);c++) out[,c]=concat(elements[,columnize(spec[c],"")],"","r")
	return(out)
	} 

end 

//>>mosave<<
*!17nov2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata: 

//!type: paths
//!pathto: 1) returns the entire path to [partial], prepending seattel() to pathless names;  2) creates any missing directories in the path, in the OS
//!partial: the path or filename to complete
//!inst: flag to include instance# in filename
//!exists: if truish, return empty if path/file does not exist.
//!R: complete path, verified as existing
stata("capture mata mata drop pathto()")
string scalar pathto(string scalar partial,| matrix inst, matrix exists) { //>>def func<<
	if (partial=="") return("")
	
	parts=pathparts(partial,(1,2,3)) //assumes spec is already canonical...
	if (!truish(parts[1])) parts[1]=seattel()
	parts[2]=inst_name(parts[2],truish(inst))
	if (parts[3]==".lmat"&c("stata_version")>=14) parts[3]=sprintf(".lmat2") //klugy but...
	fpath=concat(parts,"")
	
	if (truish(exists)) return(fpath*fexists(fpath))
	
	tpath=tokenpath(parts[1])
	verify=tpath[1]
	for (i=2;i<=length(tpath);i++) {
		verify=pathjoin(verify,tpath[i])
		if (!direxists(verify)) {
			if (_mkdir(verify)==693) _error(693,"Could not create a directory: "+verify)
			}
		}
	return(fpath)
	}

end 
//>>mosave<<
*! 8jun2011
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.1
mata:
//!type: paths
//!pcanon: get canonical (absolute) path from any input
//!input: can include wildcards & relative refs
//!reqs: f:ile, d:ir, fex:ists, fn:ew, dcn(=dir can not-exist); If nothing is specified, final dirsep determines file or directory
//!defext: extension to use if none is in [input]. Can inlcude . or not
//!R: canonical path.
stata("capture mata mata drop pcanon()")
string scalar pcanon(string scalar input, |string scalar reqs, string scalar defext) { //>>def func<<
	tdir=st_macroexpand(char(96)+":env TEMP'")
	if (substr(input,1,strlen(tdir))==tdir) return(input) //kluge because tempfile returns "short" filename
	
	ipath=strtrim(subinstr(input,char(34),"")) //going for mixed-case
	
	optionel(reqs,(&(fil="f:ile"),&(dir="d:ir"),&(fex="fex:ists"),&(fnew="fn:ew"),&(dcn="dcn"))) 
	if (dir & any((fil,fex,fnew))|(fex&fnew)) errel(sprintf("Incompatible pcanon options (%s)",reqs))
	
	if (fil+dir+fex+fnew==0) dir=sum(substr(ipath,-1):==("/","\",":")) | sum(ipath:==("",".",".."))
	if (ipath=="") {
		if (dir) ipath="."
		else errel("pcanon: no file name specified")
		}
	if (!(fex|fnew)) fex=.
	
	if (strlen(defext) & pathsuffix(ipath)=="") ipath=ipath+(substr(defext,1,1)=="."?"":".")+defext
	abs=pathisabs(ipath)|(c("os")=="Windows" & regexm(ipath,"^[a-zA-Z]:$")) //crazy
	if (!abs) ipath=pathjoin(pwd(),ipath)
	parts=tokenpath(ipath)
	parts=select(parts,parts:!=".")
	while (length(back=toindices(parts:==".."))) parts=parts[1..back[1]-2],cut(parts,back[1]+1)
	glob=strpos(parts,"*"):|strpos(parts,"?")
	if (glob[1]) errel("Wildcards cannot be used for the root directory")
	//can't traverse directories when there's no permission at a higher directory. So, lump together non-wildcard parts. It'd be good, on error, to walk back to the shortest non-working path.
	found=parts[1]
	for (i=2;i<=cols(parts)-!dir;i++) { 
		if (!glob[i]) found=pathjoin(found,parts[i])
		else {
			next=direl(found,"dirs",parts[i],1) //til they fix dir
			if (length(next)>1) errel(pathjoin(found,parts[i])+" is an ambiguous pattern")
			else if (!length(next)) errel("Directory not found: "+pathjoin(found,parts[i]))
			else found=next
			}
		}
	found=found+dirsep()
	if (!dcn&!direxists(found)) errel("Directory not found: "+found)
	if (!dir) {
		next=expand(direl(found,"files",parts[i],1),.,1) //til they fix dir
		if (length(next)>1) errel(pathjoin(found,parts[i])+" is an ambiguous pattern")
		if (fex==1&!fexists(next)) errel("File not found: "+pathjoin(found,parts[i]))
		else if (fex==0&fexists(next)) errel("File already exists: "+pathjoin(found,parts[i]))
		if (strlen(next)) found=next
		else found=pathjoin(found,parts[i])
		}
	
	return(found)
	}

end
//>>mosave<<
*! 5feb2016
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: numeric
//!pless: return a value that p is less than
//!p: a p value
//!digits: 2 by default
//!R: the <ceiling
stata("capture mata mata drop pless()")
string vector pless(real vector p,| real scalar digits) { //>>def func
	digits=firstof(2\digits)
	scaled=10^digits:*p
	up=ceil(10^digits:*p)
	return(strofreal((up:+(up:==scaled)):/10^digits,sprintf("%%5.%ff",digits)))
	}
end
//>>mosave
*! 23apr2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: select
stata("capture mata mata drop pmax()")
scalar pmax(scalar a, scalar b) { //>>def func<<
	return(a>=b?a:b)
	}

//!type: select
stata("capture mata mata drop pmin()")
scalar pmin(scalar a, scalar b) { //>>def func<<
	return(a<=b?a:b)
	}
end
//>>mosave<<

*! 20mar2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:
//!type: stata
//!promote: promote stata vars to larger datatypes. Will go from long to float.
//!plustype: stata datatype to increase to (larger datatypes unaffected).
//!vars: varlist to promote (ix or name)
stata("capture mata mata drop promote()")
void promote(string scalar plustype, vector vars) { //>>def func<<
	ntypes=("byte","int","long","float","double")
	vtypes=J(1,length(vars),"")
	for (v=1;v<=length(vars);v++) vtypes[v]=st_vartype(vars[v])
	if (st_isstrvar(vars[1])) up=strtoreal(substr(plustype,4)):>strtoreal(substr(vtypes,4))
	else up= toindices(plustype:==ntypes):>vmap(vtypes,ntypes)
	if (any(up)) {
		varnames=eltype(vars)=="string"?vars:st_varname(vars)
		stata(sprintf("recast %s %s",plustype,concat(select(varnames,up)," ")))
		}
	}
end
//>>mosave<<
*! 05apr2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.1
mata:

//!type: stata
stata("capture mata mata drop qlabel()")
void qlabel(string scalar varpat, real vector values, vector labels,| string scalar name, matrix filter, matrix modify) { //>>def func<<
	if (length(values)!=length(labels)) errel ("Number of values must match number of labels")
	varlist=varlist(varpat,truish(filter)*"nfrep")
	if (!length(varlist)) return
	if (truish(modify)) {
		lab=uniqrows(charget(varlist,"@vlab")')
		for (l=1;l<=rows(lab);l++) if (truish(lab[l])) if (!st_vlexists(lab[l])) lab[l]=""
		lab=uniqrows(lab)
		if (length(lab)>1&lab[1]!="") errel("When modifying a label, all referenced variables must have the same label (or none)")
		lab=firstof(cut(lab,-1)\name\varlist[1]+"_qlab")
		}
	else {
		lab=firstof(name\varlist[1]+"_qlab")
		st_vldrop(lab)
		}
	st_vlmodify(lab,colshape(values,1),colshape(labels,1))
	for (v=1;v<=length(varlist);v++) st_varvaluelabel(varlist[v],lab)
	}
end
//>>mosave<<
*!12may2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:
//!type: string
stata("capture mata mata drop quotes()")
string matrix quotes() { //>>def func<<
	return(char((96,34)),char((34,39))\char(34),char(34))
	}
end
//>>mosave<<
*!unknown v10.1
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: numeric
stata("capture mata mata drop rangel()")
real colvector rangel(real scalar a, real scalar b, real scalar delta) { //>>def func<<
	if (a>=. | b>=. | delta>=.) _error(3351)
	n = trunc(abs(b-a)/abs(delta))
	if (n>=.) _error(3300)
	return((0::n):*delta:+a)
	}

end
//>>mosave<<
*! 10aug2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.2
mata:
//!type: trans
//!recode_: recode in place
//!orig: to recode
//!subs: two column matrix, c1=orig, c2=replacement
stata("capture mata mata drop recode_()")
void recode_(matrix orig, matrix subs) { //>>def func<<
	if (eltype(orig)!=eltype(subs)) errel("Element type of matrix and substitutions must match")
	if (cols(subs)!=2) errel("Substitutions must be a 2-col matrix: orig,new")
	for (r=1;r<=rows(subs);r++) _editvalue(orig,subs[r,1],subs[r,2])
	}

//!type: trans
//!recode_: recode to return
//!orig: to recode
//!subs: two column matrix, c1=orig, c2=replacement
//!R: recoded orig
stata("capture mata mata drop recode()")
matrix recode(matrix orig, matrix subs) { //>>def func<<
	out=orig
	recode_(out,subs)
	return(out)
	}
end
//>>mosave<<
*!unknown v10.1
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata: 

//!type: search
stata("capture mata mata drop regexs2()")
string matrix regexs2(string matrix body, string matrix pat, real scalar num) { //>>def func<<
	pattern=pat
	if (length(pattern)==1) pattern=J(rows(body),cols(body),pattern)
	else if (rows(pattern)==1) pattern=J(rows(body),1,pattern)
	else pattern=J(1,cols(body),pattern)
	(void) body+pattern //to check conformability
	res=J(rows(body),cols(body),"")
	for (r=1;r<=rows(body);r++) {
		for (c=1;c<=cols(body);c++) {
			found=regexm(body[r,c],pattern[r,c])
			if (found) res[r,c]=regexs(num)
			}
		}
	return(res)
	}

end
//>>mosave<<
*! 23aug2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.1
mata:
//!type: trans
stata("capture mata mata drop replace()")
void replace(matrix orig, real matrix cond, matrix rep) { //>>def func<<
	corig=colshape(orig,1)
	changers=toindices(colshape(cond,1))
	if (orgtype(rep)=="scalar") crep=J(length(orig),1,rep)
	else if (orgtype(rep)=="rowvector") crep=J(rows(orig),1,colshape(rep,1))
	else if (orgtype(rep)=="colvector") crep=colshape(J(1,cols(orig),rep),1)
	else crep=colshape(rep,1)
	corig[changers]=crep[changers]
	orig=colshape(corig,cols(orig))
	}
end
//>>mosave<<

*!11apr2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: config
//!riffle: rearrange matrix by every nth row/col
//!deck: to riffle
//!by: inc for subsequent row/col/cell
//!col: flag to riffle rows instead of cols
//!R: reconfiged deck
stata("capture mata mata drop riffle()")
matrix riffle(matrix deck, real scalar by,| matrix byrow) { //>>def func<<
	if (by==1) return(deck)
	type=truish(byrow)+2*(substr(orgtype(deck),4)=="vector") //better spec correctly!
	if (type==0) size=cols(deck)
	else if (type==1) size=rows(deck)
	else size=length(deck)
	if (size/by<2) return(deck)
	ord=vec((0..by-1):+J(1,by,rangel(1,size,by)))[|1\size|]
	if (type==0) return(deck[,ord])
	else if (type==1) return(deck[ord,])
	else return(deck[ord])
	}
end
//>>mosave<<
*!8may2015
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:



//!type: trans
//!scofmat: scalar of matrix
//!body: matrix to scalarize
//!R: scalar version
stata("capture mata mata drop scofmat()")
string scalar scofmat(string matrix body) { //>>def func<<
	dels=charsubs(body,2)
	if (!length(body)) return(concat(dels,"")+dels[1]*cols(body)+dels[2]*rows(body))
	return(concat(dels,"")+concat(concat(body:+dels[1],"","r"):+dels[2],""))
	}

//!type: trans
//!sctomat: scalar to matrix
//!body: previously scalarized matrix
//!R: matrix again
stata("capture mata mata drop sctomat()")
string matrix sctomat(string scalar body) { //>>def func<<
	if (!truish(body)) return(J(0,0,""))
	dels=columnize(substr(body,1,2),"")
	b2=substr(body,3)
	if (!strpos(b2,dels[1])) {
		if (!strpos(b2,dels[2])) return(J(0,0,""))
		return(J(strlen(b2),0,""))
		}
	if (!strpos(b2,dels[2])) return(J(0,strlen(b2),""))
	b2=substr(b2,1,strlen(b2)-1)
	b2=columnize(b2,dels[2],"e")'
	b2=substr(b2,1,strlen(b2):-1)
	b2=columnize(b2,dels[1],"e")
	return(b2)
	}

end
//>>mosave<<
*! 3dec2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:
//!type: gears
//!R: the path to the seattel (settings) directory
stata("capture mata mata drop seattel()")
string scalar seattel() { //>>def func<<
	base=untokenpath(cut(tokenpath(c("sysdir_personal")),1,-2))
	if (!direxists(base)) {
		if (_mkdir(base)==693) _error(693,"Could not create an 'ado' directory one level up from Stata's (nominal) PERSONAL directory: "+base)
		}
	return(pathjoin(base,"seattel"+dirsep()))
	}
end
//>>mosave<<
*! 16mar2011
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.1
mata:

//!type: select
//!selectv: select, ensuring a vector is returned
//!x: thing to select from
//!v: selection vector
//!rc: which dimension to keep (min1) instead of returning 0,0
stata("capture mata mata drop selectv()")
matrix selectv(matrix x, real vector v, string scalar rc) { //>>def func<<
	y=select(x,v)
	if (length(y)) return(y)
	return(J((rc=="r")*pmax(1,rows(x)),(rc=="c")*pmax(1,cols(x)),missingof(x)))
	}
end
//>>mosave<<
*! 8oct 2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.1
mata:

//!type: stata
stata("capture mata mata drop settouse()")
void settouse(matrix touse,| string scalar ifin, string scalar filtervar) { //>>def func<<
	if (strlen(ifin+filtervar)) {
		if (!truish(touse)) (void) st_addvar("byte",touse=st_tempname())
		stata(sprintf("qui replace %s=0",touse))
		stata(sprintf("qui replace %s=1 %s %s",touse,ifin,adorn("&",filtervar)))
		}
	else if (!truish(touse)) touse=""
	}
end
//>>mosave<<
*!9nov2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.1
mata:
//!type: config
//!shapeof: make a vector match another vector's orientation
//!ret: vector to shape and return
//!match: shape to copy
//!R: row or col vector as appropriate
stata("capture mata mata drop shapeof()")
vector shapeof(vector ret, vector match) { //>>def func<<
	if (orgtype(match)=="rowvector") return(rowshape(ret,1))
	else if (orgtype(match)=="colvector") return(colshape(ret,1))
	else return(ret)
	}
end
//>>mosave<<
*!16aug2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 10.1
mata: 

//!type: debug
stata("capture mata mata drop show()")
void show(matrix x,| scalar title) { //>>def func<<
	if (truish(title)) {
		stit=eltype(title)=="string"?title:strofreal(title)
		printf("{res:{ul:%s}}%s",stit,strlen(stit)?eol():"")
		}
	if (rows(x)==0|cols(x)==0) {
		printf("[%f,%f] %s matrix\n\n",rows(x),cols(x),eltype(x))
		return
		}
	if (eltype(x)=="pointer") { //wish I could code the pointer values...
		x
		return
		}
	if (eltype(x)=="struct") {
		printf("array keys\n")
		show(asarray_keys(x)) //this will error for non-arrays! do something...
		return
		}
	if (alignr=eltype(x)=="real") y=strofreal(x)
	else y=x
	overhead=3
	left=strlen(strofreal(rows(y)))+2
	tot=c("linesize")-1-left
	if (cols(y)*(1+overhead)>tot) _error(77,sprintf("Too many columns for the page width (%f)",cols(y)))
	marks=charsubs(y,2)
	y=y:+!strlen(y):*marks[1]
	sizes=colmax(strlen(y)):+overhead
	order=order(sizes',1)
	for (s=1;s<=length(sizes);s++) {
		remain=tot-(s>1?sum(sizes[order[1..s-1]]):0)
		sizes[order[s]]=min((sizes[order[s]],trunc(remain/(length(sizes)+1-s))))
		}
	y=substr(y,1,sizes:-overhead)
	extra=(sizes:-overhead:-strlen(y)):*" "
	y=subinstr(y,"{",marks[2])
	y=subinstr(y," ","{txt:-}")
	y=subinstr(y,marks[2],"{c -(}")
	y=subinstr(y,marks[1],"{txt:*}")
	y=subinstr(y,char(9),"{txt:{ul:t}}")
	y=subinstr(y,char(10),"{txt:{ul:n}}")
	y=subinstr(y,char(13),"{txt:{ul:c}}")
	controls=chars((1..31,127..160))
	key=J(0,1,"")
	for (c=1;c<=length(controls);c++) {
		if (any(strpos(y,controls[c]))) {
			if (rows(key)==26) errel("More than 26 control characters present")
			key=key\"{txt:"+char(65+rows(key))+"=}{res:"+strofreal(ascii(controls[c]))+"}"
			y=subinstr(y,controls[c],"{txt:{ul:"+char(64+rows(key))+"}}")
			}
		}
	if (alignr) y=extra:+y
	else y=y:+extra
	rix=strofreal(1::rows(y))
	rix=(max(strlen(rix)):-strlen(rix)):*" ":+rix
	cix=strofreal(1..cols(y))
	cix=cix:+" ":*(sizes:-strlen(cix))
	printf("{txt}"+(alignr?"n":"s")+" "*max(strlen(rix))+concat(cix,""))
	//printf("{txt}  "+" "*max(strlen(rix))+concat(cix,""))
	printf("\n{res}")
	y="{txt:":+rix:+"} {txt:{c |}} ":+concat(y," {txt:{c |}} ","r"):+" {txt:{c |}}"
	display(y)
	printf("\n")
	if (length(key)) display(key)
	}

end 
//>>mosave<<


*!10may2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: parse
stata("capture mata mata drop slurp()")
string scalar slurp(string scalar bev, string vector sip) { //>>def func<<
	fpos=strpos(bev,sip[2])
	if (!fpos) errel("Too many openers (eg, {hi:(} )")
	sips=!any(sip:==quotes())?quotes()\sip:sip
	spos=strpos(bev,sips[,1])
	spos1=editmissing(min(select(spos,spos)),0)
	pref=""
	while (spos1&spos1<fpos) {
		six=toindices(spos:==spos1)[1]
		pref=pref+substr(bev,1,spos1+strlen(sips[six,1])-1)
		bev=substr(bev,spos1+strlen(sips[six,1]))
		pref=pref+slurp(bev,sips[six,])
		fpos=strpos(bev,sip[2])
		spos=strpos(bev,sips[,1])
		spos1=editmissing(min(select(spos,spos)),0)
		}
	pref=pref+substr(bev,1,fpos+strlen(sip[2])-1)
	bev=substr(bev,fpos+strlen(sip[2]))
	return(pref)
	}

end
//>>mosave<<

*!unknown v10.1
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata: 

//!type: stata
//!somevars: subset of vars (string, numeric)
//!allvars: names or indexes of variables to check
//!which: what to return: takes [s:tring, n:umeric]
//!R: variable names
stata("capture mata mata drop somevars()")
vector somevars(vector allvars, string scalar which) { //>>def func<<
	optionel(which,(&(str="s:tring"),&(shstr="ss:tring"),&(num="n:umeric")))
	if (str+shstr+num>1) errel("only a single variable type can be specified")
	sn=J(rows(allvars),cols(allvars),.)
	for (v=1;v<=length(allvars);v++) sn[v]=st_isstrvar(allvars[v])+(st_vartype(allvars[v])=="strL")
	if (num) return(selectv(allvars,!sn,"r"))
	else if (shstr) return(selectv(allvars,sn:==1,"r"))
	else return(selectv(allvars,sn,"r"))
	}

end 
//>>mosave<<
*!unkown v10.1
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: string
stata("capture mata mata drop sput()")
void sput(string scalar s, string scalar matter, | real scalar lf) { //>>def func<<
	if (args()<3) lf=1
	cr=lf*select((char(13),char(10),char((13,10))),c("os"):==("MacOSX","Unix","Windows"))
	s=s+matter+cr
	}

end
//>>mosave<<
*! 6nov2013

* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: sql
stata("capture mata mata drop sql_print()")
void sql_print(string scalar sqltext,| matrix hline) { //>>def func<<
	if (truish(hline)) printf("{res:{hline 20}}\n")
	printf("{txt}")
	text=subinstr(sqltext,"%","%%")
	text=subinstr(text,char((10,10)),"{p_end}"+char(13)+"{p}")
	text=subinstr(text,char(10),"{p_end}{p}")
	display("{p 1 1 1}"+text+"{p_end}")
	displayflush()
	}

//!type: sql
stata("capture mata mata drop sql_dnload()")
void sql_dnload(string vector dmeta, string scalar sql,| class sql_conn sc) { //>>def func<<
	class recentle_data scalar rld
	
	if (!length(sc)) {
		sc=sql_conn()
		sc.get()
		}
	rld.ncmd="sql"
	rld.ndir=sc.humstr()
	dmeta=expand(dmeta,2)
	rld.nmode=dmeta[1]
	rld.nfile=dmeta[2]
	rld.ndetails=sql
	
	sql_print(sql,"line")
	stata(sprintf("odbc load, noquote lower clear conn(%s) e(",sc.connstr())+char(34)+sql+char(34)+")")
	//sql string can be too long for sprint
	//odbc pads trailing, but need to know about initial
	//mf regex final char bug
	sstrs=somevars(varlist("*"),"ss")
	if (truish(sstrs)&st_nobs()) {
		el_view(V=.,.,sstrs)
		V[.,.]=strreverse(regexr(strreverse(V),"^ +",""))
		stata("qui compress")
		}
	rld.add()
	}

//!type: sql
stata("capture mata mata drop sql_upload()")
void sql_upload(string scalar table,| class sql_conn sc) { //>>def func<<
	if (!length(sc)) {
		sc=sql_conn()
		sc.get()
		}
	sandt=sql_rparts(table,23,sc)
	(void) sql_submit(sql_ischema(sql_rparts(sandt,2)))
	(void) sql_submit(sprintf("if object_id('%s') is not null drop table %s",sandt,sandt))
	block="block"*!anyof(charget(varlist("*"),"@type"),"strL")
	sql=sprintf(`"odbc insert, table("%s") create %s conn(%s)"',sandt,block,sc.connstr())
	sql_print(sql,"line")
	stata(sql)
	}

//!type: sql
stata("capture mata mata drop sql_move()")
void sql_move(string scalar orig, string scalar final) { //>>def func<<
	class sql_meta scalar sm
	
	sm.fromsql(orig)
	oparts=sql_rparts(orig,(2,3,23))
	fparts=sql_rparts(final,(2,3,23))
	if (oparts[1]!=fparts[1]) { //diff schema
		sql_submit(sql_ischema(fparts[1])+sprintf("alter schema %s transfer %s",fparts[1],oparts[3]))
		if (oparts[2]!=fparts[2]) sql_submit(sprintf("sp_rename '%s', '%s'",fparts[1]+"."+oparts[2],fparts[2]))
		}
	else if (oparts[2]!=fparts[2]) sql_submit(sprintf("sp_rename '%s', '%s'",oparts[3],fparts[2]))
	//sp rename moves all constraints, but doesn't rename them...
	sm.dest(final)
	sm.tosql()
	//get this into meta!
	oblob=sm.home_s+".dta_"+oparts[1]+"_"+oparts[2]
	fblob="dta_"+fparts[1]+"_"+fparts[2]
	sql_submit(sprintf("if object_id('%s') is not null exec sp_rename '%s', '%s'",oblob,oblob,fblob))
	}

//!type: sql
stata("capture mata mata drop sql_submit()")
string matrix sql_submit(string scalar sqlcode,| class sql_conn sc, matrix quiet) { //>>def func<<
	if (sqlcode=="el_holdcode") sqlcode=st_global("el_holdcode")
	
	if (substr(sqlcode,-1)!=";") sqlcode=sqlcode+";" //!
	if (!truish(quiet)) sql_print(sqlcode,"line")
	stata("capture log close")
	stata(sprintf("qui log using %s, replace text",sql2=pathto("_sql.log","i")))
	if (!length(sc)) {
		sc=sql_conn()
		sc.get()
		}
	stata("odbc exec("+char(34)+sqlcode+char(34)+sprintf("), conn(%s)",sc.connstr()))
	stata("qui log close")
	res=ftostr(sql2)
	if (!truish(res)) return(J(0,2,""))
	res=strtrim(colshape(cut(tokel(res,"|","-"),2),3)[,1..2]) //no col name causes error
	if (!any(truish(res))) return(J(0,2,""))
	for (r=1;r<=rows(res);r++) {
		if (res[r,1]!="") cr=r
		else res[cr,2]=res[cr,2]+res[r,2]
		}
	return(select(res,tru2(res[,1])))
	}

//!type: sql
//!sql_rparts: parse rightpaths into constituents (& repeat...)
//!paths: to parse
//!spec: elements of rpaths are 1=servers-db, 2=schema, 3=table each cell in spec is a 1-3 digit number, specifying which elements for that cell.
//!R: 1 row/path, 1 col/spec-cell
stata("capture mata mata drop sql_rparts()")
string vector sql_rparts(string scalar rpath,| real vector spec, class sql_conn sc) { //>>def func<<
	if (!length(rpath)) return(rpath)
	if (!length(sc)) {
		sc=sql_conn()
		sc.get()
		}
	elements=colwords(rpath,"r",3,".")
	elements=firstof(elements\(sc.field("database"),sc.field("schema"),""))
	if (args()==1) return(elements)
	
	if (any(regexm(strofreal(spec),"[^123]"))) errel("Parts of pathparts can only include digits 1,2,3",spec)
	out=J(1,cols(spec),"")
	for (c=1;c<=cols(spec);c++) out[,c]=concat(elements[,columnize(spec[c],"")],".","r")
	return(out)
	}

//!type: sql
stata("capture mata mata drop sql_ischema()")
string scalar sql_ischema(name,| class sql_conn sc) { //>>def func
	class elfs_sql scalar elf
	
	if (!length(sc)) {
		sc=sql_conn()
		sc.get()
		}
	auth=adorn("authorization ",subinstr(elf.get("Default owner"),"%db%",sc.field("database")))
	return(sprintf("if schema_id('%s') is null exec('create schema %s %s');\n",name,name,auth))
	//need BEGIN and END; around exec?
	}

end
//>>mosave<<
*!6jun2016
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).

version 11
mata:


stata("capture mata mata drop sql_write()")
void sql_write(string scalar cmd) { //>>def func
	class codex scalar cx
	class sql_conn scalar sc
	
	scmd=subcmdl(cmd,("wide","ljall","topofeach"))
	if (scmd=="wide") {
		syntaxl(cmd,&(codex="!using"), (&(path="sav:ing="),&(wide="!w:idedef="),&(lng="!l:ongdef="),&(cont="!c:ontent="),&(key="key=") ,&(grps="!g:roups=")))
		wide=tokel(wide,",")
		if (truish(wide)!=2) errel("A wide table and column name must each be specified.")
		lng=tokel(lng,",")
		if (truish(lng)!=2) errel("A long table and column name must each be specified.")
		cont=tokel(cont,",")
		if (!truish(cont)) errel("At least one content field must be specified.")
		
		idw_tab=wide[1]
		idw_col=wide[2]
		long_tab=lng[1]
		cx_col=lng[2]
		
		cx.readcode(codex)
		cx_vals=select(cx.keys[,5],cx.keys[,3]:==grps)
		
		
		path=pcanon(path,"f",".sql")
		sel=sprintf("select AA.%s",idw_col)
		from=sprintf("\nfrom %s AA\n",adorn("^t:",idw_tab))
		for (v=1;v<=length(cx_vals);v++) {
			for (c=1;c<=length(cont);c++) {
				if(cont[c]==lng[2]) sput(sel,sprintf("\n, case when CX%f.%s is null then 0 else 1 end %s",v,cx_col,cx_vals[v]),0)
				else sput(sel,sprintf(", CX%f.%s %s",v,cont[c],cx_vals[v]+"_"+cont[c]),0)
				}
			sput(from,sprintf("left join %s CX%f on AA.%s=CX%f.%s and CX%f.%s='%s'",adorn("^t:",long_tab),v,idw_col,v,idw_col,v,cx_col,cx_vals[v]))
			}
		fowrite(path,"^t=dopref"+eol()+sel+from)
		}
	else if (scmd=="ljall") {
		syntaxl(cmd,NULL,(&(path="!sav:ing="),&(prim="!pr:imary="),&(add="!add=")))
		
		prim=strtrim(tokel(prim,","))
		if (truish(prim)<2) errel("primary requires a table name and at least one column name.")
		add=strtrim(tokenstrip(tokel(add,",")))
		addc=add[,2]
		addt=add[,1]:+add[,4]
		if (truish(addt)<2) errel("At least 2 tables must be specified for ljall")
		
		sc.get()
		columns=sql_submit(sprintf("select table_name, ordinal_position, column_name from information_schema.columns where table_schema='%s' and table_name in(%s)",sc.field("schema"),concat(adorn("'",addt,"'"),",")),sc)
		
		columns=strtrim(strlower(colshape(columns[,2],3)))
		columns=select(columns,columns[,3]:!=prim[,2]) //case, etc!
		for (t=1;t<=length(addt);t++) {
			if (truish(addc[t])) columns=select(columns,columns[,1]:!=addt[t]:|asvmatch(columns[,3],addc[t],"m"))
			}
		sorter=vmap(columns[,1],addt),strtoreal(columns[,2])
		columns=columns[,3]
		cosort_((&sorter,&columns),(1,1\1,2))
		
		path=pcanon(path,"f",".sql")
		sput(sel="",sprintf("select AA.*, %s",concat(columns,",")))
		from=sprintf("from %s AA\n",adorn("^t:",prim[1]))
		for (a=1;a<=length(addt);a++) {
			sput(from,sprintf("left join %s BB%f on AA.%s=BB%f.%s",adorn("^t:",addt[a]),a,prim[2],a,prim[2]))
			}
		fowrite(path,"^t=dopref"+eol()+sel+from)
		}
	else if (scmd=="topofeach") {
		syntaxl(cmd,NULL,(&(path="!sav:ing="),&(top="top="),&(cols="!cols="), &(ta="!ta="),&(tb="!tb="),&(jo="!jo:inon="),&(vals="!vals=")))
		top=strtoreal(top)
		vals=tokel(vals)
	
		path=pcanon(path,"f",".sql")
		sel=""
		for (v=1;v<=length(vals);v++) {
			sel=adorn("",sel,"union"+eol())
			sput(sel,sprintf("select top %f %s",top,cols))
			sput(sel,sprintf("from %s AA join %s BB on AA.%s=BB.%s",ta,tb,jo,jo))
			sput(sel,sprintf("where AA.each='%s'",vals[v]))
			}
		fowrite(path,"^t=dopref"+eol()+sel)
		}
	else errel("Unrecognized sql write subcommand")
	}
end
//>>mosave
*!31mar2014
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

end
 global sdb (`"!"#%&*+select table_schema s_name, table_name t_name, column_name c_name, data_type dtype,  coalesce(character_maximum_length, max_length) size, rows, ordinal_position, modify_date mod_date%from information_schema.columns AA%left join sys.tables BB on schema_id(table_schema)=schema_id and table_name=BB.name%left join sys.partitions CC on BB.object_id=CC.object_id%left join sys.types DD on data_type=DD.name%join information_schema.schemata EE on table_schema=EE.schema_name%where left(schema_owner,1)=*u*"')
 mata:
end
 global jqy (`"!"%&*-/*(document).ready(function(){&		*(-p.expander-).click(function() {*(this).toggleClass(-expanded collapsed-); *(this).next().slideToggle(200)});&		*(-tr[qcid]-).click(function() {*(-#-+*(this).attr(-qcid-)).animate({width:-toggle-})});&		*(-tr[qcid]-).hover(function() {*(this).css(-color-,-orange-)},function() {*(this).css(-color-,--)})&		*(-tr[qsqid]-).click(function() {qt=*(this).attr(-qsqid-);*(-#-+qt).popup({autoopen:true})});&		*(-tr[qsqid]-).hover(function() {*(this).css(-color-,-orange-)},function() {*(this).css(-color-,--)})&		*(-.qcols-).click(function() {*(this).animate({width:-toggle-})});&});"')
 mata:
end
 global css (`"!"%&()*h3 {color:white; font-weight: bold;margin-left:1.5em}&.bod {display:none; padding-left:1.2em}&table {cursor: pointer}&.qid {float:left}&.qcols {float: left; display: none}&.qcode {display:none; padding:1em;background-color:white; border-radius:1em}&.qcode p.qname {background-color:#AACCDD;color:white;font-weight:bold;text-align:center;font-size:1.15em}&[qsqid] {color:gray}&.expander {font-size: 1.2em; cursor: pointer; color:darkgray; font-weight: bold; padding-left:1.5em}&body {background-color:#AACCDD}&.section {background-color:white; padding: .5em; margin: .5em; border-radius: 15px}&.divend {clear: both}"')
 mata:
end
 global expcol (`"!"#%&*<.expanded {background-position: left center; background-repeat: no-repeat; background-image: url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAIAAAC0tAIdAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAVUlEQVR42q3y0Q3AIAhEAXQY9t+DqWiTRiRwpzHy/DvefSg+dsK1rYON7V6kw4ZqKkxbRFTB+XJs18IfUjsWPMG39HGEvkktpCnYDlONbR6q1vBPFrzG2j6uDNI67AAAAABJRU5ErkJggg==)%	}%.collapsed {background-position: left center; background-repeat: no-repeat; background-image: url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAIAAAC0tAIdAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAQklEQVR42r3wwQ0AIAgDATCM++/BVOrHvqhpTeTed4Q0pkOnnZnjcLO3B1hQ2yyIUmWBZCN4uu39bW+CRtpb4ae9AFyEPq6YRshcAAAAAElFTkSuQmCC)%	}%"')
 mata:

//!type: sql
stata("capture mata mata drop sqldb()")
void sqldb(string scalar main) { //>>def func<<
	class tabel scalar t
	class htmlpgs scalar page
	class htmltable scalar ht
	class sql_meta scalar sm
	class sql_conn scalar sc
	class elfs_out scalar elfo
	class elfs_sql scalar elfs
	class recentle_proj scalar prj
	
	syntaxl(main,&(schemas="anything"), (&(path="p:ath="),&(saving="sav:ing="),&(portable="port:able")))
	if (truish(saving)) saving=pcanon(saving,"file",".html")
	
	prj.get()
	prjdb=prj.oth_get("sqldb")
	if (length(prjdb)!=4) prjdb=J(1,4,"")
	if (truish(path)) sc.userset(path)
	else sc.userset(prjdb[1])
	schemas=firstof(schemas\prjdb[2]\"*")
	savdir=firstof(pathparts(saving,1)\prjdb[3]\prj.prjdir\pwd())
	savnam=firstof(pathparts(saving,2)\prjdb[4]\sc.field("database"))
	prj.oth_set("sqldb",(sc.humstr(),schemas,savdir,savnam))
	
	sm.makesql()
	sql_dnload("bkgrnd",sprintf("select * from %s",sm.home_s+"."+sm.home_t),sc)
	qs=el_sdata(.,varlist("*"))
	//gotta check that columns match current def
	qklu=columnize(colshape(adorn(concat(qs[,1..2],":"):+":",columnize(qs[,5],","),"!":+qs[,3]),1),"!")
	qklu=expand(qklu,2) //for now cols listed; not sure what to really do
	
	sql_dnload("bkgrnd",strob_to($sdb),sc) //schemas are now restricted to owner 'u' - improve this kluge
	
	stata(sprintf(`"qui gen str%f q_name="""',max(strlen(qklu[,2])\1)))
	stata("order q_name, after(t_name)")
	el_view(V=.,.,"q_name")
	V[.]=lookupin(qklu[,2],vmap(strlower(concat(el_data(.,(1,2,4)),":")),qklu[,1]))
	/**/stata(sprintf(`"qui replace q_name="%s" if mi(q_name)"',sm.nquery))
	
	stata("qui destring rows, replace")
	stata("qui replace size=. if size<0")
	stata("qui bysort s_name t_name q_name: egen qtot=total(rows*size/1000000)")
	stata("qui bysort s_name t_name: egen tot=total(rows*size/1000000)")
	stata("qui tostring size rows, replace format(%12.0fc) force")
	
	cols=strlower(el_data(.,("s_name","t_name","q_name","c_name","dtype","size"))) //dtype
	corder=el_data(.,"ordinal_position")
	if (length(qs)) {
		key=concat(cols[,1..3],":")
		qmap=vmap(concat(qs[,1..3],":"),key)
		qs[,5]=strofreal(lookupin(el_data(.,"qtot"),qmap),"%5.0f")
		qs=select(qs,qmap) //drop orphan qs
		}
	
	stata(`"qui gen totstr=string(tot,"%9.0f")"')
	stata(`"qui gen modstr=string(mod_date,"%tcCCYY-NN-DD_HH:MM")"')
	tabs=strlower(uniqrows(el_data(.,("s_name","t_name"/*,qname*/,"rows","totstr","modstr"))))
	
	dflt=strlower(elfs.get("Default schema"))
	atabs=tabs[,1..2],J(rows(tabs),1,""),tabs[,3..5],J(rows(tabs),3,"")\qs[,(1..3,6,5,7,4,8,9)]
	sorder=(atabs[,1]:==dflt):+2:*(strhas(atabs[,1],"\")):+4:*(atabs[,1]:==sm.home_s)
	sorder=recode(sorder,(0,3))
	cosort_((&sorder,&atabs),(1,1\2,1\2,2\2,3))
	
	sorder=(cols[,1]:==dflt):+2:*(strhas(cols[,1],"\")):+4:*(cols[,1]:==sm.home_s)
	sorder=recode(sorder,(0,3))
	cosort_((&sorder,&cols,&corder),(1,1\2,1\2,2\3,1))
	
	if (truish(schemas)&schemas!="*") {
		atabs=select(atabs,asvmatch(atabs[,1],schemas,"multi"))
		cols=select(cols,asvmatch(cols[,1],schemas,"multi"))
		}
	
	page.page()
	page.addfw("html_fw_jquery",portable)
	page.addfw("html_fw_jquerypopupoverlay",portable)
	page.addcss(strob_to($expcol))
	page.addcss(strob_to($css))
	t.o_parse("htm")
	elfo.init(elfo.mhtml)
	tscheme=elfo.get("")
	tscheme[,1]=subinstr(tscheme[,1],".",".ht_") 
	page.addcss(concat(tscheme[,1]:+" {":+tscheme[,2]:+"}"," "))
	page.addjs(strob_to($jqy))
	
	page.div("all") /*?? or make each div, or include this somewhere else*/
	page.place("<h3>"+sc.field("database")+"&emsp;|&emsp;"+schemas+"&emsp;|&emsp;"+datetime()+"</h3>")
	
	sixs=toindices(differ(atabs[,1],"b","t")),toindices(differ(atabs[,1],"","t"))
	cixs=toindices(differ(concat(cols[,1..2],":"),"b","t")),toindices(differ(concat(cols[,1..2],":"),"","t"))
	cix=0
	isqrow=tru2(atabs[,3])
	qid=isqrow:*"qsqid='":+!isqrow:*"qcid='":+atabs[,1]:+"-":+atabs[,2]:+isqrow:*("-":+atabs[,3]):+"'"
	qtip=isqrow:*(" title='":+atabs[,7]:+"'")
	
	for (s=1;s<=rows(sixs);s++) {
		sixr=sixs[s,1]..sixs[s,2]
		page.place("<div class='section'><p class='expander collapsed'>"+atabs[sixs[s,1],1]+"</p>")
		page.place("<div class='bod'>")
		
		t.body="Table","","Rows","MB","Mod Date"\"","Qname","Qtime","MB","Run Date"\atabs[sixr,2]:*!isqrow[sixr],atabs[sixr,3..6]
		t.head=2
		t.altrows=1
		t.set(t._align,.,1..2,t.left)
		t.padbefore=t.padafter=0
		t.render()
		
		ht.read(t.rendered)
		t.rendered="" //what is this??
		ht.trows[2]="style='color:gray'"
		ht.trows[3..rows(ht.trows)]=qid[sixr]
		ht.tcells[3..rows(ht.trows),2]=ht.tcells[3..rows(ht.trows),2]+qtip[sixr]
		page.place("<div class='qid'>"+ht.write()+"</div>")
		
		for (six=sixs[s,1];six<=sixs[s,2];six++) {
			if (!isqrow[six]) {
				++cix
				t.body=cols[cixs[cix,1],2],J(1,3,"")\"Qname","Column","Type","Size"\
				cols[cixs[cix,1]..cixs[cix,2],3..6]
				t.head=2
				t.altrows=1
				t.set(t._align,.,1..2,t.left)
				t.set(t._align,1,1,t.left)
				t.set(t._span,1,1,4)
				t.padbefore=t.padafter=0
				t.render()
				page.addcss(t.o_scheme, t.s_body)
				page.place("<div id='"+atabs[six,1]+"-"+atabs[six,2]+"' class='qcols'>"+t.rendered+"</div>")
				t.rendered="" //why??
				}
			}
		page.place("<div class='divend'></div></div></div>")
		}
	
	qs=select(atabs,isqrow)
	qssub=subinstrf(subinstrf(subinstrf(qs[,9],"<","&lt;"),">","&gt;"),char(10),"<br />"):+"<hr>":+qs[,8]
	qsnam=concat(qs[,1..3],"-")
	page.place(concat("<div class='qcode' id='":+qsnam:+"'>":+adorn("<p class='qname'>",qsnam,"</p>"):+qssub:+"</div>",eol()))
	
	page.write("",saving=savdir+savnam)
	//prj.oth_write()
	launchfile(saving)
	}
end
//>>mosave<<

*! 23may2014
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:





//!type: sql
stata("capture mata mata drop sqlget()")
void sqlget(string scalar main) { //>>def func<<
	class sql_meta scalar sm
	class dataset_dta scalar ds
	class recentle_data scalar rld
	class sql_conn scalar sc
	
	syntaxl(main,&(tpath="anything"),(&(keep="k:eep="),&(where="where="),&(quick="q:uick="),&(dist="d:istinct"), &(rand="r:andomize="),&(verb="v:erbose")))
	
	req=(!truish(main)|main=="<") //won't work for sqli !
	if (req) {
		rld.ncmd="sql"
		rld.nmode="get"
		rld.get(main)
		sc.userset(rld.ndir)
		sandt=sm.home_s+".dta_"+sc.field("schema")+"_"+rld.nfile
		}
	else {
		tpath=sql_rparts(tpath,(1,2,3,123))
		sandt=sm.home_s+".dta_"+tpath[2]+"_"+tpath[3]
		}
	
	sql_dnload("bkgrnd",sprintf("if object_id('%s') is not null  select * from %s else select 'zip' a, 'zip' b",sandt,sandt))
	if (st_nvar()==1) {
		fowrite(blob=pathto("_dtameta.dta"),_st_sdata(1,1))
		ds.with("c l")
		ds.readfile(blob)
		}
	
	if (req) {
		//	sm.fromsql() no meta for re-sqli
		sql_dnload(("get","re-query"),rld.ndetails,sc)
		}
	else {
		rand=tokenpair(rand,"=")'
		keep=keep+adorn(truish(keep)?" ":"* ",rand[1])
		andtop=rpref=rjoin=""
		if (truish(quick)&tpath[1]=="cdwwork") {
			sql_dnload("bkgrnd",sprintf("if object_id('cdwwork.meta.dwindex') is not null select indexcolumns from cdwwork.meta.dwindex where dwviewname='%s' and clusteredflag='y'",tpath[3]))
			if (st_nobs()==1) cix=regexs2(el_data(.,.),",([^,]+DateTime)",1)
			if (verb) stata("tlist")
			if (truish(cix)) andtop=sprintf(" %s>='%s'",cix,strofreal(dofq(qofd(dofc(datetime(".")))-1),"%td_CY-N-D"))
			}
		if (truish(keep)) {
			sql_dnload("bkgrnd",sprintf("select column_name, ordinal_position from %s.information_schema.columns where table_schema='%s' and table_name='%s'",tpath[1],tpath[2],tpath[3]))
			stata("sort ordinal")
			stata("drop ordinal")
			if (verb) stata("tlist")
			tcols=strlower(el_data(.,.))'
			
			kvars=varlistk(tcols,keep,"nfrep")
			if (truish(rand[1])) {
				rand[1]=varlistk(kvars,rand[1])
				rand[2]=firstof(rand[2]\"rid")
				recode_(kvars,rand)
				}
			kvars=firstof(concat(kvars,",")\"*")
			}
		else kvars="*"
		if (truish(rand)) {
			rpref=sprintf("with dids as (select distinct %s from %s), rids as (select %s, row_number() over(order by newid()) %s from dids) ",rand[1],tpath[4],rand[1],rand[2])
			rjoin=sprintf(" AA join rids BB on AA.%s=BB.%s",rand[1],rand[1])
			}
		sql=rpref+sprintf("select %s %s %s from %s %s %s ",dist*"distinct",adorn("top ",quick),kvars,tpath[4],rjoin,adorn("where ",concat((where,andtop),"and")))
		sm.fromsql(tpath[4])
		sql_dnload(("get",tpath[3]),sql)
		}
	
	if (ds.nvars) {
		stvars=varlist("*")
		stata(sprintf("order %s",concat(lookupin(ds.vnames,vmap(stvars,ds.vnames))," ")))
		//label extra vars as unknown
		stvars=varlist("*")
		map=vmap(ds.vnames,stvars)
		//message?
		for (n=1;n<=ds.nvars;n++) {
			if (map[n]) {
				st_varlabel(map[n],ds.nlabels[n])
				if (strlen(ds.vlabrefs[n])) st_varvaluelabel(map[n],ds.vlabrefs[n]) //error for strings otherwise
				st_varformat(map[n],ds.formats[n])
				if (st_vartype(map[n])=="double"&ds.bytes[n]==4) stata(sprintf("recast float %s",ds.vnames[n]))
				}
			chars=select(ds.chars,ds.chars[,1]:==ds.vnames[n])
			if (truish(chars)) charset(ds.vnames[n],chars[,2],chars[,3])
			}
		for (n=1;n<=length(ds.vlabnames);n++) {
			st_vlmodify(ds.vlabnames[n],strtoreal((*ds.vlabtabs[n])[,1]),(*ds.vlabtabs[n])[,2])
			}
		charset("_dta","@lab",ds.dtalabel)
		}
	
	sm.todta()
	stata("del, nov")
	}
end
//>>mosave<<

*! 17apr2014
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
*! split from sqldo 24jun2015
version 11
mata:
end
 global mtoo (`"!"#&*+-select c.name, +ix+ type&from sys.columns c&join sys.index_columns ic&on c.object_id=ic.object_id and c.column_id=ic.column_id&where ic.index_id=1 and ic.object_id=object_id(+%s+)&union&select name, +add+ type&from sys.columns&where object_id=object_id(+%s+)"')
 mata:
end
 global mergesql (`"!"#%&*-declare @mixcols table (name varchar(100));%declare @anoncols table (name varchar(100), dtype varchar(50));%declare @drcols varchar(1000);%declare @addcols varchar(1000);%declare @upcols varchar(1000);%declare @ixjoin varchar(1000);%%insert into @mixcols%select c.name%from sys.columns c%join sys.index_columns ic%on c.object_id=ic.object_id and c.column_id=ic.column_id%where ic.index_id=1 and ic.object_id=object_id(@master);%%select @ixjoin= coalesce(@ixjoin+* and *,**)+*m.*+name+*=a.*+name%from @mixcols;%%insert into @anoncols%select c.name, CASE WHEN ty.name in (*char*,*varchar*,*nchar*,*nvarchar*,*binary*,*varbinary*) THEN ty.name+*(* + CAST(c.max_length AS varchar(4)) + *)* ELSE ty.name END dtype%from ^^fuck^^sys.columns c%join sys.types ty%on c.user_type_id = ty.user_type_id %where c.object_id=object_id(@tempdb+@adder) and not exists (%select 1%from @mixcols m%where m.name=c.name%);%%if @@rowcount=0%begin%set @addcols= @qname+* tinyint constraint wdef default 0 with values*%set @upcols= @qname+*= case when exists a.*+(select top 1 name from @mixcols)+* then 1 else 0 end*%insert into @anoncols select @qname name, *tinyint* dtype%end%else%begin%select @addcols= coalesce(@addcols+*, *,**)+name+* *+dtype from @anoncols;%select @upcols=coalesce(@upcols+*, *,**)+name+*=a.*+name from @anoncols;%end;%%with%mdrcols as (%select c.name%from sys.columns c%join @anoncols a%on c.name=a.name%where object_id=object_id(@master))%%select @drcols= coalesce(@drcols+*, *,**)+name%from mdrcols;%%if @drcols is not null exec (*alter table *+@master+* drop column *+@drcols+*;*);%exec (*alter table *+@master+* add *+@addcols+*;*);%exec (*update *+@master+* set *+@upcols+* from *+@master+* m left join *+@adder+* a on *+@ixjoin+*;*);"')
 mata:

//!type: sql
stata("capture mata mata drop sqlmerge()")
void sqlmerge(string vector dest, class sql_meta scalar sm,| matrix keep) { //>>def func
	adder=sm.db+sm.s_name+"."+sm.t_name
	//if (!truish(sm.q_name)) errel("No meta-data for merge")
	sm.dest(dest[1])
	sm.q_name=dest[2]
	
	sql=sprintf(strob_to($mtoo),sm.dest,adder)
	x=colshape(sql_submit(sql)[,2],2)
	ixs=select(x[,1],x[,2]:=="ix")
	if (!length(ixs)) errel("Master table isn't indexed") //nothing to enforce unique...
	adds=select(x[,1],x[,2]:=="add")
	not=vmap(adds,ixs)
	if (truish(not)!=length(ixs)) errel("Merging table doesn't include necessary index columns")
	sm.q_cols=concat(select(adds,!not),",")
	
	sput(sql="",sprintf("declare @master varchar(100) ='%s';",sm.dest))
	sput(sql,sprintf("declare @adder varchar(100) ='%s';",adder))
	tdb=substr(adder,1,1)=="#"
	sput(sql,sprintf("declare @tempdb varchar(10) ='%s';",tdb?"tempdb..":""))
	sput(sql,sprintf("declare @qname varchar(100) ='%s';",sm.q_name))
	sput(sql,subinstr(strob_to($mergesql),"^^fuck^^",tdb?"tempdb.":""))
	if (!truish(keep)) sput(sql,sprintf("drop table %s",adder))
	
	sql_submit(sql)
	sm.tosql("merge")
	}
end
//>>mosave
*! 23dec2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: string
//!ssort: stable sort of string matrix
//!in: matrix to sort
//!ixs: columns to sort on; stable order on the rest
//!R: sorted matrix
stata("capture mata mata drop ssort()")
string matrix ssort(string matrix in, real rowvector ixs) { //>>def func<<
	if (!length(in)|!length(ixs)) return(in)
	o=order(in,ixs)
	d=runningsum(differ(concat(in[o,ixs],"","r"),"prev"))
	o2=order((d,(1::rows(d))[o]),(1,2))
	return(in[o,][o2,])
	}
end
//>>mosave<<
*! 23dec2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:
//!type: gears
//!R: "Stata[flavor]-[bit].exe"
stata("capture mata mata drop stataexe()")
string scalar stataexe() { //>>def func<<
	//I don't really know if these are right, other than MP-64
	return(sprintf("Stata%s-%f.exe",("","IC","SE","MP")[1+(c("flavor")=="IC")+c("SE")+c("MP")],c("bit")))
	}
end
//>>mosave<<
*!unknown v10.1
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:
//!type: string
stata("capture mata mata drop strcount()")
real matrix strcount(string matrix in, string scalar target) { //>>def func<<
	cnt=J(rows(in),cols(in),0)
	if (any(strlen(in))) {
		text=in
		while(any(pos=strpos(text,target))) {
			cnt=cnt:+(pos:>0)
			text=substr(text,pos:+1)
			}
		}
	return(cnt)
	}

end
//>>mosave<<
*! 21dec2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:
//!type: string
//!strhas: Whether a string contains any substring
//!in: string(s) to search
//!test: set of substrings to search for
//!pos: when specified, tests for substrings only at that position; accepts neg pos
//!R: t/f for every cell of {in}
stata("capture mata mata drop strhas()")
real matrix strhas(string matrix in, string vector test,| real scalar pos) { //>>def func<<
	out=J(rows(in),cols(in),0)
	if (!length(in)) return(out)
	orblank=any(test:=="")
	test=select(test,tru2(test))
	if (truish(pos)) for (t=1;t<=length(test);t++) out=out:|substr(in,pos,strlen(test[t])):==test[t]
	else for (t=1;t<=length(test);t++) out=out:|strpos(in,test[t])
	if (orblank) out=out:|in:==""
	return(out)
	}
end
//>>mosave<<
*!3mar2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.1
mata:
//!type: string
//!strlast: get last (rightmost) position of a substring
//!body: to search in
//!bit: to search for
//!R: for each cell, position of rightmost find, or strlen+1 if not found
stata("capture mata mata drop strlast()")
real matrix strlast(string matrix body, string matrix bit) { //>>def func<<
	blen=strlen(body):+1
	ya=strpos(strreverse(body),strreverse(bit))
	return((ya:>0):*(blen:-ya:-strlen(bit):+1):+(!ya:*blen))
	}
end
//>>mosave<<
*! 19aug2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.1
mata:
//!type: gears
//!strob_of: translate a matrix into a string literal for use in mata (&stata) code
//!gname: name of global macro to hold result
//!datain: variable to translate; empty matrices only up to 255x255
//!notrack: by default, globals are tracked for later dropping
stata("capture mata mata drop strob_of()")
void strob_of(string scalar gname, string matrix datain,| matrix notrack) { //>>def func<<
	//when printed in do files, control characters, line feeds, macro chars cause problems, need to be excluded
	if (!length(datain)) {
		data=strofreal(rows(datain),"%03.0f")+strofreal(cols(datain),"%03.0f")
		if (strlen(data)>6) errel("Empty strob matrices can only be up to 999 rows or cols")
		}
	else {
		dels=charsubs(datain,7,(1..31,36,39,96))
		data=datain:+(datain:==""):*dels[1] //empty cells - concat & columnize (used to) both drop empty cells
		if (cols(data)>1) data=concat(data,dels[2]) //cols
		data=concat(data,dels[3]) //rows
		data=subinstr(data,eol(),dels[4]) //hope eol is good enough...
		data=subinstr(data,"$",dels[5])
		data=subinstr(data,"'",dels[6])
		data=subinstr(data,"`",dels[7])
		data=concat(dels,"")+data
		}
	data=char((96,34))+data+char((34,39))
	st_global(gname,data)
	}

//!type: gears
//!strob_to: translate a string literal created by strob_of back into a matrix
//!gcontent: global macro (ie, the string literal)
//!R: unpacked strob
stata("capture mata mata drop strob_to()")
string matrix strob_to(string scalar gcontent) { //>>def func<<
	if (strlen(gcontent)<7) return(J(strtoreal(substr(gcontent,1,3)),strtoreal(substr(gcontent,4,6)),""))
	
	dels=columnize(substr(gcontent,1,7),"")
	data=columnize(substr(gcontent,8),dels[3])'
	data=columnize(data,dels[2])
	data=subinstr(data,dels[1],"") //eol here should be fine...
	data=subinstr(data,dels[4],eol()) //eol here should be fine...
	data=subinstr(data,dels[5],"$") //eol here should be fine...
	data=subinstr(data,dels[6],"'") //eol here should be fine...
	data=subinstr(data,dels[7],"`") //eol here should be fine...
	return(data)
	}

end
//>>mosave<<
*!5feb2016
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: string
//!strstd: standardized string
//!in: string to adjust
//!dont: actually just leave alone
//!R: no tab, lf, cr, leading, trailing, mult int; lowercase
stata("capture mata mata drop strstd()")
string matrix strstd(string matrix in,|matrix dont) { //>>def func
	if (truish(dont)) return(in)
	out=subinstrf(in,char(9)," ")
	out=subinstrf(out,char(10)," ")
	out=subinstrf(out,char(13)," ")
	out=strtrim(stritrim(out))
	out=strlower(out)
	return(out)
	}
end
//>>mosave
*! 1may2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.1
mata: 

//!type: stata
//!strvars: whether vars are string or numeric
//!vnames: names of variables to check
//!R: 1 for str variable 0 for anything else
stata("capture mata mata drop strvars()")
real vector strvars(vector vnames) { //>>def func<<
	sn=rowshape(vnames,1)
	if (eltype(sn)=="string") sn=_st_varindex(sn)
	for (v=1;v<=length(sn);v++) if(sn[v]!=.) sn[v]=st_isstrvar(sn[v])
	return(shapeof(sn,vnames))
	}

end 
//>>mosave<<
*!29jan2016
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: parse
//!subcmdl: extract subcommand
//!meat: entire subcommand line, will return line minus subcommand
//!allowed: ocanon vector of allowed values
//!oknone: truish means null sub-command is allowed
//!R: (o)canonical subcommand word
stata("capture mata mata drop subcmdl()")
string scalar subcmdl(string scalar meat, string vector allowed,| matrix oknone) { //>>def func
	cmd=expand(tokel(meat,","),2)
	if (length(cmd)>2) errel("Too many commas on the command line")
	
	scmd=expand(tokel(cmd[1],"","","",1),2)
	if (truish(scmd[1])) scmd[1]=ocanon("sub-command",scmd[1],allowed)
	else if (!truish(oknone)) errel("A sub-command is required")
	meat=scmd[2]+adorn(",",cmd[2])
	return(scmd[1])
	}
end
//>>mosave
	
*!unknown v10.1
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata: 

//!type: paths
stata("capture mata mata drop subfiles()")
string colvector subfiles(string colvector start,| string vector match, real scalar maxd) { //>>def func<<
	dirs=start; files=J(0,1,""); i=0; mark=length(start); depth=1 
	if (args()<2) match="*.*" 
	if (args()<3) maxd=. 
	while (i<length(dirs)&depth<maxd) { 
		dirs=dirs\dir(dirs[++i],"dirs","*",1) 
		depth=depth+(i==mark) 
		if (i==mark) mark=rows(dirs) 
		} 
	for (i=rows(dirs);i;i--) {
		for (j=length(match);j;j--) files=files\dir(dirs[i],"files",match[j],1)
		}
	if (length(files)) return(sort(files,1))
	//if (length(files)) return(subinstr(sort(files,1),"\","/")) //changing with dir() to handle mixed case
	//if (length(files)) return(strlower(subinstr(sort(files,1),"\","/"))) 
	else return(J(0,1,""))
	} 

end 
//>>mosave<<
*!21may2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:
//!type: string
//!subinstrf: fixes subinstr to accept void matrices
//!s: the text to substitute in
//!old: text to find
//!newer: text to replace with
//!cnt: number of times to replace, if limited
//!R: matrix of substrings, or NOTHING!
stata("capture mata mata drop subinstrf()")
string matrix subinstrf(string matrix s, string matrix old, string matrix newer, |real matrix cnt) { //>>def func<<
	if (!length(s)|!length(old)|!length(newer)) return(s)
	if (!length(cnt)) return(subinstr(s,old,newer))
	return(subinstr(s,old,newer,cnt))
	}
end
//>>mosave<<
*!8mar2013 maybe
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:
//!type: string
//!substrf: fixes substr to accept void matrices
//!body: the text to search
//!start: starting position
//!length: length of substring
//!R: matrix of substrings, or NOTHING!
stata("capture mata mata drop substrf()")
string matrix substrf(string matrix body, real matrix start,|real matrix length) { //>>def func<<
	if (!length(body)) return(body)
	if (!length(length)) length=.
	return(substr(body,start,length))
	}
end
//>>mosave<<
*! 26jan2011
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.1
mata:

//!type: parse
stata("capture mata mata drop syntaxl()")
void syntaxl(string scalar meatin, pointer vector main, | pointer vector optsin, string scalar remainder) { //>>def func<<
	meat=expand(tokel(meatin,","),1)
	if (length(meat)>2) errel("Too many commas on command line...")
	
	if (truish(main)) {
		start=J(1,length(main),"")
		for (a=1;a<=length(main);a++) start[a]=*main[a]
		mandies=substr(start,1,1):=="!"
		start=subinstr(start,"!","")
		
		cmd=strtrim(expand(tokel(" "+cut(meat,1,1),(" ["\" if "\" in "\" using "),"",dels),1))
		inp=toindices(dels:==" in ","z")
		ifp=toindices(dels:==" if ","z")
		up=toindices(dels:==" using ","z")
		wp=toindices(dels:==" [","z")
		
		if (ix=toindices(start:=="anything","z")) {
			*main[ix]=cut(cmd,1,1)
			if (!strlen(*main[ix])& mandies[ix]) errel("This command requires a (main) parameter")
			}
		if (ix=toindices(start:=="ifin","z")) { //need to make sure ifin ends up as in... if... (for later concat)
			*main[ix]=concat((cut(dels,inp,inp),cut(cmd,inp,inp),cut(dels,ifp,ifp),cut(cmd,ifp,ifp)),"")
			if (!strlen(*main[ix]) & mandies[ix]) errel("-if/in- missing")
			}
		else if (inp+ifp) errel ("-if/in- not allowed")
		if (ix=toindices(start:=="using","z")) {
			*main[ix]=expand(cut(cmd,up,up),1)
			if (!strlen(*main[ix]) & mandies[ix]) errel("-using- is missing")
			}
		else if (up) errel("-using- not allowed")
		if (ix=toindices(start:=="weight","z")) {
			//should handle different kins of weight here
			wgts=tokel(subinstr(cut(cmd,wp,wp,1),"]",""),"=")
			if (length(wgts)>1) {
				type=substrf(cut(wgts,1,1),1,2)
				if (truish(type)&type!="fw") errel("Only frequency weights are supported at the moment")
				}
			*main[ix]=expand(cut(wgts,-1),1)
			}
		else if (wp) errel("-weight- not allowed")
		}
	if (length(optsin)) optionel(cut(meat,2,.,1),optsin,remainder)
	}

end
//>>mosave<<
*! 9mar2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:
//!type: stata
//!tinytype: find smallest stata datatype of mata vector
//!data: vector to analyse
//!R: stata datatype
stata("capture mata mata drop tinytype()")
string scalar tinytype(vector data) { //>>def func<<
	if (eltype(data)=="string") {
		if (!length(data)) return("str1")
		maxs=pmax(1,max(strlen(data)))
		if (maxs>2045) return("strL")
		else return("str"+strofreal(maxs))
		}
	
	if (!length(data)) return("byte")
	mind=min(data)
	maxd=max(data)
	if (trunc(data)==data) {
		if (mind<c("minint")|maxd>c("maxint")) return("long")
		if (mind<c("minbyte")|maxd>c("maxbyte")) return("int")
		return("byte")
		}
	else {
		if (mind<c("minfloat")|maxd>c("maxfloat")) return("double")
		else return("float")
		}
	}
end
//>>mosave<<
*! 31may2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: trans
//!tohexff: translates decimal to hex
//!in: decimal (real/string)
//!digits: digits of output - using leading 0's
//!R: hex
stata("capture mata mata drop tohexff()")
string matrix tohexff(matrix in,| real scalar digits) { //>>def func<<
	if (args()<2) digits=2
	dec=(eltype(in)=="string")?strtoreal(in):in
	dec=trunc(dec)
	if (any(dec:<0)|hasmissing(dec)) errel("tohexFF only takes non-negative, non-missing numbers")
	out=J(rows(dec),cols(dec),"")
	for (r=1;r<=rows(out);r++) {
		for (c=1;c<=cols(out);c++) {
			i=1
			do {
				hd=mod(dec[r,c],16)
				dec[r,c]=(dec[r,c]-hd)/16
				i++
				out[r,c]=(hd>9?substr("ABCDEF",hd-9,1):strofreal(hd))+out[r,c]
				} while(dec[r,c]!=0)
			while (strlen(out[r,c])<digits) out[r,c]="0"+out[r,c]
			}
		}
	return(out)
	}
end
//>>mosave<<

*! 26jan2011
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: search
stata("capture mata mata drop toindices()")
real vector toindices(vector body,| scalar zero) { //>>def func<<
	if (length(body)) t=select(rowshape(1..length(body),rows(body)),eltype(body)=="string"?strlen(body):body)
	if (length(t)) return(t)
	else if (args()==2) return(0)
	else if (orgtype(body)=="colvector") return(J(0,1,0))
	else return(J(1,0,0))
	}
//handles t=0,0 after select
end
//>>mosave<<
*!3mar2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.1
mata:
//!type: parse
//!tokel: get tokens, ignoring parsers inside grouping chars
//!bodyin: string to parse
//!dels: delimiters to parse on; defaults to space. Cell boundaries are always delimiters
//!pskips: col1=openers, col2=closers; defaults to parentheses; one cell dash [-] causes no skips. double and compound quotes always skip (?!)
//!each: has 2 aspects: 1) it determines whether to parse on each consecutive delimiter. 2) it can return the delimiters for each cell. Default behavior depends on the delimiter: multiple spaces are treated as 1 delimiter by default; anything else as multiple delimiters. Setting [each] to any nonempty value will switch the behavior. But: if [each] is a variable (rather than an expression) each consecutive delimiter is parsed, and [each] will return the vector of delimiters.
//!N: max number of tokens to parse (ie, add to input vect)
//!R: tokens
stata("capture mata mata drop tokel()")
string rowvector tokel(string vector bodyin,|string colvector dels, string matrix pskips, matrix each, real scalar N) { //>>def func<<
	if (!length(bodyin)) return(J(1,0,""))
	if (!truish(dels)) dels=" "
	else dels=dels[order(strlen(dels),-1)]
	empties=!isfleeting(each)|(truish(each)&dels==" ")|(!truish(each)&dels!=" ")
	if (length(bodyin)>1) {
		dels=charsubs(bodyin,1)\dels
		body=concat(bodyin,dels[1],"e")
		}
	else body=bodyin
	if (pskips=="-") skips=J(1,2,charsubs(body,1))
	else {
		if (!truish(pskips)) skips=("(",")")
		else skips=pskips[order(strlen(pskips),-1),]
		skips=quotes()\skips
		}
	each=""
	out=J(1,0,"")
	bit=""
	while (length(out)<N&strlen(body)) {
		dpos=strpos(body,dels)
		dix=editmissing(min(select(dpos,dpos)),0)
		spos=strpos(body,skips[,1])
		skix=editmissing(min(select(spos,spos)),0)
		if (!dix) {
			bit=bit+body
			body=""
			}
		else if (!skix|dix<skix) {
			if (dix) each=each,dels[toindices(dpos:==dix)[1]]
			if (empties|strlen(tok=bit+substr(body,1,dix-1))) out=out,tok
			body=substr(body,dix+strlen(each[cols(each)]))
			if (empties&!strlen(body)) out=out,""
			bit=""
			}
		else {
			sk=skips[toindices(spos:==skix)[1],]
			bit=bit+substr(body,1,skix+strlen(sk[1])-1)
			body=substr(body,skix+strlen(sk[1]))
			bit=bit+slurp(body,sk)
			}
		}
	if (strlen(bit)) out=out,bit
	if (length(bodyin)>1) {
		each=subinstr(each,dels[1],"")
		if (strpos(body,dels[1])) body=tokel(body,dels[1],"-")
		}
	if (any(strlen(body))) out=out,body
	return(out)
	}
end
//>>mosave<<


*!14feb2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.1
mata:
//!type: parse
//!tokenfunc: parse on function names
//!bodyin: string to parse
//!funin: function names (no parens)
//!R: 2 row matrix. columns are either functions or non-functions; function columns have names in second row, body in first row. No parens. 
stata("capture mata mata drop tokenfunc()")
string matrix tokenfunc(string vector bodyin, string vector funin) { //>>def func<<
	out=J(2,0,"")
	if (!truish(bodyin)) return(out)
	funcs=vec(funin:+"(")
	for (b=1;b<=length(bodyin);b++) {
		body=bodyin[b]
		while (truish(body)) {
			tokd=tokel(body,funcs,"-",func="",1)
			if (strlen(tokd[1])) out=out,(tokd[1]\"")
			body=cut(tokd,2) //gotta be a single cell here, side-affected by slurp
			if (truish(body)) out=out,(slurp(body,("(",")"))\func[2])
			}
		}
	if (any(fcells=toindices(out[2,],"z"))) out[1,fcells]=substr(out[1,fcells],1,strlen(out[1,fcells]):-1)
	out[2,]=subinstr(out[2,],"(","")
	return(out)
	}
end
//>>mosave<<

*! 18jan2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:
//!type: parse
//!tokenpair: For parsing a series of (possibly) paired items
//!text: to parse
//!pair: pairing operator, empty=don't parse
//!skips: as in tokel c1=opener, c2=closer - skips pairing operator
//!R: 2row matrix: first items in first row, second (paired) items in second row
stata("capture mata mata drop tokenpair()")
string matrix tokenpair(string rowvector text, string scalar pair,|string matrix skips) { //>>def func<<
	if (!truish(pair)|!truish(text)) return(expand(text,.,2))
	out=J(2,length(text),"")
	for (p=1;p<=length(text);p++) {
		a=tokel(text[p],pair,skips)
		if (cols(a)>2) errel("Multiple 'pairing' operators in one term",text[p])
		out[1..cols(a),p]=a'
		}
	return(out)
	}
end
//>>mosave<<
*! uknown v10.1
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata: 

//!type: paths
stata("capture mata mata drop tokenpath()")
string vector tokenpath(string scalar orig) { //>>def func<<
	if (!truish(orig)) return(orig)
	tokenized=J(1,0,"")
	path=orig
	if (substr(path,1,2)=="//") path="\\"+substr(path,3,.)
	while (strlen(path)) {
		pathsplit(path,path,element)
		tokenized=element,tokenized
		}
	tokenized=subinstr(subinstr(tokenized,":/",":"),":\",":") //don't know why it leaves :/ in there
	if (anyof(("/",dirsep()),tokenized[1])) tokenized=cut(tokenized,2) //or why it leaves initial dirsep
	
	//for network share, can't access dirs above share point
	if (substr(tokenized[1],1,2)=="\\"&length(spot=toindices(strpos(tokenized,"$")))) tokenized=untokenpath(tokenized[1..spot[1]]),cut(tokenized,spot[1]+1)
	
	return(tokenized)
	}

//!type: paths
stata("capture mata mata drop untokenpath()")
string scalar untokenpath(string vector tpath) { //>>def func<<
	if (!length(tpath)) return(tpath)
	p=tpath[1]
	for (i=2;i<=length(tpath);i++) p=pathjoin(p,tpath[i])
	return(p)
	}

end 
//>>mosave<<
*!3mar2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11.1
mata:
//!type: parse
//!tokenstrip: extract bits from parens or similar
//!body: stuff to parse
//!chars: 2 char vector, defaults to parens; otherwise opening & closing delims
//!R: 4 column matrix, 1 row per input cell: 1)pre-opener, 2)between chars, 3)post-closer, 4) no delim chars
stata("capture mata mata drop tokenstrip()")
string matrix tokenstrip(string vector body,|string vector chars) { //>>def func<<
	if (!length(body)) return(J(0,4,""))
	if (!length(chars)) chars=("(",")")
	bod=vec(body)
	b1=strpos(bod,chars[1])
	if (any(b1 :& strpos(bod,chars[2]):<b1)) errel("Mis-aligned parentheses (or similar)")
	b2=strlast(bod,chars[2])
	out=J(rows(bod),4,"")
	out[,1]=substr(bod,1,b1:-1)
	out[,2]=substr(bod,b1:+strlen(chars[1]),b2:-b1:-strlen(chars[1]))
	out[,3]=substr(bod,b2:+strlen(chars[2]))
	if (any(sw=toindices(!b1))) out[sw,(2,4)]=out[sw,(4,2)]
	if (strpos(out[,2],chars[2])<strpos(out[,2],chars[1])) errel("Mis-aligned parentheses (or similar)")
	return(out)
	}
end
//>>mosave<<


*! 05dec2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:
//!type: search
//!tru2: temporary function for truish calls that use matrix return
//!mabye: to eval
//!ztrue: flag to count real 0 as true (ie truish is 'notmissing')
//!R: 0/1 per element: (non-zero) non-missing for real; non-empty for string, non-null for pointer.
stata("capture mata mata drop tru2()")
real matrix tru2(matrix maybe,| matrix ztrue) { //>>def func<<
	if (!length(maybe)) return(J(rows(maybe),cols(maybe),0))
	if (eltype(maybe)=="string") tf=strlen(maybe):>0
	else if (eltype(maybe)=="pointer") { //pointers only compared in pairs!
		m2=colshape(maybe,1)
		tf=J(length(m2),1,.)
		for (m=length(m2);m;m--) tf[m]=m2[m]!=NULL
		tf=colshape(tf,cols(maybe))
		}
	else if (length(ztrue)) tf=maybe:<.
	else tf=maybe:!=0:&maybe:<.
	return(tf)
	}
end
//>>mosave<<
*! 05dec2012
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:
//!type: search
//!truish: scalar true/false for real,string,pointer
//!mabye: to eval
//!R: sum of: (non-zero) non-missing for real; non-empty for string, non-null for pointer.
stata("capture mata mata drop truish()")
real scalar truish(matrix maybe) { //>>def func<<
	if (!length(maybe)) return(0)
	if (eltype(maybe)=="string") tf=strlen(maybe):>0
	else if (eltype(maybe)=="pointer") { //pointers only compared in pairs!
		m2=colshape(maybe,1)
		tf=J(length(m2),1,.)
		for (m=length(m2);m;m--) tf[m]=m2[m]!=NULL
		tf=colshape(tf,cols(maybe))
		}
	else tf=maybe:!=0:&maybe:<.
	return(sum(tf))
	}
end
//>>mosave<<
*!13may2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:
//!type: search
//!uniqs: count of uniq or duplicated rows
//!bits: to count
//!dups: truish returns dup count
//!R: count
stata("capture mata mata drop uniqs()")
real scalar uniqs(matrix bits,| matrix dups) { //>>def func<<
	r=rows(uniqrows(bits))
	return(truish(dups)?rows(bits)-r:r)
	}
end
//>>mosave<<
*!13may2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: stata
//!varlist: get varlist from pattern(s), using data-in-memory as potential vars
//!pats: a vector of varlist patterns
//!options: optionel: see varlistk
//!mods: modifiers: see varlistk
//!notfound: returns patterns not found: see varlistk
//!R: variables matching input pats
stata("capture mata mata drop varlist()")
string vector varlist(string vector pats,|string scalar options, string vector mods, matrix notfound) { //>>def func<<
	vlist=varlistk(st_nvar()?st_varname(1..st_nvar()):J(1,0,""),pats,options,mods,notfound)
	return(vlist)
	}
end
//>>mosave<<

*!unknown separated 9jun2015
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: stata
stata("capture mata mata drop varlistex()")
string vector varlistex(string scalar path, string vector pats,|string scalar options, string vector mods, matrix notfound) { //>>def func<<
	class dataset_dta scalar ds
	
	ds.readfile(path)
	return(varlistk(ds.vnames,pats,options,mods,notfound))
	}
end
//>>mosave
*!13may2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: stata
//!varlistk: kernel for other varlist commands
//!vars: a rowvector of variable names; temps (__x) will be excluded
//!pats: vector of search terms
//!options: optionel: all[=empty input returns all vars] nfok[=notfound ok] nfrep[=notfoudn report] min()[=min found vars] max()[=max found vars] noab:brev single[=return scalar varname]
//!mods: vector of valid modifiers [""]=everything valid; [1]=(first) or (last) specifies that only first or last word is validated; [pair(x)]=varname pair on x; returns vector of modifiers corresponding to vector of vars
//!notfound: returns patterns not found in vars
//!R: vector of vars selected by pats
stata("capture mata mata drop varlistk()")
string vector varlistk(string vector vars, string vector pats,|string scalar options, string vector mods, matrix notfound) { //>>def func<<
	optionel(options,(&(all="all"),&(ok="nfok"),&(nfrep="nfrep"),&(min="min="), &(max="max="),&(noab="noab:brev"),&(single="single")))
	
	if (!truish(pats)) {
		if (truish(strtoreal(min))) errel(sprintf("At least %s variables must be specified",min))
		if (all) {
			rvars=rowshape(vars,1)
			rvars=selectv(rvars,substrf(rvars,1,2):!="__","r")
			mods=J(1,length(rvars),"")
			return(rvars)
			}
		else {
			mods=single?"":J(1,0,"")
			return(mods)
			}
		}
	
	if (substrf(mods,1,5)=="pair(") {
		pairs=tokenpair(tokel(pats),tokenstrip(mods)[2])'
		patterns=pairs[,1]
		pmods=pairs[,2]
		}
	else {
		tokd=tokenstrip(tokel(pats))
		if (any(strlen(tokd[,1]):&strlen(tokd[,3]))) errel("A modifier cannot be attached to both prior & following elements")
		pmods=tokd[,2]
		if (truish(pmods)) {
			if (!length(mods)) errel("No modifiers allowed")
			if (mods!="") {
				if (mods[1]=="(first)") {
					cpmods=colwords(pmods)
					pmods=ocanon("Modifiers",cpmods[,1]',cut(mods,2)):+rowshape(cut(cpmods,2),1)
					}
				else if (mods[1]=="(last)") {
					cpmods=colwords(pmods,"r")
					pmods=ocanon("Modifiers",cpmods[,2]',cut(mods,2)):+rowshape(cut(cpmods,1,-2),1)
					}
				else pmods=ocanon("Modifiers",pmods',mods)
				}
			}
		carry=""
		for (t=1;t<=rows(tokd);t++) {
			if (!any(strlen(tokd[t,(1,3,4)]))) carry=pmods[t]
			else if (strlen(tokd[t,4])) pmods[t]=carry
			else carry=""
			}
		ispat=toindices(rowmax(tru2(tokd[,(1,3,4)])))
		patterns=concat(tokd[ispat,(1,3,4)],"")
		pmods=pmods[ispat]
		}
	
	vp=asvmatch(vars,patterns,"details"+" noab"*(noab|c("varabbrev")=="off"))
	if (any(vp)) {
		vkey=firstof((1::rows(vp)):*vp,"row",0)
		o=order((vkey\1..cols(vkey))',(1,2))
		o=select(o,vkey[o]')
		vlist=vars[o]
		mods=rowshape(pmods[vkey[o]],1) //before rs depends whether pmods is empty
		}
	else vlist=mods=J(1,0,"")
	notfound=concat(select(patterns,!rowsum(vp))," ")
	
	if (truish(notfound)) {
		if (nfrep) printf("{txt:Variables/patterns not found:} {res:%s}\n",notfound)
		else if (!ok) errel("Variables/patterns not found: "+notfound)
		}
	
	if (truish(min)&cols(vlist)<strtoreal(min)) errel(sprintf("At least %s variables must be specified",min),vlist)
	if ((truish(max)|truish(single))&cols(vlist)>strtoreal(max)) errel(sprintf("At most %s variables must be specified",max),vlist)
	
	if (single) vlist=expand(vlist,1)
	return(vlist)
	}
end
//>>mosave<<

*!26feb2016
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: stata
//!varofchar: get varname by characteristic
//!chname: characteristic name
//!chcont: char content (filter)
//!R: variable names
stata("capture mata mata drop varofchar()")
string rowvector varofchar(string scalar chname,| string scalar chcont) { //>>def func<<
	vars=varlist("*")
	chars=charget(vars,chname)
	if (truish(chcont)) return(selectv(vars,chars:==chcont,"r"))
	else return(selectv(vars,tru2(chars),"r"))
	}
end
//>>mosave
*! 16dec2014
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:

//!type: stata
//!vlabnames: get valid vlabel names
//!vars: vars to be labeled
//!labs: desired label names, if other than varnames
//!R: valid names, with _a-_z appended if necessary. Cells with no name had all labels taken.
stata("capture mata mata drop vlabnames()")
string vector vlabnames(string vector vars,| string vector labs) { //>>def func<<
	inuse=charget(varlist("*"),"@vlab")
	inuse=select(inuse,tru2(inuse))
	for (v=1;v<=length(inuse);v++) {
		inuse[v]=inuse[v]*st_vlexists(inuse[v])
		}
	inuse=select(inuse,tru2(inuse))
	
	lnames=J(rows(vars),cols(vars),"")
	stub=firstof(pad(labs,vars,"\"))
	for (v=1;v<=length(vars);v++) {
		lname=stub[v]
		for (suffix=97;suffix<=122;suffix++) {
			if (!any(lname:==inuse)) break
			lname=stub[v]+"_"+char(suffix)
			}
		if (suffix<=122) lnames[v]=lname
		}
	return(lnames)
	}
end
//>>mosave<<

*! 21aug2013
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:
//!type: search
//!vmap: map cells in v1 to cells in v2
//!v1: values to look for
//!v2: vector to search in
//!opts: o:nly, i:nonly, n:otonly, b:oth; all options will cause the result to exclude 0's
//!R: for each cell of v1, it's v2ix (or 0); only=only for matches; in=v1ix of matches; not=v1ix of non-matches; both=2col matrix c1=in, c2=only
stata("capture mata mata drop vmap()")
real matrix vmap(vector v1, vector v2,| string scalar opts) { //>>def func<<
	optionel(opts,(&(only="o:nly"),&(in="i:nonly"),&(not="n:otonly"),&(both="b:oth")))
	s1=length(v1)
	s2=length(v2)
	out=shapeof(J(1,s1,0),v1)
	if (in) for (i1=1;i1<=s1;i1++) out[i1]=i1*anyof(v2,v1[i1])
	else if (not) for (i1=1;i1<=s1;i1++) out[i1]=i1*!anyof(v2,v1[i1])
	else {
		for (i1=1;i1<=s1;i1++) {
			for (i2=1;i2<=s2;i2++) {
				if (v1[i1]==v2[i2]) {
					out[i1]=i2
					break
					}
				}
			}
		}
	if (both) return(select(((1::length(out)),vec(out)),vec(out)))
	if (only|in|not) out=selectv(out,out,orgtype(v1)=="colvector"?"c":"r") 
	return(out)
	}
end
//>>mosave<<

*! 6may2015
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
*code is ok for 11, though this is only called from 13
mata:
end
 global pref (`"!#&*+,-Set objExcel = CreateObject("Excel.Application")*objExcel.DisplayAlerts = 0*objExcel.Workbooks.open "%%xlspath%%""')
 mata:
end
 global suf (`"!#&*+,-objExcel.ActiveWorkbook.Worksheets(1).columns.Autofit()*objExcel.ActiveWorkbook.Worksheets(1).rows(2).Select*objExcel.ActiveWindow.FreezePanes=True*objExcel.ActiveWorkbook.SaveAs "%%xlspath%%"*objExcel.Quit"')
 mata:

//!type: file
//!xlcolor: set colors of xl cells
//!path: path of xl file
//!cs: settings c1=ws#, c2=row#, c3=col#, c4=0:font/1:interior, c5=rgb
stata("capture mata mata drop xlcolor()")
void xlcolor(string scalar path, real matrix cs) { //>>def func<<
	sput(setc="",subinstr(strob_to($pref),"%%xlspath%%",path))
	for (r=1;r<=rows(cs);r++) { 
		sput(setc,sprintf("objExcel.ActiveWorkbook.Worksheets(%f).cells(%f,%f).%s.color=%f", 	cs[r,1],cs[r,2],cs[r,3],cs[r,4]?"Font":"Interior",cs[r,5]))
		}
	sput(setc,subinstr(strob_to($suf),"%%xlspath%%",path))
	fowrite(vbpath=pathto("_xlcolors.vbs"),setc)
	stata("shell "+vbpath)
	}
end
//>>mosave<<

*!12may2015
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
version 11
mata:
end
 global readcolor (`"!#&*/23Set objExcel = CreateObject("Excel.Application")*objExcel.DisplayAlerts = 0*2open (path, confirmconversions, readonly)*objExcel.Workbooks.open "%%xlpath%%", false, true*Set FSO = CreateObject("Scripting.FileSystemObject")*Set xlcolor=FSO.CreateTextFile("%%textpath%%")**Set currentWorkSheet = objExcel.ActiveWorkbook.Worksheets(1)*usedColumnsCount = currentWorkSheet.UsedRange.Columns.Count*usedRowsCount = currentWorkSheet.UsedRange.Rows.Count*top = currentWorksheet.UsedRange.Row*lft = currentWorksheet.UsedRange.Column*Set Cells = currentWorksheet.Cells*For row = top to top+usedRowsCount-1*For column = lft to lft+usedColumnsCount-1*set ccell=Cells(row,column)*xlcolor.Write (Ccell.Interior.color)*xlcolor.Write (",")*xlcolor.Write (Ccell.font.color)*xlcolor.Write (",")*Next*xlcolor.Writeline ("")*Next*objExcel.Quit"')
 mata:

//!type: file
//!xlmread: reads non-data bits (eg, colors) from an excel file, and writes to a text file
//!xlpath: excel file path
//!R: text file path
stata("capture mata mata drop xlmread()")
string scalar xlmread(string scalar xlpath) { //>>def func<<
	script=subinstr(strob_to($readcolor),"%%xlpath%%",xlpath)
	script=subinstr(script,"%%textpath%%",tpath=pathto("_xlmore.txt","inst"))
	fowrite(vbpath=pathto("_xlmore.vbs"),script)
	unlink(tpath)
	stata("shell "+vbpath)
	return(tpath)
	}
end
//>>mosave<<
local sv=c(stata_version)
mata:
string scalar lowyseattlev() {
return("[`sv'] 2016-09-02 09:42")
}
pathsplit(findfile("lowyseattle.do",c("adopath")+";C:\Users\vhapuglowye\ado\lowyseattle\lowyseattle_files\"),ls1="",ls2="")
st_local("lspath",ls1)
mata mlib create lowyseattle, dir(`lspath') replace
mata mlib add lowyseattle *(), dir(`lspath')
mata mlib index
end
