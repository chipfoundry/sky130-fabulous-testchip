#!/bin/bash
# Simplified multi-fabric test script
# Tests each design on each fabric and reports results

FABRICS=("small" "medium" "large")
FABRIC_FULL=("classic_fabric_chipfoundry_small" "classic_fabric_chipfoundry_medium" "classic_fabric_chipfoundry_large")
DESIGNS=("addition" "all_ones" "all_zeros" "counter" "passthrough" "sys_reset" "multiplication" "register_file" "macc_8x8_20" "ram_32x4_2r_1w")

# Results
declare -A RESULTS
TOTAL=0
PASSED=0
FAILED=0

echo "===  FABulous Multi-Fabric Test Matrix ==="
echo ""

for i in "${!FABRICS[@]}"; do
    fabric_short="${FABRICS[$i]}"
    fabric_full="${FABRIC_FULL[$i]}"
    
    echo "Testing on ${fabric_short} fabric (${fabric_full})..."
    
    for design in "${DESIGNS[@]}"; do
        design_path="designs/classic/$design"
        
        if [ ! -d "$design_path" ]; then
            continue
        fi
        
        ((TOTAL++))
        test_id="${design}_${fabric_short}"
        
        # Run test
        cd "$design_path" 2>/dev/null || continue
        
        start_time=$(date +%s%N)
        
        # Only test synth (PNR requires nextpnr which may not be available)
        if FABRIC="$fabric_full" TILE_LIBRARY=classic make clean synth &>/dev/null 2>&1; then
            end_time=$(date +%s%N)
            duration=$(( (end_time - start_time) / 1000000 ))
            
            echo "  ✅ $design @ $fabric_short ... ${duration}ms"
            RESULTS[$test_id]="PASS"
            ((PASSED++))
        else
            echo "  ❌ $design @ $fabric_short ... FAIL"
            RESULTS[$test_id]="FAIL"
            ((FAILED++))
        fi
        
        cd - &>/dev/null
    done
done

echo ""
echo "=== SUMMARY ==="
echo "Total:  $TOTAL"
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "Pass Rate: $(( PASSED * 100 / TOTAL ))%"

echo ""
echo "=== Compatibility Matrix ==="
echo ""
printf "%-20s" "Design"
for fabric_short in "${FABRICS[@]}"; do
    printf "%-12s" "$fabric_short"
done
echo ""

printf "%-20s" "---"
for fabric_short in "${FABRICS[@]}"; do
    printf "%-12s" "---"
done
echo ""

for design in "${DESIGNS[@]}"; do
    printf "%-20s" "$design"
    for fabric_short in "${FABRICS[@]}"; do
        result="${RESULTS[${design}_${fabric_short}]}"
        if [ "$result" == "PASS" ]; then
            printf "%-12s" "✅ PASS"
        elif [ "$result" == "FAIL" ]; then
            printf "%-12s" "❌ FAIL"
        else
            printf "%-12s" "? SKIP"
        fi
    done
    echo ""
done
