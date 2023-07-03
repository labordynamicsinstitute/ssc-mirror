# -*- coding:utf-8 -*-
'''this python script is used to process the payload file'''
import sys
import os
import json
import io

def filewrite(data,filepath,jsonbool=True):
    with io.open(filepath,'w',encoding='utf-8') as file:
        if jsonbool:
            file.write(json.dumps(data,ensure_ascii=False,indent=4))
        else:
            content = statacode(data)
            file.write(content)

def statacode(content):
    start_index = content.find('```')
    while start_index != -1:
        end_index = content.find('```', start_index + len('```'))
        if end_index != -1:
            # 提取Stata代码块
            stata_code = content[start_index + 4:end_index - 1].strip()
            replacement = "\n".join(['{stata "' + s + '"}' for s in stata_code.split("\n")])
            content = content[:start_index] + replacement + content[end_index + len('```'):]
        start_index = content.find('```', start_index + len('```'))
    return content

try:
    if sys.argv[1] == "version":
        with open("PythonScriptVersion.txt","w") as f:
            f.write("REPORT:In this system, the Python Version in Shell within Stata is " + str(sys.version_info.major))
    elif sys.argv[1] == "read":
        filetype = sys.argv[3]
        if sys.version_info.major == 2:
            path = sys.argv[2].decode('unicode_escape')
            with open(path ,'r') as file:
                text = file.read().decode('utf8')
            with open("payload.txt",'r') as file:
                data = json.load(file)
        else:
            path = sys.argv[2].encode().decode('unicode_escape')
            with open(path ,'r',encoding = 'utf-8') as file:
                text = file.read()
            with open("payload.txt",'r',encoding = 'utf-8') as file:
                data = json.load(file)

        data['messages'].append({
            "role":"user",
            "content":"There are content of the " + filetype + " file as below:\n" + text
        })
        filewrite(data,"payload.txt")
    elif sys.argv[1] == "system":
        if sys.version_info.major == 2:
            content = sys.argv[2].decode('unicode_escape')
            filepath = sys.argv[3].decode('unicode_escape')
            with open(filepath,'r') as file:
                data = json.load(file)
        else:
            content = sys.argv[2].encode().decode('unicode_escape')
            filepath = sys.argv[3]
            with open(filepath,'r',encoding='utf-8') as file:
                data = json.load(file)

        data['messages'][0]['content'] += content
        filewrite(data,filepath)
    elif sys.argv[1] == "add":
        if sys.version_info.major == 2:
            content = sys.argv[2].decode('unicode_escape')
            with open("payload.txt",'r') as file:
                data = json.load(file)
        else:
            content = sys.argv[2].encode().decode('unicode_escape')
            with open("payload.txt",'r',encoding='utf-8') as file:
                data = json.load(file)

        data['messages'].append({
            "role":"user",
            "content":content
            })
        filewrite(data,"payload.txt")
    elif sys.argv[1] == "log":
        if sys.version_info.major == 2:
            logfile = sys.argv[2].decode('unicode_escape')
            with open("payload.txt",'r') as file:
                data = json.load(file)
            with open("res.txt",'r') as file:
                resinfo = json.load(file)
        else:
            logfile = sys.argv[2]
            with open("payload.txt",'r',encoding='utf-8') as file:
                data = json.load(file)
            with open("res.txt",'r',encoding='utf-8') as file:
                resinfo = json.load(file)
        
        if "error" in resinfo:
            pass
        else:
            new = resinfo['choices'][0]['message']
            data['messages'].append(new)
            filewrite(data,logfile)
    elif sys.argv[1] == "type":
        if sys.version_info.major == 2:
            with open("res.txt",'r') as file:
                resinfo = json.load(file)
        else:
            with open("res.txt",'r',encoding='utf-8') as file:
                resinfo = json.load(file)
        if "error" in resinfo:
            filewrite(resinfo['error']['message'],"output.txt",jsonbool=False)
        else:
            filewrite(resinfo['choices'][0]['message']['content'],"output.txt",jsonbool=False)
    elif sys.argv[1] == "gen":
        if sys.version_info.major == 2:
            path = sys.argv[3].decode('unicode_escape')
            engine = sys.argv[2].decode('unicode_escape')
        else:
            path = sys.argv[3]
            engine = sys.argv[2]
        data = { "model": engine, 
                "messages": 
                    [{"role": "system", 
                      "content": ""}], 
                "temperature": 0.2
                }
        filewrite(data,path + "/payload-"+engine+".txt")

    if sys.version_info.major == 2:
        with open("chatgpt_test_log.txt","a") as f:
            f.write(unicode(sys.argv[1])+": success \n")
    else:
        with open("chatgpt_test_log.txt","a",encoding='utf-8') as f:
            f.write(sys.argv[1]+": success \n")
except Exception as e:
    with open("chatgpt_test_log.txt","a") as f:
        f.write(sys.argv[1] + ":" + str(e) + "\n")
