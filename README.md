# Benchmarking-Multi-Tenant-Architectures-in-PostgreSQL


## Prerequisits

* Have a Kubernetes cluster to carry the experiments
* Have a computer with Python and bash to run the orchestrator
* Have `kubectl` working to connect to the cluster

## Installation

1. `pip install bexhoma==0.8.13` to prepare a Python environment with all dependencies
1. Clone https://github.com/Beuth-Erdelt/Benchmark-Experiment-Host-Manager (version 0.8.13) for config files
1. Follow the instructions given there to make bexhoma working. This in particular means adjust [configuration](https://bexhoma.readthedocs.io/en/latest/Config.html)
    1. Copy `k8s-cluster.config` to `cluster.config`
    1. Set name of context, namespace and name of cluster in that file
    1. Make sure the `resultfolder` is set to a folder that exists on your local filesystem
1. copy this repository into the cloned directory to overwrite some manifests and configs

## Run the Experiments

See script to run experiments from bash.
Warning: It takes weeks (!) to run all experiments completely.

## Evaluate Experiments

Each experiment generates a results folder.
This folder primarily contains raw data from the experiment, including performance metrics, hardware measurements, and component logs.
Bexhoma provides a Python interface for convenient handling and analysis of this data.

Install Jupyter `conda install jupyter` to run the notebooks.
