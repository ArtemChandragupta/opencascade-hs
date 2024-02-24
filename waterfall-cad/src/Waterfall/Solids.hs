module Waterfall.Solids 
( Solid
, nowhere
, unitCube
, centeredCube
, box
, unitSphere
, unitCylinder
, centeredCylinder
, unitCone
, prism
) where


import Waterfall.Internal.Solid (Solid (..), solidFromAcquire, nowhere)
import Waterfall.Internal.Finalizers (toAcquire)
import Waterfall.TwoD.Internal.Shape (rawShape)
import Waterfall.Transforms (translate)
import qualified Waterfall.TwoD.Shape as TwoD.Shape
import qualified OpenCascade.BRepPrimAPI.MakeBox as MakeBox
import qualified OpenCascade.BRepPrimAPI.MakeSphere as MakeSphere
import qualified OpenCascade.BRepPrimAPI.MakeCylinder as MakeCylinder
import qualified OpenCascade.BRepPrimAPI.MakeCone as MakeCone
import qualified OpenCascade.GP as GP
import Linear (V3 (..), unit, _z, (^*))
import qualified OpenCascade.GP.Pnt as GP.Pnt
import qualified OpenCascade.GP.Vec as GP.Vec
import qualified OpenCascade.BRepPrimAPI.MakePrism as MakePrism
import qualified OpenCascade.Inheritance as Inheritance

-- | A cube with side lengths of 1, one vertex on the origin, another on \( (1, 1, 1) \)
unitCube :: Solid
unitCube = solidFromAcquire $ do
    a <- GP.origin
    b <- GP.Pnt.new 1 1 1
    builder <- MakeBox.fromPnts a b
    Inheritance.upcast <$> MakeBox.solid builder

-- | A cube with side lengths of 1, centered on the origin
centeredCube :: Solid
centeredCube = solidFromAcquire $ do
    a <- GP.Pnt.new (-1/2) (-1/2) (-1/2)
    b <- GP.Pnt.new (1/2) (1/2) (1/2)
    builder <- MakeBox.fromPnts a b
    Inheritance.upcast <$> MakeBox.solid builder

-- | A cuboid, one vertex on the origin, another on a given point
box :: V3 Double -> Solid
box (V3 x y z) = solidFromAcquire $ do
    a <- GP.origin
    b <- GP.Pnt.new x y z
    builder <- MakeBox.fromPnts a b
    Inheritance.upcast <$> MakeBox.solid builder
    
-- | A sphere with radius of 1, centered on the origin
unitSphere :: Solid
unitSphere = solidFromAcquire $ Inheritance.upcast <$> MakeSphere.fromRadius 1

-- | A cylinder with radius 1, length 1,
-- one of it's circular faces centered on the origin,
-- the other centered on \( (0, 0, 1) \)
unitCylinder :: Solid
unitCylinder = solidFromAcquire $ Inheritance.upcast <$> MakeCylinder.fromRadiusAndHeight 1 1

-- | A cylinder with radius 1, length 1,
-- centered on the origin,
centeredCylinder :: Solid
centeredCylinder = translate (unit _z ^* (-0.5)) $ unitCylinder

-- | A cone 
-- With a point at the origin 
-- and a circular face with Radius 1, centered on \( (0, 0, 1) \)
unitCone :: Solid
unitCone = solidFromAcquire $ Inheritance.upcast <$> MakeCone.fromTwoRadiiAndHeight 0 1 1

-- | Extruded a 2D face into a prism with a given length \(len\).
--
-- One of the prisms faces lies on the plane \(z = 0\),
-- the other on the plane \(z = len\).
prism :: Double -> TwoD.Shape.Shape -> Solid
prism len face = solidFromAcquire $ do
    p <- toAcquire . rawShape $ face
    v <- GP.Vec.new 0 0 len
    MakePrism.fromVec p v True True



