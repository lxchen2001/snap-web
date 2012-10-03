{-# LANGUAGE ExtendedDefaultRules #-}
{-# LANGUAGE OverloadedStrings    #-}

module Models.Topic where

import           Control.Applicative   ((<$>), (<*>))
import           Control.Monad.CatchIO (throw)
import           Control.Monad.State
import           Data.Baeson.Types
import           Data.Bson
import qualified Data.Bson             as BSON
import qualified Data.Text             as T
import           Data.Time             (UTCTime)
import           Database.MongoDB
import qualified Database.MongoDB      as DB
import           Snap.Snaplet.Auth
import           Snap.Snaplet.MongoDB

import           Application
import           Models.Exception
import           Models.Internal.Types
import           Models.Utils


-- |
--
data Topic = Topic
    { _topicId   :: Maybe ObjectId
    , _title     :: T.Text
    , _content   :: T.Text
    , _author    :: ObjectId
    , _createAt  :: UTCTime
    , _updateAt  :: UTCTime
    , _topicTags :: Maybe [ObjectId]
    } deriving (Show, Eq)

topicCollection :: Collection
topicCollection = u "topics"

getTopicId :: Topic -> T.Text
getTopicId = objectIdToText . _topicId

emptyTopic :: AppHandler Topic
emptyTopic = do
  oid <- liftIO genObjectId
  let t = timestamp oid
  return $ Topic Nothing "" "" oid t t Nothing

--------------------------------------------------------------------------------
-- Impl of Persistent Interface
--------------------------------------------------------------------------------

instance MongoDBPersistent Topic where
  mongoColl _  = topicCollection
  toMongoDoc   = topicToDocument
  fromMongoDoc = topicFromDocumentOrThrow
  mongoInsertId topic v = topic { _topicId = objectIdFromValue v }
  mongoGetId = _topicId

-- | Transform @Topic@ to mongoDB document.
--   Nothing of id mean new topic thus empty "_id" let mongoDB generate objectId.
--
topicToDocument :: Topic -> Document
topicToDocument topic = case _topicId topic of
                          Nothing -> docs
                          Just x  -> ("_id" .= x) : docs
                        where docs =
                                [  "title"   .= _title topic
                                , "content"  .= _content topic
                                , "author"   .= _author topic
                                , "createAt" .= _createAt topic
                                , "updateAt" .= _updateAt topic
                                , "tags"     .= _topicTags topic
                                ]

-- | Transform mongo Document to be a Topic parser.
--
documentToTopic :: Document -> Parser Topic
documentToTopic d = Topic
                    <$> d .: "_id"
                    <*> d .: "title"
                    <*> d .: "content"
                    <*> d .: "author"
                    <*> d .: "createAt"
                    <*> d .: "updateAt"
                    <*> d .: "tags"

-- | parse the topic document
--
topicFromDocumentOrThrow :: Document -> IO Topic
topicFromDocumentOrThrow d = case parseEither documentToTopic d of
    Left e  -> throw $ BackendError $ show e
    Right r -> return r



--------------------------------------------------------------------------------
-- CRUD
--------------------------------------------------------------------------------


-- | create a new topic.
--
createNewTopic ::  Topic -> AppHandler Topic
createNewTopic = mongoInsert


-- | save a new topic.
--
saveTopic :: Topic -> AppHandler Topic
saveTopic = mongoSave


-- | Find One Topic
--
findOneTopic :: ObjectId -> AppHandler Topic
findOneTopic oid = do
  et <- emptyTopic
  mongoFindById $ et { _topicId = Just oid }


-- | Find All Topic.
--
findAllTopic :: AppHandler [Topic]
findAllTopic  = findTopicGeneric []


-- | Find topic per tag.
--
findTopicByTag :: ObjectId                   -- ^ Tag ID
                  -> AppHandler [Topic]
findTopicByTag tagId = findTopicGeneric  [ "tags" =: tagId ]


-- | Even generic find handler
--
findTopicGeneric :: Selector -> AppHandler [Topic]
findTopicGeneric se = do
  et <- emptyTopic
  let topicSelection = select se topicCollection
  mongoFindAllBy et (topicSelection {sort = sortByCreateAtDesc})


sortByCreateAtDesc :: Order
sortByCreateAtDesc = [ "createAt" =: -1 ]

------------------------------------------------------------------------------

