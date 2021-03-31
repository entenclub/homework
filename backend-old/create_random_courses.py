import string
import random

from homework import db
from homework.database.course import Course

for i in range(1000):
    out = ''
    for i in range(12):
        out += random.choice(string.ascii_letters)

    new_course = Course()
    new_course.teacher = out
    new_course.subject = out

    db.session.add(new_course)
    db.session.commit()

print("completed (created 1000 random entries).")