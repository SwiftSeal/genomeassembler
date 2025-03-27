include { MINIMAP2_ALIGN as MINIMAP2_ONT } from '../../../modules/nf-core/minimap2/align/main.nf'
include { MINIMAP2_ALIGN as MINIMAP2_HIFI } from '../../../modules/nf-core/minimap2/align/main.nf'
include { REPETITIVE_KMERS } from '../prepare_winnowmap_kmers/main.nf'
include { WINNOWMAP_ALIGN as WINNOWMAP_ONT } from '../../../modules/local/winnowmap/align/main.nf'
include { WINNOWMAP_ALIGN as WINNOWMAP_HIFI } from '../../../modules/local/winnowmap/align/main.nf'
include { RUN_BUSCO } from './busco/main.nf'
include { RUN_QUAST } from './quast/main.nf'
include { MERQURY_QC } from './merqury/main.nf'
include { GCI } from '../../../modules/local/gci/main.nf'


workflow QC {
    take:
    inputs
    ont_reads
    hifi_reads
    scaffolds
    aln_to_ref
    meryl_kmers

    main:
    Channel.empty().set { ch_versions }
    Channel.empty().set { quast_out }
    Channel.empty().set { busco_out }
    Channel.empty().set { merqury_report_files }
    Channel.empty().set { minimap2_ont_aln }
    Channel.empty().set { minimap2_hifi_aln }
    Channel.empty().set { winnowmap_ont_aln }
    Channel.empty().set { winnowmap_hifi_aln }

    // generate alignments
    if (params.gci || params.quast) {
        // Minimap alignments
        if (params.ont) {
            MINIMAP2_ONT(ont_reads.join(scaffolds), true, 'bai', false, false)
            MINIMAP2_ONT.out.bam.set { minimap2_ont_aln }
            ch_versions = ch_versions.mix(MINIMAP2_ONT.out.versions)
        }

        if (params.hifi) {
            MINIMAP2_HIFI(hifi_reads.join(scaffolds), true, 'bai', false, false)
            MINIMAP2_HIFI.out.bam.set { minimap2_ont_aln }
            ch_versions = ch_versions.mix(MINIMAP2_HIFI.out.versions)
        }

        // Winnowmap alignments (only for GCI)
        if (params.gci) {
            // generate repetitive kmers list from scaffolds
            REPETITIVE_KMERS(scaffolds)
            REPETITIVE_KMERS.out.repetitive_kmers.set { repetitive_kmers }
            ch_versions = ch_versions.mix(REPETITIVE_KMERS.out.versions)
            // Need to generate scaffold kmer database
            if (params.ont) {
                ont_reads
                    .join(scaffolds)
                    .join(repetitive_kmers)
                    .set { winnowmap_ont_input }

                WINNOWMAP_ONT(winnowmap_ont_input, true, 'bai', false, false)
                WINNOWMAP_ONT.out.bam.set { winnowmap_ont_aln }
                ch_versions = ch_versions.mix(WINNOWMAP_ONT.out.versions)
            }

            if (params.hifi) {
                hifi_reads
                    .join(scaffolds)
                    .join(repetitive_kmers)
                    .set { winnowmap_hifi_input }

                WINNOWMAP_HIFI(winnowmap_hifi_input, true, 'bai', false, false)
                WINNOWMAP_HIFI.out.bam.set { winnowmap_hifi_aln }
                ch_versions = ch_versions.mix(WINNOWMAP_HIFI.out.versions)
            }

            // Combine all alignments for GCI
            scaffolds
                .join(minimap2_ont_aln)
                .join(winnowmap_ont_aln)
                .join(minimap2_hifi_aln)
                .join(minimap2_ont_aln)
                .set { gci_input }
            GCI(gci_input)
        }

        // QUAST read selection
        if (params.quast) {
            qc_aln = params.qc_reads == "ONT" ? minimap2_ont_aln: minimap2_hifi_aln
            RUN_QUAST(scaffolds, inputs, aln_to_ref, qc_aln)
            RUN_QUAST.out.quast_tsv.set { quast_out }
            ch_versions = ch_versions.mix(RUN_QUAST.out.versions)
        }
    }

    RUN_BUSCO(scaffolds)
    RUN_BUSCO.out.batch_summary.set { busco_out }

    ch_versions = ch_versions.mix(RUN_BUSCO.out.versions)

    if (params.short_reads) {
        MERQURY_QC(scaffolds, meryl_kmers)
        MERQURY_QC.out.stats
            .join(
                MERQURY_QC.out.spectra_asm_hist
            )
            .join(
                MERQURY_QC.out.spectra_cn_hist
            )
            .join(
                MERQURY_QC.out.assembly_qv
            )
            .set { merqury_report_files }

        ch_versions = ch_versions.mix(MERQURY_QC.out.versions)
    }

    versions = ch_versions

    emit:
    quast_out
    busco_out
    merqury_report_files
    versions
}
