{-#  LANGUAGE TemplateHaskell #-}
{-# LANGUAGE DuplicateRecordFields #-}

module GameLogic where

import System.Random (StdGen)
import Prelude hiding (Left,Right)
import Types.Common
import Types.GameObjs
import Render.ImageIO

import Control.Lens
import Codec.Picture 
import qualified Data.HashSet as S

import Settings

import Debug.Trace

initialState :: StdGen -> ImageMap -> GameState 
initialState g is = GameState { 
   _board = emptyBoard is
  ,_status = InProgress
  ,_gen = g
  ,_images = is
}

emptyBoard is = Board {
  _player1 = Player {
    _gameObj  = GameObj {
      _position = (0,0)
     ,_img = ""
     ,_display = True}
   ,_dir      = Left
   ,_aliveTime= 0
   ,_score    = 0
   ,_inMotion = False}
 ,_objs = S.singleton testcoin
 ,_levelName = Level Settings.levelImageSrc
}

testcoin = GameObj {
  _position = (80,10)
  ,_img = "coin.png"
  ,_display = True
}

update :: (GameState, GameInput) -> GameState
update (gameState, input) = tick $ case input of
  None -> set (board.player1.inMotion) False gameState
  dir -> move dir gameState

move :: Direction -> GameState -> GameState
move d g = if wallCollision (makeMove d g) then g else makeMove d g

wallCollision :: GameState -> Bool
wallCollision g = let
  (x,y) = view (board.player1.gameObj.position) g
  xsize = 7
  ysize = 10
  playerLocs = [(x',y') | x' <- [x-xsize..x+xsize],y' <- [y-ysize.. y+ysize]]
  boardPixels = map (\(x,y) -> pixelAtFromCenter (fst $ getImg _levelName g) x y) playerLocs
 in 
  any (==blackAPixel) (boardPixels)

traceMe x = traceShow x x
pixelAtFromCenter :: Image PixelRGBA8 -> Int -> Int -> PixelRGBA8
pixelAtFromCenter i x y = let
  h = imageHeight i 
  w = imageWidth i 
  x' = (w `div` 2) + x
  y' = (h `div` 2) + (-y)
 in
  pixelAt i x' y'
  --whitePixel

makeMove :: Direction -> GameState -> GameState
makeMove d g = let 
    updateF = case d of
     Down  -> (0,-1)
     Up    -> (0,1)
     Left  -> (-1,0)
     Right -> (1,0)
     _     -> (0,0)
    appT (dx,dy) (x,y) = (x+dx,y+dy)
    newPos = over (board.player1.gameObj.position) (appT updateF) g
    newDir = set (board.player1.dir) d newPos
  in
    set (board.player1.inMotion) True newDir

-- | conviences

isGameOver :: GameState -> Bool
isGameOver s = False

tick :: GameState -> GameState
tick = over (board.player1.aliveTime) (+1) 
