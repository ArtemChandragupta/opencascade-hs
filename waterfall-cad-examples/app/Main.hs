module Main (main) where

import CsgExample (csgExample)
import PrismExample (prismExample)
import GearExample (gearExample)
import FilletExample (filletExample)
import RevolutionExample (revolutionExample)
import SweepExample (sweepExample)
import TextExample (textExample)
import Waterfall.IO (writeSTL, writeSTEP)
import qualified Waterfall.Solids as Solids
import qualified Options.Applicative as OA
import Control.Applicative ((<|>))
import Control.Monad (join)

outputOption :: OA.Parser (Solids.Solid -> IO ()) 
outputOption =
    let stlOption = writeSTL <$> (OA.option OA.auto (OA.long "resolution" <> OA.help "stl file linear tolerance") <|> pure 0.001) <*>
                        OA.strOption (OA.long "stl" <> OA.metavar "Stl file to write results to")
        stepOption = writeSTEP <$> OA.strOption (OA.long "step" <> OA.metavar "Stl file to write results to")
     in stlOption <|> stepOption

exampleOption :: OA.Parser Solids.Solid
exampleOption = OA.flag' csgExample (OA.long "csg" <> OA.help "example from the wikipedia page on Constructive Solid Geometry" ) <|>
                OA.flag' prismExample (OA.long "prism" <> OA.help "need to give this a better name" ) <|>
                OA.flag' filletExample (OA.long "fillet" <> OA.help "demonstrates adding fillets to an object" ) <|>
                OA.flag' revolutionExample (OA.long "revolution" <> OA.help "demonstrates revolving a path into a solid" ) <|>
                OA.flag' sweepExample (OA.long "sweep" <> OA.help "demonstrates sweeping a shape along a path" ) <|>
                (OA.flag' gearExample (OA.long "gear" <> OA.help "generate an involute gear") <*>
                 (OA.option OA.auto (OA.long "thickness" <> OA.help "gear depth") <|> pure 1.0) <*>
                 (OA.option OA.auto (OA.long "module" <> OA.help "gear module") <|> pure 5.0) <*>
                 (OA.option OA.auto (OA.long "nGears" <> OA.help "number of gears") <|> pure 20) <*>
                 (OA.option OA.auto (OA.long "pitch" <> OA.help "pitchAngle") 
                    <|> ((* (pi/180)) <$> OA.option OA.auto (OA.long "pitchDegrees" <> OA.help "pitch angle in degrees"))
                    <|> pure (20*pi/180)) 
                ) <|> 
                (OA.flag' textExample (OA.long "text" <> OA.help "render text") <*>
                 (OA.strOption (OA.long "font" <> OA.help "font path")) <*>
                 (OA.option OA.auto (OA.long "size" <> OA.help "font size") <|> pure 12.0) <*>
                 (OA.strOption (OA.long "content" <> OA.help "text to render") <|> pure "Waterfall CAD") <*>
                 (OA.option OA.auto (OA.long "depth" <> OA.help "depth to extrude the text to") <|> pure 10.0) 
                )


main :: IO ()
main = join (OA.execParser opts)
    where
        opts = OA.info ((outputOption <*> exampleOption) OA.<**> OA.helper) 
            (OA.fullDesc
             <> OA.progDesc "generate and write a 3D model"
             <> OA.header "examples for Waterfall-CAD")
