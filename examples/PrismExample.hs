module PrismExample
( prismExample
) where 

import qualified Waterfall.Solids as Solids
import qualified Waterfall.TwoD.Path as Path
import Linear.V3
import Linear.V2
import Linear.Vector 
import Data.Function ((&))

prismExample :: Solids.Solid
prismExample = Solids.prism (V3 0 0 1) $ 
    Path.pathFrom (V2 (-1) (-1)) 
        [ Path.arcTo (V2 (-1.5) 0) (V2 (-1) 1)
        , Path.lineTo (V2 1 1)
        , Path.bezierTo (V2 1.5 1) (V2 1.5 (-1)) (V2 1 (-1))
        , Path.lineTo (V2 (-1) (-1))
        ]