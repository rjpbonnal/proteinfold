//
// Download all the required AlphaFold 2 databases and parameters
//
// TODO create parameters and include them in nextflow config
bfd            = 'https://storage.googleapis.com/alphafold-databases/casp14_versions/bfd_metaclust_clu_complete_id30_c90_final_seq.sorted_opt.tar.gz'
small_bfd      = 'https://storage.googleapis.com/alphafold-databases/reduced_dbs/bfd-first_non_consensus_sequences.fasta.gz'
af2_params     = 'https://storage.googleapis.com/alphafold/alphafold_params_2022-03-02.tar'
mgnify         = 'https://storage.googleapis.com/alphafold-databases/casp14_versions/mgy_clusters_2018_12.fa.gz'
pdb70          = 'http://wwwuser.gwdg.de/~compbiol/data/hhsuite/databases/hhsuite_dbs/old-releases/pdb70_from_mmcif_200916.tar.gz'
pdb_mmCIF      = 'rsync.rcsb.org::ftp_data/structures/divided/mmCIF/' //'rsync.rcsb.org::ftp_data/structures/divided/mmCIF/' ftp.pdbj.org::ftp_data/structures/divided/mmCIF/ rsync.ebi.ac.uk::pub/databases/pdb/data/structures/divided/mmCIF/
pdb_obsolete   = 'ftp://ftp.wwpdb.org/pub/pdb/data/status/obsolete.dat'
uniclust30     = 'https://storage.googleapis.com/alphafold-databases/casp14_versions/uniclust30_2018_08_hhsuite.tar.gz'
uniref90       = 'ftp://ftp.uniprot.org/pub/databases/uniprot/uniref/uniref90/uniref90.fasta.gz'
pdb_seqres     = 'ftp://ftp.wwpdb.org/pub/pdb/derived_data/pdb_seqres.txt'
uniprot_sprot  = 'ftp://ftp.ebi.ac.uk/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.fasta.gz'
uniprot_trembl = 'ftp://ftp.ebi.ac.uk/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_trembl.fasta.gz'

include {
    ARIA2_UNCOMPRESS as ARIA2_AF2_PARAMS
    ARIA2_UNCOMPRESS as ARIA2_BFD
    ARIA2_UNCOMPRESS as ARIA2_SMALL_BFD
    ARIA2_UNCOMPRESS as ARIA2_MGNIFY
    ARIA2_UNCOMPRESS as ARIA2_PDB70
    ARIA2_UNCOMPRESS as ARIA2_UNICLUST30
    ARIA2_UNCOMPRESS as ARIA2_UNIREF90
    ARIA2_UNCOMPRESS as ARIA2_UNIPROT_SPROT
    ARIA2_UNCOMPRESS as ARIA2_UNIPROT_TREMBL } from './aria2_uncompress'

include { ARIA2             } from '../../modules/nf-core/aria2/main'
include { COMBINE_UNIPROT   } from '../../modules/local/combine_uniprot'
include { DOWNLOAD_PDBMMCIF } from '../../modules/local/download_pdbmmcif'

workflow PREPARE_AF2_DBS {
    main:
    ch_bfd        = Channel.empty()
    ch_bfd_small  = Channel.empty()
    ch_versions   = Channel.empty()


    if (params.af2_db) {
        if (params.full_dbs) {
            ch_bfd       = file("${params.af2_db}/bfd/*" )
            ch_bfd_small = file("${projectDir}/assets/dummy_db")
        }
        else {
            ch_bfd       = file("${projectDir}/assets/dummy_db")
            ch_bfd_small = file("${params.af2_db}/small_bfd/*")
        }

        // TODO parameters for each of the DBs that could be updated or provided in a user path
        // maybe have a db.config?
        // TODO add checkIfExists (need to create a fake structure for testing)
        // Add an if for each parameter?
        ch_params     = file( "${params.af2_db}/alphafold_params_*/*" )
        ch_mgnify     = file( "${params.af2_db}/mgnify/*" )
        ch_pdb70      = file( "${params.af2_db}/pdb70/*", type: 'any' )
        ch_mmcif      = file( "${params.af2_db}/pdb_mmcif/*", type: 'any' )
        ch_uniclust30 = file( "${params.af2_db}/uniclust30/*", type: 'any' )
        ch_uniref90   = file( "${params.af2_db}/uniref90/*" )
        ch_pdb_seqres = file( "${params.af2_db}/pdb_seqres/*" )
        ch_uniprot    = file( "${params.af2_db}/uniprot/*" )
    }
    else {
        if (params.full_dbs) {
            ARIA2_BFD(
                bfd
            )
            ch_bfd =  ARIA2_BFD.out.db
            ch_versions = ch_versions.mix(ARIA2_BFD.out.versions)
        } else {
            ARIA2_SMALL_BFD(
                small_bfd
            )
            ch_bfd_small = ARIA2_SMALL_BFD.out.db
            ch_versions = ch_versions.mix(ARIA2_SMALL_BFD.out.versions)
        }

        ARIA2_AF2_PARAMS(
            af2_params
        )
        ch_params = ARIA2_AF2_PARAMS.out.db
        ch_versions = ch_versions.mix(ARIA2_AF2_PARAMS.out.versions)

        ARIA2_MGNIFY(
            mgnify
        )
        ch_mgnify = ARIA2_MGNIFY.out.db
        ch_versions = ch_versions.mix(ARIA2_MGNIFY.out.versions)


        ARIA2_PDB70(
            pdb70
        )
        ch_pdb70 = ARIA2_PDB70.out.db
        ch_versions = ch_versions.mix(ARIA2_PDB70.out.versions)

        DOWNLOAD_PDBMMCIF(
            pdb_mmCIF,
            pdb_obsolete
        )
        ch_mmcif = DOWNLOAD_PDBMMCIF.out.ch_db
        ch_versions = ch_versions.mix(DOWNLOAD_PDBMMCIF.out.versions)

        ARIA2_UNICLUST30(
            uniclust30
        )
        ch_uniclust30 = ARIA2_UNICLUST30.out.db
        ch_versions = ch_versions.mix(ARIA2_UNICLUST30.out.versions)

        ARIA2_UNIREF90(
            uniref90
        )
        ch_uniref90 = ARIA2_UNIREF90.out.db
        ch_versions = ch_versions.mix(ARIA2_UNIREF90.out.versions)

        ARIA2 (
            pdb_seqres
        )
        ch_pdb_seqres = ARIA2.out.downloaded_file
        ch_versions = ch_versions.mix(ARIA2.out.versions)

        ARIA2_UNIPROT_SPROT(
            uniprot_sprot
        )
        ch_versions = ch_versions.mix(ARIA2_UNIPROT_SPROT.out.versions)
        ARIA2_UNIPROT_TREMBL(
            uniprot_trembl
        )
        ch_versions = ch_versions.mix(ARIA2_UNIPROT_TREMBL.out.versions)
        COMBINE_UNIPROT (
            ARIA2_UNIPROT_SPROT.out.db,
            ARIA2_UNIPROT_TREMBL.out.db
        )
        ch_uniprot = COMBINE_UNIPROT.out.ch_db
        ch_version =  ch_versions.mix(COMBINE_UNIPROT.out.versions)



    }

	emit:
    bfd        = ch_bfd
    bfd_small  = ch_bfd_small
    params     = ch_params
    mgnify     = ch_mgnify
    pdb70      = ch_pdb70
    pdb_mmcif  = ch_mmcif
    uniclust30 = ch_uniclust30
    uniref90   = ch_uniref90
    pdb_seqres = ch_pdb_seqres
    uniprot    = ch_uniprot
    versions   = ch_versions
}
