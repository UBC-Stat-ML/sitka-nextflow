#!/usr/bin/env nextflow

deliverableDir = 'deliverables/' + workflow.scriptName.replace('.nf','')

params.binaryMarkers = null

binaryMarkers = file(params.binaryMarkers)

if (binaryMarkers == null) {
  throw new RuntimeException("Set --binaryMarkers to the input.")
}

process buildCode {
  cache true 
  input:
    val gitRepoName from 'nowellpack'
    val gitUser from 'UBC-Stat-ML'
    val codeRevision from 'e2871bcc011b61c44cb6901240061bb546962dc9'
    val snapshotPath from "${System.getProperty('user.home')}/w/nowellpack"
  output:
    file 'code' into code
  script:
    template 'buildRepo.sh' 
}


process inference {
  echo true
  input:
    file code
    file binaryMarkers
    env JAVA_OPTS from '-Xmx10g'
  """
  echo OK
  code/bin/corrupt-infer-with-noisy-params  \
    --model.binaryMatrix $binaryMarkers \
    --model.globalParameterization false \
    --model.fprBound 0.5 \
    --model.fnrBound 0.5 \
    --model.minBound 0.001 \
    --engine PT \
    --engine.nChains 50 \
    --engine.nScans 100 \
    --engine.thinning 1 \
    --postProcessor corrupt.post.CorruptPostProcessor \
    --model.samplerOptions.useCellReallocationMove true \
    --postProcessor.runPxviz true \
    --experimentConfigs.tabularWriter.compressed true \
    --engine.nPassesPerScan 0.5 \
    --model.predictivesProportion 0.0 \
    --engine.nThreads MAX  \
    --engine.initialization FORWARD \
    --engine.random 12455 
  """
}



process summarizePipeline {
  cache false
  output:
      file 'pipeline-info.txt'   
  publishDir deliverableDir, mode: 'copy', overwrite: true
  """
  echo 'scriptName: $workflow.scriptName' >> pipeline-info.txt
  echo 'start: $workflow.start' >> pipeline-info.txt
  echo 'runName: $workflow.runName' >> pipeline-info.txt
  echo 'nextflow.version: $workflow.nextflow.version' >> pipeline-info.txt
  """
}
