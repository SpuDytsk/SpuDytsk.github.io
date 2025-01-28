#!/usr/bin/env python3

import yaml
import getopt
import sys
import re

##################################################################################################
# Headers cannot be placed to rst file separately! Sphinx cannot see separated code. 
# Change :widths: to adjust wight of columns 
# Also you can set the column names
# ################################################################################################


################ detected_types or media_types ################
en_media_types = """
.. csv-table::
   :widths: 10 10 30 50
   :header-rows: 1

   "Dec","Hex","Name","Description"
"""

ru_media_types = """
.. csv-table::
   :widths: 10 10 30 50
   :header-rows: 1

   "Dec","Hex","Имя","Описание"
"""

################ event_message_ids ################
en_event_message = """
.. csv-table::
   :widths: 10 45 45
   :header-rows: 1

   "ID","Message","Description"
"""

ru_event_message = """
.. csv-table::
   :widths: 10 45 45
   :header-rows: 1

   "ID","Сообщение","Описание"
"""

################ notification_names ################
en_alarms = """
.. csv-table::
   :widths: 20, 20, 10, 50
   :header-rows: 1

   "Key name","Name","Type","Description"
"""

ru_alarms = """
.. csv-table::
   :widths: 20, 20, 10, 50
   :header-rows: 1

   "Ключевое имя","Название","Тип","Описание"
"""

################ event_names ################
en_events = """
.. csv-table::
   :widths: 20, 20, 60
   :header-rows: 1

   "Key name","Name","Description"
"""

ru_events = """
.. csv-table::
   :widths: 20, 20, 60
   :header-rows: 1

   "Ключевое имя","Название","Описание"
"""

headers = {'en': {'detected_types':en_media_types, 'media_types':en_media_types, 'event_message_ids':en_event_message, 'notification_names': en_alarms, 'event_names': en_events}, 'ru': {'detected_types':ru_media_types, 'media_types':ru_media_types, 'event_message_ids':ru_event_message, 'notification_names': ru_alarms, 'event_names': ru_events}}

def media_types_yml2ReST(out, data, lang, tableType):
    if tableType not in data[lang]:
        print('Warning: Input file does not content Stream Type data')
        exit()
    for msg_id, value in data[lang][tableType].items():
        typeName = value['name']
        typeTitle = value['title']
        typeNameCsv = typeName.replace("\"", "\"\"")             #escape character '"' in CSV format
        typeTitleCsv = typeTitle.replace("\"", "\"\"")        
        message_to_write = '   "' + str(msg_id) + '","' + str(hex(msg_id)) + '","' + typeNameCsv + '","' + typeTitleCsv + '"\n'
        out.write(message_to_write)

def event_message_yml2ReST(out, data, lang, tableType):
    if tableType not in data[lang]:
        print('Warning: Input file does not content Messages data')
        exit()
    for msg_id, value in data[lang][tableType].items():
        alarmMessage = value['message']
        messageDescription = value['description']
        alarmMessageCsv = alarmMessage.replace("\"", "\"\"")             #escape character '"' in CSV format
        messageDescriptionCsv = messageDescription.replace("\"", "\"\"") 
        message_to_write = '   "' + str(msg_id) + '","' + alarmMessageCsv + '","' + messageDescriptionCsv + '"\n'   # use csv-table style
        out.write(message_to_write)

def html2rest(text):
    
    text = re.sub(r'\s*<br><br>\s*', '\n\n   | ', text)  #Handle <br>: change tag to \n
    text = re.sub(r'\s*<br>\s*', '\n   | ', text)
    
    for b in ['<b>', '</b>']:                          #Handle <b>: make ReST bold
        text = text.replace(b, '**')
        text = text.replace(b.upper(), '**')
        
    text = re.sub(r'<\s*ul[^>]*>', '\n\n   ', text)    #Handle <ul>: find and remove tag like <ul class="freg">
    text = re.sub(r'<li>', '* ', text)                 # make list using * as bullet 
    text = re.sub(r'\s*</li>\s*</ul>\s*', '\n\n   ', text)
    text = re.sub(r'\s*</li>\s*', '\n   ', text)

    cleanr = re.compile('<.*?>')                       #Clean other unhandled  HTML
    text = re.sub(cleanr, '', text)
    
    text = text.replace('&lt;','<')                     #replace '&lt;' and '&gt;' to < > symbols
    text = text.replace('&gt;','>')
    
    return text

def checkAlarmType(lines,key, lang):
    for i in range(0, len(lines)):
        if key in lines[i]:
            for j in range(i+1, i+5):  # If key found then search in next 5 lines for "state: true|false"
                if 'state' in lines[j]: 
                    if 'true' in lines[j]:
                        return 'State' if lang == 'en' else 'Состояние'
                    elif 'false' in lines[j]:
                        return 'Event' if lang == 'en' else 'Событие'
    print ('Error:[checkAlarmType] Key or State field not found')
    exit()

def alarms_yml2ReST(out, data, lang, tableType, schemePath):
    if tableType not in data[lang]:
        print('Warning: Input file does not content Alarms description')
        exit()
        
    schemefile = open(schemePath, encoding="utf-8")
    schemelines = schemefile.readlines()
    
    for key,value in data[lang][tableType].items():
        hintReST = "| " + html2rest(data[lang]['hint'].get('hint_' + str(key)))
        hintReSTcsv = hintReST.replace("\"", "\"\"") #escape character '"' in CSV format
        alarmType = checkAlarmType(schemelines, key, lang)
        message_to_write = '   "' + str(key) + '","' + str(value) + '","' + str(alarmType) + '","' + hintReSTcsv + '"\n'   # use csv-table style
        out.write(message_to_write)

def getReSTstring(data,yaml_path): #https://stackoverflow.com/a/31033676
    keys = yaml_path.split('.')
    rv = data
    isHint = False;
    for key in keys:
        if key == "hint": isHint = True
        rv = rv[key]
    if isHint: rv = "| " + html2rest(rv)      # "| " - uses to save \n in the total html code
    else: rv = html2rest(rv)
    rv = rv.replace("\"", "\"\"")  #escape character '"' in CSV format
    return rv

def getDefaultValue(model,settingName,defaultsGroup):
    keys = settingName.split('.')  #{ru.profiles.threshold.etr290p3_defIntervals_defNitInterval_actual}
    lastKey = keys[-1]
    keys = lastKey.split('_')
    keys.insert(0,defaultsGroup)
    rv = model
    preKey = ""
    for key in keys:
        if not isinstance(rv, dict): return ""    # do not handle list type. Need to improve algorithm if needs to handle yaml array
        value = rv.get(preKey + key,"wrongKey")
        if value == "wrongKey": 
            preKey = preKey + key + "_"
        else:
            rv = value
            preKey = ""
    return str(rv)

def replace_macro_yml2ReST(out, data, template, model):
    next(template) #skip first line in _template with :orphan: macro
    for line in template:
        macros = re.findall(r'(?<=\%\{).*?(?=\})', line)  #Locking for the all %{macro} in line, some lines has no macro
        for yaml_path in macros:
            line = line.replace ("%{" + yaml_path + "}", getReSTstring(data,yaml_path))
        defaultsGroups = re.findall(r'(?<=\$\{).*?(?=\})', line)  #Locking for the all ${macro} in line, some lines has no macro
        for grope in defaultsGroups:
            line = line.replace ("${" + grope + "}", getDefaultValue(model,macros[0],grope))  #Pass setting name to find default value
        out.write(line)
    exit()

##################################################################################################################################################
# "event_erb2ReST" function:
# The file /app/views/tasks/_events_selection.html.erb describes the event filter, which is located on the task page.
# Why not use Events2 scheme at /app/models/event2.rb? The necessary events had already been selected and grouped in '_events_selection.html.erb'.
################################################################################################################################################

def event_erb2ReST(out, data, lang, tableType, schemePath):
    if tableType not in data[lang]:
        print('Warning: Input file does not content Events description')
        exit()

    schemefile = open(schemePath, encoding="utf-8")
    schemelines = schemefile.readlines()

    for key,value in data[lang][tableType].items():
        hintReST = "| " + html2rest(data[lang]['hint'].get('hint_' + str(key)))
        hintReSTcsv = hintReST.replace("\"", "\"\"") #escape character '"' in CSV format
        message_to_write = '   "' + str(key) + '","' + str(value) + '","' + hintReSTcsv + '"\n'   # use csv-table style
        out.write(message_to_write)

def main():
    try:
        opts, args = getopt.getopt(sys.argv[1:], 'i:o:', ['input=','output=','template=','model=','tableType=','schemePath='])
    except getopt.GetoptError as err:
        print(str(err))
        sys.exit(2)
    yamlFile = None
    restFile = None
    templatePath = None
    modelPath = None
    tableType = None
    schemePath = None
    if len(opts) == 0:
        print('No one option')
        exit()
    for o, a in opts:
        if o in ("-i", '--input'):
            yamlFile = a
        elif o in ('-o', '--output'):
            restFile = a
        elif o in ('--template'):
            templatePath = a
        elif o in ('--model'):
            modelPath = a
        elif o in ('--tableType'):
            tableType = a
        elif o in ('--schemePath'):
            schemePath = a
        else:
            print('unhandled option')
    if tableType == None:
        print('tableType is not set')
        exit()
    
    out = open(restFile, 'w', encoding="utf-8")
    f = open(yamlFile, encoding="utf-8")
    data = yaml.safe_load(f)
    
    if 'en' in data:  #Check the file lang 
        lang = 'en'
    elif 'ru' in data:
        lang = 'ru'
    else:
        print('Warning: Wrong input file format')
        exit()
    
    if tableType != 'macro_replacement':
        print('Import data from Rails Project to ReST. Type:' + tableType + ' Lang:' + lang)
        out.write(headers[lang][tableType]) #Add header to output file
        
    if tableType == 'media_types':
        media_types_yml2ReST(out, data, lang, tableType)
    elif tableType == 'detected_types':
        media_types_yml2ReST(out, data, lang, tableType)
    elif tableType == 'event_message_ids':
        event_message_yml2ReST(out, data, lang, tableType)
    elif tableType == 'notification_names':
        alarms_yml2ReST(out, data, lang, tableType, schemePath)
    elif tableType == 'event_names':
        event_erb2ReST(out, data, lang, tableType, schemePath)
    elif tableType == 'macro_replacement':
        print('Replace macro and export to ReST. Type:' + tableType + ' Lang:' + lang)
        template = open(templatePath, 'r', encoding="utf-8")
        if modelPath: 
            f = open(modelPath, 'r', encoding="utf-8")
            model = yaml.safe_load(f)
        else: model = None
        replace_macro_yml2ReST(out, data, template, model)
    print("Output file created: " + restFile)

if __name__ in ("__main__", "yamltorest"):
    main()
