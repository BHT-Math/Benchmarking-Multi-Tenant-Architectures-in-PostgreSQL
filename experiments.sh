#!/usr/bin/env bash

######################################################################################
# Bash Script for Multi-Tenancy Experiments in PostgreSQL
######################################################################################
#
# This scripts starts a sequence of experiments with varying parameters.
# Each experiment waits until previous tests have been completed.
# Logs are written to a log folder.
# At the end, logs are cleaned and the summaries are extracted and stored in separate files.
#
# Author: Patrick K. Erdelt
# Email: patrick.erdelt@bht-berlin.de
# Date: 2025-10-01
# Version: 1.0
######################################################################################


# Import functions from testfunctions.sh
source ./testfunctions.sh

BEXHOMA_NODE_SUT="cl-worker11"
BEXHOMA_NODE_LOAD="cl-worker19"
BEXHOMA_NODE_BENCHMARK="cl-worker19"
LOG_DIR="./logs_multitenant"

BEXHOMA_DURATION=10
BEXHOMA_TARGET=65536
BEXHOMA_SF=10
BEXHOMA_THREADS=$((BEXHOMA_SF * 10))
BEXHOMA_CPU=40
BEXHOMA_RAM=200


if ! prepare_logs; then
    echo "Error: prepare_logs failed with code $?"
    exit 1
fi



###########################################
############# TPC-C with PVC ##############
###########################################
# Make sure: fsync=on
sed -i 's/fsync=off/fsync=on/' k8s/deploymenttemplate-PostgreSQL.yml
# Make sure: synchronous_commit=off
sed -i 's/synchronous_commit=on/synchronous_commit=off/' k8s/deploymenttemplate-PostgreSQL.yml
# Make sure: random_page_cost=60
sed -i 's/random_page_cost=1/random_page_cost=60/' k8s/deploymenttemplate-PostgreSQL.yml

experiment_extension="01_pvc"

for i in {1..2}; do
    # Set local variables
    BEXHOMA_TENANTS=$i
    tenants=$BEXHOMA_TENANTS
    sizeInGi=$((tenants * 50))
    BEXHOMA_SIZE_ALL="${sizeInGi}Gi"

    # Calculate RAM and CPU per tenant
    ramPerTenant=$((BEXHOMA_RAM / tenants))
    cpuPerTenant=$((BEXHOMA_CPU / tenants))

    BEXHOMA_LIMIT_RAM="${ramPerTenant}Gi"
    BEXHOMA_LIMIT_RAM_TOTAL="${BEXHOMA_RAM}Gi"

    # Schema mode
    schemaLog="$LOG_DIR/test_benchbase_run_postgresql_tenants_${experiment_extension}_schema_${tenants}.log"
    python ./benchbase.py run -rc 0 -rr "$BEXHOMA_LIMIT_RAM_TOTAL" -lc 0 -lr "$BEXHOMA_LIMIT_RAM_TOTAL" -m -mc \
        -tb "$BEXHOMA_TARGET" -sf "$BEXHOMA_SF" -sd "$BEXHOMA_DURATION" \
        --dbms PostgreSQL \
        -rnn "$BEXHOMA_NODE_SUT" \
        -rnl "$BEXHOMA_NODE_LOAD" \
        -rnb "$BEXHOMA_NODE_BENCHMARK" \
        -nlp 1 -nlt "$BEXHOMA_THREADS" -nbp 1 -nbt "$BEXHOMA_THREADS" \
        -ne "${tenants},${tenants}" \
        -mtn "$tenants" -mtb schema \
        -rst shared -rss "$BEXHOMA_SIZE_ALL" -rsr \
        > "$schemaLog" 2>&1

    bexperiments stop

    # Database mode
    dbLog="$LOG_DIR/test_benchbase_run_postgresql_tenants_${experiment_extension}_database_${tenants}.log"
    python ./benchbase.py run -rc 0 -rr "$BEXHOMA_LIMIT_RAM_TOTAL" -lc 0 -lr "$BEXHOMA_LIMIT_RAM_TOTAL" -m -mc \
        -tb "$BEXHOMA_TARGET" -sf "$BEXHOMA_SF" -sd "$BEXHOMA_DURATION" \
        --dbms PostgreSQL \
        -rnn "$BEXHOMA_NODE_SUT" \
        -rnl "$BEXHOMA_NODE_LOAD" \
        -rnb "$BEXHOMA_NODE_BENCHMARK" \
        -nlp 1 -nlt "$BEXHOMA_THREADS" -nbp 1 -nbt "$BEXHOMA_THREADS" \
        -ne "${tenants},${tenants}" \
        -mtn "$tenants" -mtb database \
        -rst shared -rss "$BEXHOMA_SIZE_ALL" -rsr \
        > "$dbLog" 2>&1

    bexperiments stop

    # Container mode (fixed 50Gi size)
    containerLog="$LOG_DIR/test_benchbase_run_postgresql_tenants_${experiment_extension}_container_${tenants}.log"
    python ./benchbase.py run -rc 0 -rr "$BEXHOMA_LIMIT_RAM" -lc 0 -lr "$BEXHOMA_LIMIT_RAM" -m -mc \
        -tb "$BEXHOMA_TARGET" -sf "$BEXHOMA_SF" -sd "$BEXHOMA_DURATION" \
        --dbms PostgreSQL \
        -rnn "$BEXHOMA_NODE_SUT" \
        -rnl "$BEXHOMA_NODE_LOAD" \
        -rnb "$BEXHOMA_NODE_BENCHMARK" \
        -nlp 1 -nlt "$BEXHOMA_THREADS" -nbp 1 -nbt "$BEXHOMA_THREADS" \
        -ne 1,1 \
        -mtn "$tenants" -mtb container \
        -rst shared -rss 50Gi -rsr \
        > "$containerLog" 2>&1

    bexperiments stop

    clean_logs
done



###########################################
########### TPC-C without PVC #############
###########################################
# Make sure: fsync=on
sed -i 's/fsync=off/fsync=on/' k8s/deploymenttemplate-PostgreSQL.yml
# Make sure: synchronous_commit=off
sed -i 's/synchronous_commit=on/synchronous_commit=off/' k8s/deploymenttemplate-PostgreSQL.yml
# Make sure: random_page_cost=60
sed -i 's/random_page_cost=1/random_page_cost=60/' k8s/deploymenttemplate-PostgreSQL.yml

experiment_extension="02_local"

for i in {1..2}; do
    # Set local variables
    BEXHOMA_TENANTS=$i
    tenants=$BEXHOMA_TENANTS
    sizeInGi=$((tenants * 50))
    BEXHOMA_SIZE_ALL="${sizeInGi}Gi"

    # Calculate RAM and CPU per tenant
    ramPerTenant=$((BEXHOMA_RAM / tenants))
    cpuPerTenant=$((BEXHOMA_CPU / tenants))

    BEXHOMA_LIMIT_RAM="${ramPerTenant}Gi"
    BEXHOMA_LIMIT_RAM_TOTAL="${BEXHOMA_RAM}Gi"

    # Schema mode
    schemaLog="$LOG_DIR/test_benchbase_run_postgresql_tenants_${experiment_extension}_schema_${tenants}.log"
    python ./benchbase.py run -rc 0 -rr "$BEXHOMA_LIMIT_RAM_TOTAL" -lc 0 -lr "$BEXHOMA_LIMIT_RAM_TOTAL" -m -mc \
        -tb "$BEXHOMA_TARGET" -sf "$BEXHOMA_SF" -sd "$BEXHOMA_DURATION" \
        --dbms PostgreSQL \
        -rnn "$BEXHOMA_NODE_SUT" \
        -rnl "$BEXHOMA_NODE_LOAD" \
        -rnb "$BEXHOMA_NODE_BENCHMARK" \
        -nlp 1 -nlt "$BEXHOMA_THREADS" -nbp 1 -nbt "$BEXHOMA_THREADS" \
        -ne "${tenants},${tenants}" \
        -mtn "$tenants" -mtb schema \
        > "$schemaLog" 2>&1

    bexperiments stop

    # Database mode
    dbLog="$LOG_DIR/test_benchbase_run_postgresql_tenants_${experiment_extension}_database_${tenants}.log"
    python ./benchbase.py run -rc 0 -rr "$BEXHOMA_LIMIT_RAM_TOTAL" -lc 0 -lr "$BEXHOMA_LIMIT_RAM_TOTAL" -m -mc \
        -tb "$BEXHOMA_TARGET" -sf "$BEXHOMA_SF" -sd "$BEXHOMA_DURATION" \
        --dbms PostgreSQL \
        -rnn "$BEXHOMA_NODE_SUT" \
        -rnl "$BEXHOMA_NODE_LOAD" \
        -rnb "$BEXHOMA_NODE_BENCHMARK" \
        -nlp 1 -nlt "$BEXHOMA_THREADS" -nbp 1 -nbt "$BEXHOMA_THREADS" \
        -ne "${tenants},${tenants}" \
        -mtn "$tenants" -mtb database \
        > "$dbLog" 2>&1

    bexperiments stop

    # Container mode (fixed 50Gi size)
    containerLog="$LOG_DIR/test_benchbase_run_postgresql_tenants_${experiment_extension}_container_${tenants}.log"
    python ./benchbase.py run -rc 0 -rr "$BEXHOMA_LIMIT_RAM" -lc 0 -lr "$BEXHOMA_LIMIT_RAM" -m -mc \
        -tb "$BEXHOMA_TARGET" -sf "$BEXHOMA_SF" -sd "$BEXHOMA_DURATION" \
        --dbms PostgreSQL \
        -rnn "$BEXHOMA_NODE_SUT" \
        -rnl "$BEXHOMA_NODE_LOAD" \
        -rnb "$BEXHOMA_NODE_BENCHMARK" \
        -nlp 1 -nlt "$BEXHOMA_THREADS" -nbp 1 -nbt "$BEXHOMA_THREADS" \
        -ne 1,1 \
        -mtn "$tenants" -mtb container \
        > "$containerLog" 2>&1

    bexperiments stop

    clean_logs
done










###########################################
######### TPC-C durable ramdisk ###########
###########################################
# Make sure: fsync=on
sed -i 's/fsync=off/fsync=on/' k8s/deploymenttemplate-PostgreSQL.yml
# Make sure: synchronous_commit=on
sed -i 's/synchronous_commit=off/synchronous_commit=on/' k8s/deploymenttemplate-PostgreSQL.yml
# Make sure: random_page_cost=1
sed -i 's/random_page_cost=60/random_page_cost=1/' k8s/deploymenttemplate-PostgreSQL.yml

experiment_extension="04_ramdisk"

for i in {1..2}; do
    # Set local variables
    BEXHOMA_TENANTS=$i
    tenants=$BEXHOMA_TENANTS
    sizeInGi=$((tenants * 50))
    BEXHOMA_SIZE_ALL="${sizeInGi}Gi"

    # Calculate RAM and CPU per tenant
    ramPerTenant=$((BEXHOMA_RAM / tenants))
    cpuPerTenant=$((BEXHOMA_CPU / tenants))

    BEXHOMA_LIMIT_RAM="${ramPerTenant}Gi"
    BEXHOMA_LIMIT_RAM_TOTAL="${BEXHOMA_RAM}Gi"

    # Schema mode
    schemaLog="$LOG_DIR/test_benchbase_run_postgresql_tenants_${experiment_extension}_schema_${tenants}.log"
    python ./benchbase.py run -rc 0 -rr "$BEXHOMA_LIMIT_RAM_TOTAL" -lc 0 -lr "$BEXHOMA_LIMIT_RAM_TOTAL" -m -mc \
        -tb "$BEXHOMA_TARGET" -sf "$BEXHOMA_SF" -sd "$BEXHOMA_DURATION" \
        --dbms PostgreSQL \
        -rnn "$BEXHOMA_NODE_SUT" \
        -rnl "$BEXHOMA_NODE_LOAD" \
        -rnb "$BEXHOMA_NODE_BENCHMARK" \
        -nlp 1 -nlt "$BEXHOMA_THREADS" -nbp 1 -nbt "$BEXHOMA_THREADS" \
        -ne "${tenants},${tenants}" \
        -mtn "$tenants" -mtb schema \
        -rst ramdisk -rss "$BEXHOMA_SIZE_ALL" -rsr \
        > "$schemaLog" 2>&1

    bexperiments stop

    # Database mode
    dbLog="$LOG_DIR/test_benchbase_run_postgresql_tenants_${experiment_extension}_database_${tenants}.log"
    python ./benchbase.py run -rc 0 -rr "$BEXHOMA_LIMIT_RAM_TOTAL" -lc 0 -lr "$BEXHOMA_LIMIT_RAM_TOTAL" -m -mc \
        -tb "$BEXHOMA_TARGET" -sf "$BEXHOMA_SF" -sd "$BEXHOMA_DURATION" \
        --dbms PostgreSQL \
        -rnn "$BEXHOMA_NODE_SUT" \
        -rnl "$BEXHOMA_NODE_LOAD" \
        -rnb "$BEXHOMA_NODE_BENCHMARK" \
        -nlp 1 -nlt "$BEXHOMA_THREADS" -nbp 1 -nbt "$BEXHOMA_THREADS" \
        -ne "${tenants},${tenants}" \
        -mtn "$tenants" -mtb database \
        -rst ramdisk -rss "$BEXHOMA_SIZE_ALL" -rsr \
        > "$dbLog" 2>&1

    bexperiments stop

    # Container mode (fixed 50Gi size)
    containerLog="$LOG_DIR/test_benchbase_run_postgresql_tenants_${experiment_extension}_container_${tenants}.log"
    python ./benchbase.py run -rc 0 -rr "$BEXHOMA_LIMIT_RAM" -lc 0 -lr "$BEXHOMA_LIMIT_RAM" -m -mc \
        -tb "$BEXHOMA_TARGET" -sf "$BEXHOMA_SF" -sd "$BEXHOMA_DURATION" \
        --dbms PostgreSQL \
        -rnn "$BEXHOMA_NODE_SUT" \
        -rnl "$BEXHOMA_NODE_LOAD" \
        -rnb "$BEXHOMA_NODE_BENCHMARK" \
        -nlp 1 -nlt "$BEXHOMA_THREADS" -nbp 1 -nbt "$BEXHOMA_THREADS" \
        -ne 1,1 \
        -mtn "$tenants" -mtb container \
        -rst ramdisk -rss 50Gi -rsr \
        > "$containerLog" 2>&1

    bexperiments stop

    clean_logs
done





###########################################
########### TPC-C durable local ###########
###########################################
# Make sure: fsync=on
sed -i 's/fsync=off/fsync=on/' k8s/deploymenttemplate-PostgreSQL.yml
# Make sure: synchronous_commit=on
sed -i 's/synchronous_commit=off/synchronous_commit=on/' k8s/deploymenttemplate-PostgreSQL.yml
# Make sure: random_page_cost=1
sed -i 's/random_page_cost=60/random_page_cost=1/' k8s/deploymenttemplate-PostgreSQL.yml

experiment_extension="05_localdurable"

for i in {1..2}; do
    # Set local variables
    BEXHOMA_TENANTS=$i
    tenants=$BEXHOMA_TENANTS
    sizeInGi=$((tenants * 50))
    BEXHOMA_SIZE_ALL="${sizeInGi}Gi"

    # Calculate RAM and CPU per tenant
    ramPerTenant=$((BEXHOMA_RAM / tenants))
    cpuPerTenant=$((BEXHOMA_CPU / tenants))

    BEXHOMA_LIMIT_RAM="${ramPerTenant}Gi"
    BEXHOMA_LIMIT_RAM_TOTAL="${BEXHOMA_RAM}Gi"

    # Schema mode
    schemaLog="$LOG_DIR/test_benchbase_run_postgresql_tenants_${experiment_extension}_schema_${tenants}.log"
    python ./benchbase.py run -rc 0 -rr "$BEXHOMA_LIMIT_RAM_TOTAL" -lc 0 -lr "$BEXHOMA_LIMIT_RAM_TOTAL" -m -mc \
        -tb "$BEXHOMA_TARGET" -sf "$BEXHOMA_SF" -sd "$BEXHOMA_DURATION" \
        --dbms PostgreSQL \
        -rnn "$BEXHOMA_NODE_SUT" \
        -rnl "$BEXHOMA_NODE_LOAD" \
        -rnb "$BEXHOMA_NODE_BENCHMARK" \
        -nlp 1 -nlt "$BEXHOMA_THREADS" -nbp 1 -nbt "$BEXHOMA_THREADS" \
        -ne "${tenants},${tenants}" \
        -mtn "$tenants" -mtb schema \
        > "$schemaLog" 2>&1

    bexperiments stop

    # Database mode
    dbLog="$LOG_DIR/test_benchbase_run_postgresql_tenants_${experiment_extension}_database_${tenants}.log"
    python ./benchbase.py run -rc 0 -rr "$BEXHOMA_LIMIT_RAM_TOTAL" -lc 0 -lr "$BEXHOMA_LIMIT_RAM_TOTAL" -m -mc \
        -tb "$BEXHOMA_TARGET" -sf "$BEXHOMA_SF" -sd "$BEXHOMA_DURATION" \
        --dbms PostgreSQL \
        -rnn "$BEXHOMA_NODE_SUT" \
        -rnl "$BEXHOMA_NODE_LOAD" \
        -rnb "$BEXHOMA_NODE_BENCHMARK" \
        -nlp 1 -nlt "$BEXHOMA_THREADS" -nbp 1 -nbt "$BEXHOMA_THREADS" \
        -ne "${tenants},${tenants}" \
        -mtn "$tenants" -mtb database \
        > "$dbLog" 2>&1

    bexperiments stop

    # Container mode (fixed 50Gi size)
    containerLog="$LOG_DIR/test_benchbase_run_postgresql_tenants_${experiment_extension}_container_${tenants}.log"
    python ./benchbase.py run -rc 0 -rr "$BEXHOMA_LIMIT_RAM" -lc 0 -lr "$BEXHOMA_LIMIT_RAM" -m -mc \
        -tb "$BEXHOMA_TARGET" -sf "$BEXHOMA_SF" -sd "$BEXHOMA_DURATION" \
        --dbms PostgreSQL \
        -rnn "$BEXHOMA_NODE_SUT" \
        -rnl "$BEXHOMA_NODE_LOAD" \
        -rnb "$BEXHOMA_NODE_BENCHMARK" \
        -nlp 1 -nlt "$BEXHOMA_THREADS" -nbp 1 -nbt "$BEXHOMA_THREADS" \
        -ne 1,1 \
        -mtn "$tenants" -mtb container \
        > "$containerLog" 2>&1

    bexperiments stop

    clean_logs
done






###########################################
############# TPC-H with PVC ##############
###########################################
# Make sure: fsync=on
sed -i 's/fsync=off/fsync=on/' k8s/deploymenttemplate-PostgreSQL.yml
# Make sure: synchronous_commit=off
sed -i 's/synchronous_commit=on/synchronous_commit=off/' k8s/deploymenttemplate-PostgreSQL.yml
# Make sure: random_page_cost=60
sed -i 's/random_page_cost=1/random_page_cost=60/' k8s/deploymenttemplate-PostgreSQL.yml

experiment_extension="06_pvc"

BEXHOMA_SF=10
BEXHOMA_NUM_RUN=5
BEXHOMA_CPU=40
BEXHOMA_RAM=480

for i in {1..2}; do
    # Set local variables
    BEXHOMA_TENANTS=$i
    tenants=$BEXHOMA_TENANTS
    sizeInGi=$((tenants * 50))
    BEXHOMA_SIZE_ALL="${sizeInGi}Gi"

    # Calculate RAM and CPU per tenant
    ramPerTenant=$((BEXHOMA_RAM / tenants))
    cpuPerTenant=$((BEXHOMA_CPU / tenants))

    BEXHOMA_LIMIT_RAM="${ramPerTenant}Gi"
    BEXHOMA_LIMIT_RAM_TOTAL="${BEXHOMA_RAM}Gi"

    # Schema mode
    schemaLog="$LOG_DIR/test_tpch_run_postgresql_tenants_${experiment_extension}_schema_${tenants}.log"
    python tpch.py run -rc 0 -rr "$BEXHOMA_LIMIT_RAM_TOTAL" -lc 0 -lr "$BEXHOMA_LIMIT_RAM_TOTAL" -m -mc -rcp -shq -t 3600 -nr "$BEXHOMA_NUM_RUN" \
        -mtn "$tenants" -mtb schema \
        -sf "$BEXHOMA_SF" \
        --dbms PostgreSQL \
        -ii -ic -is \
        -nlp "$tenants" -nbp 1 \
        -ne "${tenants},${tenants}" \
        -rnn "$BEXHOMA_NODE_SUT" -rnl "$BEXHOMA_NODE_LOAD" -rnb "$BEXHOMA_NODE_BENCHMARK" \
        -rst shared -rss "$BEXHOMA_SIZE_ALL" -rsr \
        > "$schemaLog" 2>&1

    bexperiments stop

    # Database mode
    dbLog="$LOG_DIR/test_tpch_run_postgresql_tenants_${experiment_extension}_database_${tenants}.log"
    python tpch.py run -rc 0 -rr "$BEXHOMA_LIMIT_RAM_TOTAL" -lc 0 -lr "$BEXHOMA_LIMIT_RAM_TOTAL" -m -mc -rcp -shq -t 3600 -nr "$BEXHOMA_NUM_RUN" \
        -mtn "$tenants" -mtb database \
        -sf "$BEXHOMA_SF" \
        --dbms PostgreSQL \
        -ii -ic -is \
        -nlp "$tenants" -nbp 1 \
        -ne "${tenants},${tenants}" \
        -rnn "$BEXHOMA_NODE_SUT" -rnl "$BEXHOMA_NODE_LOAD" -rnb "$BEXHOMA_NODE_BENCHMARK" \
        -rst shared -rss "$BEXHOMA_SIZE_ALL" -rsr \
        > "$dbLog" 2>&1

    bexperiments stop

    # Container mode (fixed 50Gi size)
    containerLog="$LOG_DIR/test_tpch_run_postgresql_tenants_${experiment_extension}_container_${tenants}.log"
    python tpch.py run -rc 0 -rr "$BEXHOMA_LIMIT_RAM" -lc 0 -lr "$BEXHOMA_LIMIT_RAM" -m -mc -rcp -shq -t 3600 -nr "$BEXHOMA_NUM_RUN" \
        -mtn "$tenants" -mtb container \
        -sf "$BEXHOMA_SF" \
        --dbms PostgreSQL \
        -ii -ic -is \
        -nlp 1 -nbp 1 \
        -ne 1,1 \
        -rnn "$BEXHOMA_NODE_SUT" -rnl "$BEXHOMA_NODE_LOAD" -rnb "$BEXHOMA_NODE_BENCHMARK" \
        -rst shared -rss "50Gi" -rsr \
        > "$containerLog" 2>&1

    bexperiments stop

    clean_logs
done
