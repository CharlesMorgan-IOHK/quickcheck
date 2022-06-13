{-# LANGUAGE ApplicativeDo     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE StrictData        #-}

module Plutus.Script.Evaluation.Test.Options (
    Options (..),
    parseOptions,
    parserInfo,
) where

import Data.Text (Text)
import GHC.Conc (numCapabilities)
import Options.Applicative qualified as O

data Options = Options
    { optsS3Endpoint        :: Text
    , optsS3AccessKeyId     :: Text
    , optsS3SecretAccessKey :: Text
    , optsS3Region          :: Text
    , optsS3Bucket          :: Text
    , optsS3Prefix          :: Text
    , optsEventFilePattern  :: Text
    , optsConcurrency       :: Int
    }

parseOptions :: O.Parser Options
parseOptions = do
    optsS3Endpoint <-
        O.option O.str $
            mconcat
                [ O.long "s3-endpoint"
                , O.value "https://s3.devx.iog.io"
                , O.metavar "S3_ENDPOINT"
                ]
    optsS3AccessKeyId <-
        O.option O.str $
            mconcat
                [ O.long "s3-access-key-id"
                , O.value "plutus"
                , O.metavar "S3_ACCESS_KEY_ID"
                ]
    optsS3SecretAccessKey <-
        O.option O.str $
            mconcat
                [ O.long "s3-secret-access-key"
                , O.value "plutuskey"
                , O.metavar "S3_SECRET_ACCESS_KEY"
                ]
    optsS3Region <-
        O.option O.str $
            mconcat
                [ O.long "s3-region"
                , O.value "us-east-1"
                , O.metavar "S3_REGION"
                ]
    optsS3Bucket <-
        O.option O.str $
            mconcat
                [ O.long "s3-bucket"
                , O.value "plutus"
                , O.metavar "S3_BUCKET"
                ]
    optsS3Prefix <-
        O.option O.str $
            mconcat
                [ O.long "s3-prefix"
                , O.value "script-evaluation-dump/"
                , O.metavar "S3_PREFIX"
                ]
    optsEventFilePattern <-
        O.option O.str $
            mconcat
                [ O.long "s3-event-file-pattern"
                , O.value "*.event"
                , O.metavar "S3_EVENT_FILE_PATTERN"
                ]
    optsConcurrency <-
        O.option O.auto $
            mconcat
                [ O.long "concurrency"
                , O.value numCapabilities
                , O.metavar "CONCURRENCY"
                , O.help "How many threads to use"
                ]
    pure Options{..}

parserInfo :: O.ParserInfo Options
parserInfo =
    O.info
        (parseOptions O.<**> O.helper)
        (O.fullDesc <> O.header "Run script evaluation regression test")
