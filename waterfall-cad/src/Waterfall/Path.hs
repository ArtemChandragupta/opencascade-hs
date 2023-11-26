module Waterfall.Path
( Path
, line
, lineTo
, lineRelative
, arcVia
, arcViaTo
, arcViaRelative
, bezier
, bezierTo
, bezierRelative
, pathFrom
, pathFromTo
) where


import Waterfall.Internal.Path (Path(..), joinPaths)
import Control.Arrow (second)
import Data.Foldable (traverse_, foldl')
import Linear.V3 (V3(..))
import Control.Monad.IO.Class (liftIO)
import qualified Linear.V3 as V3
import Linear ((^*), distance, normalize)
import qualified OpenCascade.GP as GP
import qualified OpenCascade.GP.Pnt as GP.Pnt 
import qualified OpenCascade.BRepBuilderAPI.MakeEdge as MakeEdge
import qualified OpenCascade.BRepBuilderAPI.MakeWire as MakeWire
import qualified OpenCascade.TopoDS as TopoDS
import qualified OpenCascade.GC.MakeArcOfCircle as MakeArcOfCircle
import qualified OpenCascade.Geom as Geom
import qualified OpenCascade.NCollection.Array1 as NCollection.Array1
import qualified OpenCascade.Geom.BezierCurve as BezierCurve
import OpenCascade.Inheritance (upcast)
import Foreign.Ptr
import Data.Acquire

v3ToPnt :: V3 Double -> Acquire (Ptr GP.Pnt)
v3ToPnt (V3 x y z) = GP.Pnt.new x y z

edgesToPath :: Acquire [Ptr TopoDS.Edge] -> Path
edgesToPath es = Path $ do
    edges <- es
    builder <- MakeWire.new
    liftIO $ traverse_ (MakeWire.addEdge builder) edges
    MakeWire.wire builder

line :: V3 Double -> V3 Double -> Path
line start end = edgesToPath $ do
    pt1 <- v3ToPnt start
    pt2 <- v3ToPnt end
    pure <$> MakeEdge.fromPnts pt1 pt2

lineTo :: V3 Double -> V3 Double -> (V3 Double, Path)
lineTo end = \start -> (end, line start end) 

lineRelative :: V3 Double -> V3 Double -> (V3 Double, Path)
lineRelative dEnd = do
    end <- (+ dEnd)
    lineTo end

arcVia :: V3 Double -> V3 Double -> V3 Double -> Path
arcVia start mid end = edgesToPath $ do
    s <- v3ToPnt start
    m <- v3ToPnt mid
    e <- v3ToPnt end
    theArc <- MakeArcOfCircle.from3Pnts s m e
    pure <$> MakeEdge.fromCurve (upcast theArc)

arcViaTo :: V3 Double -> V3 Double -> V3 Double -> (V3 Double, Path)
arcViaTo mid end = \start -> (end, arcVia start mid end) 

arcViaRelative :: V3 Double -> V3 Double -> V3 Double -> (V3 Double, Path)
arcViaRelative dMid dEnd = do
    mid <- (+ dMid) 
    end <- (+ dEnd) 
    arcViaTo mid end

bezier :: V3 Double -> V3 Double -> V3 Double -> V3 Double -> Path
bezier start controlPoint1 controlPoint2 end = edgesToPath $ do
    s <- v3ToPnt start
    c1 <- v3ToPnt controlPoint1
    c2 <- v3ToPnt controlPoint2
    e <- v3ToPnt end
    arr <- NCollection.Array1.newGPPntArray 1 4
    liftIO $ do 
        NCollection.Array1.setValueGPPnt arr 1 s
        NCollection.Array1.setValueGPPnt arr 2 c1
        NCollection.Array1.setValueGPPnt arr 3 c2
        NCollection.Array1.setValueGPPnt arr 4 e
    b <- BezierCurve.toHandle =<< BezierCurve.fromPnts arr
    pure <$> MakeEdge.fromCurve (upcast b)

    
bezierTo :: V3 Double -> V3 Double -> V3 Double -> V3 Double -> (V3 Double, Path)
bezierTo controlPoint1 controlPoint2 end = \start -> (end, bezier start controlPoint1 controlPoint2 end) 

bezierRelative :: V3 Double -> V3 Double -> V3 Double -> V3 Double -> (V3 Double, Path)
bezierRelative dControlPoint1 dControlPoint2 dEnd = do
    controlPoint1 <- (+ dControlPoint1)
    controlPoint2 <- (+ dControlPoint2)
    end <- (+ dEnd)
    bezierTo controlPoint1 controlPoint2 end

pathFrom :: V3 Double -> [(V3 Double -> (V3 Double, Path))] -> Path
pathFrom start commands = snd $ pathFromTo commands start 
     
pathFromTo :: [(V3 Double -> (V3 Double, Path))] -> V3 Double -> (V3 Double, Path)
pathFromTo commands start = 
    let go (pos, paths) cmd = second (:paths) (cmd pos)
        (end, allPaths) = foldl' go (start, []) commands
     in (end, joinPaths allPaths)




