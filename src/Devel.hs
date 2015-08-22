{-|
Module      : Devel
Description : An entry point for GHC to compile yesod-devel.
Copyright   : (c)
License     : GPL-3
Maintainer  : njagi@urbanslug.com
Stability   : experimental
Portability : POSIX
-}
module Devel where

import Devel.Build (build)
import Devel.ReverseProxy
import IdeSession (sessionConfigFromEnv)
import System.Environment (lookupEnv, setEnv)
import Devel.Config (setConfig)


buildAndRun :: FilePath -> String ->  Bool -> IO ()
buildAndRun buildFile runFunction reverseProxy = do
  -- set config for ide-backend to find.
  _ <- setConfig
  
  -- This is for ide-backend.
  config <- sessionConfigFromEnv
  
  -- If port isn't set we assume port 3000
  mPort <- lookupEnv "PORT"
  let srcPort = case mPort of
                  Just p -> read p :: Int
                  _ -> 3000

  -- Gives us a port to reverse proxy to.
  destPort <- cyclePorts srcPort

  case reverseProxy of
    True  -> setEnv "PORT" (show destPort)
    False -> setEnv "PORT" (show srcPort)

  build buildFile runFunction reverseProxy config (srcPort, destPort)


cyclePorts :: Int -> IO Int
cyclePorts p = do
  let port = p + 1
  portAvailable <- checkPort port
  case portAvailable of
    True -> return port
    _ -> cyclePorts port
