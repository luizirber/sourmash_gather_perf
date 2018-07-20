from glob import glob

INPUTS = glob('data/*.sig')

rule all:
  input: 
      expand("outputs/{branch}.profile",
             branch=['master',
                     'refactor/more_cython',
                     'impr/node_data',
                     'feature/bf_query',
                     'refactor/rust_inspired'])

rule index:
    output: 'outputs/subset.sbt.json'
    input: INPUTS
    shell: '''
        sourmash info
        sourmash index -k 31 -d 2 -x 1e6 {output} {input}
    '''

rule profile:
    output: 'outputs/{branch}.profile'
    input:
        query='input.sig',
        index='outputs/subset.sbt.json'
    benchmark: 'benchmarks/{branch}'
    conda: 'envs/{branch}.yaml'
    shell: '''
      echo $(which sourmash)
	    python -m cProfile -o {output} $(which sourmash) gather {input.query} {input.index}
    '''

