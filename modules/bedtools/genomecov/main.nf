// Import generic module functions
include { initOptions; saveFiles; getSoftwareName; getProcessName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process BEDTOOLS_GENOMECOV {
    tag "$meta.id"
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:meta, publish_by_meta:['id']) }

    conda (params.enable_conda ? "bioconda::bedtools=2.30.0" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/bedtools:2.30.0--hc088bd4_0"
    } else {
        container "quay.io/biocontainers/bedtools:2.30.0--hc088bd4_0"
    }

    input:
    tuple val(meta), path(intervals), val(scale)
    path  sizes
    val   extension

    output:
    tuple val(meta), path("*.${extension}"), emit: genomecov
    path  "versions.yml"                   , emit: versions

    script:
    def prefix     = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"
    def args_token = options.args.tokenize()
    def args       = options.args
    args += (scale > 0 && scale != 1) ? " -scale $scale" : ""

    if (!args_token.contains('-bg') && (scale > 0 && scale != 1)) {
        args += " -bg"
    }

    if (intervals.name =~ /\.bam/) {
        """
        bedtools \\
            genomecov \\
            -ibam $intervals \\
            $args \\
            > ${prefix}.${extension}

        cat <<-END_VERSIONS > versions.yml
        ${getProcessName(task.process)}:
            ${getSoftwareName(task.process)}: \$(bedtools --version | sed -e "s/bedtools v//g")
        END_VERSIONS
        """
    } else {
        """
        bedtools \\
            genomecov \\
            -i $intervals \\
            -g $sizes \\
            $args \\
            > ${prefix}.${extension}

        cat <<-END_VERSIONS > versions.yml
        ${getProcessName(task.process)}:
            ${getSoftwareName(task.process)}: \$(bedtools --version | sed -e "s/bedtools v//g")
        END_VERSIONS
        """
    }
}
