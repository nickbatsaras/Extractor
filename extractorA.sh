#!/bin/bash

##
#
# Extractor
# =========
# 
#
# This script is used for the purposes of CS-240 (Data Structures) at
# University of Crete, Computer Science Department.
#
# The main goal is to automate the process of:
#   1) Extracting all the student submitted projects
#   2) Classify them based on what programming language was used
#   3) Re-structure the directory tree of the extracted and classified projects
#   4) In case a student re-submits the 1rst phase of the project
#      at phase 2, take into account the latter submission for phase 1
#
#
# @file   extractorA.sh
#
# @author Nick Batsaras <nickbatsaras@gmail.com>
#
# @desc   A script to extract a group of .tgz files and classify them based on
#         the source files they contain.
#
# TODOs:
#    1. Add support for more extensions
#    2. Add support for regular expressions
#
##


##
# Prints usage/help message and terminates script
##
usage() {
    echo
    echo "Usage:"
    echo "      ./extractorA.sh -i <input-dir> -o <output-dir> [-h]"
    echo
    echo "Options:"
    echo "      -i   Directory with compressed projects"
    echo "      -o   Directory to hold output"
    echo "      -h   Show usage"
    echo

    exit 1
}


##
# Includes the script for the restructure function
##
source ~/Extractor/restructure.sh


##
# Searches each directory for files with specific extensions (.c, .java, etc)
# and classifies it based on the files it contains.
#
# If directory contains .c files, it goes to a C/ directory
# If directory contains .java files, it goes to a Java/ directory
# ...
#
# Then, proceeds to call restructure to re-structure the classified
# directory.
#
# @param $1 The programming language
# @param $2 The input directory
# @param $3 The output directory
##
classify() {
    cd "$2"
    for dir in ./*/
    do
        local dir=${dir%*/}
        cd "$dir"

        local files=(`find . -name "${sources[$1]}"`)
        if [ ${#files[@]} -gt 0 ]
        then
            cd ".."
            mv "$dir" "$3/$1"
            continue
        fi

        cd ".."
    done

    restructure "$1" "$3"
}

inputdir=""
outputdir=""

# Parse command-line arguments
while getopts ":i:o:h" opt
do
    case $opt in
        i) 
            if [ ! -d "$OPTARG" ]
            then
                echo "ERROR: Directory $OPTARG does not exist" >&2
                exit 1
            fi
            curr_dir="`pwd`"; cd "$OPTARG"
            inputdir="`pwd`"; cd "$curr_dir"
            ;; 
        o) 
            if [ ! -d "$OPTARG" ]
            then
                echo "ERROR: Directory $OPTARG does not exist" >&2
                exit 1
            fi
            curr_dir="`pwd`"; cd "$OPTARG"
            outputdir="`pwd`"; cd "$curr_dir"
            ;;
       \?)
            echo "ERROR: Invalid option: -$OPTARG" >&2; usage;;
        :)
            echo "ERROR: Option -$OPTARG requires an argument." >&2; usage;;
        h | *)
            usage;;
    esac
done

# Check if input/output options were specified
if [ "$inputdir" = "" ]
then
    echo "ERROR: Missing input directory" >&2
    check=1
fi

if [ "$outputdir" = "" ]
then
    echo "ERROR: Missing output directory" >&2
    check=1
fi

if [ ! -z $check ]; then usage; fi

declare -A sources=(["C"]="*.c" ["C++"]="*.cpp" ["Java"]="*.java")
declare -A headers=(["C"]="*.h" ["C++"]="*.h"   ["Java"]="*.java")

# Extract all .tgz files inside input directory
cd "$inputdir"
for file in *.tgz
do
    exdir="${file%%.*}"
    mkdir "$exdir" 2> /dev/null
    tar xzf "$file" -C "$exdir"
done

# Create directories for classified output
mkdir "$outputdir/C"
mkdir "$outputdir/C++"
mkdir "$outputdir/Java"

# Classify extracted directories
classify "C"    "$inputdir" "$outputdir"
classify "C++"  "$inputdir" "$outputdir"
classify "Java" "$inputdir" "$outputdir"