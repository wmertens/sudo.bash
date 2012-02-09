# Wrap sudo to handle aliases and functions
# Wout.Mertens@gmail.com
#
# Accepts -x as well as regular sudo options: this expands variables as you not root
#
# Comments and improvements welcome
#
# Installing: source this from your .bashrc and set alias sudo=sudowrap
#  You can also wrap it in a script that changes your terminal color, like so:
#  function setclr() {
#	local t=0               
#	SetTerminalStyle $1                
#	shift
#	"$@"
#	t=$?
#	SetTerminalStyle default
#	return $t
#  }
#  alias sudo="setclr sudo sudowrap"
#  If SetTerminalStyle is a program that interfaces with your terminal to set its
#  color.

# Note: This script only handles one layer of aliases/functions.

# If you prefer to call this function sudo, uncomment the following
# line which will make sure it can be called that
#typeset -f sudo >/dev/null && unset sudo

sudowrap () 
{
	local c="" t="" parse=""
	local -a opt
	#parse sudo args
	OPTIND=1
	i=0
	while getopts xVhlLvkKsHPSb:p:c:a:u: t; do
		if [ "$t" = x ]; then
			parse=true
		else
			opt[$i]="-$t"
			let i++
			if [ "$OPTARG" ]; then
				opt[$i]="$OPTARG"
				let i++
			fi
		fi
	done
	shift $(( $OPTIND - 1 ))
	if [ $# -ge 1 ]; then
		c="$1";
		shift;
		case $(type -t "$c") in 
		"")
			echo No such command "$c"
			return 127
			;;
		alias)
			c="$(type "$c")"
			# Strip "... is aliased to `...'"
			c="${c#*\`}"
			c="${c%\'}"
			;;
		function)
			c="$(type "$c")"
			# Strip first line
			c="${c#* is a function}"
			c="$c;\"$c\""
			;;
		*)
			c="\"$c\""
			;;
		esac
		if [ -n "$parse" ]; then
			# Quote the rest once, so it gets processed by bash.
			# Done this way so variables can get expanded.
			while [ -n "$1" ]; do
				c="$c \"$1\""
				shift
			done
		else
			# Otherwise, quote the arguments. The echo gets an extra
			# space to prevent echo from parsing arguments like -n
			while [ -n "$1" ]; do
				t="${1//\'/\'\\\'\'}"
				c="$c '$t'"
				shift
			done
		fi
		echo sudo "${opt[@]}" -- bash -xvc \""$c"\" >&2
		command sudo "${opt[@]}" bash -xvc "$c"
	else
		echo sudo "${opt[@]}" >&2
		command sudo "${opt[@]}"
	fi
}
# Allow sudowrap to be used in subshells
export -f sudowrap
