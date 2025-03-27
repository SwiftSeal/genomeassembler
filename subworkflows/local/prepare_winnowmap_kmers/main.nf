include { MERYL_PRINT as PRE_WINNOWMAP_MERYL_PRINT } from '../../../modules/local/meryl/print/main'
include { MERYL_COUNT  as PRE_WINNOWMAP_MERYL_COUNT } from '../../../modules/nf-core/meryl/count/main'

workflow REPETITIVE_KMERS {
    take:
    genome_assembly

    main:
    Channel.empty().set { ch_versions }

    // generate meryl kmer counts
    // TEMP - count 15mers for now
    PRE_WINNOWMAP_MERYL_COUNT(genome_assembly, 15)
    // TEMP - thresholds hardcoded in rule
    PRE_WINNOWMAP_MERYL_PRINT(PRE_WINNOWMAP_MERYL_COUNT.out.meryl_db)

    PRE_WINNOWMAP_MERYL_PRINT.out.txt.set { repetitive_kmers }

    versions = ch_versions.mix(PRE_WINNOWMAP_MERYL_COUNT.out.versions).mix(PRE_WINNOWMAP_MERYL_PRINT.out.versions)

    emit:
    repetitive_kmers
    versions
}