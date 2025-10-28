#!/bin/bash

# make && clear && ./minishell 2> logs.txt < input.txt
# make debug && clear && ./minishell 2> logs.txt < quotes.txt
# ./minishell >> logs.txt < pipesandredirs.txt

# valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes --trace-children=yes --suppressions=tests/minishell.supp ./minishell

# valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes --trace-children=yes --suppressions=minishell.supp ./minishell >> logs.txt < pipesandredirs.txt

# SANITY CHECK

CY=$(tput setaf 51)
BL=$(tput setaf 39)
GR=$(tput setaf 70)
OR=$(tput setaf 202)
YE=$(tput setaf 214)
RE=$(tput setaf 1)

FIRE=$(tput bold setaf 202)
FLAME=$(tput bold setaf 214)

RES=$(tput sgr0)
B=$(tput bold)

TESTDIR=$(pwd)/tests/
LEAKSDIR=$(pwd)/tests/leaks/

INPUTS=("sanity.txt" "pipesandredirs.txt" "quotes.txt" "weird_long.txt" "2test.txt" "input.txt" "redirs.txt")

# if [ -z "$(ls -A tests/expected)" ]; then
# 	./make_expected_output.sh
# else
# 	printf "${FLAME}Expected output awaits at %s\n" "${TESTDIR}expected${RES}"
# fi

# COOL AnImAtIoNs ---------------------------------------------------
textanim()
{
	local text="$1"
	local len=${#text}

	tput civis
	trap "tput cnorm; printf '\033[2K\r'; tput sgr0; exit" INT TERM EXIT

	for ((i=0; i<len; i++)); do
		line=""
		for ((j=0; j<len; j++)); do
			if (( j == i )); then
				line+="${FLAME}${text:j:1}${RES}"
			else
				line+="${FIRE}${text:j:1}${RES}"
			fi
		done
		printf "%s\r" "$line"
		sleep 0.02
	done
	printf "\n"
}

textanim_s()
{
	local text="$1"
	local len=${#text}

	tput civis
	trap "tput cnorm; printf '\033[2K\r'; tput sgr0; exit" INT TERM EXIT

	for ((i=0; i<len; i++)); do
		line=""
		for ((j=0; j<len; j++)); do
			if (( j == i )); then
				line+="${YE}${text:j:1}${RES}"
			else
				line+="${OR}${text:j:1}${RES}"
			fi
		done
		printf "%s\r" "$line"
		sleep 0.02
	done
	printf "\n"
}

textanim_results()
{
	local text="$1"
	local len=${#text}

	tput civis
	trap "tput cnorm; exit" INT TERM EXIT

	for ((i=0; i<len; i++)); do
		line=""
		for ((j=0; j<len; j++)); do
			if (( j == i )); then
				line+="${CY}${text:j:1}${RES}"
			else
				line+="${BL}${text:j:1}${RES}"
			fi
		done
		printf "%s\r" "$line"
		sleep 0.05
	done
	tput cnorm
	trap - INT TERM EXIT
	printf "\033[${len}C"
}

# TESTER ------------------------------------------------------------

text=" A Tiny Little >> MiniShell << Tester  "
textanim "$text"

SHELLDIRS=($(find /home/$USER -type d -name "minishell"))
# SHELLDIRS=($(find /Users/$USER/Homework -type d -name "minishell"))
DIRCOUNT=${#SHELLDIRS[@]}

if [ "$DIRCOUNT" -gt 1 ]
then
	printf "${YE}Multiple minishell directories found: $DIRCOUNT${RES}\n"
	PS3="Choose the correct one: "
	select CHOICE in "${SHELLDIRS[@]}"
	do
		if [ -n "$CHOICE" ]
		then
			DIR="$CHOICE"
			break
		fi
	done
else
	DIR="${SHELLDIRS[0]}"
fi

printf "${BL}${B}DEBUG chosen dir: $DIR${RES}\n"

# NORMINETTE --------------------------------------------------------

printf "${GR}>> Run Norminette checks? [y/n]${RES} "
tput cnorm
read ARG
if [ "$ARG" = "y" ]
then
	# text=">> Norminetting Libft "
	# textanim_s "$text"
	# norminette -o ${DIR}/libft/* > norm_check.txt
	text=">> Norminetting "
	textanim_s "$text"
	norminette -o ${DIR}/* >> norm_check.txt
	grep  ": Error" norm_check.txt > norm_grep.txt
	if [ -s norm_grep.txt ]
	then
		printf "${YE}>> Norminette found issues. Would you like to see them? [y/n]${RES} "
		tput cnorm
		read ARG
		if [ "$ARG" = "y" ]
		then
			cat norm_grep.txt
			printf "${GR}>> Proceed? [y/n]${RES} "
			tput cnorm
			read ARG
			if [ "$ARG" = "n" ]
			then
				exit 1
			fi
		fi
	else
		printf "${GR}Norminette is OK. Proceeding!${RES}\n"
	fi
fi

# (IN)SANITY --------------------------------------------------------

echo
text=" MINISHELL SANITY CHECK  "
textanim "$text"
printf "\n${GR}>> Proceed? [y/n]${RES} "
tput cnorm
read ARG
if [ "$ARG" = "y" ]
then
	if [ ! -f "minishell" ]
	then
		printf "\n./minishell isn't found\n"
		text=">> Preparing minishell "
		textanim_s "$text"
		sleep 0.5
		cd ${DIR}
		make
	fi
	./minishell < ${TESTDIR}2test.txt
fi

# LEAKS -------------------------------------------------------------

echo
text=" LEAKS CHECK  "
textanim "$text"
printf "${GR}\n>> Continue? [y/n]${RES} "
tput cnorm
read ARG

if [ "$ARG" = "y" ]
then
	printf "Readline leaks will be surpressed\n"
	touch ${DIR}/forbidden_file
	chmod 000 ${DIR}/forbidden_file
	touch valid_infile_1
	touch valid_infile_2
	results=()
	for file in "${INPUTS[@]}"
	do
		out="${file%%.*}"
		log="${LEAKSDIR}leaks_${out}.txt"
		valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes --trace-children=yes --track-fds=yes --suppressions=${TESTDIR}minishell.supp ${DIR}/./minishell 2> "$log"  1> /dev/null < "${TESTDIR}${file}"
		# valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes --trace-children=yes --suppressions=${TESTDIR}minishell.supp ${DIR}/./minishell 2> "$log"  1> /dev/null < "${TESTDIR}${file}"
		text=">> Checking leaks with ${file} "
		textanim_s "$text"
		ZEROLEAKS=$(grep -ic " lost: 0 bytes in 0 blocks" "$log")
		ZEROREACH=$(grep -ic "still reachable: 0 bytes in 0 blocks" "$log")
		TOTALLEAKS=$(grep -ic " lost: .* bytes in .* blocks" "$log")
		TOTALREACH=$(grep -ic "still reachable: .* bytes in .* blocks" "$log")
#		if (( "$TOTALLEAKS" - "$ZEROLEAKS" -eq 0 && "$TOTALREACH" - "$ZEROREACH" -eq 0))
		if (( (TOTALLEAKS - ZEROLEAKS) == 0 && (TOTALREACH - ZEROREACH) == 0 ))
		then
			results+=("$out: OK")
		else
			results+=("$out: LEAKS (see logs: $log)")
			line=$(grep 'FILE DESCRIPTORS:' $log)
			awk '{for(i=1;i<=NF;i++) if($(i+1)=="open") open=$(i); if($(i+1)=="std)") std=$(i)} END{if(open>=std) print "No suspicious file descriptors"; else print "Suspicious file descriptors"}' <<< "$line"

			# FDOPENCOUNT=$(grep -ic "Open file descriptor " "$log")
			# if [[ ! "$FDOPENCOUNT" -eq 0 ]]
			# then
			# 	printf "${RE}File descriptors: ${RES}\n"
			# 	grep "Open file descriptor " "$log"
			# 	grep "FILE DESCRIPTORS" "$log"

			# fi
		fi
	done
	echo
	for r in "${results[@]}"; do
		filename="${r%%:*}"
		result="${r#*: }"
		textanim_results "$filename: "
		if [[ "$result" == LEAKS* ]]
		then
			printf "${YE}%s${RES}\n" "$result"
		else
			printf "${GR}%s${RES}\n" "$result"
		fi
	done
fi

# CLEAN UP ----------------------------------------------------------

echo
text=" CLEAN UP  "
textanim "$text"
tput cnorm
printf "${GR}\nClean up? This will remove test logs and test files, and perform make fclean on ${DIR}. [y/n]${RES} "
read ARG
if [ "$ARG" = "y" ]; then
	echo
	echo rm -fr ${LEAKSDIR}*
	rm -fr ${LEAKSDIR}*
	echo rm -f forbidden_file valid_infile_1 valid_infile_2
	rm -f forbidden_file valid_infile_1 valid_infile_2
	cd ${DIR}
	echo make fclean
	make fclean
fi

