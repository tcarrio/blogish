+++
title = "Codility :: Sparse Integer Decomposition"
tags = ["coding", "algorithms"]
+++

Awhile back I had worked on some Codility exercises, one of which was this case for sparse integer decomposition. This solution ended up snagging me a top 5 percentile in performance and I figured I would share the approach.

## The Task

A non-negative integer N is called sparse if its binary representation does not contain two consecutive bits set to 1. For example, 41 is sparse, because its binary representation is "101001" and it does not contain two consecutive 1s. On the other hand, 26 is not sparse, because its binary representation is "11010" and it contains two consecutive 1s.

Two non-negative integers P and Q are called a sparse decomposition of integer N if P and Q are sparse and N = P + Q.

For example:

        8 and 18 are a sparse decomposition of 26 (binary representation of 8 is "1000", binary representation of 18 is "10010");
        9 and 17 are a sparse decomposition of 26 (binary representation of 9 is "1001", binary representation of 17 is "10001");
        2 and 24 are not a sparse decomposition of 26; though 2 + 24 = 26, the binary representation of 24 is "11000", which is not sparse.

Write a function:

    def solution(N)

that, given a non-negative integer N, returns any integer that is one part of a sparse decomposition of N. The function should return −1 if there is no sparse decomposition of N.

For example, given N = 26 the function may return 8, 9, 17 or 18, as explained in the example above. All other possible results for N = 26 are 5, 10, 16 and 21.

Write an efficient algorithm for the following assumptions:

        N is an integer within the range [0..1,000,000,000].

## The Solution

```python
from math import ceil, log2

def calculate_alternating_mask(value):
    """
    calculate_alternating_mask determines a binary mask with a maximum
    range based on the provided value, then iterates through each bit in
    the mask, alternating the setting of that bit to 0.
    
    the end result is a mask with at most every other bit set to 1, in the
    worst case scenario that all bits were 1 in the binary representation
    of the input value.
    
    @example: calculate_alternating_mask(15) -> 0b1010
    @example: calculate_alternating_mask(0b1111) -> 0b1010
    @example: calculate_alternating_mask(0xf) -> 0b1010
    
    @example: calculate_alternating_mask(255) -> 0b10101010
    @example: calculate_alternating_mask(0b11111111) -> 0b10101010
    @example: calculate_alternating_mask(0xff) -> 0b10101010
    """
    binary_index = ceil(log2(value))
    alternating_mask = 2 ** binary_index - 1
    
    zero_bit = 1
    while binary_index >= 0:
        if (zero_bit == 1):
            alternating_mask -= 2 ** binary_index
        
        zero_bit ^= 0b1
        binary_index -= 1
    
    return alternating_mask

def solution(N):
    """
    solution will specially handle cases at the minimum range of valid
    input values to return early. otherwise, an alternating mask will
    be generated to calculate a sparse integer based on the value.
    """
    if N <= 2:
      return N

    return N & calculate_alternating_mask(N)
```

## The Breakdown

The wording of the problem would seem to indicate that it's possible to not find a sparse decomposition of a value, but generally speaking there will always be two components to derive from a single non-negative integer. The restrictions are only that the integer be part a sparse decomposition that has a corresponding but not reported sparse decomposition integer whose sums are the original value N. Since these decompositions are not limited by N > 0 or N > 1, this means we can break down any value M into N + P where 0 ≤ N ≤ M.

With all of that in mind, the methodology here is to generate an alternating bitmask (1010101...) of equivalent binary order to the input number (4 = 0b100, mask = 0b101. 15 = 0b1111, mask = 0b1010). That is binary `AND`ed with the input number M to calculate a decomposition where there is never two successive 1s, as it's mathematically impossible given the mask never has two successive 1s and the nature of the binary AND operation.

This only works because of loose requirements. For example, if the requirements were instead 0 < N < M, we could not return 0 or M. This solution could be extended to cover scenarios where the initial bitmask (1010) AND returns 0 or M, where we could bitshift the mask (0101) and repeat the check. At this point, if the result still returns 0 or M, there is no sparse decomposition that fulfills 0 < N < M.
