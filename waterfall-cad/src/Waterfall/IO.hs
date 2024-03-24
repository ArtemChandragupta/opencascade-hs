module Waterfall.IO
( ReadError (..)
, writeSTL
, writeSTEP
, writeGLTF
, writeGLB
, writeOBJ
, readSTL
, readSTEP
, readGLTF
, readGLB
, readOBJ
) where 

import Waterfall.Internal.Solid (Solid(..))
import qualified Waterfall.Internal.Remesh as Remesh
import qualified OpenCascade.BRepMesh.IncrementalMesh as BRepMesh.IncrementalMesh
import qualified OpenCascade.StlAPI.Writer as StlWriter
import qualified OpenCascade.StlAPI.Reader as StlReader
import qualified OpenCascade.STEPControl.Writer as StepWriter
import qualified OpenCascade.STEPControl.StepModelType as StepModelType
import qualified OpenCascade.STEPControl.Reader as STEPReader
import qualified OpenCascade.XSControl.Reader as XSControl.Reader
import qualified OpenCascade.IFSelect.ReturnStatus as IFSelect.ReturnStatus
import qualified OpenCascade.TDocStd.Document as TDocStd.Document
import qualified OpenCascade.Message.Types as Message
import qualified OpenCascade.Message.ProgressRange as Message.ProgressRange
import qualified OpenCascade.TColStd.IndexedDataMapOfStringString as TColStd.IndexedDataMapOfStringString
import qualified OpenCascade.RWGltf.CafWriter as RWGltf.CafWriter
import qualified OpenCascade.RWGltf.CafReader as RWGltf.CafReader
import qualified OpenCascade.RWObj.CafWriter as RWObj.CafWriter
import qualified OpenCascade.RWObj.CafReader as RWObj.CafReader
import qualified OpenCascade.RWMesh.Types as RWMesh
import qualified OpenCascade.RWMesh.CafReader as RWMesh.CafReader
import qualified OpenCascade.TDocStd.Types as TDocStd
import qualified OpenCascade.TColStd.Types as TColStd
import qualified OpenCascade.XCAFDoc.DocumentTool as XCafDoc.DocumentTool
import qualified OpenCascade.XCAFDoc.ShapeTool as XCafDoc.ShapeTool
import qualified OpenCascade.TopoDS.Types as TopoDS
import qualified OpenCascade.TopoDS.Shape as TopoDS.Shape
import qualified OpenCascade.TopExp.Explorer as TopExp.Explorer
import qualified OpenCascade.TopAbs.ShapeEnum as ShapeEnum
import qualified OpenCascade.BRepBuilderAPI.MakeSolid as MakeSolid
import OpenCascade.Handle (Handle)
import OpenCascade.Inheritance (upcast, unsafeDowncast)
import Control.Monad.IO.Class (MonadIO, liftIO)
import Control.Monad (void, unless, when)
import System.IO (hPutStrLn, stderr)
import Waterfall.Internal.Finalizers (toAcquire, fromAcquire)
import Data.Acquire
import Foreign.Ptr (Ptr)

-- | Write a `Solid` to a (binary) STL file at a given path
--
-- Because BRep representations of objects can store arbitrary precision curves,
-- but STL files store triangulated surfaces, 
-- this function takes a "deflection" argument used to discretize curves.
--
-- The deflection is the maximum allowable distance between a curve and the generated triangulation.
writeSTL :: Double -> FilePath -> Solid -> IO ()
writeSTL linDeflection filepath (Solid ptr) = (`withAcquire` pure) $ do
    s <- toAcquire ptr
    mesh <- BRepMesh.IncrementalMesh.fromShapeAndLinDeflection s linDeflection
    liftIO $ BRepMesh.IncrementalMesh.perform mesh
    writer <- StlWriter.new
    liftIO $ do
            StlWriter.setAsciiMode writer False
            res <- StlWriter.write writer s filepath
            unless res (hPutStrLn stderr ("failed to write " <> filepath))
    return ()

-- | Write a `Solid` to a STEP file at a given path
--
-- STEP files can be imported by [FreeCAD](https://www.freecad.org/)
writeSTEP :: FilePath -> Solid -> IO ()
writeSTEP filepath (Solid ptr) = (`withAcquire` pure) $ do
    s <- toAcquire ptr
    writer <- StepWriter.new
    _ <- liftIO $ StepWriter.transfer writer s StepModelType.Asls True
    void . liftIO $ StepWriter.write writer filepath

cafWriter :: (FilePath -> Ptr (Handle TDocStd.Document) -> Ptr TColStd.IndexedDataMapOfStringString -> Ptr Message.ProgressRange -> Acquire ()) -> Double -> FilePath -> Solid-> IO ()
cafWriter write linDeflection filepath (Solid ptr) = (`withAcquire` pure) $ do
    s <- toAcquire ptr
    mesh <- BRepMesh.IncrementalMesh.fromShapeAndLinDeflection s linDeflection
    liftIO $ BRepMesh.IncrementalMesh.perform mesh
    doc <- TDocStd.Document.fromStorageFormat ""
    mainLabel <- TDocStd.Document.main doc
    shapeTool <- XCafDoc.DocumentTool.shapeTool mainLabel
    _ <- XCafDoc.ShapeTool.addShape shapeTool s True True
    meta <- TColStd.IndexedDataMapOfStringString.new
    progress <- Message.ProgressRange.new
    write filepath doc meta progress

writeGLTFOrGLB :: Bool -> Double -> FilePath -> Solid -> IO ()
writeGLTFOrGLB binary =
    let write filepath doc meta progress = do 
            writer <- RWGltf.CafWriter.new filepath binary
            liftIO $ RWGltf.CafWriter.perform writer doc meta progress
    in cafWriter write

-- | Write a `Solid` to a glTF file at a given path
--
-- glTF, or Graphics Library Transmission Format is a JSON based format 
-- used for three-dimensional scenes and models
--
-- Because BRep representations of objects can store arbitrary precision curves,
-- but glTF files store triangulated surfaces, 
-- this function takes a "deflection" argument used to discretize curves.
--
-- The deflection is the maximum allowable distance between a curve and the generated triangulation.
writeGLTF :: Double -> FilePath -> Solid -> IO ()
writeGLTF = writeGLTFOrGLB False

-- | Write a `Solid` to a glb file at a given path
--
-- glb is the binary variant of the glTF file format
--
-- Because BRep representations of objects can store arbitrary precision curves,
-- but glTF files store triangulated surfaces, 
-- this function takes a "deflection" argument used to discretize curves.
--
-- The deflection is the maximum allowable distance between a curve and the generated triangulation.
writeGLB :: Double -> FilePath -> Solid -> IO ()
writeGLB = writeGLTFOrGLB True

-- | Write a `Solid` to an obj file at a given path
--
-- Wavefront OBJ is a simple ascii file format that stores geometric data.
--
-- Because BRep representations of objects can store arbitrary precision curves,
-- but obj files store triangulated surfaces, 
-- this function takes a "deflection" argument used to discretize curves.
--
-- The deflection is the maximum allowable distance between a curve and the generated triangulation.
writeOBJ :: Double -> FilePath -> Solid -> IO ()
writeOBJ = 
    let write filepath doc meta progress = do 
            writer <- RWObj.CafWriter.new filepath
            liftIO $ RWObj.CafWriter.perform writer doc meta progress
    in cafWriter write

data ReadError = FileReadError | NonManifoldError deriving (Eq, Show)

checkNonNull:: MonadIO m => Ptr TopoDS.Shape -> m (Either ReadError (Ptr TopoDS.Shape))
checkNonNull shape = do
    isNull <- liftIO . TopoDS.Shape.isNull $ shape
    return $ if isNull 
        then Left FileReadError
        else Right shape

possibleShellToSolid :: Ptr TopoDS.Shape -> Acquire (Either ReadError (Ptr TopoDS.Shape))
possibleShellToSolid s = do
    explorer <- TopExp.Explorer.new s ShapeEnum.Shell
    makeSolid <- MakeSolid.new
    let go = do
            isMore <- liftIO $ TopExp.Explorer.more explorer
            when isMore $ do
                liftIO $ print "more"
                shell <- liftIO $ unsafeDowncast =<< TopExp.Explorer.value explorer
                liftIO $ MakeSolid.add makeSolid shell
                liftIO $ TopExp.Explorer.next explorer
                go
    go
    Right . upcast <$> MakeSolid.solid makeSolid

-- | Read a `Solid` from an STL file at a given path
readSTL :: FilePath -> IO (Either ReadError Solid)
readSTL filepath = (fmap (fmap Solid)) . fromAcquire $ do
    shape <- TopoDS.Shape.new
    reader <- StlReader.new
    res <- liftIO $ StlReader.read reader shape filepath
    if res 
        then possibleShellToSolid shape
        else return $ Left FileReadError

-- | Read a `Solid` from a STEP file at a given path
--
-- This does far less validation on the returned data than it should
readSTEP :: FilePath -> IO (Either ReadError Solid)
readSTEP filepath = (fmap (fmap Solid)) . fromAcquire $ do
    reader <- STEPReader.new
    status <- liftIO $ XSControl.Reader.readFile (upcast reader) filepath
    _ <- liftIO $ XSControl.Reader.transferRoots (upcast reader)
    shape <- XSControl.Reader.oneShape (upcast reader)
    if status == IFSelect.ReturnStatus.Done
        then checkNonNull shape
        else return . Left $ FileReadError

cafReader :: Acquire (Ptr RWMesh.CafReader) -> FilePath -> IO (Either ReadError Solid)
cafReader mkReader filepath = fmap (fmap Solid) . fromAcquire $ do
    reader <- mkReader
    doc <- TDocStd.Document.fromStorageFormat ""
    progress <- Message.ProgressRange.new
    _ <- liftIO $ RWMesh.CafReader.setDocument reader doc
    res <- liftIO $ RWMesh.CafReader.perform reader filepath progress
    if res 
        then fmap Right . Remesh.remesh =<< RWMesh.CafReader.singleShape reader
        else return . Left $ FileReadError 

-- | Read a `Solid` from a GLTF file at a given path
--
-- This should support reading both the GLTF (json) and GLB (binary) formats
--
-- This does far less validation on the returned data than it should
readGLTF :: FilePath -> IO (Either ReadError Solid)
readGLTF  = cafReader $ do
    reader <- RWGltf.CafReader.new 
    liftIO $ RWGltf.CafReader.setDoublePrecision reader True
    liftIO $ RWMesh.CafReader.setFileLengthUnit (upcast reader) 1
    return (upcast reader)

-- | Alias for `readGLTF`
--
-- This does far less validation on the returned data than it should
readGLB :: FilePath -> IO (Either ReadError Solid)
readGLB = readGLTF

-- | Read a `Solid` from an obj file at a given path
--
-- This should support reading both the GLTF (json) and GLB (binary) formats
--
-- This does far less validation on the returned data than it should
readOBJ :: FilePath -> IO (Either ReadError Solid)
readOBJ  = cafReader $ do
    reader <- RWObj.CafReader.new 
    liftIO $ RWObj.CafReader.setSinglePrecision reader False
    liftIO $ RWMesh.CafReader.setFileLengthUnit (upcast reader) 1
    return (upcast reader)