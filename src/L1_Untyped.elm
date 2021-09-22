module L1_Untyped exposing (..)

{-|

    --== Simple recursion ==--
    eval (Var "f") [ ( "f", Lam "x" (App (Var "f") (Var "x")) ) ] --> Ok (Lam "x" (App (Var "f") (Var "x")))
    eval (Var "f") [ ( "f", Lam "x" (App (Var "x") (Var "f")) ) ] --> Ok (Lam "x" (App (Var "x") (Var "f")))

    --== Factorial ==--
    -- f 0 = 1
    -- f n = n * f (n - 1)
    factorial : Expr
    factorial =
        Lam "n" (app (eq (Var "n") (Num 0)) [ Num 1, mul (Var "n") (App (Var "f") (sub (Var "n") (Num 1))) ])

    eval (Var "f") [ ( "f", factorial ) ] --> Ok factorial
    eval (App (Var "f") (Num 0)) [ ( "f", factorial ) ] --> Ok (Num 1)
    eval (App (Var "f") (Num 1)) [ ( "f", factorial ) ] --> Ok (Num 1)
    -- eval (App (Var "f") (Num 5)) [ ( "f", factorial ) ] -- Ok (Num 120)

-}


type Expr
    = Num Float
    | Var String
    | Let Env Expr
    | Lam String Expr
    | App Expr Expr
      -- Built-in functions
    | Add
    | Sub
    | Mul
    | Eq


type Error
    = UndefinedVar String
    | NotAFunction Expr


type alias Env =
    List ( String, Expr )


get : String -> Env -> Maybe Expr
get x env =
    case env of
        ( y, ey ) :: envTail ->
            if x == y then
                Just ey

            else
                get x envTail

        [] ->
            Nothing


{-|

    lam [] (Var "e") --> Var "e"

    lam [ "x" ] (Var "e") --> Lam "x" (Var "e")

    lam [ "x", "y", "z" ] (Var "e") --> Lam "x" (Lam "y" (Lam "z" (Var "e")))

-}
lam : List String -> Expr -> Expr
lam xs e =
    List.foldr Lam e xs


{-|

    app (Var "f") [] --> Var "f"

    app (Var "f") [ Var "x" ] --> App (Var "f") (Var "x")

    app (Var "f") [ Var "x", Var "y", Var "z" ] --> App (App (App (Var "f") (Var "x")) (Var "y")) (Var "z")

-}
app : Expr -> List Expr -> Expr
app f xs =
    List.foldl (\x e -> App e x) f xs


add : Expr -> Expr -> Expr
add e1 e2 =
    App (App Add e1) e2


sub : Expr -> Expr -> Expr
sub e1 e2 =
    App (App Sub e1) e2


mul : Expr -> Expr -> Expr
mul e1 e2 =
    App (App Mul e1) e2


eq : Expr -> Expr -> Expr
eq e1 e2 =
    App (App Eq e1) e2


{-|

    --== Number value ==--
    eval (Num 42) [] --> Ok (Num 42)

    --== Variable ==--
    eval (Var "x") [] --> Err (UndefinedVar "x")

    eval (Var "x") [ ( "x", Num 1 ) ] --> Ok (Num 1)

    eval (Var "x") [ ( "x", Var "x" ) ] --> Ok (Var "x")

    eval (Var "x") [ ( "x", Var "y" ), ( "y", Num 1 ) ] --> Ok (Num 1)

    eval (Var "x") [ ( "y", Num 1 ), ( "x", Var "y" ) ] --> Ok (Num 1)

    --== Let bindings ==--
    eval (Let [] (Var "x")) [ ( "x", Num 1 ) ] --> Ok (Num 1)

    eval (Let [ ( "x", Num 1 ) ] (Var "x")) [ ( "x", Num 2 ) ] --> Ok (Num 1)

    --== Lamda abstraction ==--
    eval (Lam "x" (Num 1)) [] --> Ok (Lam "x" (Num 1))

    eval (Lam "x" (Var "y")) [] --> Err (UndefinedVar "y")

    eval (Lam "x" (Var "x")) [] --> Ok (Lam "x" (Var "x"))

    --== Application ==--
    eval (App (Num 1) (Num 2)) [] --> Err (NotAFunction (Num 1))

    eval (App (Var "f") (Var "x")) [] --> Err (UndefinedVar "f")

    eval (App (Var "f") (Var "x")) [ ( "f", Var "f" ) ] --> Err (UndefinedVar "x")

    eval (App (Var "f") (Var "x")) [ ( "f", Var "f" ), ( "x", Num 1 ) ] --> Ok (App (Var "f") (Num 1))

    eval (App (Lam "x" (Var "x")) (Var "x")) [ ( "x", Num 1 ) ] --> Ok (Num 1)

    eval (App (Var "f") (Var "x")) [ ( "f", Lam "x" (Var "x") ), ( "x", Num 1 ) ] --> Ok (Num 1)

    eval (App (App (Var "f") (Num 1)) (Var "x")) [ ( "f", Var "f" ), ( "x", Num 2 ) ] --> Ok (App (App (Var "f") (Num 1)) (Num 2))

    eval (App (App (Var "f") (Lam "x" (Var "x"))) (Var "x")) [ ( "f", Lam "x" (Var "x") ), ( "x", Num 1 ) ] --> Ok (Num 1)

    --== Addition ==--
    eval (App Add (Var "x")) [ ( "x", Num 3 ) ] --> Ok (App Add (Num 3))

    eval (add (Var "x") (Var "y")) [ ( "x", Num 3 ), ( "y", Num 2 ) ] --> Ok (Num 5)

    --== Subtraction ==--
    eval (App Sub (Var "x")) [ ( "x", Num 3 ) ] --> Ok (App Sub (Num 3))

    eval (sub (Var "x") (Var "y")) [ ( "x", Num 3 ), ( "y", Num 2 ) ] --> Ok (Num 1)

    --== Multiplication ==--
    eval (App Mul (Var "x")) [ ( "x", Num 3 ) ] --> Ok (App Mul (Num 3))

    eval (mul (Var "x") (Var "y")) [ ( "x", Num 3 ), ( "y", Num 2 ) ] --> Ok (Num 6)

    --== Equality ==--
    eval (App Eq (Var "x")) [ ( "x", Num 1 ) ] --> Ok (App Eq (Num 1))

    eval (eq (Var "x") (Var "y")) [ ( "x", Num 1 ), ( "y", Num 2 ) ] --> Ok (Lam "True" (Lam "False" (Var "False")))

    eval (eq (Var "x") (Var "y")) [ ( "x", Num 2 ), ( "y", Num 2 ) ] --> Ok (Lam "True" (Lam "False" (Var "True")))

    eval (eq (Var "x") (Var "y")) [ ( "x", Num 3 ), ( "y", Num 2 ) ] --> Ok (Lam "True" (Lam "False" (Var "False")))

-}
eval : Expr -> Env -> Result Error Expr
eval expr env =
    case expr of
        Num k ->
            Ok (Num k)

        Var x ->
            case get x env of
                Just ex ->
                    if ex == Var x then
                        Ok (Var x)

                    else
                        eval ex (( x, Var x ) :: env)

                Nothing ->
                    Err (UndefinedVar x)

        Let (( x, ex ) :: vars) e ->
            eval (Let vars e) (( x, ex ) :: env)

        Let [] e ->
            eval e env

        Lam x e ->
            case eval e (( x, Var x ) :: env) of
                Ok e_ ->
                    Ok (Lam x e_)

                Err err ->
                    Err err

        App e1 e2 ->
            case eval e1 env of
                Ok (Num k) ->
                    Err (NotAFunction (Num k))

                Ok (Lam x e) ->
                    if e2 == Var x then
                        eval e env

                    else
                        eval e (( x, Let env e2 ) :: env)

                Ok e1_ ->
                    case ( e1_, eval e2 env ) of
                        ( Var x, Ok e2_ ) ->
                            Ok (App (Var x) e2_)

                        ( App Add (Num k1), Ok (Num k2) ) ->
                            Ok (Num (k1 + k2))

                        ( App Sub (Num k1), Ok (Num k2) ) ->
                            Ok (Num (k1 - k2))

                        ( App Mul (Num k1), Ok (Num k2) ) ->
                            Ok (Num (k1 * k2))

                        ( App Eq (Num k1), Ok (Num k2) ) ->
                            if k1 == k2 then
                                Ok (Lam "True" (Lam "False" (Var "True")))

                            else
                                Ok (Lam "True" (Lam "False" (Var "False")))

                        ( _, Ok e2_ ) ->
                            Ok (App e1_ e2_)

                        ( _, Err err ) ->
                            Err err

                Err err ->
                    Err err

        op ->
            Ok op
