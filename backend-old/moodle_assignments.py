import requests
import json

base_url = 'https://gym-haan.lms.schulon.org'

r = requests.get(base_url + '/webservice/rest/server.php' + '?wstoken=' + '310e2e1ff5c28adf0c88f3d9cdb0c1ea' +
                  '&wsfunction=mod_assign_get_assignments&moodlewsrestformat=json')

output = None

with open('output.json') as f:
    output = json.load(f)

course_data = output['courses']

course_id = 631

for c in course_data:

    a = c['assignments']

    if not len(a):
        continue

    for x in a:
        print(c['fullname'], x['name'])

    print('---------------\n\n')
