include: "common.smk"


pepfile: config["pepfile"]


# Apply the settings from the pepfile, overwriting the default ones
default.update(pep.config.get("snakemake-project", dict()))

# Apply the options specified to snakemake, overwriting the default settings
# and the settings from the PEP file
default.update(config)

# Set the updated dict as the configuration for the pipeline
config = default


rule all:
    input:
        humid=expand(
            "{sample}/humid/forward_dedup.fastq.gz",
            sample=pep.sample_table["sample_name"],
        ),
        calib=expand(
            "{sample}/calib/cluster",
            sample=pep.sample_table["sample_name"],
        ),


rule concat:
    """Concatentate the input fastq files"""
    input:
        forw=get_forward,
        rev=get_reverse,
        umi=get_umi,
    output:
        forw=temp("{sample}/concat/forward.fastq.gz"),
        rev=temp("{sample}/concat/reverse.fastq.gz"),
        umi=temp("{sample}/concat/umi.fastq.gz"),
    log:
        "log/{sample}_concat.txt",
    container:
        containers["debian"]
    shell:
        """
        mkdir -p $(dirname {output.forw})

        cp {input.forw} {output.forw} || cat {input.forw} > {output.forw}
        cp {input.rev} {output.rev} || cat {input.rev} > {output.rev}
        cp {input.umi} {output.umi} || cat {input.umi} > {output.umi}
        """


rule prepend_umi:
    """Prepend the UMI to the first read"""
    input:
        forw=rules.concat.output.forw,
        umi=rules.concat.output.umi,
        scr=srcdir("scripts/prepend_umi.py"),
    output:
        forw=temp("{sample}/concat/forward.calib.fastq.gz"),
    log:
        "log/{sample}_prepare_calib.txt",
    container:
        containers["dnaio"]
    shell:
        """
        python3 {input.scr} {input.umi} {input.forw} {output.forw}
        """


rule humid:
    """Run HUMID on the fastq files"""
    input:
        forw=rules.concat.output.forw,
        rev=rules.concat.output.rev,
        umi=rules.concat.output.umi,
    output:
        forw="{sample}/humid/forward_dedup.fastq.gz",
        rev="{sample}/humid/reverse_dedup.fastq.gz",
        umi="{sample}/humid/umi_dedup.fastq.gz",
        stats="{sample}/humid/stats.dat",
    log:
        "log/{sample}-humid.txt",
    benchmark:
        repeat("benchmarks/humid_{sample}.tsv", config["repeats"])
    container:
        containers["humid"]
    shell:
        """
        folder=$(dirname {output.forw})
        mkdir -p $folder

        humid \
            -d $folder \
            -s \
            {input.forw} {input.rev} {input.umi} 2> {log}
        """


rule calib:
    """Run Calib on the fastq files"""
    input:
        forw=rules.prepend_umi.output.forw,
        rev=rules.concat.output.rev,
    params:
        umi_length=8,
    output:
        cluster="{sample}/calib/cluster",
    log:
        "log/{sample}-calib.txt",
    benchmark:
        repeat("benchmarks/calib_{sample}.tsv", config["repeats"])
    container:
        containers["calib"]
    shell:
        """
        folder=$(dirname {output.cluster})
        mkdir -p $folder

        calib \
            --input-forward {input.forw} \
            --input-reverse {input.rev} \
            --barcode-length-1 {params.umi_length} \
            --barcode-length-2 0 \
            --gzip-input \
            --output-prefix $folder/ 2> {log}
        """
