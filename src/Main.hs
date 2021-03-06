{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE Arrows #-}

module Main where

import GameController
import InitGameState 
import Types.Common

import Render.Render 
import Render.GlossInterface
import Render.ImageIO

import Input.Input

import AFRPV.Yampa (Event(..), SF, (>>>), renderNetwork)
import qualified Graphics.Gloss.Interface.IO.Game as G
import Data.Map (union)
import System.Random (newStdGen, StdGen)

import qualified Settings
import GHC.IO.Encoding

main :: IO()
main = do
  setLocaleEncoding utf8
  setFileSystemEncoding utf8
  setForeignEncoding utf8  
  playGame

-- | load a random numbe gen
--   NB : read in every image we will ever need
--   this might use up too much memor if the game uses many images since we have no way to evict an image (I think)
playGame :: IO ()
playGame = do
    g <- newStdGen

    levelImgs <- makeImgMap levelImgSrcs
    playerImgs <- makeImgMap playerImgSrcs
    --coinImg <- makeImgMap coinImgSrc
    
    let
      imgs = levelImgs `union` playerImgs
      sf = mainSF g imgs

    renderNetwork sf "network" 
    
    playYampa
        (G.InWindow "Yampa Example" (800, 600) (800, 600))
        G.white
        Settings.fps
        sf

-- | Our main signal function which is responsible for handling the whole
-- game process, starting from parsing the input, moving to the game logic
-- based on that input and finally drawing the resulting game state to
-- Gloss' Picture
mainSF :: StdGen -> ImageMap -> SF (Event InputEvent) G.Picture
mainSF g is = 
  parseInput >>> wholeGame g is (initialState g is) >>> drawGame
