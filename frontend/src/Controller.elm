module Controller exposing
    ( controllerMeshDown
    , controllerMeshUp
    , controllerUnif
    , handleDown
    , handleMove
    , handleUp
    )

import Common
    exposing
        ( Camera
        , CanvasDimensions
        , Controller
        , DragState(..)
        , MeshList
        , Uniforms
        , Vertex
        , meshPositionMap
        , viewportSize
        )
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector3 as Vec3 exposing (Vec3, vec3)
import WebGL exposing (Mesh)


controllerParams : { x : Float, y : Float, size : Float, trans : Float }
controllerParams =
    { x = 0.5
    , y = -0.2
    , size = 0.2
    , trans = 0.3
    }


controllerUnif : CanvasDimensions -> Float -> Uniforms
controllerUnif canvasDimensions shade =
    let
        xscale =
            toFloat canvasDimensions.width
                / toFloat (Tuple.first viewportSize)

        yscale =
            toFloat canvasDimensions.height
                / toFloat (Tuple.second viewportSize)

        x =
            controllerParams.x

        y =
            controllerParams.y

        size =
            controllerParams.size

        translation =
            Mat4.translate (vec3 x y 0) Mat4.identity

        scale =
            Mat4.scale (vec3 (size / xscale) (size / yscale) 1) Mat4.identity
    in
    { preScale = Mat4.identity
    , preRotation = Mat4.identity
    , preTranslation = Mat4.identity
    , scale = scale
    , rotation = Mat4.identity
    , translation = translation
    , postScale = Mat4.identity
    , postRotation = Mat4.identity
    , postTranslation = Mat4.identity
    , perspective =
        Mat4.makeOrtho -1 1 -1 1 0 10
    , camera =
        Mat4.makeLookAt (vec3 0 0 1) (vec3 0 0 0) (vec3 0 1 0)
    , shade = shade
    }


controllerMeshDown : Mesh Vertex
controllerMeshDown =
    let
        trans =
            controllerParams.trans
    in
    [ meshPositionMap
        (Vec3.add (vec3 0 -trans 0))
        [ ( Vertex (vec3 0 0 1) (vec3 1 0 0)
          , Vertex (vec3 1 0 0) (vec3 0 -1 0)
          , Vertex (vec3 0 0 1) (vec3 -1 0 0)
          )
        ]
    ]
        |> List.concat
        |> WebGL.triangles


controllerMeshUp : Mesh Vertex
controllerMeshUp =
    let
        trans =
            controllerParams.trans
    in
    [ meshPositionMap
        (Vec3.add (vec3 0 trans 0))
        [ ( Vertex (vec3 0 0 1) (vec3 -1 0 0)
          , Vertex (vec3 0 1 0) (vec3 0 1 0)
          , Vertex (vec3 0 0 1) (vec3 1 0 0)
          )
        ]
    ]
        |> List.concat
        |> WebGL.triangles


coordinatesWithinUpButton : Maybe CanvasDimensions -> ( Float, Float ) -> Bool
coordinatesWithinUpButton canvasDimensions offset =
    coordinatesWithinButton canvasDimensions offset (controllerParams.trans + 0.5)


coordinatesWithinDownButton : Maybe CanvasDimensions -> ( Float, Float ) -> Bool
coordinatesWithinDownButton canvasDimensions offset =
    coordinatesWithinButton canvasDimensions offset (-controllerParams.trans - 0.5)


coordinatesWithinButton : Maybe CanvasDimensions -> ( Float, Float ) -> Float -> Bool
coordinatesWithinButton maybeCanvas pointerOffset trans =
    case maybeCanvas of
        Just canvasDimensions ->
            let
                yscale =
                    toFloat canvasDimensions.height
                        / toFloat (Tuple.second viewportSize)

                xscale =
                    toFloat canvasDimensions.width
                        / toFloat (Tuple.first viewportSize)

                size =
                    controllerParams.size

                fixedTrans =
                    (trans * size) / yscale

                middlepointX =
                    (1 + controllerParams.x) * (toFloat canvasDimensions.width / 2)

                middlepointY =
                    (1 - controllerParams.y - fixedTrans) * (toFloat canvasDimensions.height / 2)

                sizeLimitX =
                    size * toFloat (Tuple.first viewportSize) / 2

                sizeLimitY =
                    size * toFloat (Tuple.second viewportSize) / 4
            in
            if
                (abs (middlepointX - Tuple.first pointerOffset) < sizeLimitX)
                    && (abs (middlepointY - Tuple.second pointerOffset) < sizeLimitY)
            then
                True

            else
                False

        Nothing ->
            False


handleUp : Controller -> Controller
handleUp controller =
    { controller
        | upButtonDown = False
        , downButtonDown = False
        , dragState = NoDrag
    }


handleDown : Controller -> ( Float, Float ) -> Maybe CanvasDimensions -> Controller
handleDown controller offsetPos canvasDimensions =
    let
        coordsInUp =
            coordinatesWithinUpButton canvasDimensions offsetPos

        coordsInDown =
            coordinatesWithinDownButton canvasDimensions offsetPos

        upButtonDown =
            if coordsInUp then
                True

            else
                False

        downButtonDown =
            if coordsInDown then
                True

            else
                False

        newController =
            { controller
                | previousOffset =
                    { x = round (Tuple.first offsetPos)
                    , y = round (Tuple.second offsetPos)
                    }
                , pointerOffset =
                    { x = round (Tuple.first offsetPos)
                    , y = round (Tuple.second offsetPos)
                    }
                , upButtonDown = upButtonDown
                , downButtonDown = downButtonDown
                , dragState = Drag
            }
    in
    newController


handleMove : Controller -> Camera -> ( Float, Float ) -> ( Controller, Camera )
handleMove controller camera offsetPos =
    let
        newAzimoth =
            if controller.dragState == Drag then
                camera.azimoth
                    - toFloat
                        (round (Tuple.first offsetPos)
                            - controller.previousOffset.x
                        )
                    * pi
                    / 180

            else
                camera.azimoth

        newElevation =
            if controller.dragState == Drag then
                camera.elevation
                    + toFloat
                        (round (Tuple.second offsetPos)
                            - controller.previousOffset.y
                        )
                    * pi
                    / 180

            else
                camera.elevation

        newCamera =
            { camera
                | azimoth = newAzimoth
                , elevation =
                    if newElevation <= (4 * pi / 10) then
                        if newElevation >= (-4 * pi / 10) then
                            newElevation

                        else
                            camera.elevation

                    else
                        camera.elevation
            }

        newController =
            { controller
                | previousOffset =
                    { x = round (Tuple.first offsetPos)
                    , y = round (Tuple.second offsetPos)
                    }
            }
    in
    ( newController, newCamera )
