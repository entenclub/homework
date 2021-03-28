module Models exposing (Assignment, Course, Privilege(..), User)

import Date



-- model data types


type Privilege
    = Normal
    | Admin


type alias User =
    { id : String
    , username : String
    , email : String
    , privilege : Privilege
    , moodleUrl : String
    }


type alias Assignment =
    { id : String
    , courseId : Int
    , user : User
    , title : String
    , description : Maybe String
    , dueDate : Date.Date
    , fromMoodle : Bool
    }


type alias Course =
    { id : Int
    , name : String
    , assignments : List Assignment
    , fromMoodle : Bool
    , user : String
    }
