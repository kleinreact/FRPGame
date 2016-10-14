{-# LANGUAGE Arrows #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE MultiWayIf #-}

module
    HandmadeMain
where

import System.Random (StdGen)
import FRP.Yampa

import Types
import GameLogic
import Codec.Picture

-- | Run the game while the player ('notDead')
-- when the player ('lostGame'), then ('restartGame')
wholeGame :: StdGen -> Image PixelRGB8 -> SF GameInput GameState
wholeGame g i = switch
  (notDead g i >>> (identity &&& lostGame))
  (restartGame g i)




-- | Start the game using the initial game state 
notDead :: StdGen -> Image PixelRGB8 -> SF GameInput GameState
notDead g i = runGame $ initialState g i

-- | Run the game, keeping the internal state using dHold, updating the
-- game state based on user's input (if any)
-- We could use dHold here, it might be more efficent
-- i think its more clear to use iPre tho and avoid the Event wrapper
runGame :: GameState -> SF GameInput GameState
runGame state = proc input -> do
  rec currentState <- iPre state -< updatedState
      updatedState <- arr update -< (currentState, input)
  returnA -< updatedState --currentState



-- | Throw an event when the game is lost
lostGame :: SF GameState (Event GameState)
lostGame = proc s -> do
  lost <- edge -< isGameOver s
  let snapshot = lost `tag` s
  returnA -< snapshot

-- | When the game is lost we want to show the GameOver text for some time
-- and then restart the game
restartGame :: StdGen -> Image PixelRGB8 ->  GameState -> SF GameInput GameState
restartGame g i s = switch
  (gameOver s &&& after 5 ())
  (const $ wholeGame g i)

-- | When we have lost the game we want to keep the board in a state that
-- the user reached and show some GameOver message over it
gameOver :: GameState -> SF a GameState
gameOver s = arr $ const $ s { _status = GameOver }

