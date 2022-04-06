module Common exposing (Model, viewportSize, meshPositionMap, 
                        MeshList, Vertex, Uniforms, 
                        DragState(..),
                        vertexShader, fragmentShader)

import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector3 as Vec3 exposing (vec3, Vec3)

import WebGL exposing (Shader)

viewportSize : (Int, Int)
viewportSize = (800, 800)


type DragState = Drag | NoDrag

type alias Model =
  { location : { x : Float, y: Float, z: Float }
  , rotation : Float
  , elapsed : Float
  , power : Float
  , pointerOffset : { x: Int, y: Int }
  , canvasDimensions : { width: Int, height: Int }
  , upButtonDown : Bool
  , downButtonDown : Bool
  , dragState : DragState
  , previousOffset : { x: Int, y: Int }
  , cameraAzimoth : Float
  , cameraElevation : Float
  }


meshPositionMap : (Vec3 -> Vec3) -> MeshList -> MeshList
meshPositionMap fun mesh =
  case mesh of
    [] ->
      []
    (v1, v2, v3) :: xs ->
      [ ( { v1 | position = fun v1.position }
        , { v2 | position = fun v2.position }
        , { v3 | position = fun v3.position } ) ] ++ (meshPositionMap fun xs)


type alias Uniforms =
  { rotation : Mat4
  , location : Mat4
  , perspective : Mat4
  , camera : Mat4
  , scale : Mat4
  , shade : Float
  }


type alias Vertex =
  { color : Vec3
  , position : Vec3
  }


type alias MeshList = List (Vertex, Vertex, Vertex)


vertexShader : Shader Vertex Uniforms { vcolor : Vec3 }
vertexShader =
  [glsl|
     attribute vec3 position;
     attribute vec3 color;
     uniform mat4 perspective;
     uniform mat4 camera;
     uniform mat4 rotation;
     uniform mat4 location;
     uniform mat4 scale;
     varying vec3 vcolor;
     void main () {
       gl_Position = (perspective * camera * location *
                      rotation * scale * vec4(position, 1.0));
       vcolor = color;
     }
  |]


fragmentShader : Shader {} Uniforms { vcolor : Vec3 }
fragmentShader =
  [glsl|
    precision mediump float;
    uniform float shade;
    varying vec3 vcolor;
    void main () {
      gl_FragColor = shade * vec4(vcolor, 1.0);
    }
  |]

