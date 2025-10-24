CYAN=$(tput bold setaf 44)
BLUE=$(tput setaf 96)
FIRE=$(tput setaf 202)
GREEN=$(tput setaf 70)
RESET=$(tput sgr0)

DIR=$(pwd)/tests/expected

printf "${BLUE}CREATING EXPECTED RESULTS IN BASH\n${RESET}"
# Create the files in a separate dir
bash > ${DIR}/expected_sanity.txt < tests/sanity.txt
echo The files are created in ${DIR}
# cat ${DIR}/expected_sanity.txt
# check norminette
# check built ins
# check executables
# check basic leaks