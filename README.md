Faster COVID-19 testing using PCR and hashing (bloom filter)
============================================================

According to Israeli scientists, [it's possible][pcr-pooling] to merge
multiple swab samples into one tube for PCR without losing much accuracy.
Their method involves a divide and conquer approach, starting by pooling
samples into groups of (up to) 32 and then eliminating groups with no positive
samples.

[pcr-pooling]: https://medium.com/@dinber19/more-with-less-using-pooling-to-detect-coronavirus-with-fewer-tests-8ba1a2cd8b67

I'd like to suggest an alternative approach based on hashing, essentially a
biological [Bloom filter](https://en.wikipedia.org/wiki/Bloom_filter).
The core idea is that we don't just group samples, we first split each sample
and only then group it with several other samples, and we do this in a way
that allows identification of individual positives/negatives, assuming the
ratio of positives is low (1%, ideally even less).

A bloom filter uses k distinct hash functions and m bits. Adding an input
value involves hashing it using each hash function and then setting the
resulting bit position to 1.

A biological bloom filter uses tubes instead of bits. Adding a positive sample
contaminates k tubes with the virus, whereas adding a negative sample only
slightly dilutes k tubes (essentially a no-op). Then PCR is done on all those
tubes, and the bit values are revealed. We can then use it as a traditional
bloom filter and check (on a computer) which samples are in the positive set.
Provided the ratio of positive samples is low (which it should be if we're
going to widely test asymptomatic people), the false positive rate should be
acceptable and we should be able to identify infected persons within a single
PCR run.

## Assumptions

 * we're able to split a sample into up to 10 equal parts (I hope so)
 * we can merge samples and still detect the virus (verified in the lab)
 * it's possible to correctly put thousands of sub-samples into tubes (???)
 * ratio of positive vs tested is low (so far it has been)

## Proof of Concept

Included is a Haskell program to simulate the process and calculate ideal
values of k (number of sub-samples we need) and false positivity rates.

Results:

```
$ ./covid19-bloom | column -s, -t
nRealPositive  nAll  kHashes  samplesInTube  avgFalsePositives
1              500   3        15.62          0.00
1              1000  4        41.67          0.00
1              2000  2        41.67          0.41
5              500   7        36.46          0.02
5              1000  4        41.67          0.50
5              2000  2        41.67          10.48
10             500   7        36.46          1.31
10             1000  4        41.67          4.83
10             2000  2        41.67          39.64
15             500   4        20.83          7.41
15             1000  4        41.67          17.58
15             2000  2        41.67          81.89
20             500   4        20.83          17.95
20             1000  4        41.67          40.67
20             2000  2        41.67          134.20
30             500   4        20.83          57.10
30             1000  3        31.25          114.93
30             2000  2        41.67          265.82
```

These ones look interesting:

```
nRealPositive  nAll  kHashes  samplesInTube  avgFalsePositives
1              500   3        15.62          0.00
1              1000  4        41.67          0.00
1              2000  2        41.67          0.41
5              500   7        36.46          0.02
5              1000  4        41.67          0.50
5              2000  2        41.67          10.48
10             500   7        36.46          1.31
10             1000  4        41.67          4.83
15             500   4        20.83          7.41
15             1000  4        41.67          17.58
20             500   4        20.83          17.95
20             1000  4        41.67          40.67
```

This means that if we expect to have up to 5 infected in a thousand samples, we
can test them all in a single 96-tube PCR run and identify the infected ones
almost exactly. As the ratio of infected samples rises, the false positive rate
goes up rapidly, but up to 20 infected in 1000 samples, it should fit in one
additional 96-tube PCR run. But we must be able to split a single swab into 5
pieces.
