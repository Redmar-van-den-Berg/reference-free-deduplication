#!/usr/bin/env python3
import argparse
from collections import defaultdict
from statistics import mean

def parse_humid(fname):
    with open(fname) as fin:
        for line in fin:
            if line.startswith("total"):
                total = int(line.strip('\n').split(' ')[1])
            if line.startswith("clusters"):
                clusters = int(line.strip('\n').split(' ')[1])
    return total, round(clusters/total, 3)

def average_benchmark(fname):
    """Read the benchmark results and return the average"""
    values = defaultdict(list)
    with open (fname) as fin:
        header = next(fin).strip('\n').split('\t')
        for line in fin:
            d = {k: v for k, v in zip(header, line.strip('\n').split('\t'))}
            # This value is anoying to work with, use 's' instead
            d.pop('h:m:s')
            for k, v in d.items():
                values[k].append(float(v))

    return {k: round(mean(v), 3) for k, v in values.items()}


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("--samples", nargs='+', help="samples")
    parser.add_argument("--tools", nargs='+', help="tools")

    args = parser.parse_args()

    header = "reads duplication tool s max_rss max_vms max_uss max_pss io_in io_out mean_load cpu_time".split()
    print(*header, sep='\t')
    for sample in args.samples:
        for tool in args.tools:
            # Used to get the number of reads, and fraction of duplicates
            humid_stats = f"{sample}/humid/stats.dat"
            nr_reads, duplication = parse_humid(humid_stats)

            benchmark_file = f"benchmarks/{tool}_{sample}.tsv"
            benchmark_results = average_benchmark(benchmark_file)

            # Add the sample duplication stats from HUMID
            benchmark_results["reads"] = nr_reads
            benchmark_results["duplication"] = duplication

            # Add the tool name
            benchmark_results["tool"] = tool

            print(*(benchmark_results[field] for field in header), sep='\t')
