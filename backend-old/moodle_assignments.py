import requests
import json

base_url = 'https://gym-haan.lms.schulon.org'

 r = requests.get(base_url + '/webservice/rest/server.php' + '?wstoken=' + '6603c9f1cf2183a5755df7f7be8b811c' +
                  '&wsfunction=mod_assign_get_assignments&moodlewsrestformat=json')

output = None

with open('output.json') as f:
    output = json.load(f)

course_data = output['courses']

course_id = 631

for c in course_data:
    if not c['id'] == course_id:
        continue

    a = c['assignments']

    if not len(a):
        continue

    for x in a:
        print(x['name'])

    print('---------------\n\n')
