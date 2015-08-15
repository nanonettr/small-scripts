#!/bin/bash

GEREKLIBOS=25 # Gigabyte
DONGUSAYISI=5 # Passes

# Standart seyler
echo ""

function mksound() {
    echo -e '\007' > /dev/console;
}

function pidtree() {
    [ -n "$ZSH_VERSION"  ] && setopt shwordsplit
    declare -A CHILDS
    while read P PP;do
	CHILDS[$PP]+=" $P"
    done < <(ps -e -o pid= -o ppid=)

    walk() {
	echo "$1"

	for i in ${CHILDS[$1]}; do
	    walk $i
	done
    }

    for i in "$@";do
	walk $i
    done
}

function cleanup() {
    mksound

    if [[ ! -z $lastpid ]]; then
	if [ "$(ps a | awk '{print $1}' | grep -E ^${lastpid}$)" ]; then
	    echo -n "---- Durduruluyor "
	    echo -n "(${lastpid})"
	    while [ "$(ps a | awk '{print $1}' | grep -E ^${lastpid}$)" ]; do
		SUBPIDS=$(pidtree ${lastpid})
		TREELAST=$(echo ${SUBPIDS} | awk '{print $NF}')

		killcount=0
		echo -n " "
		echo -n "(${TREELAST})"
		while [ "$(ps a | awk '{print $1}' | grep -E ^${TREELAST}$)" ]; do
		    case "${killcount}" in
			[05])
			    kill -15 ${TREELAST}
			    echo -n "*"
			;;
			1[05])
			    kill -2 ${TREELAST}
			    echo -n "+"
			;;
			2[05])
			    kill -1 ${TREELAST}
			    echo -n "-"
			;;
			[3-9][05])
			    kill -9 ${TREELAST}
			    echo -n "!"
			;;
			[1-9][0-9][05])
			    kill -9 ${TREELAST}
			    echo -n "!"
			;;
			*)
			    echo -n "."
			;;
		    esac

		    ((killcount++))
		    sleep 0.4
		done
	    done
	    echo " tamamlandı!.."
	fi
    fi

    echo -n "---- Temizleniyor"

    if [[ ! -z $TMPDOSYASI ]]; then
	echo -n "!"
	rm "${TMPDOSYASI}" >/dev/null 2>&1
    fi

    if [[ ! -z $DDTESTDOSYASI ]]; then
	echo -n "!"
	rm "${DDTESTDOSYASI}" >/dev/null 2>&1
    fi

    if [[ ! -z $dongu ]]; then
	ls -la ${RUNDIZIN}/Bonnie.* >/dev/null 2>&1
	if [[ $? -eq "0" ]]; then
	    echo -n "!"
	    rm -rf ${RUNDIZIN}/Bonnie.*
	else
	    echo -n "."
	fi

	ls -la ${RUNDIZIN}/test.[0-9].0 >/dev/null 2>&1
	if [[ $? -eq "0" ]]; then
	    echo -n "!"
	    rm -rf ${RUNDIZIN}/test.[0-9].0
	else
	    echo -n "."
	fi

	ls -la ${RUNDIZIN}/test.[0-9][0-9].0 >/dev/null 2>&1
	if [[ $? -eq "0" ]]; then
	    echo -n "!"
	    rm -rf ${RUNDIZIN}/test.[0-9][0-9].0
	else
	    echo -n "."
	fi

	ls -la ${RUNDIZIN}/iozone.DUMMY.* >/dev/null 2>&1
	if [[ $? -eq "0" ]]; then
	    echo -n "!"
	    ls -la ${RUNDIZIN}/iozone.DUMMY.*
	else
	    echo -n "."
	fi
    fi

    if [[ ! -z $STARTDIZIN ]]; then
	echo -n "+"
	cd "${STARTDIZIN}"
    fi

    echo " tamamlandı!.."

    sync
    echo ""
    echo "     Nano Disk Speed Tester - Build 20150813..."
    echo ""

    if [[ ! -z $dongu ]]; then
	((dongu--))
	echo "     ${dongu} döngü tamamlandı."


	if (( "$dongu" > 0 )); then
	    header="\n%21s %16s %11s %8s %9s\n"
	    format="%30.30s %9.2f %9.2f %9.2f %9.2f\n"

	    printf "${header}" "TEST ISMI" "TOPLAM" "ORTALAMA" "MINIMUM" "MAXIMUM"

	    TESTINDEX=0
	    while [[ "${TESTINDEX}" -lt "${#TESTA[@]}" ]]; do
		printf "${format}" "${TESTA[${TESTINDEX}]}" "${TESTC[${TESTINDEX}]}" "${TESTD[${TESTINDEX}]}" "${TESTE[${TESTINDEX}]}" "${TESTF[${TESTINDEX}]}"
		((TESTINDEX++))
	    done
	    echo ""
	fi
    fi

}

trap cleanup EXIT

function myHelp() {
    exit 1
}

function bashtrap() {
    echo ""
    echo "---- [CTRL]+[C]!..";
    tput cnorm
    #reset
    stty sane
    myHelp
}

trap bashtrap INT TERM

if [[ $(pidof -s -o '%PPID' -x $(basename $0)) ]]; then
    echo "---- Programın bir kopyası zaten çalısıyor!.."
    myHelp
fi

MYPID=$$
ionice -c 2 -n 5 -p "${MYPID}" >/dev/null 2>&1
renice -n 10 -p "${MYPID}" >/dev/null 2>&1

MYCOMMANDS=( pidof basename renice ionice tput stty ps awk grep sleep rm )
for i in "${MYCOMMANDS[@]}"; do
    command -v ${i} >/dev/null 2>&1
    CNF=$?
    if [[ "$CNF" -eq "1" ]]; then
	echo "---- ${i} komutu bulunamadı!.."
	echo >&2
	myHelp
    fi
done


function pause() {
    read -s -p "Devam etmek için [ENTER] tuşuna basın..." </dev/tty
    echo ""
}

function spinner() {
    local pid=$1
    local delay=0.06
    local spinstr='|/-\'
    tput civis

    while [ "$(ps a | awk '{print $1}' | grep -E ^${pid}$)" ]; do
        local temp=${spinstr#?}
        printf "[%c]" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b"
    done
    printf "   \b\b\b"
    tput cnorm
}
# /Standart seyler

if [[ -z $1 ]]; then
    echo "---- Dizin belirtilmemiş!.."
    myHelp
fi

if [[ ! -d $1 ]]; then
    echo "---- Verilen yol bir dizin değil!.."
    myHelp
fi

BOSALAN=$(df -BG -P ${1} | tail -1 | awk '{print $4}' | cut -d'G' -f1)
#if [[ ! $GEREKLIBOS -lt $BOSALAN ]]; then
if (( "$GEREKLIBOS" > "$BOSALAN" )); then
    echo "---- Dizinin bağlantı noktasında yeterli boş alan yok!.."
    myHelp
fi

STARTDIZIN=$(pwd)
RUNDIZIN="${1}"
TMPDOSYASI="${RUNDIZIN}/.disktest.tmp~"
DDTESTDOSYASI="${RUNDIZIN}/.disktest.dd~"
KOMUTONEK="TIMEFORMAT=%R; sync; echo 3 > /proc/sys/vm/drop_caches; time nocache"

SCRIPTCOMMANDS=( bc dd bonnie fio iozone nocache )
for i in "${SCRIPTCOMMANDS[@]}"; do
    command -v ${i} >/dev/null 2>&1
    CNF=$?
    if [[ "$CNF" -eq "1" ]]; then
	echo "---- ${i} komutu bulunamadı!.."
	echo >&2
	myHelp
    fi
done



KOMUTINDEX=0
# --------------------------------------------------------------------------------------------------
TESTA[${KOMUTINDEX}]="Sıralı yazma testi 4k blok"
TESTB[${KOMUTINDEX}]="dd if=/dev/zero bs=4k count=5200000 conv=fdatasync of="${DDTESTDOSYASI}""
((KOMUTINDEX++))

TESTA[${KOMUTINDEX}]="Sıralı yazma testi 64k blok"
TESTB[${KOMUTINDEX}]="dd if=/dev/zero bs=64k count=320000 conv=fdatasync of="${DDTESTDOSYASI}""
((KOMUTINDEX++))

TESTA[${KOMUTINDEX}]="Sıralı yazma testi 128k blok"
TESTB[${KOMUTINDEX}]="dd if=/dev/zero bs=128k count=160000 conv=fdatasync of="${DDTESTDOSYASI}""
((KOMUTINDEX++))

TESTA[${KOMUTINDEX}]="Sıralı okuma testi 4k blok"
TESTB[${KOMUTINDEX}]="dd of=/dev/null bs=4k if="${DDTESTDOSYASI}""
((KOMUTINDEX++))

TESTA[${KOMUTINDEX}]="Sıralı okuma testi 64k blok"
TESTB[${KOMUTINDEX}]="dd of=/dev/null bs=64k if="${DDTESTDOSYASI}""
((KOMUTINDEX++))

TESTA[${KOMUTINDEX}]="Sıralı okuma testi 128k blok"
TESTB[${KOMUTINDEX}]="dd of=/dev/null bs=128k if="${DDTESTDOSYASI}""
((KOMUTINDEX++))

TESTA[${KOMUTINDEX}]="Bonnie 8 paralel"
TESTB[${KOMUTINDEX}]="bonnie -c 8 -b -r 1024 -s 1750 -n 2 -u root -d ${RUNDIZIN}"
((KOMUTINDEX++))

TESTA[${KOMUTINDEX}]="Fio 16 paralel sıralı"
TESTB[${KOMUTINDEX}]="fio --name test --numjobs=16 --iodepth=16 --size=72M --rw=readwrite --ioengine=libaio --direct=1 --directory=${RUNDIZIN}"
((KOMUTINDEX++))

TESTA[${KOMUTINDEX}]="Fio 16 paralel rastgele"
TESTB[${KOMUTINDEX}]="fio --name test --numjobs=16 --iodepth=16 --size=22M --rw=randrw --ioengine=libaio --direct=1 --directory=${RUNDIZIN}"
((KOMUTINDEX++))

TESTA[${KOMUTINDEX}]="iozone 64 paralel 4k blok"
TESTB[${KOMUTINDEX}]="iozone -IoceTO -r 4k -s 1M -t 64 -i 0 -i 2 -i 8"
((KOMUTINDEX++))

TESTA[${KOMUTINDEX}]="iozone 64 paralel 64k blok"
TESTB[${KOMUTINDEX}]="iozone -IoceTO -r 64k -s 10M -t 64 -i 0 -i 2 -i 8"
((KOMUTINDEX++))

TESTA[${KOMUTINDEX}]="iozone 64 paralel 128k blok"
TESTB[${KOMUTINDEX}]="iozone -IoceTO -r 128k -s 16M -t 64 -i 0 -i 2 -i 8"
((KOMUTINDEX++))
# --------------------------------------------------------------------------------------------------

TESTINDEX=0
while [[ "${TESTINDEX}" -lt "${#TESTA[@]}" ]]; do
    TESTC[${TESTINDEX}]=0 # toplam
    TESTD[${TESTINDEX}]=0 # ortalama
    TESTE[${TESTINDEX}]=2600000 # min
    TESTF[${TESTINDEX}]=0 # max

    ((TESTINDEX++))
done

cd "${RUNDIZIN}"

for (( dongu=1; dongu <= ${DONGUSAYISI}; dongu++ )) do
    TESTINDEX=0
    while [[ "${TESTINDEX}" -lt "${#TESTA[@]}" ]]; do
	echo -n "${TESTA[${TESTINDEX}]} "
	eval $KOMUTONEK ${TESTB[${TESTINDEX}]} >"${TMPDOSYASI}" 2>&1 &
	lastpid=$!
	spinner ${lastpid}

	sync
	KOMUTSURE=$(tail -1 "${TMPDOSYASI}")

	echo -n ${KOMUTSURE}
	echo " saniyede tamamlandı."

	# Toplam
	TESTC[${TESTINDEX}]=$(echo "scale=3; ${TESTC[${TESTINDEX}]} + ${KOMUTSURE}" | bc)

	# Ortalama
	TESTD[${TESTINDEX}]=$(echo "scale=3; ${TESTC[${TESTINDEX}]} / ${dongu}" | bc)

	# Min
	if (( $(echo "${KOMUTSURE} < ${TESTE[${TESTINDEX}]}" | bc) == 1 )); then
	    TESTE[${TESTINDEX}]=${KOMUTSURE}
	fi

	# Max
	if (( $(echo "${KOMUTSURE} > ${TESTF[${TESTINDEX}]}" | bc) == 1 )); then
	    TESTF[${TESTINDEX}]=${KOMUTSURE}
	fi

	echo "....Geçiş:${dongu} Toplam:${TESTC[${TESTINDEX}]} Ortalama:${TESTD[${TESTINDEX}]} Min:${TESTE[${TESTINDEX}]} Max:${TESTF[${TESTINDEX}]}"
	echo ""

	((TESTINDEX++))
    done

    echo "---- Döngü ${dongu} tamamlandı..."
    echo ""
done

exit 0
