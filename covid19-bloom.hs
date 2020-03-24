import Data.Csv (encode)
import Data.List
import Text.Printf
import qualified Data.BloomFilter as Bloom
import qualified Data.BloomFilter.Hash as Bloom
import qualified Data.ByteString.Lazy as B

pcrTubes = 96
maxSamplesInTube = 50

kHashesCandidates = [2..20]
salts = [0..100]

samplesInTube kHashes nAll = fromIntegral nAll * fromIntegral kHashes / fromIntegral pcrTubes

genSamples :: Int -> [Int]
genSamples salt = map (salt +) [1..]

bloom samples kHashes nRealPositive =
    Bloom.fromList (Bloom.hashes kHashes) pcrTubes (take nRealPositive samples)

tryBloom samples nRealPositive nAll =
    [ nTestedPositive filt - nRealPositive
    | kHashes <- kHashesCandidates, let filt = bloom samples kHashes nRealPositive
    , samplesInTube kHashes nAll <= maxSamplesInTube ]
  where
    nTestedPositive filt = length $ filter id [n `Bloom.elem` filt | n <- take nAll samples]

optimalBloom nRealPositive nAll = fmap (\(_, avg, k) -> (avg, k)) optimum
  where
    allFalsePositives = transpose [ tryBloom samples nRealPositive nAll | samples <- map genSamples salts ]
    avgFalsePositives = map avg allFalsePositives
    sumSquareFalsePositives = map (sum . map (^2)) allFalsePositives
    optimum = if null allFalsePositives
        then Nothing
        else Just $ minimum $ zip3 sumSquareFalsePositives avgFalsePositives kHashesCandidates

avg :: (Num a, Integral a) => [a] -> Double
avg xs = fromIntegral (sum xs) / fromIntegral (length xs)

table :: [(Int, Int, Int, String, String)]
table =
    [ (nRealPositive, nAll, kHashes, fmt (samplesInTube kHashes nAll), fmt avgFalsePositives)
    | nRealPositive <- [1, 5, 10, 15, 20, 30]
    , nAll <- [500, 1000, 2000, 5000]
    , Just (avgFalsePositives, kHashes) <- [optimalBloom nRealPositive nAll] ]
  where
    fmt :: Double -> String
    fmt d = printf "%.2f" d

main = do
    B.putStr (encode [("nRealPositive", "nAll", "kHashes", "samplesInTube", "avgFalsePositives")])
    B.putStr (encode table)
