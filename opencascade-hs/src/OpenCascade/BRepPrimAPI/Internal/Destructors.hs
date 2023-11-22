{-# LANGUAGE CApiFFI #-}
module OpenCascade.BRepPrimAPI.Internal.Destructors where

import OpenCascade.BRepPrimAPI.Types

import Foreign.Ptr

foreign import capi unsafe "hs_BRepPrimAPI_MakeBox.h hs_delete_BRepPrimAPI_MakeBox" deleteMakeBox :: Ptr MakeBox -> IO ()


