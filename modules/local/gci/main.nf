process GCI {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"

    input:
    tuple val(meta), path(scaffolds), path(minimap2_ont_bam), path(winnowmap_ont_bam), path(minimap2_hifi_bam), path(winnowmap_hifi_bam)

    output:
    path val(meta), path("*.gci")              , emit: gci
    path  "versions.yml"                       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def hifi_mappings = ((minimap2_hifi_bam) && (winnowmap_hifi_bam)) ? "--hifi $minimap2_hifi_bam $winnowmap_hifi_bam " : ""
    def ont_mappings = ((minimap2_ont_bam) && (winnowmap_ont_bam)) ? "--ont $minimap2_ont_bam $winnowmap_ont_bam" : ""

    """
    python GCI.py \\
        -r $scaffolds \\
        $hifi_mappings \\
        $ont_mappings \\
        -t $task.cpus \\
        -o ${prefix}
    """

    stub:
        def prefix = task.ext.prefix ?: "${meta.id}"
        """
        touch ${prefix}.gci

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            GCI: \$(python GCI --version 2>&1)
        END_VERSIONS
        """

}