# Benchmarking-Multi-Tenant-Architectures-in-PostgreSQL

This repository contains the source code used to reproduce the examples presented in the paper.

## Prerequisits

* Have a Kubernetes cluster to carry the experiments
* Have a computer with Python and bash to run the orchestrator
* Have `kubectl` working to connect to the cluster

We recommend to use a Python environment like `conda create -n bexhoma python==3.11.9 ipython`.

## Installation

1. `pip install bexhoma==0.8.13` to prepare a Python environment with all dependencies
1. Clone https://github.com/Beuth-Erdelt/Benchmark-Experiment-Host-Manager (version [0.8.13](https://github.com/Beuth-Erdelt/Benchmark-Experiment-Host-Manager/releases/tag/v0.8.13)) for config files
1. Copy this repository into the cloned directory to overwrite some manifests and configs
1. Follow the instructions to make bexhoma working. This in particular means adjust [configuration](https://bexhoma.readthedocs.io/en/latest/Config.html)
    1. Copy `k8s-cluster.config` to `cluster.config`
    1. Set name of context, namespace and name of cluster in that file
    1. Make sure the `resultfolder` is set to a folder that exists on your local filesystem

## Run the Experiments

See [script](experiments.sh) to run experiments from bash.

Warning: It takes weeks (!) to run all experiments completely.

Note: The provided script does not configure the [Kubernetes CPUManager Policy](https://kubernetes.io/blog/2024/08/22/cpumanager-static-policy-distributed-cpu-across-cores/), as this setting cannot be modified from the client side.
Please refer to the official Kubernetes documentation for instructions on configuring this policy.

## Evaluate Experiments

Each experiment produces a dedicated results directory containing the raw data, including performance metrics, hardware measurements, and component logs.
Bexhoma provides a Python interface for efficient access and analysis of this data.
Jupyter (`conda install jupyter`) can be used to open the accompanying notebooks, which illustrate the code used to generate the plots presented in the paper.

