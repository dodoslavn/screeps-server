#!/bin/bash

cd $(dirname $0)

. ./config.sh

./network.sh

./screeps.sh
