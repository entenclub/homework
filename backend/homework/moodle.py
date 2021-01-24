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

    cache_objs_query = db.session.query(MoodleCache).filter(
        MoodleCache.moodle_url == base_url).filter(MoodleCache.user_id == user.id)
    cache_objs = cache_objs_query.all()

    expired = False
    user_courses_data = None

    for cache_obj in cache_objs:
        if (datetime.datetime.now() - cache_obj.cached_at).days > 7:
            expired = True
            break

    new_enough = False
    user_courses = []

    if cache_objs:
        if expired:
            print("[ * ] cache expired")
            cache_objs_query.delete()
            cache_objs = []

            try:
                db.session.commit()
            except Exception as e:
                print("[ - ] error deleting objects: {}".format(e))

            # what the fuck even is this code lol
            user_courses_data = get_user_courses_req(base_url, token)

        for cache_obj in cache_objs:
            if (datetime.datetime.utcnow() - cache_obj.cached_at).seconds > 60:
                new_enough = False
                break

    else:
        # since there is no usable cache, get stuff
        user_courses_data = get_user_courses_req(base_url, token, user.moodle_user_id)

    # if there has been a fresh new request, execute this lol
    if user_courses_data is not None:
        for ud in user_courses_data:
            user_courses.append({"id": ud['id'],
                                 "name": ud['displayname']
                                 # other stuff is irrelevant for current application.
                                 # i guess there will be more stuff added?
                                 })

    # if the cache has not been updated recently, or is straight up empty, renew it
    if not new_enough or not cache_objs:
        # start a new thread caching stuff in the background
        t = threading.Thread(
            target=cache_courses, name='cache courses', args=(user_courses, base_url, token, user.id, user.moodle_user_id,))
        t.start()

    # this returns moodle data
    if not cache_objs:
        return user_courses

    # this returns cache
    return_stuff = []
    for co in cache_objs:
        tmp = co.to_dict()
        tmp['id'] = tmp['courseId']
        return_stuff.append(tmp)

    return return_stuff


def get_user_courses_req(base_url: str, token: str, moodle_user_id: int):
    with eventlet.Timeout(20):
        courses_request = requests.get(
            base_url + '/webservice/rest/server.php' + '?wstoken=' + token + '&wsfunction=' + 'core_enrol_get_users_courses' + '&moodlewsrestformat=json' + f'&userid={moodle_user_id}')

        if not courses_request.ok:
            raise Exception("error accessing moodle")

    return courses_request.json()


def cache_courses(courses, base_url: str, token: str, user_id: int, moodle_user_id: int):
    print("caching initiated...")
    if courses is None or len(courses) == 0:
        print("courses are not there, fetching..")
        try:
            user_courses_data = get_user_courses_req(
                base_url, token, moodle_user_id)
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
            print(
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

    db.session.commit()

    #print("[ + ] successfully cached courses?")
