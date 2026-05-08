#!/bin/bash
# Multi-Fabric Design Validation Script
# Tests all designs across all fabric sizes to ensure portability

# set -e removed for resilience - script will catch individual build failures

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
WORKSPACE_ROOT="$SCRIPT_DIR/../.."
DESIGNS_DIR="$SCRIPT_DIR/designs"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
FABRICS=("classic_fabric_chipfoundry_small" "classic_fabric_chipfoundry_medium" "classic_fabric_chipfoundry_large")
TILE_LIBRARY="classic"

# Design groups
SIMPLE_DESIGNS=("addition" "all_ones" "all_zeros" "counter" "passthrough" "sys_reset")
COMPLEX_DESIGNS=("multiplication" "register_file" "macc_8x8_20" "ihp_sram_1024x32_1rw" "mem_1024x32_1rw")
MEMORY_DESIGNS=("ram_32x4_2r_1w")

# Design I/O requirements (estimated from port counts)
# These are approximate - if a design fails with "insufficient I/O",
# it means actual required pins > estimated. Update estimates accordingly.
declare -A DESIGN_IO_REQS=(
  ["addition"]=6          # 2 inputs + 1 output
  ["all_ones"]=28         # actual port is [27:0]
  ["all_zeros"]=28        # actual port is [27:0]  
  ["counter"]=11          # clock + reset + enable + 8-bit output
  ["passthrough"]=12      # input/output pass-through
  ["sys_reset"]=4         # minimal control signals
  ["multiplication"]=20   # 2 inputs + output
  ["register_file"]=30    # multi-port register file
  ["macc_8x8_20"]=27      # multiplier accumulator with 12-bit output + controls
  ["ihp_sram_1024x32_1rw"]=40   # 32-bit data + 10-bit address + control
  ["mem_1024x32_1rw"]=40   # similar to SRAM
  ["ram_32x4_2r_1w"]=28   # 5-bit addr (x2) + 2-bit addr + 4-bit data (x2) + control
)

# Fabric I/O capacities
declare -A FABRIC_IO_CAPACITY=(
  ["classic_fabric_chipfoundry_small"]=24
  ["classic_fabric_chipfoundry_medium"]=24
  ["classic_fabric_chipfoundry_large"]=48
)

# Results tracking
declare -A TEST_RESULTS
declare -A BUILD_TIMES
PASSED=0
FAILED=0
SKIPPED=0
TOTAL=0

# Helper functions
log_info() { echo -e "${BLUE}[INFO]${NC} $@"; }
log_pass() { echo -e "${GREEN}[PASS]${NC} $@"; }
log_fail() { echo -e "${RED}[FAIL]${NC} $@"; }
log_skip() { echo -e "${YELLOW}[SKIP]${NC} $@"; }
log_section() { echo -e "\n${BLUE}=== $@ ===${NC}\n"; }

# Tool check
check_tools() {
    local missing=0
    for tool in yosys nextpnr-generic python3; do
        if ! command -v $tool &> /dev/null; then
            log_fail "Tool '$tool' not found. Please ensure you are inside the nix-shell."
            missing=1
        fi
    done
    return $missing
}

# Check if a design fits in a fabric based on I/O requirements
can_design_fit() {
    local design=$1
    local fabric=$2
    local design_ios=${DESIGN_IO_REQS[$design]:-0}
    local fabric_capacity=${FABRIC_IO_CAPACITY[$fabric]:-0}
    
    if [ $design_ios -gt $fabric_capacity ]; then
        return 1  # Cannot fit
    fi
    return 0  # Can fit
}

# Build a design on a specific fabric
build_design() {
    local design=$1
    local fabric=$2
    local design_path="$DESIGNS_DIR/classic/$design"
    
    if [ ! -d "$design_path" ]; then
        log_skip "Design '$design' not found at $design_path"
        ((SKIPPED++))
        return 2
    fi
    
    local test_name="${design}@${fabric##*_}"
    ((TOTAL++))
    
    # Check I/O requirements
    if ! can_design_fit "$design" "$fabric"; then
        log_skip "$test_name - Insufficient I/O pins"
        ((SKIPPED++))
        TEST_RESULTS[$test_name]="SKIP (I/O: ${DESIGN_IO_REQS[$design]} > ${FABRIC_IO_CAPACITY[$fabric]})"
        return 0
    fi
    
    # Clean and build
    local start_time
    if date +%s%N &>/dev/null; then
        start_time=$(date +%s%N)
    else
        start_time=$(($(date +%s) * 1000000000))
    fi
    
    cd "$design_path"
    local local_log="build_log.txt"
    # timeout 300s prevents hanging on unroutable designs (common with register_file/sram)
    if FABRIC="$fabric" TILE_LIBRARY="$TILE_LIBRARY" timeout 300s make clean all &> "$local_log"; then
        local end_time
        if date +%s%N &>/dev/null; then
            end_time=$(date +%s%N)
        else
            end_time=$(($(date +%s) * 1000000000))
        fi
        local duration=$(( (end_time - start_time) / 1000000 ))  # Convert to ms
        
        log_pass "$test_name (${duration}ms)"
        ((PASSED++))
        TEST_RESULTS[$test_name]="PASS"
        BUILD_TIMES[$test_name]=$duration
    else
        local exit_code=$?
        log_fail "$test_name"
        ((FAILED++))
        TEST_RESULTS[$test_name]="FAIL"
        
        # Show error snippet
        if [ $exit_code -eq 124 ]; then
            echo "     Error: Build TIMED OUT after 300s (Design too large/unroutable)"
        elif [ -f "$local_log" ]; then
            echo "     Error snippet (last 15 lines):"
            tail -n 15 "$local_log" | sed 's/^/     > /'
            echo "     Full log: $design_path/$local_log"
        fi
    fi
    
    cd - &> /dev/null
    return 0
}

# Main test execution
run_tests() {
    log_section "FABulous Multi-Fabric Design Validation"
    echo "Workspace: $WORKSPACE_ROOT"
    echo "Designs: $DESIGNS_DIR"
    echo "Fabrics: ${#FABRICS[@]} sizes"
    echo "Test combinations: $(( (${#SIMPLE_DESIGNS[@]} + ${#COMPLEX_DESIGNS[@]} + ${#MEMORY_DESIGNS[@]}) * ${#FABRICS[@]} ))"
    
    # Test simple designs (should work on all fabrics)
    log_section "Testing Simple Designs (Expected: All Fabrics)"
    for design in "${SIMPLE_DESIGNS[@]}"; do
        for fabric in "${FABRICS[@]}"; do
            build_design "$design" "$fabric"
        done
    done
    
    # Test complex designs (may have I/O constraints)
    log_section "Testing Complex Designs (Expected: Large Fabric)"
    for design in "${COMPLEX_DESIGNS[@]}"; do
        for fabric in "${FABRICS[@]}"; do
            build_design "$design" "$fabric"
        done
    done
    
    # Test memory designs (likely to have I/O constraints)
    log_section "Testing Memory Designs (Expected: Selective)"
    for design in "${MEMORY_DESIGNS[@]}"; do
        for fabric in "${FABRICS[@]}"; do
            build_design "$design" "$fabric"
        done
    done
}

# Print summary report
print_summary() {
    log_section "Test Summary Report"
    
    echo "Total Tests:  $TOTAL"
    echo -e "Passed:       ${GREEN}$PASSED${NC}"
    echo -e "Failed:       ${RED}$FAILED${NC}"
    echo -e "Skipped:      ${YELLOW}$SKIPPED${NC}"
    echo ""
    
    if [ $FAILED -eq 0 ] && [ $PASSED -gt 0 ]; then
        echo -e "${GREEN}✅ All tests passed!${NC}"
    elif [ $FAILED -gt 0 ]; then
        echo -e "${RED}❌ Some tests failed. See details above.${NC}"
    fi
    
    # Detailed results table
    log_section "Detailed Results"
    printf "%-35s %-10s\n" "Test" "Result"
    printf "%-35s %-10s\n" "---" "---"
    
    for test in $(echo "${!TEST_RESULTS[@]}" | tr ' ' '\n' | sort); do
        local result=${TEST_RESULTS[$test]}
        if [[ $result == "PASS" ]]; then
            local time=${BUILD_TIMES[$test]:-0}
            printf "%-35s ${GREEN}%-10s${NC} (%dms)\n" "$test" "$result" "$time"
        elif [[ $result == "FAIL" ]]; then
            printf "%-35s ${RED}%-10s${NC}\n" "$test" "$result"
        else
            printf "%-35s ${YELLOW}%-10s${NC}\n" "$test" "$result"
        fi
    done
    
    # Compatibility matrix
    log_section "Design Compatibility Matrix"
    echo ""
    printf "%-20s %-10s %-10s %-10s\n" "Design" "Small" "Medium" "Large"
    printf "%-20s %-10s %-10s %-10s\n" "---" "---" "---" "---"
    
    for design in "${SIMPLE_DESIGNS[@]}" "${COMPLEX_DESIGNS[@]}" "${MEMORY_DESIGNS[@]}"; do
        local small_result="${TEST_RESULTS[${design}@small]:-UNKNOWN}"
        local medium_result="${TEST_RESULTS[${design}@medium]:-UNKNOWN}"
        local large_result="${TEST_RESULTS[${design}@large]:-UNKNOWN}"
        
        # Convert to symbol
        small_result=${small_result:0:1}
        medium_result=${medium_result:0:1}
        large_result=${large_result:0:1}
        
        printf "%-20s %-10s %-10s %-10s\n" "$design" "$small_result" "$medium_result" "$large_result"
    done
    
    echo ""
    echo "Legend:"
    echo -e "  P = ${GREEN}PASS${NC}, F = ${RED}FAIL${NC}, S = ${YELLOW}SKIP${NC}"
}

# Parse command line arguments
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

OPTIONS:
  -d, --design DESIGN    Test only a specific design
  -f, --fabric FABRIC    Test only a specific fabric
  -h, --help            Show this help message
  -s, --synth-only      Only run synthesis, skip PNR/bitstream
  
EXAMPLES:
  $0                              # Run full test suite
  $0 -d counter                   # Test counter design on all fabrics
  $0 -f small                     # Test all designs on small fabric
  $0 -d ram_32x4_2r_1w -f large   # Test specific design on specific fabric

EOF
}

# Main execution
main() {
    if ! check_tools; then
        exit 1
    fi

    if [ "$#" -eq 0 ]; then
        run_tests
        print_summary
    else
        echo "Arguments provided, but full argument parsing not yet implemented"
        echo "Showing help..."
        show_help
    fi
}

# Run main if script is executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
