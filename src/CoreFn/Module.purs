module CoreFn.Module
  ( Module(..)
  , readModuleJSON
  ) where

import Prelude
import Data.Foreign.Keys as K
import Data.Array as Array
import Control.Error.Util (exceptNoteA)
import Control.Monad.Except.Trans (ExceptT)
import CoreFn.Ident (Ident)
import CoreFn.Names (ModuleName(..))
import Data.Foreign (F, Foreign, ForeignError(..), parseJSON)
import Data.Foreign.Class (readProp)
import Data.Foreign.Index (prop)
import Data.Generic (gShow, class Generic)
import Data.Identity (Identity(..))
import Data.List.NonEmpty (singleton)
import Data.List.Types (NonEmptyList)

-- |
-- The CoreFn module representation
--
data Module = Module
  { moduleExports :: Array Ident
  , moduleForeign :: Array Ident
  , moduleImports :: Array ModuleName
  , moduleName :: ModuleName
  }

derive instance eqModule :: Eq Module
derive instance genericModule :: Generic Module
derive instance ordModule :: Ord Module

instance showModule :: Show Module where
  show = gShow

readModule :: Foreign -> F Module
readModule x = do
  keys <- K.keys x
  key <- head keys
  value <- prop key x
  moduleExports <- readProp "exports" value
  moduleForeign <- readProp "foreign" value
  moduleImports <- readProp "imports" value
  let moduleName = ModuleName key

  pure $ Module
    { moduleExports: moduleExports
    , moduleForeign: moduleForeign
    , moduleImports: moduleImports
    , moduleName: moduleName
    }

  where

  head :: forall a. Array a -> ExceptT (NonEmptyList ForeignError) Identity a
  head y = exceptNoteA ((Identity <<< Array.head) y)
                        (singleton (ForeignError "Module name not found"))

readModuleJSON :: String -> F Module
readModuleJSON json = parseJSON json >>= readModule
