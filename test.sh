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

FIRE=$(tput bold setaf 202)
FLAME=$(tput bold setaf 214)

RES=$(tput sgr0)
B=$(tput bold)

TESTDIR=$(pwd)/tests/
LEAKSDIR=$(pwd)/tests/leaks/

INPUTS=("sanity.txt" "pipesandredirs.txt" "quotes.txt" "weird_long.txt" "2test.txt" "input.txt")

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

# NORMINETTE --------------------------------------------------------

printf "${GR}>> Run Norminette checks? [y/n]${RES} "
tput cnorm
read ARG
if [ "$ARG" = "y" ]
then
	text=">> Norminetting Libft "
	textanim_s "$text"
	norminette -o libft/* > norm_check.txt
	text=">> Norminetting source files "
	textanim_s "$text"
	norminette -o >> norm_check.txt --use-gitignore
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
	results=()
	for file in "${INPUTS[@]}"; do
		out="${file%%.*}"
		log="${LEAKSDIR}leaks_${out}.txt"
		valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes --trace-children=yes --suppressions=${TESTDIR}minishell.supp ./minishell 2> "$log"  1> /dev/null < "${TESTDIR}${file}"
		text=">> Checking leaks with ${file} "
		textanim_s "$text"
		ZEROLEAKS=$(grep -ic "lost: 0" "$log")
		ZEROREACH=$(grep -ic "reachable: 0" "$log")
#		ZEROFDOPEN=$(grep -ic "0 open ")
		TOTALLEAKS=$(grep -ic "lost: " "$log")
		TOTALREACH=$(grep -ic "reachable: " "$log")
		if [[ "$TOTALLEAKS" - "$ZEROLEAKS" -eq 0 && "$TOTALREACH" - "$ZEROREACH" -eq 0 ]]; then
			results+=("$out: OK")
		else
			results+=("$out: LEAKS (see logs: $log)")
		fi
	done
	echo
	for r in "${results[@]}"; do
		filename="${r%%:*}"
		result="${r#*: }"
		textanim_results "$filename: "
		if [[ "$result" == LEAKS* ]]; then
			printf "${YE}%s${RES}\n" "$result"
		else
			printf "${GR}%s${RES}\n" "$result"
		fi
	done

fi

# CLEAN UP ----------------------------------------------------------

printf "${GR}\nClean up? It will remove test logs, executables and object files. [y/n]${RES} "
tput cnorm
read ARG
if [ "$ARG" = "y" ]; then
	echo
	echo rm -fr ${LEAKSDIR}*
	rm -fr ${LEAKSDIR}*
	echo make fclean
	make fclean
fi


	# LEAKS=$(grep -ic "0 bytes in 0" ${TESTDIR}leaks_output.txt)
	# text="Leaks check: "
	# if [ "$LEAKS" -eq 4 ]; then
	# 	textanim_results "$text"
	# 	printf "${GR}OK\n${RES}"
	# 	printf "\nRemove test logs? [y/n]\n"
	# 	read ARG
	# 	if [ "$ARG" = "y"]; then
	# 		rm ${TESTDIR}*
	# 	fi
	# else
	# 	textanim_results "$text"
	# 	printf "${FLAME}FAILED. See logs: ${TESTDIR}leaks ]\n${RES}"
	# fi



	# check norminette
	# check built ins
	# check executables
	# check basic leaks



# LOOPED ANIMATION
# tput civis

# cleanup() {
#     tput cnorm
#     tput sgr0
# 	printf '\033'
#     printf '\n'
#     exit
# }

# # On script exit, show cursor again
# trap cleanup INT TERM EXIT

# while true; do
#     for ((i=0; i<len; i++)); do
#         line=""
#         for ((j=0; j<len; j++)); do
#             if (( j == i )); then
#                 line+="${FLAME}${text:j:1}${RESET}"
#             else
#                 line+="${FIRE}${text:j:1}${RESET}"
#             fi
#         done
#         printf "%s\r" "$line"
#         sleep 0.15
#     done
# done
