#!/bin/bash

# Jednoduchy shellovsky script
# Copyright (C) 2015 savakac

# Nadstavenie globalnych pemennych a nadefinovanie odchitavania signalu pri stalceni Ctrl+C
menu_choice=""
current_cat=""
title_file="title.cdb"
tracks_file="tracks.cdb"
temp_fil=/tmp/cdb.$$
trap 'rm -f $temp_file' EXIT

# Zadefinovanie funkcii
get_return() {
	echo -e "Stlacte Enter \c"
	read x
	return 0
}

get_confirm() {
	echo -e "Ste si isty? \c"
	while true
	do
		read x
		case "$x" in
			a | ano | A | Ano | ANO )
				return 0
				;;
			n | nie | N | Nie | NIE )
				echo
				echo "Zrusene"
				return 1
				;;
			* )
				echo "Napiste ano alebo nie"
				;;
		esac
	done
}

# Nastavenie hlavneho menu
set_menu_choice() {
	clear
	echo "Volby :"
	echo
	echo " a) Pridat nove cat"
	echo " f) Hladat cat"
	echo " c) Zistit pocet cat a stop v katalogu"
	if [ "$cdcatnum" != "" ]; then
		echo " l) Vypisat stopy na cat $cdtitle"
		echo " r) Zmazat cat $cdtitle"
		echo " u) Aktualizoat informace o stopach na cat $cdtitle"
	fi
	echo " q) Koniec"
	echo 
	echo -e "Naiste prosim pismeno volby a stlacte Enter \c"
	read menu_choice
	return
}

# Funkie na vkaldanie informacii do databazovych suborov
insert_title() {
	echo $* >> $title_file
	return
}

insert_track() {
	echo $* >> $tracks_file
	return
}

# Funkcia overi ci zadani text neobsahuje ciarky a potom zvisi aktualne cislo pridavanej stopy
add_record_track() {
	echo "Zadajte informacie o stopach na tomto cat"
	echo "Po zadani poslednej stopy napiste q"
	cdtrack=1
	cdttitle=""
	while [ "$cdttitle" != "q" ]
	do
		echo -e "Stopa disku $cdtrack, nazov stopy? \c"
		read tmp
		cdttitle=${tmp%%,*}
		if [ "$tmp" != "$cdttitle" ]; then
			echo "Je mi luto, ciarky niesu povolene"
			continue
		fi
		if [ -n "$cdttitle" ]; then
			if [ "$cdttitle" != "q" ]; then
				insert_track $cdcatnum,$cdtrack,$cdttitle
			fi
		else
			cdtrack=$((cdtrack-1))
		fi
		cdtrack=$((cdtrack+1))
	done
}

# Funkcia na zadavanie hlavnych titulov
add_records() {
	# Vyzva ka zadaniu hlavnych informacii

	echo -e "Zadajte katalogovy nazov \c"
	read tmp
	cdcatnum=${tmp%%,*}

	echo -e "Zadajte titul \c"
	read tmp
	cdtitle=${tmp%%,*}

	echo -e "Zadajte zaner \c"
	read tmp
	cdtype=${tmp%%,*}

	echo -e "Zadajte skaldatela alebo interpreta \c"
	read tmp
	cdac=${tmp%%,*}

	# Zistime ci uzivatel skutocne chce zadat informacie

	echo "Budem pridavat novu polozku"
	echo "$cdcatnum $cdtitle $cdtype $cdac"
	
	# Po potvrdeni pridame zaznam na koniec suboru s titulmi

	if get_confirm; then
		insert_title $cdcatnum,$cdtitle,$cdtype,$cdac
		add_record_track
	else
		remove_records
	fi

	return
}

# Funkcia na vyhladavanie v katalogu
find_cd() {
	if [ "$1" = "n" ]; then
		asklist=n
	else
		asklist=y
	fi
	cdcatnum=""
	echo -e "Zadajte retazec ktory sa ma vyhladat medzi tutulmy na cat \c"
	read searchstr
	if [ "$searchstr" = ""]; then
		return 0
	fi

	grep "$searchstr" $title_file > $temp_file

	set $(wc -l $temp_file)
	linesfound=$l

	case "$linesfound" in
		0)	echo "Je mi luto nic som nenasiel"
			get_return
			return 0
			;;
		1) 	;;
		2)	echo "Je mi lusto nazov nieje jednoznacny."
			echo "Nalezene zaznamy:"
			cat $temp_file
			get_return
			return 0
	esac

	IFS=","
	read cdcatnum cdtitle cdtype cdac < $temp_file
	IFS=" "
	
	if [ -z "$cdcatnum" ]; then
		echo "Je mi luto ze $temp_file nemozem nacitat pole katalogu"
		get_return
		return 0
	fi

	echo
	echo "Katalogove cislo: $cdcatnum"
	echo "Titul: $cdtitle"
	echo "Zaner: $cdtype"
	echo "Skladatel/interpret: $cdac"
	echo
	get_return

	if [ "$asklist" = "y" ]; then
		echo -e "Zobrazit stipy tohoto cat? \c"
		read x
		if [ "$x" = "y" ]; then
			echo
			list_tracks
			echo
		fi
	fi
	return 1
}

# Funkcia na updatovanie zaznamov
update_cat() {
	if [ -z "$cdcatnum" ]; then
		echo "Najskor musite vybrat cat"
		find_cd n
	fi
	if [ -n "$cdcatnum" ]; then
		echo "Aktualne stopy su: "
		list_tracks
		echo
		echo "Teraz znovu zadame stopy pre cat $cdtitle"
		get_confirm && {
			grep -v "^${cdcatnum}," $tracks_file > $temp_file
			mv $temp_file $tracks_file
			echo
			add_record_tracks
		}
	fi
	return
}

# Funkcia na zistenie poctu stop
count_cds() {
	set $(wc -l $title_file)
	num_titles=$l
	set $(wc -l $tracks_file)
	num_tracks=$l
	echo "najdene $num_titles cat, na nich je celkom $num_tracks stop"
	get_return
	return
}

# Funkcia na odstranenie
remove_records() {
	if [ -z "$cdcatnum" ]; then
		echo "Najskor musite vybrat cat"
		find_cd n
	fi
	if [ -n "$cdcatnum" ]; then
		echo "Teraz odstranite cat $cdtitle"
		get_confirm && {
			grep -v "^${cdcatnum}," $title_file > $temp_file
			mv $temp_file $title_file
			grep -v "^${cdcatnum}," $tracks_file > $temp_file
			mv $temp_file $tracks_file
			cdcatnum=""
			echo "Polozka odstranena"
		}
		get_return
	fi
	return
}

# Funkcia na vypis zoznamu stop
list_tracks() {
	if [ "$cdcatnum" = "" ]; then
		echo "Teraz vybrane cat"
		return
	else
		grep "^${cdcatnum}," $tracks_file > $temp_file
		num_tracks=$(wc -l $temp_file)
		if [ "$num_tracks" = "0" ]; then
			echo "Pre cat $cdtitle neboli najdene ziadne stopy"
		else {
			echo
			echo "$cdtitle: "
			echo
			cut -f 2- -d, $temp_file
			echo
		} | ${PAGER:-more}
		fi
	fi
	get_return
	return
}

# Hlavna funkcia programu
rm -f $temp_file
if [ ! -f $title_file ]; then
	touch $title_file
fi
if [ ! -f $tracks_file ]; then
	touch $tracks_file
fi

# Nasleduje vlastny kod aplikacie

clear
echo
echo
echo "Mini databazova aplikacia"
aleep 1

quit=n
while [ "$quit" != "a" ];
do
	set_menu_choice
	case "$menu_choice" in
		a) add_records;;
		r) remove_records;;
		f) find_cd y;;
		u) update_cd;;
		c) count_cds;;
		l) list_tracks;;
		b)
			echo
			more $title_file
			echo
			get_return
		q | Q) quit=y;;
		*) echo "Je mi luto ale volba nieje platna";;
	esac
done

# Upratanie a skoncenie

rm -f $temp_file
echo "Koniec"
exit 0
