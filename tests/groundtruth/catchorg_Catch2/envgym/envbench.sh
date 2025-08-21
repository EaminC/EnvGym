#!/bin/bash
# Catch2 Environment Benchmark Test
# Tests if the environment is properly set up for the Catch2 C++ test framework project
# Don't exit on error - continue testing even if some tests fail
# set -e  # Exit on any error
trap 'echo -e "\n\033[0;31m[ERROR] Script interrupted by user\033[0m"; exit 1' INT TERM

# Function to ensure clean exit
cleanup() {
    echo -e "\n\033[0;34m[INFO] Cleaning up...\033[0m"
    jobs -p | xargs -r kill
    exit 1
}

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# Function to write results to JSON file
write_results_to_json() {
    local json_file="envgym/envbench.json"
    cat > "$json_file" << EOF
{
    "PASS": $PASS_COUNT,
    "FAIL": $FAIL_COUNT,
    "WARN": $WARN_COUNT
}
EOF
    echo -e "${BLUE}[INFO]${NC} Results written to $json_file"
}

# Check if envgym.dockerfile exists
if [ ! -f "envgym/envgym.dockerfile" ]; then
    echo -e "${RED}[CRITICAL ERROR]${NC} envgym/envgym.dockerfile does not exist"
    echo -e "${RED}[RESULT]${NC} Benchmark score: 0 (Dockerfile missing)"
    # Write 0 0 0 to JSON
    PASS_COUNT=0
    FAIL_COUNT=0
    WARN_COUNT=0
    write_results_to_json
    exit 1
fi

print_status() {
    local status=$1
    local message=$2
    case $status in
        "PASS") echo -e "${GREEN}[PASS]${NC} $message"; ((PASS_COUNT++)); ;;
        "FAIL") echo -e "${RED}[FAIL]${NC} $message"; ((FAIL_COUNT++)); ;;
        "WARN") echo -e "${YELLOW}[WARN]${NC} $message"; ((WARN_COUNT++)); ;;
        "INFO") echo -e "${BLUE}[INFO]${NC} $message"; ;;
        *) echo "[$status] $message"; ;;
    esac
}

check_command() {
    local cmd=$1; local name=$2
    if command -v "$cmd" &>/dev/null; then print_status PASS "$name is installed"; return 0; else print_status FAIL "$name is not installed"; return 1; fi
}

# Check if we're running inside Docker container
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    echo "Running inside Docker container - proceeding with environment test..."
else
    echo "Not running in Docker container - building and running Docker test..."
    if ! command -v docker &>/dev/null; then 
        echo "ERROR: Docker is not installed or not in PATH"
        # Write 0 0 0 to JSON
        PASS_COUNT=0
        FAIL_COUNT=0
        WARN_COUNT=0
        write_results_to_json
        exit 1
    fi
    if [ ! -f "envgym/envgym.dockerfile" ]; then 
        echo "ERROR: envgym.dockerfile not found. Please run this script from the Catch2 project root directory."
        # Write 0 0 0 to JSON
        PASS_COUNT=0
        FAIL_COUNT=0
        WARN_COUNT=0
        write_results_to_json
        exit 1
    fi
    echo "Building Docker image..."
    if ! docker build -f envgym/envgym.dockerfile -t catch2-env-test .; then
        echo -e "${RED}[CRITICAL ERROR]${NC} Docker build failed"
        echo -e "${RED}[RESULT]${NC} Benchmark score: 0 (Docker build failed)"
        # Write 0 0 0 to JSON
        PASS_COUNT=0
        FAIL_COUNT=0
        WARN_COUNT=0
        write_results_to_json
        exit 1
    fi
    echo "Running environment test in Docker container..."
    docker run --rm -v "$(pwd):/home/cc/EnvGym/data/catchorg_Catch2" catch2-env-test bash -c "trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM; ./envgym/envbench.sh"
    exit 0
fi

echo "=========================================="
echo "Catch2 Environment Benchmark Test"
echo "=========================================="
echo ""

# 1. System dependencies
print_status INFO "Checking system dependencies..."
check_command "g++" "g++ (GNU C++ Compiler)"
check_command "clang++" "clang++ (Clang C++ Compiler)"
check_command "cmake" "CMake"
check_command "make" "make"
check_command "ninja" "ninja"
check_command "python3" "Python 3"
check_command "git" "Git"
check_command "bash" "Bash"
check_command "ls" "ls"
check_command "doxygen" "Doxygen"

# 2. Project structure
print_status INFO "Checking project structure..."
for d in src tests examples docs tools third_party fuzzing extras; do
    if [ -d "$d" ]; then print_status PASS "$d directory exists"; else print_status FAIL "$d directory missing"; fi
done
for f in README.md LICENSE.txt CMakeLists.txt meson.build BUILD.bazel conanfile.py; do
    if [ -f "$f" ]; then print_status PASS "$f exists"; else print_status WARN "$f missing"; fi
done

# 3. Build system files
if [ -f "CMakeLists.txt" ]; then
    print_status INFO "Testing CMake configuration..."
    mkdir -p build && cd build
    if cmake .. &>/dev/null; then print_status PASS "CMake configure successful"; else print_status FAIL "CMake configure failed"; fi
    cd ..
else
    print_status WARN "CMakeLists.txt missing, skipping CMake test"
fi
if [ -f "meson.build" ]; then
    print_status INFO "Testing Meson configuration..."
    if command -v meson &>/dev/null; then
        mkdir -p buildmeson && cd buildmeson
        if meson .. &>/dev/null; then print_status PASS "Meson configure successful"; else print_status FAIL "Meson configure failed"; fi
        cd ..
    else
        print_status WARN "meson not installed, skipping Meson test"
    fi
fi
if [ -f "BUILD.bazel" ]; then print_status INFO "Bazel build file detected (not tested)"; fi
if [ -f "conanfile.py" ]; then print_status INFO "Conan build file detected (not tested)"; fi

# 4. Example build & test
if [ -f "CMakeLists.txt" ]; then
    print_status INFO "Testing example build (CMake)..."
    mkdir -p build && cd build
    if cmake .. &>/dev/null && make -j2 examples &>/dev/null; then print_status PASS "Example build (make examples) successful"; else print_status FAIL "Example build (make examples) failed"; fi
    cd ..
fi
if [ -f "examples/100-CatchMain.cpp" ]; then
    print_status INFO "Testing compilation of examples/100-CatchMain.cpp..."
    g++ -std=c++17 -I./src -o test_catch2_example examples/100-CatchMain.cpp src/catch2/catch_all.hpp &>/dev/null
    if [ -f test_catch2_example ]; then print_status PASS "examples/100-CatchMain.cpp compiles"; rm -f test_catch2_example; else print_status FAIL "examples/100-CatchMain.cpp does not compile"; fi
fi

# 5. Python tools
if [ -f "tools/convert.py" ]; then
    print_status INFO "Testing Python tool: tools/convert.py..."
    if python3 tools/convert.py --help &>/dev/null; then print_status PASS "tools/convert.py runs"; else print_status WARN "tools/convert.py failed to run"; fi
fi

# 6. Documentation
for f in README.md LICENSE.txt docs; do
    if [ -e "$f" ]; then print_status PASS "$f exists"; else print_status FAIL "$f missing"; fi
done
if [ -f "README.md" ] && grep -qi catch2 README.md; then print_status PASS "README.md contains Catch2 references"; else print_status WARN "README.md missing Catch2 references"; fi

# 7. Test directory
if [ -d "tests" ]; then
    print_status INFO "Testing test discovery..."
    testcount=$(find tests -name '*.cpp' | wc -l)
    print_status INFO "Found $testcount test .cpp files in tests/"
    if [ "$testcount" -gt 0 ]; then print_status PASS "Test source files found"; else print_status WARN "No test source files found"; fi
fi

# 8. Fuzzing directory
if [ -d "fuzzing" ]; then
    fuzzcount=$(find fuzzing -name '*.cpp' | wc -l)
    print_status INFO "Found $fuzzcount fuzzing .cpp files in fuzzing/"
    if [ "$fuzzcount" -gt 0 ]; then print_status PASS "Fuzzing source files found"; else print_status WARN "No fuzzing source files found"; fi
fi

# 9. Third party
if [ -d "third_party" ]; then
    tpcount=$(find third_party -type f | wc -l)
    print_status INFO "Found $tpcount files in third_party/"
    if [ "$tpcount" -gt 0 ]; then print_status PASS "Third party files found"; else print_status WARN "No third party files found"; fi
fi

# 10. License
if [ -f "LICENSE.txt" ]; then print_status PASS "LICENSE.txt exists"; else print_status FAIL "LICENSE.txt missing"; fi

# 11. Git
if git --version &>/dev/null; then print_status PASS "Git is properly configured"; else print_status FAIL "Git is not properly configured"; fi
if [ -d ".git" ]; then print_status PASS "This is a Git repository"; else print_status WARN "This is not a Git repository"; fi

# 12. Locale
if [ "$LANG" = "C.UTF-8" ] || [ "$LANG" = "en_US.UTF-8" ]; then print_status PASS "LANG is set to UTF-8 locale"; else print_status WARN "LANG is not set to UTF-8 locale (current: $LANG)"; fi
if [ "$LC_ALL" = "C.UTF-8" ] || [ "$LC_ALL" = "en_US.UTF-8" ]; then print_status PASS "LC_ALL is set to UTF-8 locale"; else print_status WARN "LC_ALL is not set to UTF-8 locale (current: $LC_ALL)"; fi

echo ""
echo "=========================================="
echo "Environment Benchmark Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested:"
echo "- System dependencies (C++ compilers, CMake, Python, Git, Doxygen)"
echo "- Project structure (src, tests, examples, docs, tools, third_party, fuzzing, extras)"
echo "- Build system files (CMake, Meson, Bazel, Conan)"
echo "- Example build and test compilation"
echo "- Python tools"
echo "- Documentation和LICENSE"
echo "- Test/fuzz/third_party目录"
echo "- Git仓库和本地化配置"
# Save final counts before any additional print_status calls
FINAL_PASS_COUNT=$PASS_COUNT
FINAL_FAIL_COUNT=$FAIL_COUNT
FINAL_WARN_COUNT=$WARN_COUNT

echo ""
echo "=========================================="
echo "Test Results Summary"
echo "=========================================="
echo -e "${GREEN}PASS: $FINAL_PASS_COUNT${NC}"
echo -e "${RED}FAIL: $FINAL_FAIL_COUNT${NC}"
echo -e "${YELLOW}WARN: $FINAL_WARN_COUNT${NC}"

# Write results to JSON using the final counts
PASS_COUNT=$FINAL_PASS_COUNT
FAIL_COUNT=$FINAL_FAIL_COUNT
WARN_COUNT=$FINAL_WARN_COUNT
write_results_to_json

if [ $FINAL_FAIL_COUNT -eq 0 ]; then
    print_status INFO "All tests passed! Your Catch2 environment is ready!"
elif [ $FINAL_FAIL_COUNT -lt 5 ]; then
    print_status INFO "Most tests passed! Your Catch2 environment is mostly ready."
    print_status WARN "Some optional dependencies are missing, but core functionality should work."
else
    print_status WARN "Many tests failed. Please check the output above."
    print_status INFO "This might indicate that the environment is not properly set up."
fi
print_status INFO "You can now build and use Catch2."
print_status INFO "Example: mkdir build && cd build && cmake .. && make -j2"
print_status INFO "For more information, see README.md"

print_status INFO "To start interactive container: docker run -it --rm -v \$(pwd):/home/cc/EnvGym/data/catchorg_Catch2 catch2-env-test /bin/bash" 