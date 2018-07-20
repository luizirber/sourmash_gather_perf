# Tracking down sourmash gather performance bottlenecks

This repo contains code and data for analysis of performance bottlenecks in
`sourmash gather`. It uses `snakemake` for generating profile data for some
approaches to try to fix the bottlenecks.

## Input data

The input.sig comes from a podar reads subset (2.5M reads) computed with
`sourmash compute -k 31 --scaled 1000 <(head -10000000 podar_reads.fq) -o input.sig`

I also randomly subsampled 300 microbial sigs to build the tree and I'm using
it because it takes 15-30 sec to run and the profiling data is pretty similar
to what I see with the full genbank SBT:
`python -m cProfile -o initial.profile $(which sourmash) gather input.sig /mnt/ipfs/outputs/trees/scaled/genbank-d2-k31.sbt.json`

## Approaches

- I set up a toy branch [0] moving sbt and sbtmh into Cython. There is no code
 changes, but that's already 20% faster. The goal was to lower the time it
 takes to check the hashes against the BF:
 `matches = sum(1 for value in hashes if node.data.get(value))`

- Another approach is using a BF for queries (this is implemented in [1]).
 Annoyingly, it IS SLOWER. The call to `node.data.similarity` is fast, but it
 is returning a similarity score much higher than what the current code does,
 so it searches more of the tree... But it would be pretty cool to fix that
 and turn this into the default (depending on PR #1842 in khmer [4])

- Some smaller perf benefits from moving Python code (intersection and compare)
 into C++ (PR #453 [2]). This pretty much comes from similar things I did in
 the Rust PR.

- The winner for now: [PR #516][3] replaces
  `matches = sum(1 for value in hashes if node.data.get(value))` 
  with
  ```
  get = node.data.get
  matches = sum(1 for value in hashes if get(value))
  ```
  and that makes `sourmash gather` 40% faster.

[0]: https://github.com/dib-lab/sourmash/compare/refactor/more_cython
[1]: https://github.com/dib-lab/sourmash/pull/395
[2]: https://github.com/dib-lab/sourmash/pull/453
[3]: https://github.com/dib-lab/sourmash/pull/516
[4]: https://github.com/dib-lab/khmer/pull/1842
