#!/bin/sh
# Miku Dark Mode TTY Color Override for greetd
# Forces the Linux VT to use Tokyo Night / Miku palette
# so the greeter background is #1a1b26 instead of plain black.

BLACK="1a1b26"
DARK_RED="f7768e"
DARK_GREEN="39c5bb"
DARK_YELLOW="e0af68"
DARK_BLUE="7aa2f7"
DARK_MAGENTA="bb9af7"
DARK_CYAN="7dcfff"
LIGHT_GRAY="a9b1d6"
DARK_GRAY="414868"
RED="f7768e"
GREEN="39c5bb"
YELLOW="e0af68"
BLUE="7aa2f7"
MAGENTA="bb9af7"
CYAN="7dcfff"
WHITE="c0caf5"

COLORS="${BLACK} ${DARK_RED} ${DARK_GREEN} ${DARK_YELLOW} ${DARK_BLUE} ${DARK_MAGENTA} ${DARK_CYAN} ${LIGHT_GRAY} ${DARK_GRAY} ${RED} ${GREEN} ${YELLOW} ${BLUE} ${MAGENTA} ${CYAN} ${WHITE}"

i=0
while [ $i -lt 16 ]; do
	seq="\033]P%X%s"
	val=$(printf "$seq" ${i} "$(echo "$COLORS" | cut -d ' ' -f$(( i + 1)))")

	for t in 1 2 3 4 5 6; do
		if [ -w "/dev/tty$t" ]; then
			printf "%b" "$val" > "/dev/tty$t" 2>/dev/null
		fi
	done

	i=$(( i + 1 ))
done

# Clear screens to apply the new background color
for t in 1 2 3 4 5 6; do
	if [ -w "/dev/tty$t" ]; then
		printf "\033[2J\033[H" > "/dev/tty$t" 2>/dev/null
	fi
done
