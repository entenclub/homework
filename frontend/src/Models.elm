module Models exposing (Assignment, Course, Privilege(..), User)

import Time



-- model data types


type Privilege
    = Normal
    | Admin


type alias User =
    { id : Int
    , username : String
    , email : String
    , privilege : Privilege
    }


type alias Assignment =
    { id : Int
    , courseId : Int
    , creator : User
    , title : String
    , description : Maybe String
    , dueDate : Time.Posix
    }


type alias Course =
    { id : Int
    , subject : String
    , teacher : String
    , assignments : List Assignment
    }
