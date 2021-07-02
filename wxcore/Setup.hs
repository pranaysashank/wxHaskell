
{-# LANGUAGE CPP #-}

import qualified Control.Exception as E
import Control.Monad (when, filterM)
import Data.List (foldl', intersperse, intercalate, nub, lookup, isPrefixOf, isInfixOf, find)
import Data.Maybe (fromJust)
import Distribution.PackageDescription hiding (includeDirs)
import qualified Distribution.PackageDescription as PD (includeDirs)
import Distribution.InstalledPackageInfo(installedUnitId, sourcePackageId, libraryDirs)
import Distribution.Simple
import Distribution.Simple.LocalBuildInfo (LocalBuildInfo, localPkgDescr, installedPkgs, withPrograms, buildDir, installDirTemplates)
import Distribution.Simple.PackageIndex(SearchResult (..), searchByName, allPackages )
import Distribution.Simple.Program (ConfiguredProgram (..), lookupProgram, runProgram, simpleProgram, locationPath)
import Distribution.Simple.Program.Types
import Distribution.Simple.Setup (ConfigFlags, BuildFlags)
import Distribution.System (OS (..), Arch (..), buildOS, buildArch)
import Distribution.Types.BuildInfo (includeDirs)
import Distribution.Verbosity (normal, verbose)
import System.Process (system)
import System.Directory (createDirectoryIfMissing, doesFileExist, getCurrentDirectory, getModificationTime)
import System.Environment (getEnv)
import System.FilePath ((</>), (<.>), replaceExtension, takeFileName, dropFileName, addExtension, takeDirectory)
import System.IO.Unsafe (unsafePerformIO)
import System.Process (readProcess)

import Distribution.Simple.Utils (dieNoVerbosity)

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

main :: IO ()
main = defaultMainWithHooks simpleUserHooks { confHook = myConfHook }

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

wxcoreDirectory  :: FilePath
wxcoreDirectory  = "src" </> "haskell" </> "Graphics" </> "UI" </> "WXCore"

wxcoreDirectoryQuoted  :: FilePath
wxcoreDirectoryQuoted  = "\"" ++ wxcoreDirectory ++ "\""

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

getWxcHeaderDir :: BuildInfo -> IO FilePath
getWxcHeaderDir lbi = do
    wxcHeaderDirs <- filterM (doesFileExist . (</> "wxc/wxc.h")) (includeDirs lbi)
    case wxcHeaderDirs of
      [wxcHeaderDir] -> return (wxcHeaderDir </> "wxc")
      [] -> error "getWxcHeaderDir: couldn't find wxc include directory."
      _  -> error "getWxcHeaderDir: I'm confused. I see more than one wxc include directory from the same package."

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Comment out type signature because of a Cabal API change from 1.6 to 1.7
myConfHook (pkg0, pbi) flags = do
    createDirectoryIfMissing True wxcoreDirectory

#if defined(freebsd_HOST_OS) || defined (netbsd_HOST_OS)
    -- Find GL/glx.h include path using pkg-config
    glIncludeDirs <- readProcess "pkg-config" ["--cflags", "gl"] "" `E.onException` return ""
#else
    let glIncludeDirs = ""
#endif

    lbi <- confHook simpleUserHooks (pkg0, pbi) flags
    wxcDirectory <- getWxcHeaderDir $ libBuildInfo $ fromJust (library (localPkgDescr lbi))
    let wxcoreIncludeFile  = "\"" ++ wxcDirectory </> "wxc.h\""
    let wxcDirectoryQuoted = "\"" ++ wxcDirectory ++ "\""
    let system' command    = putStrLn command >> system command
--    wxdirectExe <- getwxdirectExe lbi

    putStrLn "Generating class type definitions from .h files"
    system' $ "wxdirect -t --wxc " ++ wxcDirectoryQuoted ++ " -o " ++ wxcoreDirectoryQuoted ++ " " ++ wxcoreIncludeFile

    putStrLn "Generating class info definitions"
    system' $ "wxdirect -i --wxc " ++ wxcDirectoryQuoted ++ " -o " ++ wxcoreDirectoryQuoted ++ " " ++ wxcoreIncludeFile

    putStrLn "Generating class method definitions from .h files"
    system' $ "wxdirect -c --wxc " ++ wxcDirectoryQuoted ++ " -o " ++ wxcoreDirectoryQuoted ++ " " ++ wxcoreIncludeFile

    let lpd       = localPkgDescr lbi
    let lib       = fromJust (library lpd)
    let libbi     = libBuildInfo lib
    let custom_bi = customFieldsBI libbi

    let libbi' = libbi
--          { ldOptions      = ldOptions      libbi ++ ["-Wl,-rpath," ++ wxcDirectory]          }

    let lib' = lib { libBuildInfo = libbi' }
    let lpd' = lpd { library = Just lib' }

    return $ lbi { localPkgDescr = lpd' }
