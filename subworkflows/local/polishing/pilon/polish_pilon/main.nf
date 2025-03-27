include { RUN_PILON } from '../run_pilon/main'
include { MINIMAP2_ALIGN as MINIMAP2_SR } from '../../../../../modules/nf-core/minimap2/align/main'
include { RUN_LIFTOFF } from '../../../liftoff/main'
include { QC } from '../../../qc/main.nf'

workflow POLISH_PILON {
    take:
    ch_input
    ont_reads
    hifi_reads
    short_reads
    assembly
    ch_aln_to_ref
    meryl_kmers

    main:
    Channel.empty().set { ch_versions }

    short_reads
        .map { meta, reads -> [[id: meta.id], reads] }
        .join(assembly)
        .set { map_assembly }

    MINIMAP2_SR(map_assembly, true, 'bai', false, false)
    MINIMAP2_SR.out.bam.set { minimap2_sr_bam }
    MINIMAP2_SR.out.index.set { minimap2_sr_bai }

    minimap2_sr_bam
        .join(minimap2_sr_bai)
        .set { minimap2_sr_bam_bai }

    ch_versions = ch_versions.mix(MINIMAP2_SR.out.versions)

    RUN_PILON(assembly, minimap2_sr_bam_bai)

    RUN_PILON.out.improved_assembly.set { pilon_polished }

    ch_versions = ch_versions.mix(RUN_PILON.out.versions)

    QC(ch_input, ont_reads, hifi_reads, pilon_polished, ch_aln_to_ref, meryl_kmers)

    ch_versions = ch_versions.mix(QC.out.versions)

    if (params.lift_annotations) {
        RUN_LIFTOFF(pilon_polished, ch_input)
        ch_versions = ch_versions.mix(RUN_LIFTOFF.out.versions)
    }

    versions = ch_versions

    emit:
    pilon_polished
    quast_out               = QC.out.quast_out
    busco_out               = QC.out.busco_out
    merqury_report_files    = QC.out.merqury_report_files
    versions
}
