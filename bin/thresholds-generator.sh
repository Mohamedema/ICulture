#!/bin/bash

# Function to display usage instructions
usage() {
    echo "Usage: $0 -o <output_csv>"
    echo
    echo "Required Parameters:"
    echo "  -o <output_csv>   Path to the output CSV file."
    echo
    echo "Example:"
    echo "  bash $0 -o thresholds.csv"
    exit 0
}

# Check for help flag
if [[ "$1" == "--help" ]]; then
    usage
fi

# Parse command-line arguments
while getopts "o:" opt; do
    case "$opt" in
        o) output_csv="$OPTARG" ;;
        *) usage ;;
    esac
done

# Validate arguments
if [ -z "$output_csv" ]; then
    usage
fi

# Function to validate that input contains only numbers between 0 and 100
validate_input() {
    local input="$1"
    IFS=',' read -r -a values <<< "$input"
    for value in "${values[@]}"; do
        if ! [[ "$value" =~ ^[0-9]+$ ]] || [ "$value" -lt 0 ] || [ "$value" -gt 100 ]; then
            echo "Error: All values must be numbers between 0 and 100."
            return 1
        fi
    done
    return 0
}

# Prompt the user for identities
while true; do
    echo "Enter identity thresholds as numbers between 0 and 100, separated by commas (e.g., 90,80,70):"
    read -r identities
    validate_input "$identities" && break
done

# Prompt the user for coverages
while true; do
    echo "Enter coverage thresholds as numbers between 0 and 100, separated by commas (e.g., 90,80,70):"
    read -r coverages
    validate_input "$coverages" && break
done

# Split the inputs into arrays
IFS=',' read -r -a identity_array <<< "$identities"
IFS=',' read -r -a coverage_array <<< "$coverages"

# Create or overwrite the output CSV file
echo "Identity,Coverage" > "$output_csv"

# Generate the CSV by combining identity and coverage thresholds
for identity in "${identity_array[@]}"; do
    for coverage in "${coverage_array[@]}"; do
        echo "$identity,$coverage" >> "$output_csv"
    done
done

echo "Thresholds CSV has been saved to $output_csv"
