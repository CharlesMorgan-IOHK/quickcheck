{-# LANGUAGE OverloadedStrings #-}

{- | Plutus conformance test suite library. -}
module Common where

import Control.Exception (SomeException, evaluate, try)
import Data.Text qualified as T
import Data.Text.IO qualified as T
import PlutusCore.Core (defaultVersion)
import PlutusCore.Default (DefaultFun, DefaultUni)
import PlutusCore.Error (ParserErrorBundle (ParseErrorB))
import PlutusCore.Evaluation.Machine.ExBudgetingDefaults (defaultCekParameters)
import PlutusCore.Evaluation.Result (EvaluationResult (..))
import PlutusCore.Name (Name)
import PlutusCore.Quote (runQuoteT)
import PlutusPrelude
import Test.Tasty (TestTree, defaultMain, testGroup)
import Test.Tasty.Golden (findByExtension)
import Test.Tasty.HUnit (testCase, (@=?))
import Text.Megaparsec (SourcePos)
import UntypedPlutusCore.Core.Type qualified as UPLC
import UntypedPlutusCore.Evaluation.Machine.Cek (unsafeEvaluateCekNoEmit)
import UntypedPlutusCore.Parser qualified as UPLC

-- | A TestContent contains what you need to run a test.
data TestContent =
   MkTestContent {
       -- | The path of the input file. This is also used to name the test.
       testName    :: FilePath
       -- | The expected output of the test in `Text`.
       , expected  :: T.Text
       -- | The input to be tested, in `Text`.
       , inputProg :: T.Text
   }

{- | Create a list of `TestContent` with the given lists.
The lengths of the input lists have to be the same, otherwise, an error occurs. -}
mkTestContents ::
    -- | The list of paths of the input files.
    [FilePath] ->
        -- | The list of expected outputs.
        [T.Text] ->
            -- | The list of the inputs.
            [T.Text] ->
                [TestContent]
mkTestContents lFilepaths lRes lProgs =
    case zipWith3Exact (\f r p -> MkTestContent f r p) lFilepaths lRes lProgs of
        Just tests -> tests
        Nothing -> error $ unlines
            ["mkTestContents: Cannot run the tests because the number of input and output programs are not the same. "
            , "Number of input files: "
            , show (length lProgs)
            , " Number of output files: "
            , show (length lRes)
            , " Make sure all your input programs have an accompanying .expected file."
            ]

-- | The default shown text when a parse error occurs.
shownParseError :: T.Text
shownParseError = "parse error"

-- | The default shown text when evaluation fails.
shownEvaluationFailure :: T.Text
shownEvaluationFailure = "evaluation failure"

-- For UPLC evaluation tests

type UplcProg = UPLC.Program Name DefaultUni DefaultFun ()

termToProg :: UPLC.Term Name DefaultUni DefaultFun () -> UplcProg
termToProg = UPLC.Program () (defaultVersion ())

{- using the unsafe version of evaluate here so that it has a more generic signature.
Any exceptions will be caught for any input runner in the tests, including our `evalUplcProg`.
 -}
evalUplcProg :: UplcProg -> EvaluationResult UplcProg
evalUplcProg p =
    fmap
        termToProg
        (unsafeEvaluateCekNoEmit defaultCekParameters (UPLC._progTerm p))

{- | Run the inputs with the runner and return the results, in `Text`.
When fail, the results are the default texts for parse error or evaluation failure. -}
mkResult ::
    -- | The `runner` to run the test inputs with.
    (UplcProg -> EvaluationResult UplcProg) ->
    -- | The result of parsing.
    Either ParserErrorBundle (UPLC.Program Name DefaultUni DefaultFun SourcePos) ->
    -- | The result in `Text`.
        IO T.Text
mkResult _ (Left (ParseErrorB _err)) = pure shownParseError
mkResult runner (Right prog)        = do
    maybeException <- try (evaluate $ runner (() <$ prog)):: IO (Either SomeException (EvaluationResult UplcProg))
    case maybeException of
        Left _                  -> pure shownEvaluationFailure
        -- it doesn't matter how the evaluation fail, they're all "evaluation failure"
        Right EvaluationFailure -> pure shownEvaluationFailure
        Right a                 -> pure $ render $ pretty a

-- | The default parser to parse the inputs.
parseTxt :: T.Text -> Either ParserErrorBundle (UPLC.Program
              Name DefaultUni DefaultFun SourcePos)
parseTxt resTxt = runQuoteT $ UPLC.parseProgram resTxt

-- | Build the test tree given a list of `TestContent` and the runner.
-- TODO maybe abstract this for other tests too if it takes in `mkResult` and `runner`.
mkTestCases :: [TestContent] -> (UplcProg -> EvaluationResult UplcProg) -> IO TestTree
mkTestCases lTest runner = do
    results <- for lTest (mkResult runner . parseTxt . inputProg)
    -- make everything (name, assertion) all at once to make sure pairings are correct
    let maybeNameAssertion =
            zipWithExact (\t res -> (testName t, expected t @=? res)) lTest results
    testContents <- case maybeNameAssertion of
        Just lNameAssertion -> pure $
            fmap (\a -> uncurry testCase a) lNameAssertion
        Nothing -> error "mkTestCases: Number of tests and results don't match."
    pure $ testGroup "UPLC evaluation tests" testContents

-- | Run the tests given a `runner`.
runTests ::
    -- | The action to run the input through for the tests.
    (UplcProg -> EvaluationResult UplcProg) ->
        IO ()
runTests runner = do
    inputFiles <- findByExtension [".uplc"] "uplc/evaluation/"
    outputFiles <- findByExtension [".expected"] "uplc/evaluation/"
    lProgTxt <- for inputFiles T.readFile
    lEvaluatedRes <- for outputFiles T.readFile
    if length inputFiles == length lProgTxt && length lEvaluatedRes == length lProgTxt then
        do
        let testContents = mkTestContents inputFiles lEvaluatedRes lProgTxt
        testTree <- mkTestCases testContents runner
        defaultMain testTree
    else
        error $ unlines
            ["Cannot run the tests because the number of input and output programs are not the same. "
            , "Number of input files: "
            , show (length lProgTxt)
            , " Number of output files: "
            , show (length lEvaluatedRes)
            , " Make sure all your input programs have an accompanying .expected file."
            ]
