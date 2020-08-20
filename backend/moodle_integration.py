import time

import requests
import json

start = time.time()
base_url = 'https://gym-haan.lms.schulon.org'

username, password = 'id4009', 'g0z89u1baISbAz4VAbUH2RKFL6JAZPdSIqft0GCAtd3G9YhWBMOPTwF1IOizV8XQ#'

body = {'username': username, 'password': password}

auth_request = requests.post(base_url + '/login/token.php?service=moodle_mobile_app', body)
# print(r.status_code, r.text)

if not auth_request.ok:
    print(f"error. status code {auth_request.status_code} d exiting...")
    exit()

creds = auth_request.json()
#print(creds)

"""
$ curl "https://your.site.com/moodle/webservice/rest/server.php?wstoken=...&wsfunction=...&moodlewsrestformat=json"
"""


courses_reqest = requests.get(base_url + '/webservice/rest/server.php' + '?wstoken=' + creds['token'] + '&wsfunction=' + 'core_enrol_get_users_courses' + '&moodlewsrestformat=json' + '&userid=412')

courses = courses_reqest.json()

for course in courses:
    print(course["fullname"])

print("time elapsed: {}".format(time.time() - start))