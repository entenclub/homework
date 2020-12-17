module Models exposing (Assignment, Course, Privilege(..), User)

import Date



-- model data types


type Privilege
    = Normal
    | Admin


type alias User =
    { id : Int
    , username : String
    , email : String
    , privilege : Privilege
    , moodleUrl : String
    }


type alias Assignment =
    { id : Int
    , courseId : Int
    , creator : User
    , title : String
    , description : Maybe String
    , dueDate : Date.Date
    , fromMoodle : Bool
    }


type alias Course =
    { id : Int
    , name : String
    , subject : String
    , teacher : String
    , assignments : List Assignment
    , fromMoodle : Bool
    , creator : Int
    }
