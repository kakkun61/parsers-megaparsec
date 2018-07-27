-- |
-- A newtype wrapper for 'Parsec.ParsecT' that has instances of 'Parsing', 'CharParsing',
-- 'LookAheadParsing', and 'TokenParsing'.
--
-- 'Parsing' and 'LookAheadParsing' have instances for any 'Stream' instance.
--
-- 'CharParsing' and 'TokenParsing' only have instances for 'String', strict 'Text.Text',
-- and lazy 'Lazy.Text', because those type classes expect the 'Token' type to be 'Char'

{-# language GeneralizedNewtypeDeriving #-}
{-# language FlexibleInstances #-}
module Text.Megaparsec.Parsers where

import Control.Applicative (Alternative)
import Control.Monad (MonadPlus)
import Control.Monad.Cont.Class (MonadCont)
import Control.Monad.Error.Class (MonadError)
import Control.Monad.Fail (MonadFail)
import Control.Monad.IO.Class (MonadIO)
import Control.Monad.Reader.Class (MonadReader)
import Control.Monad.State.Class (MonadState)
import Control.Monad.Trans (MonadTrans)
import Data.Monoid (Monoid)
import Data.Semigroup (Semigroup)
import Data.String (fromString)
import Text.Megaparsec (MonadParsec, Stream, Token)
import Text.Parser.Combinators (Parsing(..))
import Text.Parser.Char (CharParsing(..))
import Text.Parser.LookAhead (LookAheadParsing(..))
import Text.Parser.Token (TokenParsing(..))

import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Text as Text
import qualified Data.Text.Lazy as Lazy
import qualified Text.Megaparsec as Parsec
import qualified Text.Megaparsec.Char as Parsec

newtype ParsecT e s m a
  = ParsecT { unParsecT :: Parsec.ParsecT e s m a }
  deriving
    ( Functor, Applicative, Alternative, Monad, MonadPlus
    , MonadParsec e s, MonadError e', MonadReader r, MonadState st
    , MonadTrans, MonadFail, MonadIO, MonadCont, Semigroup, Monoid
    )

-- | Note: 'unexpected' requires a non-empty string
instance (Ord e, Stream s) => Parsing (ParsecT e s m) where
  try = Parsec.try
  (<?>) = (Parsec.<?>)
  notFollowedBy = Parsec.notFollowedBy
  eof = Parsec.eof
  unexpected = Parsec.unexpected . Parsec.Label . NonEmpty.fromList

instance Ord e => CharParsing (ParsecT e String m) where
  satisfy = Parsec.satisfy
  char = Parsec.char
  notChar = Parsec.notChar
  anyChar = Parsec.anyChar
  string = Parsec.string
  text = fmap Text.pack . string . Text.unpack

-- | Lazy 'Lazy.Text'
instance Ord e => CharParsing (ParsecT e Lazy.Text m) where
  satisfy = Parsec.satisfy
  char = Parsec.char
  notChar = Parsec.notChar
  anyChar = Parsec.anyChar
  string = fmap Lazy.unpack . Parsec.string . Lazy.pack
  text = fmap Lazy.toStrict . Parsec.string . Lazy.fromStrict

-- | Strict 'Text.Text'
instance Ord e => CharParsing (ParsecT e Text.Text m) where
  satisfy = Parsec.satisfy
  char = Parsec.char
  notChar = Parsec.notChar
  anyChar = Parsec.anyChar
  string = fmap Text.unpack . Parsec.string . Text.pack
  text = Parsec.string

instance (Ord e, Stream s) => LookAheadParsing (ParsecT e s m) where
  lookAhead = Parsec.lookAhead

instance Ord e => TokenParsing (ParsecT e String m)
-- | Lazy 'Lazy.Text'
instance Ord e => TokenParsing (ParsecT e Text.Text m)
-- | Strict 'Text.Text'
instance Ord e => TokenParsing (ParsecT e Lazy.Text m)