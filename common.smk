containers = {
    "debian": "docker://debian:latest",
    "humid": "docker://quay.io/biocontainers/humid:1.0.2--h5f740d0_0",
    "calib": "docker://quay.io/biocontainers/calib:0.3.4--hdcf5f25_5",
    # mulled container with dnaio=0.8.1 and pysam=0.19.0
    "dnaio": "docker://quay.io/biocontainers/mulled-v2-2996a7d035117c4238b2b801e740a69df21d91e1:6b3ae5f1a97f370227e8134ba3efc0e318b288c3-0",
    "pardre": "docker://quay.io/biocontainers/pardre:2.2.5--h6b557da_3",
}

default = dict()
default["repeat"] = 1
default["mismatch"] = 1
default["umi_length"] = 8


pepfile: config["pepfile"]


# Apply the settings from the pepfile, overwriting the default ones
default.update(pep.config.get("test-umi-deduplication", dict()))

# Apply the options specified to snakemake, overwriting the default settings
# and the settings from the PEP file
default.update(config)

# Set the updated dict as the configuration for the pipeline
config = default

# Make sample names easily accessible
samples = sorted(list(pep.sample_table.sample_name))
tools = ["humid", "pardre", "calib"]


def get_fastq(wildcards, column):
    fastq = pep.sample_table.loc[wildcards.sample, column]

    # If a single fastq file is specified, forward will be a string
    if isinstance(fastq, str):
        return [fastq]
    # If multiple fastq files were specified, forward will be a list
    else:
        return fastq


def get_forward(wildcards):
    return get_fastq(wildcards, "forward")


def get_reverse(wildcards):
    return get_fastq(wildcards, "reverse")


def get_umi(wildcards):
    return get_fastq(wildcards, "umi")


def get_benchmarks():
    return expand(
        "benchmarks/{tool}_{sample}.tsv",
        sample=samples, tool=tools
    )

def get_humid_stats():
    return expand(
        "{sample}/humid/stats.dat",
        sample=samples
    )
