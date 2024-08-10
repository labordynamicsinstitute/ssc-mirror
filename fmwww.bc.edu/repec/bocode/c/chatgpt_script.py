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
    tmp_index = content.find('```')
    while tmp_index != -1:
        start_index = content.find('\n', tmp_index + 3) + 1
        if start_index == 0:  # 如果没有换行符，跳出循环
            break
        end_index = content.find('```', start_index)
        if end_index == -1:
            break
        # 提取Stata代码块
        stata_code = content[start_index:end_index].strip()
        replacement = "\n".join(['{stata "' + s + '"}' for s in stata_code.split("\n")])
        content = content[:tmp_index] + replacement + content[end_index+3:]
        tmp_index = content.find('```')
    return content


try:
    if sys.argv[1] == "version":
        with open("PythonScriptVersion.txt","w") as f:
            f.write("REPORT:In this system, the Python Version in Shell within Stata is " + str(sys.version_info.major))
    elif sys.argv[1] == "add":
        content_type = sys.argv[3]
        if sys.version_info.major == 2:
            path_or_content = sys.argv[2].decode('unicode_escape')
            with open(sys.argv[4],'r') as file:
                data = json.load(file)
            if content_type != "prompt":
                with open(path_or_content ,'r') as file:
                    text = file.read().decode('utf8')
                data['messages'].append({
                    "role":"user",
                    "content":"There are content of the " + content_type + " file as below:\n" + text
                })
            else:
                data['messages'].append({
                    "role":"user",
                    "content":path_or_content
                    })
        else:
            path_or_content = sys.argv[2].encode('unicode_escape').decode('unicode_escape')
            with open(sys.argv[4],'r',encoding = 'utf-8') as file:
                data = json.load(file)
            if content_type != "prompt":
                with open(path_or_content ,'r',encoding = 'utf-8') as file:
                    text = file.read()
                data['messages'].append({
                    "role":"user",
                    "content":"There are content of the " + content_type + " file as below:\n" + text
                })
            else:                
                data['messages'].append({
                    "role":"user",
                    "content":path_or_content
                    })
        filewrite(data,sys.argv[4])
    elif sys.argv[1] == "system":
        if sys.version_info.major == 2:
            content = sys.argv[2].decode('unicode_escape')
            filepath = sys.argv[3].decode('unicode_escape')
            with open(filepath,'r') as file:
                data = json.load(file)
        else:
            content = sys.argv[2].encode('unicode_escape').decode('unicode_escape')
            filepath = sys.argv[3]
            with open(filepath,'r',encoding='utf-8') as file:
                data = json.load(file)

        data['messages'][0]['content'] += content
        filewrite(data,filepath)
    elif sys.argv[1] == "multilog":
        obs_num = sys.argv[3]
        if sys.version_info.major == 2:
            logfile = sys.argv[2].decode('unicode_escape')
            with open(logfile,'r') as file:
                logdata = json.load(file)
        else:
            logfile = sys.argv[2]
            with open(logfile,'r',encoding = 'utf-8') as file:
                logdata = json.load(file)
        for page in range(1,int(obs_num) + 1):
            payload_file = "_chatgpt_tmpdata/payload_" + str(page) + ".txt"
            res_file = "_chatgpt_tmpdata/res_" + str(page) + ".txt"
            out_file = "_chatgpt_tmpdata/output_" + str(page) + ".txt"
            if sys.version_info.major == 2:
                with open(payload_file,'r') as file:
                    data = json.load(file)
                with open(res_file,'r') as file:
                    resinfo = json.load(file)
            else:
                with open(payload_file,'r',encoding='utf-8') as file:
                    data = json.load(file)
                with open(res_file,'r',encoding='utf-8') as file:
                    resinfo = json.load(file)
            if "error" in resinfo:
                filewrite(resinfo['error']['message'],out_file,jsonbool=False)
            else:
                new_query = data['messages'][-1]
                new_res = resinfo['choices'][0]['message']
                logdata['messages'].append(new_query)
                logdata['messages'].append(new_res)
                filewrite(resinfo['choices'][0]['message']['content'],out_file,jsonbool=False)
        filewrite(logdata,logfile)
    elif sys.argv[1] == "log":
        payload_file = sys.argv[2]
        res_file = "res.txt"

        if sys.version_info.major == 2:
            logfile = sys.argv[2].decode('unicode_escape')
            with open(payload_file,'r') as file:
                data = json.load(file)
            with open(res_file,'r') as file:
                resinfo = json.load(file)
        else:
            logfile = sys.argv[2]
            with open(payload_file,'r',encoding='utf-8') as file:
                data = json.load(file)
            with open(res_file,'r',encoding='utf-8') as file:
                resinfo = json.load(file)
        if "error" in resinfo:
            pass
        else:
            new = resinfo['choices'][0]['message']
            data['messages'].append(new)
            filewrite(data,logfile)
    elif sys.argv[1] == "type":
        res_file = "res.txt"
        out_file = "output.txt"

        if sys.version_info.major == 2:
            with open(res_file,'r') as file:
                resinfo = json.load(file)
        else:
            with open(res_file,'r',encoding='utf-8') as file:
                resinfo = json.load(file)
        if "error" in resinfo:
            filewrite(resinfo['error']['message'],out_file,jsonbool=False)
        else:
            filewrite(resinfo['choices'][0]['message']['content'],out_file,jsonbool=False)
    elif sys.argv[1] == "gen":
        if sys.version_info.major == 2:
            path = sys.argv[5].decode('unicode_escape')
            engine = sys.argv[2].decode('unicode_escape')
        else:
            path = sys.argv[5]
            engine = sys.argv[2]
        data = { "model": engine,
                "temperature": float(sys.argv[4]),
                "messages": 
                    [{"role": "system", 
                      "content": ""}], 
                }
        if int(sys.argv[3]) > 0:
            data['max_tokens'] = int(sys.argv[3])
        filewrite(data,path + "/payload-"+engine+".txt")

    if sys.version_info.major == 2:
        with open("chatgpt_test_log.txt","a") as f:
            f.write(unicode(sys.argv[1])+": success \n")
    else:
        with open("chatgpt_test_log.txt","a",encoding='utf-8') as f:
            f.write(sys.argv[1]+": success \n")
except Exception as e:
    with open("chatgpt_test_log.txt","a") as f:
        f.write(sys.argv[1] + ":failed. " + str(e) + "\n")
        f.write('#'.join(sys.argv))

