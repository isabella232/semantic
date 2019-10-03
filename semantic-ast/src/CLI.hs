{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE TypeApplications #-}
module CLI (main) where

import System.Environment
import TreeSitter.Unmarshal
import TreeSitter.Python.AST
import TreeSitter.Python
import Source.Range
import Source.Span
import Data.ByteString (readFile, ByteString)
import System.IO (FilePath)
import Options.Applicative hiding (style)
import Data.Semigroup ((<>))

main :: IO ()
main = generateAST =<< execParser opts

opts :: ParserInfo SemanticAST
opts = info (parseAST <**> helper)
  ( fullDesc
 <> progDesc "Read a file, output an AST"
 <> header "semantic-ast - generates ASTs" )

generateAST :: SemanticAST -> IO ()
generateAST (SemanticAST file _) = do
 bytestring <- Data.ByteString.readFile file
 print =<< parseByteString @TreeSitter.Python.AST.Module @(Range, Span) tree_sitter_python bytestring
-- TODO: Define formats for json, sexpression, etc.
data Format = Show

data SemanticAST = SemanticAST
  { sourceFilePath :: Prelude.String
  , format         :: Prelude.String
  }

parseAST :: Parser SemanticAST
parseAST = SemanticAST
    <$> strOption
        ( long "semantic-ast"
       <> metavar "FILEPATH"
       <> help "Specify filepath containing source code to parse" )
    <*> strOption
        ( long "format"
       <> help "Specify one these formats: -json -sexpression -show" )

data Input
  = FileInput FilePath
  | StdInput

input :: Parser Input
input = fileInput <|> stdInput

-- pass in a file as an argument and parse its contents
fileInput :: Parser Input
fileInput = FileInput <$> strOption
  (  long "file"
  <> short 'f'
  <> metavar "FILENAME"
  <> help "Input file" )

-- cat something in
stdInput :: Parser Input
stdInput = flag' StdInput
  (  long "stdin"
  <> help "Read from stdin" )
