import requests
import eventlet

def get_user_courses(user):
    base_url = user.moodle_url
    token = user.moodle_token

    if token is None or base_url is None:
        return None

    """
    $ curl "https://your.site.com/moodle/webservice/rest/server.php?wstoken=...&wsfunction=...&moodlewsrestformat=json"
    """

    with eventlet.Timeout(5):
        courses_request = requests.get(
            base_url + '/webservice/rest/server.php' + '?wstoken=' + token + '&wsfunction=' + 'core_enrol_get_users_courses' + '&moodlewsrestformat=json' + '&userid=412')
    

    return courses_request.json()
