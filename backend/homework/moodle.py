import requests
import eventlet
import datetime
import threading
from homework import db
from homework.database.moodle import MoodleCache
from homework.database.user import User


def get_user_courses(user: User):
    base_url = user.moodle_url
    token = user.moodle_token

    if token is None or base_url is None:
        return None

    """
    $ curl "https://your.site.com/moodle/webservice/rest/server.php?wstoken=...&wsfunction=...&moodlewsrestformat=json"
    """

    cache_objs = db.session.query(MoodleCache).filter(
        MoodleCache.moodle_url == base_url).filter(MoodleCache.user_id == user.id).all()

    expired = False
    user_courses_data = None

    for cache_obj in cache_objs:
        if (datetime.datetime.now() - cache_obj.cached_at).days > 7:
            expired = True
            break

    if expired:
        print("[ * ] cache expired")
        db.session.remove(cache_objs)

        try:
            db.session.commit()
        except Exception as e:
            print("[ - ] error deleting objects: {}".format(e))

        # what the fuck even is this code lol
        user_courses_data = get_user_courses_req(base_url, token)

    user_courses = None

    if user_courses_data is not None:
        for ud in user_courses_data:
            user_courses.append({"id": ud['id'],
                                 "name": ud['displayname']
                                 # other stuff is irrelevant for current application.
                                 # i guess there will be more stuff added?
                                 })

    new_enough = True
    for cache_obj in cache_objs:
        if (datetime.datetime.utcnow() - cache_obj.cached_at).seconds > 60:
            new_enough = False
            break

    if not new_enough:
        # start a new thread caching stuff in the background
        t = threading.Thread(
            target=cache_courses, name='cache courses', args=(user_courses, base_url, token, user.id,))
        t.start()

    # return the cached stuff
    # print('[ * ] (moodle.get_user_courses()): returning cached stuff')

    return [x.to_dict() for x in cache_objs]


def get_user_courses_req(base_url: str, token: str):
    with eventlet.Timeout(20):
        courses_request = requests.get(
            base_url + '/webservice/rest/server.php' + '?wstoken=' + token + '&wsfunction=' + 'core_enrol_get_users_courses' + '&moodlewsrestformat=json' + '&userid=412')

        if not courses_request.ok:
            raise Exception("error accessing moodle")

    return courses_request.json()


def cache_courses(courses, base_url: str, token: str, user_id: int):
    if courses is None:
        try:
            user_courses_data = get_user_courses_req(base_url, token)
            courses = []
            for ud in user_courses_data:
                courses.append({"id": ud['id'],
                                "name": ud['displayname']
                                # other stuff is irrelevant for current application.
                                # i guess there will be more stuff added?
                                })

            if type(user_courses_data) is not list:
                raise TypeError("moodle returned invalid data")
        except eventlet.Timeout:
            print("[ - ] (cache_courses()): timeout after 20 seconds.")

        except TypeError as e:
            print(f"[ - ] (cache_courses()): {e}")

        except Exception as e:
            printf(
                f"[ - ] (cache_courses()): misc error getting courses from moodle: {e}")

    existing = MoodleCache.query.filter_by(user_id=user_id).delete()
    db.session.commit()

    for c in courses:
        new_c = MoodleCache()
        new_c.course_id = c['id']
        new_c.name = c['name']
        new_c.teacher = ''
        new_c.moodle_url = base_url
        new_c.user_id = user_id

        db.session.add(new_c)
        # print(c)

    db.session.commit()

    #print("[ + ] successfully cached courses?")
