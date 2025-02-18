{-#LANGUAGE FlexibleContexts, FlexibleInstances, MultiParamTypeClasses #-}
module Carnap.Languages.PurePropositional.Logic.ThomasBolducAndZach
    ( parseThomasBolducAndZachTFLCore, ThomasBolducAndZachTFLCore
    , parseThomasBolducAndZachTFL, ThomasBolducAndZachTFL
    , thomasBolducAndZachTFL2019Calc, thomasBolducAndZachTFLCalc
    , thomasBolducAndZachNotation) where

import Data.Map as M (lookup, Map)
import Text.Parsec
import Carnap.Core.Data.Types (Form)
import Carnap.Languages.PurePropositional.Syntax
import Carnap.Languages.PurePropositional.Parser
import Carnap.Calculi.NaturalDeduction.Syntax
import Carnap.Calculi.NaturalDeduction.Parser
import Carnap.Calculi.NaturalDeduction.Checker
import Carnap.Languages.ClassicalSequent.Syntax
import Carnap.Languages.ClassicalSequent.Parser
import Carnap.Languages.PurePropositional.Logic.Rules

{-| A system for propositional logic resembling the basic proof system TFL
from the Calgary Remix of Forall x book
-}

data ThomasBolducAndZachTFLCore = ConjIntro  | As
                                | ConjElim1  | ConjElim2
                                | DisjIntro1 | DisjIntro2
                                | DisjElim1  | DisjElim2
                                | DisjElim3  | DisjElim4
                                | CondIntro1 | CondIntro2
                                | CondElim
                                | BicoIntro1 | BicoIntro2
                                | BicoIntro3 | BicoIntro4
                                | BicoElim1  | BicoElim2
                                | NegeIntro1 | NegeIntro2
                                | NegeElim   | ContElim 
                                | Indirect1  | Indirect2
                                | Reiterate
                                | Pr (Maybe [(ClassicalSequentOver PurePropLexicon (Sequent (Form Bool)))])
                                deriving (Eq)

data ThomasBolducAndZachTFL = Core ThomasBolducAndZachTFLCore
                            | DisSyllo1  | DisSyllo2
                            | ModTollens | DoubleNeg  
                            | Lem1       | Lem2
                            | Lem3       | Lem4
                            | DeMorgan1  | DeMorgan2
                            | DeMorgan3  | DeMorgan4
                            deriving (Eq)
                            --skipping derived rules for now

instance Show ThomasBolducAndZachTFLCore where
        show ConjIntro  = "∧I"
        show ConjElim1  = "∧E"
        show ConjElim2  = "∧E"
        show NegeIntro1 = "¬I"
        show NegeIntro2 = "¬I"
        show NegeElim   = "¬E"
        show Indirect1  = "IP"
        show Indirect2  = "IP"
        show CondIntro1 = "→I"
        show CondIntro2 = "→I"
        show CondElim   = "→E"
        show ContElim   = "X"
        show DisjElim1  = "∨E"
        show DisjElim2  = "∨E"
        show DisjElim3  = "∨E"
        show DisjElim4  = "∨E"
        show DisjIntro1 = "∨I"
        show DisjIntro2 = "∨I"
        show BicoIntro1 = "↔I"
        show BicoIntro2 = "↔I"
        show BicoIntro3 = "↔I"
        show BicoIntro4 = "↔I"
        show BicoElim1  = "↔E"
        show BicoElim2  = "↔E"
        show Reiterate  = "R"
        show As         = "AS"
        show (Pr _)     = "PR"

instance Show ThomasBolducAndZachTFL where
        show (Core x)   = show x
        show DisSyllo1  = "DS"
        show DisSyllo2  = "DS"
        show ModTollens = "MT"
        show DoubleNeg  = "DNE"
        show Lem1       = "LEM"
        show Lem2       = "LEM"
        show Lem3       = "LEM"
        show Lem4       = "LEM"
        show DeMorgan1  = "DeM"
        show DeMorgan2  = "DeM"
        show DeMorgan3  = "DeM"
        show DeMorgan4  = "DeM"

instance Inference ThomasBolducAndZachTFLCore PurePropLexicon (Form Bool) where
        ruleOf ConjIntro  = adjunction
        ruleOf ConjElim1  = simplificationVariations !! 0
        ruleOf ConjElim2  = simplificationVariations !! 1
        ruleOf NegeIntro1 = explicitConstructiveFalsumReductioVariations !! 0
        ruleOf NegeIntro2 = explicitConstructiveFalsumReductioVariations !! 1
        ruleOf NegeElim   = falsumIntroduction
        ruleOf Indirect1  = explicitNonConstructiveFalsumReductioVariations !! 0
        ruleOf Indirect2  = explicitNonConstructiveFalsumReductioVariations !! 1
        ruleOf CondIntro1 = conditionalProofVariations !! 0
        ruleOf CondIntro2 = conditionalProofVariations !! 1
        ruleOf CondElim   = modusPonens
        ruleOf ContElim   = falsumElimination
        ruleOf DisjIntro1 = additionVariations !! 0
        ruleOf DisjIntro2 = additionVariations !! 1 
        ruleOf DisjElim1  = proofByCasesVariations !! 0
        ruleOf DisjElim2  = proofByCasesVariations !! 1
        ruleOf DisjElim3  = proofByCasesVariations !! 2
        ruleOf DisjElim4  = proofByCasesVariations !! 3
        ruleOf BicoIntro1 = biconditionalProofVariations !! 0
        ruleOf BicoIntro2 = biconditionalProofVariations !! 1
        ruleOf BicoIntro3 = biconditionalProofVariations !! 2
        ruleOf BicoIntro4 = biconditionalProofVariations !! 3
        ruleOf BicoElim1  = biconditionalPonensVariations !! 0
        ruleOf BicoElim2  = biconditionalPonensVariations !! 1
        ruleOf Reiterate  = identityRule
        ruleOf As         = axiom
        ruleOf (Pr _)     = axiom

        indirectInference x
            | x `elem` [ DisjElim1, DisjElim2, DisjElim3, DisjElim4
                       , CondIntro1, CondIntro2 , BicoIntro1, BicoIntro2
                       , BicoIntro3, BicoIntro4] = Just PolyProof
            | x `elem` [ NegeIntro1, NegeIntro2
                       , Indirect1, Indirect2] = Just assumptiveProof
            | otherwise = Nothing

        isAssumption As = True
        isAssumption _  = False

        isPremise (Pr _) = True
        isPremise _  = False

        restriction (Pr prems) = Just (premConstraint prems)
        restriction _ = Nothing

instance Inference ThomasBolducAndZachTFL PurePropLexicon (Form Bool) where
        ruleOf (Core x)   = ruleOf x
        ruleOf DisSyllo1  = modusTollendoPonensVariations !! 0 
        ruleOf DisSyllo2  = modusTollendoPonensVariations !! 1
        ruleOf ModTollens = modusTollens
        ruleOf DoubleNeg  = doubleNegationElimination
        ruleOf Lem1       = tertiumNonDaturVariations !! 0 
        ruleOf Lem2       = tertiumNonDaturVariations !! 1
        ruleOf Lem3       = tertiumNonDaturVariations !! 2
        ruleOf Lem4       = tertiumNonDaturVariations !! 3
        ruleOf DeMorgan1  = deMorgansLaws !! 0
        ruleOf DeMorgan2  = deMorgansLaws !! 1
        ruleOf DeMorgan3  = deMorgansLaws !! 2
        ruleOf DeMorgan4  = deMorgansLaws !! 3

        indirectInference (Core x) = indirectInference x
        indirectInference x
            | x `elem` [Lem1,Lem2,Lem3,Lem4] = Just (PolyTypedProof 2 (ProofType 1 1))
            | otherwise = Nothing

        isAssumption (Core x) = isAssumption x
        isAssumption _  = False

        isPremise (Core x) = isAssumption x
        isPremise _  = False

        restriction (Core x) = restriction x
        restriction _ = Nothing

parseThomasBolducAndZachTFLCore :: RuntimeNaturalDeductionConfig PurePropLexicon (Form Bool) -> Parsec String u [ThomasBolducAndZachTFLCore]
parseThomasBolducAndZachTFLCore rtc = do r <- choice (map (try . string) [ "AS","PR","&I","/\\I", "∧I","&E","/\\E","∧E", "~I","-I", "¬I"
                                                                      , "~E","-E", "¬E","IP","->I", ">I", "=>I", "→I","->E", "=>E", ">E", "→E", "X"
                                                                      , "vI","\\/I", "|I", "∨I", "vE","\\/E", "|E", "∨E","<->I", "↔I","<->E"
                                                                      , "↔E","R"])
                                         case r of
                                            r | r == "AS"   -> return [As]
                                              | r == "PR" -> return [Pr (problemPremises rtc)]
                                              | r `elem` ["&I","/\\I","∧I"] -> return [ConjIntro]
                                              | r `elem` ["&E","/\\E","∧E"] -> return [ConjElim1, ConjElim2]
                                              | r `elem` ["~I","¬I","-I"]   -> return [NegeIntro1, NegeIntro2]
                                              | r `elem` ["~E","¬E","-E"]   -> return [NegeElim]
                                              | r == "IP" -> return [Indirect1, Indirect2]
                                              | r `elem` ["->I", ">I", "=>I", "→I"] -> return [CondIntro1,CondIntro2]
                                              | r `elem` ["->E", ">E", "=>E", "→E"]  -> return [CondElim]
                                              | r == "X"    -> return [ContElim]
                                              | r `elem` ["∨I","vI", "|I", "\\/I"] -> return [DisjIntro1, DisjIntro2]
                                              | r `elem` ["∨E","vE", "|E", "\\/E"] -> return [DisjElim1, DisjElim2, DisjElim3, DisjElim4]
                                              | r `elem` ["<->I","↔I"] -> return [BicoIntro1, BicoIntro2, BicoIntro3, BicoIntro4]
                                              | r `elem` ["<->E","↔E"]   -> return [BicoElim1, BicoElim2]
                                              | r == "R" -> return [Reiterate]

parseThomasBolducAndZachTFL :: RuntimeNaturalDeductionConfig PurePropLexicon (Form Bool) -> Parsec String u [ThomasBolducAndZachTFL]
parseThomasBolducAndZachTFL rtc = try parseExt <|> (map Core <$> parseThomasBolducAndZachTFLCore rtc)
        where parseExt = do r <- choice (map (try . string) ["DS","MT","DNE","LEM","DeM"])
                            case r of
                               r | r == "DS"   -> return [DisSyllo1,DisSyllo2]
                                 | r == "MT"   -> return [ModTollens]
                                 | r == "DNE"  -> return [DoubleNeg]
                                 | r == "LEM"  -> return [Lem1,Lem2,Lem3,Lem4]
                                 | r == "DeM"   -> return [DeMorgan1,DeMorgan2,DeMorgan3,DeMorgan4]

parseThomasBolducAndZachTFLProof :: RuntimeNaturalDeductionConfig PurePropLexicon (Form Bool) -> String -> [DeductionLine ThomasBolducAndZachTFL PurePropLexicon (Form Bool)]
parseThomasBolducAndZachTFLProof rtc = toDeductionFitch (parseThomasBolducAndZachTFL rtc) (purePropFormulaParser thomasBolducZachOpts)

parseThomasBolducAndZachTFL2019Proof :: RuntimeNaturalDeductionConfig PurePropLexicon (Form Bool) -> String -> [DeductionLine ThomasBolducAndZachTFLCore PurePropLexicon (Form Bool)]
parseThomasBolducAndZachTFL2019Proof rtc = toDeductionFitch (parseThomasBolducAndZachTFLCore rtc) (purePropFormulaParser thomasBolducZachOpts)

thomasBolducAndZachNotation :: String -> String 
thomasBolducAndZachNotation x = case runParser altParser 0 "" x of
                        Left e -> show e
                        Right s -> s
    where altParser = do s <- try handleAtom <|> fallback
                         rest <- (eof >> return "") <|> altParser
                         return $ s ++ rest
          handleAtom = do c <- oneOf "ABCDEFGHIJKLMNOPQRSTUVWXYZ" <* char '('
                          args <- oneOf "abcdefghijklmnopqrstuvwxyz" `sepBy` char ','
                          char ')'
                          return $ c:args
          fallback = do c <- anyChar 
                        return [c]

dropOuterParens s = case (strip s, break (== '⊢') s) of
      (s'@(_:_:_:_),_) | (head s' == '(') && (last s' == ')') && (balance 0 (inner s') == 0) -> inner s'
      (_,(a@(_:_),b@(_:_))) -> (dropOuterParens a) ++ " ⊢ " ++ (dropOuterParens $ tail b)
      _ -> s

    where balance 0 (')':_) = -1
          balance n [] = n
          balance n ('(':rest) = balance (n+1) rest 
          balance n (')':rest) = balance (n-1) rest
          balance n (_:rest) = balance n rest

          strip = reverse . dropWhile (== ' ') . reverse . dropWhile (== ' ') 
          inner = init . tail 

thomasBolducAndZachTFLCalc = mkNDCalc 
    { ndRenderer = FitchStyle StandardFitch
    , ndParseProof = parseThomasBolducAndZachTFLProof
    , ndProcessLine = hoProcessLineFitch
    , ndProcessLineMemo = Just hoProcessLineFitchMemo
    , ndParseSeq = parseSeqOver (purePropFormulaParser thomasBolducZachOpts)
    , ndParseForm = purePropFormulaParser thomasBolducZachOpts
    , ndNotation = thomasBolducAndZachNotation
    }

thomasBolducAndZachTFL2019Calc = mkNDCalc 
    { ndRenderer = FitchStyle StandardFitch
    , ndParseProof = parseThomasBolducAndZachTFL2019Proof
    , ndProcessLine = hoProcessLineFitch
    , ndProcessLineMemo = Just hoProcessLineFitchMemo
    , ndParseSeq = parseSeqOver (purePropFormulaParser thomasBolducZachOpts)
    , ndParseForm = purePropFormulaParser thomasBolducZachOpts
    , ndNotation = dropOuterParens
    }
