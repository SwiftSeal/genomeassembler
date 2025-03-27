include { LINKS } from '../../../../modules/local/links/main'
include { QC } from '../../qc/main'
include { RUN_LIFTOFF } from '../../liftoff/main'

workflow RUN_LINKS {
    take:
    inputs
    ont_reads
    hifi_reads
    assembly
    _references
    ch_aln_to_ref
    meryl_kmers

    main:
    Channel.empty().set { ch_versions }

    if (params.qc_reads == "ONT") {
        LINKS(assembly.join(ont_reads))
    } else if (params.qc_reads == "HIFI") {
        LINKS(assembly.join(hifi_reads))
    }
    
    LINKS.out.scaffolds.set { scaffolds }

    ch_versions = ch_versions.mix(LINKS.out.versions)

    QC(inputs, ont_reads, hifi_reads, scaffolds, ch_aln_to_ref, meryl_kmers)

    ch_versions = ch_versions.mix(QC.out.versions)

    if (params.lift_annotations) {
        RUN_LIFTOFF(scaffolds, inputs)
        ch_versions = ch_versions.mix(RUN_LIFTOFF.out.versions)
    }

    versions = ch_versions

    emit:
    scaffolds
    quast_out               = QC.out.quast_out
    busco_out               = QC.out.busco_out
    merqury_report_files    = QC.out.merqury_report_files
    versions
}
