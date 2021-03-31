import time

import requests
import json

start = time.time()
base_url = 'https://gym-haan.lms.schulon.org'

#username, password = 'id4009', 'g0z89u1baISbAz4VAbUH2RKFL6JAZPdSIqft0GCAtd3G9YhWBMOPTwF1IOizV8XQ#'
username, password = 'id4539', 'Gurke0810!'

body = {'username': username, 'password': password}

auth_request = requests.post(base_url + '/login/token.php?service=moodle_mobile_app', body)
# print(r.status_code, r.text)

if not auth_request.ok:
    exit()

creds = auth_request.json()

"""
$ curl "https://your.site.com/moodle/webservice/rest/server.php?wstoken=...&wsfunction=...&moodlewsrestformat=json"
"""


courses_reqest = requests.get(base_url + '/webservice/rest/server.php' + '?wstoken=' + creds['token'] + '&wsfunction=' + 'core_enrol_get_users_courses' + '&moodlewsrestformat=json' + '&userid=412')

courses = courses_reqest.json()


