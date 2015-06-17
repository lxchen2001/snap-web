{-# LANGUAGE ExtendedDefaultRules #-}
{-# LANGUAGE OverloadedStrings    #-}

module Views.TagSplices where

import           Application
import           Control.Monad.Trans
import           Data.Bson           (ObjectId)
import           Data.Maybe          (fromMaybe)
import qualified Data.Text           as T
import           Heist
import qualified Heist.Interpreted   as I
import           Models.Tag
import           Models.Utils

------------------------------------------------------------------------------

-- | Splice of listing multiple tags
--
topicTagSplice :: Maybe [ObjectId] -> I.Splice AppHandler
topicTagSplice ids =
    lift (findSomeTags $ fromMaybe [] ids)
    >>= tagsSplice

tagSplice :: Tag -> I.Splice AppHandler
tagSplice = I.runChildrenWithText . tagSpliceImpl


tagSpliceImpl :: Tag -> Splices T.Text
tagSpliceImpl (Tag tid name _) = do
  "tagId" ## objectIdToText tid
  "tagName" ## name

tagsSplice :: [Tag] -> I.Splice AppHandler
tagsSplice = I.mapSplices tagSplice
