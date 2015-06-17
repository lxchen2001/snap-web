{-# LANGUAGE ExtendedDefaultRules #-}
{-# LANGUAGE OverloadedStrings    #-}

module Controllers.Home where

import           Application
import Data.Monoid (mappend)
import           Data.ByteString    (ByteString)
import qualified Heist.Interpreted  as I
import           Snap.Core
import           Snap.Snaplet
import           Snap.Snaplet.Heist

import           Models.Topic       (findAllTopic)
import           Views.TopicSplices
import           Views.Utils

------------------------------------------------------------------------------

-- | Renders the front page of the sample site.
--
index :: Handler App App ()
index = ifTop $ do
    page <- decodedParamNum "p"
    topics <- findAllTopic
    let splices = I.bindSplices $ topicSplices topics page `mappend` subTitleSplice Nothing
    heistLocal splices $ render "index"

redirectToHome :: Handler App App ()
redirectToHome = redirect303 "/"

redirect303 :: ByteString -> Handler App App ()
redirect303 url = redirect' url 303
