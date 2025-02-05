/*
 * Run Alphafold2 PRED
 */
process RUN_AF2_PRED {
    tag "${seq_name}"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://luisas/af2_split:v.1.0' :
        'luisas/af2_split:v.1.0' }"

    input:
    tuple val(seq_name), path(fasta)
    val   db_preset
    val   model_preset
    path ('params/*')
    path ('bfd/*')
    path ('small_bfd/*')
    path ('mgnify/*')
    path ('pdb70/*')
    path ('pdb_mmcif/*')
    path ('uniclust30/*')
    path ('uniref90/*')
    path ('pdb_seqres/*')
    path ('uniprot/*')
    path  msa

    output:
    path ("${fasta.baseName}*")
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    if [ -d params/alphafold_params_* ]; then ln -r -s params/alphafold_params_*/* params/; fi
    python3 /app/alphafold/run_predict.py \
        --fasta_paths=${fasta} \
        --model_preset=${model_preset} \
        --output_dir=\$PWD \
        --data_dir=\$PWD \
        --random_seed=53343 \
        --msa_path=${msa} \
        $args

    cp "${fasta.baseName}"/ranked_0.pdb ./"${fasta.baseName}".alphafold.pdb

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 --version | sed 's/Python //g')
    END_VERSIONS
    """

    stub:
    """
    touch ./"${fasta.baseName}".alphafold.pdb

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        awk: \$(gawk --version| head -1 | sed 's/GNU Awk //; s/, API:.*//')
    END_VERSIONS
    """
}
