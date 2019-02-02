{-#LANGUAGE OverloadedStrings#-}
{-#LANGUAGE DeriveFunctor#-}
{-#LANGUAGE GeneralizedNewtypeDeriving#-}
{-#LANGUAGE BangPatterns#-}
{-#LANGUAGE ScopedTypeVariables#-}

module Faker.Name where

import Data.Yaml
import Faker
import Config
import Data.Vector (Vector, (!))
import qualified Data.Vector as V
import Data.Map.Strict (Map)
import Control.Monad.Catch
import Data.Text
import System.Directory (doesFileExist)
import System.FilePath
import Control.Monad.IO.Class
import qualified Data.Text as T
import System.Random
import Debug.Trace

parseName :: FromJSON a => FakerSettings -> Value -> Parser a
parseName settings (Object obj) = do
  en <- obj .: (getLocale settings)
  faker <- en .: "faker"
  name <- faker .: "name"
  pure name
parseName settings val = fail $ "expected Object, but got " <> (show val)

parseNameField :: FromJSON a => FakerSettings -> Text -> Value -> Parser a
parseNameField settings txt val = do
  name <- parseName settings val
  field <- name .: txt
  pure field

parseUnresolvedNameField :: FromJSON a => FakerSettings -> Text -> Value -> Parser (Unresolved a)
parseUnresolvedNameField settings txt val = do
  name <- parseName settings val
  field <- name .: txt
  pure $ pure field

parseMaleFirstName :: FromJSON a => FakerSettings -> Value -> Parser a
parseMaleFirstName settings = parseNameField settings "male_first_name"

parseFemaleFirstName :: FromJSON a => FakerSettings -> Value -> Parser a
parseFemaleFirstName settings = parseNameField settings "female_first_name"

parseFirstName :: FromJSON a => FakerSettings -> Value -> Parser (Unresolved a)
parseFirstName settings = parseUnresolvedNameField settings  "first_name"

parseLastName :: FromJSON a => FakerSettings -> Value -> Parser a
parseLastName settings = parseNameField settings "last_name"

parsePrefix :: FromJSON a => FakerSettings -> Value -> Parser a
parsePrefix settings = parseNameField settings "prefix"

parseSuffix :: FromJSON a => FakerSettings -> Value -> Parser a
parseSuffix settings = parseNameField settings "suffix"

parseFieldName :: FromJSON a => FakerSettings -> Value -> Parser (Unresolved a)
parseFieldName settings = parseUnresolvedNameField settings  "name"

parseNameWithMiddle :: FromJSON a => FakerSettings -> Value -> Parser (Unresolved a)
parseNameWithMiddle settings = parseUnresolvedNameField settings "name_with_middle"

maleFirstNameProvider :: (MonadThrow m, MonadIO m) => FakerSettings -> m (Vector Text)
maleFirstNameProvider settings = fetchData settings Name parseMaleFirstName

femaleFirstNameProvider :: (MonadThrow m, MonadIO m) => FakerSettings -> m (Vector Text)
femaleFirstNameProvider settings = fetchData settings Name parseFemaleFirstName

firstNameProvider :: (MonadThrow m, MonadIO m) => FakerSettings -> m (Unresolved (Vector Text))
firstNameProvider settings = fetchData settings Name parseFirstName

lastNameProvider :: (MonadThrow m, MonadIO m) => FakerSettings -> m (Vector Text)
lastNameProvider settings = fetchData settings Name parseLastName

prefixProvider :: (MonadThrow m, MonadIO m) => FakerSettings -> m (Vector Text)
prefixProvider settings = fetchData settings Name parsePrefix

suffixProvider :: (MonadThrow m, MonadIO m) => FakerSettings -> m (Vector Text)
suffixProvider settings = fetchData settings Name parseSuffix

nameProvider :: (MonadThrow m, MonadIO m) => FakerSettings -> m (Unresolved (Vector Text))
nameProvider settings = fetchData settings Name parseFieldName

nameWithMiddleProvider :: (MonadThrow m, MonadIO m) => FakerSettings -> m (Unresolved (Vector Text))
nameWithMiddleProvider settings = fetchData settings Name parseNameWithMiddle


resolveNameText :: (MonadIO m, MonadThrow m) => FakerSettings -> Text -> m Text
resolveNameText settings txt = do
  let fields = resolveFields txt
  nameFields <- mapM (resolveNameField settings) fields
  pure $ operateFields txt nameFields

resolveNameField :: (MonadThrow m, MonadIO m) => FakerSettings -> Text -> m Text
resolveNameField settings "female_first_name" = randomVec settings femaleFirstNameProvider
resolveNameField settings "male_first_name" = randomVec settings maleFirstNameProvider
resolveNameField settings "prefix" = randomVec settings prefixProvider
resolveNameField settings "suffix" = randomVec settings suffixProvider
resolveNameField settings "first_name" = randomUnresolvedVec settings firstNameProvider resolveNameText
resolveNameField settings "last_name" = randomVec settings lastNameProvider
resolveNameField settings str = throwM $ InvalidField "name" str

maleFirstName :: Fake Text
maleFirstName = Fake (\settings -> randomVec settings maleFirstNameProvider)

femaleFirstName :: Fake Text
femaleFirstName = Fake (\settings -> randomVec settings femaleFirstNameProvider)

prefix :: Fake Text
prefix = Fake (\settings -> randomVec settings prefixProvider)

suffix :: Fake Text
suffix = Fake (\settings -> randomVec settings suffixProvider)

name :: Fake Text
name = Fake (\settings -> randomUnresolvedVec settings nameProvider resolveNameText)

nameWithMiddle :: Fake Text
nameWithMiddle = Fake (\settings -> randomUnresolvedVec settings nameWithMiddleProvider resolveNameText)