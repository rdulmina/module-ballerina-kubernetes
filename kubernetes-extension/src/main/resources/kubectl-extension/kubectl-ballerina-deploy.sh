#!/bin/bash
# ---------------------------------------------------------------------------
#  Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

trap ctrl_c INT
trap on_error ERR

function ctrl_c() {
    echo "cancelling building/deploying"
    exit 2;
}

function on_error() {
    echo "error: unable to build or deploy due to error"
    exit 1;
 }

if [[ "$1" != "" ]]
then
    BALLERINA_CMD="ballerina"

    if ! type "$BALLERINA_CMD" > /dev/null 2>&1;
    then
        if ! [[ -z "$BALLERINA_HOME" ]] ; then
            BALLERINA_CMD="$BALLERINA_HOME/bin/$BALLERINA_CMD"
        else
            printf "error: unable to find \"ballerina\" command or BALLERINA_HOME environment variable\n"
            exit 1
        fi
    fi

    echo "> building ballerina source..."
    BAL_BUILD_OUTPUT="$(${BALLERINA_CMD} build $1)"
    echo "${BAL_BUILD_OUTPUT}"

    if [[ $? -eq 0 ]]; then
        HAS_COMMANDS=false
        echo "\n> deploying artifacts..."

        while read -r LINE; do
            if [[ $LINE == kubectl* ]] || [[ $LINE == oc* ]] ;
            then
                HAS_COMMANDS=true
                echo "\n$> $LINE"
                ${LINE}
            fi
        done <<< "$BAL_BUILD_OUTPUT"

        if [[ "$HAS_COMMANDS" = false ]] ; then
            echo "error: cannot find any artifacts to deploy"
            exit 1
        fi

        echo "\n> deployment complete!"
        exit 0
    fi
fi

echo "error: no ballerina source or module(s) provided to build"
exit 1