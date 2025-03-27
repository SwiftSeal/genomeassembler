process MERYL_PRINT {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/meryl:1.4.1--h4ac6f70_0':
        'biocontainers/meryl:1.4.1--h4ac6f70_0' }"

    input:
    tuple val(meta), path(meryl_db)

    output:
    tuple val(meta), path("*.txt"), emit: txt
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    meryl print \\
        greater-than distinct=0.9998 \\
        threads=$task.cpus \\
        memory=${task.memory.toGiga()} \\
        $args \\
        $meryl_db > ${prefix}.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        meryl: \$( meryl --version |& sed 's/meryl //' )
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        meryl: \$( meryl --version |& sed 's/meryl //' )
    END_VERSIONS
    """
}