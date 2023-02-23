#!/bin/bash
# Copyright 2023, NVIDIA CORPORATION & AFFILIATES. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#  * Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#  * Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#  * Neither the name of NVIDIA CORPORATION nor the names of its
#    contributors may be used to endorse or promote products derived
#    from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ``AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
# OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
FASTERTRANSFORMER_BRANCH_TAG=${FASTERTRANSFORMER_BRANCH_TAG:="main"}
FASTERTRANSFORMER_BRANCH=${FASTERTRANSFORMER_BRANCH:="https://github.com/triton-inference-server/fastertransformer_backend.git"}
SERVER_TIMEOUT=600
SERVER_LOG_BASE="./inference_server"
CLIENT_LOG_BASE="./client"

MODELDIR=${MODELDIR:=`pwd`/models}
TRITON_DIR=${TRITON_DIR:="/opt/tritonserver"}
SERVER=${TRITON_DIR}/bin/tritonserver
BACKEND_DIR=${TRITON_DIR}/backends
SERVER_ARGS_EXTRA="--exit-timeout-secs=${SERVER_TIMEOUT} --backend-directory=${BACKEND_DIR}"
SERVER_ARGS="--model-repository=${MODELDIR} ${SERVER_ARGS_EXTRA}"
source ../common/util.sh

rm -f $SERVER_LOG_BASE* $CLIENT_LOG_BASE*

RET=0

mkdir ${MODELDIR}
# Clone repo
git clone --single-branch --depth=1 -b ${FASTERTRANSFORMER_BRANCH_TAG} ${FASTERTRANSFORMER_BRANCH}
cp -r fastertransformer_backend/all_models/t5 models/*
SERVER_LOG=$SERVER_LOG_BASE.log
CLIENT_LOG=$CLIENT_LOG_BASE.log

run_server

# in separate container
python3 tools/issue_request.py tools/requests/sample_request_single_t5.json > $CLIENT_LOG 2>&1
if [ $? -ne 0 ]; then
    cat $CLIENT_LOG
    RET=1
fi

kill_server

if [ $RET -eq 0 ]; then
  echo -e "\n***\n*** Test Passed\n***"
else
    cat $SERVER_LOG
    cat $CLIENT_LOG
    echo -e "\n***\n*** Test FAILED\n***"
fi

exit $RET
