# routes

## user
- [x] `GET` `/user` gets user from session cookie
- [ ] `GET` `/user/{id}` gets user from `{id}`
- [x] `POST` `/user` creates new user (register)
- [x] `POST` `/user/register` creates new user (register) (legacy route -- to be removed probably)
- [ ] `POST` `/user/logout` deletes session
- [x] `POST` `/user/login` authenticates user (creates session)
- [x] `GET` `/username-taken/{username}` is `{username}` taken?

## assignment
- [x] `POST` `/assignment` creates new assignment
- [x] `DELETE` `/assignment?id=` deletes assignment

## course
- [x] `GET` `/courses/search/{searchterm}` 
- [x] `GET` `/courses/active` gets all courses with active assignments (only active assignments to save bandwidth)

## moodle
- [ ] `GET` `/moodle/get-courses`
- [x] `POST` `/moodle/authenticate`
- [ ] `POST` `/moodle/get-school-info`

### not used currently

These endpoints would be used if non-moodle courses were currently supported in [the frontend](https://github.com/entenclub/homework/tree/master/frontend) currently hosted at [https://hausis.3nt3.de](https://hausis.3nt3.de)

- [ ] `GET` `/courses` gets all courses the current user is enrolled in
- [ ] `POST` `/courses` creates new course
- [ ] `POST` `/courses` creates new course
- [ ] `GET` `/user/{id}` gets user from `{id}`
- [ ] `POST` `/user/logout` deletes session
- [ ] `GET` `/moodle/get-courses` I don't really think this is used?
- [ ] `POST` `/moodle/get-school-info`
