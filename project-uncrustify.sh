#!/bin/bash

# This script helps beautify our code w/ Uncrustify

# Help/Usage ------------------------------------
function usage() {
    printf "[USAGE] This script uncrustifies a whole project. \n"
    printf "        For now, this script parses C source files. \n"
    printf "\n[USAGE] Arguments : \n"
    printf "        <PROJECTPATH> : This is the path pointing to your project's directory. \n"
    printf "\n[USAGE] Options : \n"
    printf "        -h | --help : Gives the user help for this script. \n"
    printf "        --backup : Enables the creation of backup files. \n"
    printf "        --cp-backup <DIR> : Copies the backup files into DIR, \n" 
    printf "                      which is in the project directory\n"
    printf "        -l | -language <C|CXX/C++/CPP> Language of the project\n"
    printf "\n"
}

# Fetching the .sh's directory ------------------
MYDIR=$(dirname $(readlink -f $0))
echo "MYDIR = $MYDIR"
echo "PWD   = $PWD"

# Fetching the default configuration file
UNCRUSTIFYCFG="$MYDIR/custom-uncrustify-config.cfg" # Default value

# Project definition ----------------------------

# Analysing options -----------------------------
OPTS=$(getopt -o hc:l: -l help,backup,cp-backup:,language: -- "$@")
if [[ $? != 0 ]]; then
    printf "[ERROR] getopt failed !\n"
    exit 1
fi

printf "$OPTS\n"
eval set -- "$OPTS"

BACKUP=false
COPYBACKUP=false
COPYBACKUPPATH=
LANG=

while true; do
    case "$1" in
        -h) usage; echo "[DEBUG] h arg"; exit 0;;
        -c) UNCRUSTIFYCFG=$2; 
            echo "[DEBUG] c arg, UNCRUSTIFYCFG = $UNCRUSTIFYCFG"; 
            shift 2;;
        --help) usage; 
            echo "[DEBUG] help arg"; 
            exit 0;;
        --backup) BACKUP=true; 
            echo "[DEBUG] backup arg, BACKUP = $BACKUP"; 
            shift;;
        --cp-backup) COPYBACKUP=true;
            BACKUP=true; 
            COPYBACKUPPATH=$PROJECTDIR/$2; 
            echo "[DEBUG] cp-backup arg, COPYBACKUPPATH = $COPYBACKUPPATH"; 
            shift 2;;
        -l) LANG=$2; 
            echo "[DEBUG] l arg, LANG = $LANG"; 
            shift 2;;
        --language) LANG=$2; 
            echo "[DEBUG] language arg, LANG = $LANG"; 
            shift 2;;
        --) echo "[DEBUG] -- arg"; 
            shift; 
            break;;
        *) echo "[DEBUG] * arg"; 
            break;;
    esac
done

# Project definition ----------------------------
PROJECTDIR="$PWD/$(echo $1 | sed 's/\/$//')" # Remove last '/' char if exist
shift

LISTFILE="src_file_list.txt"

# Does the config file exist ? ------------------
if [[ -f "$UNCRUSTIFYCFG" ]]; then
    echo "[INFO ] Using config file : $UNCRUSTIFYCFG"
else
    echo "[ERROR] No config file found !"
    exit
fi

# Does the project exist ------------------------
if [[ $PROJECTDIR == "" ]]; then
    printf "[ERROR] Please pass your project directory's path as the first argument !\n"
    usage
    exit -1
fi

if [[ ! -d $PROJECTDIR ]]; then
    printf "[ERROR] Project directory ($PROJECTDIR) does not exist. Please check project path. \n"
    exit -1
fi

printf "[INFO ] The project is located in $PROJECTDIR\n"

# Backup or not ? -------------------------------
BACKUPFLAG=--replace
if [[ $BACKUP == false ]]; then
    BACKUPFLAG="$BACKUPFLAG --no-backup"
fi

# Language ---------------------------------------
LANGFLAG=
LANG=$(echo $LANG | tr [:lower:] [:upper:])
#echo "[DEBUG] LANG = $LANG"
if [[ $LANG == "" ]]; then
    printf "[INFO ] No language specified, set to default : C\n"
    LANGFLAG="C"
else
    if [[ ${LANG} == "C" ]]; then
        LANGFLAG="C"
    elif [[ ${LANG} == "C++" ]] || [[ ${LANG} == "CPP" ]] || [[ ${LANG} == "CXX" ]]; then
        LANGFLAG="CPP"
    else
        printf "[ERROR] Language not yet supported or language incorrectly entered. \n"
        exit 1
    fi
fi

# Removing list of source files form previous call
if [[ -f $PROJECTDIR/$LISTFILE ]]; then
    rm -rfv $PROJECTDIR/$LISTFILE;
fi

# Creating list of source files -----------------
touch $PROJECTDIR/$LISTFILE

# Listing source files to be beautified ---------
if [[ $LANGFLAG == "C" ]]; then
    find $PROJECTDIR -type f -name "*.c" -not -path "$PROJECTDIR/build*/*" >> $PROJECTDIR/$LISTFILE
    find $PROJECTDIR -type f -name "*.h" -not -path "$PROJECTDIR/build*/*" >> $PROJECTDIR/$LISTFILE
elif [[ $LANGFLAG == "CPP" ]]; then
    find $PROJECTDIR -type f -name "*.hh" -not -path "$PROJECTDIR/build*/*"  >>  $PROJECTDIR/$LISTFILE
    find $PROJECTDIR -type f -name "*.hpp" -not -path "$PROJECTDIR/build*/*" >> $PROJECTDIR/$LISTFILE
    find $PROJECTDIR -type f -name "*.hxx" -not -path "$PROJECTDIR/build*/*" >> $PROJECTDIR/$LISTFILE
    find $PROJECTDIR -type f -name "*.h++" -not -path "$PROJECTDIR/build*/*" >> $PROJECTDIR/$LISTFILE
    find $PROJECTDIR -type f -name "*.cpp" -not -path "$PROJECTDIR/build*/*" >> $PROJECTDIR/$LISTFILE
    find $PROJECTDIR -type f -name "*.cxx" -not -path "$PROJECTDIR/build*/*" >> $PROJECTDIR/$LISTFILE
    find $PROJECTDIR -type f -name "*.c++" -not -path "$PROJECTDIR/build*/*" >> $PROJECTDIR/$LISTFILE
    find $PROJECTDIR -type f -name "*.cc" -not -path "$PROJECTDIR/build*/*"  >>  $PROJECTDIR/$LISTFILE
fi

# Printing list of files ------------------------
printf "\n[INFO ] Detected the following source files : \n"
cat $PROJECTDIR/$LISTFILE

# Uncrustifying ---------------------------------
printf "\n[INFO ] Uncrustifying the source files : \n"
#echo "[DEBUG] uncrustify -l $LANGFLAG -c $UNCRUSTIFYCFG $BACKUPFLAG -F $PROJECTDIR/$LISTFILE"
uncrustify -l $LANGFLAG -c $UNCRUSTIFYCFG $BACKUPFLAG -F $PROJECTDIR/$LISTFILE
printf "\n"

# Removing source file --------------------------
rm $PROJECTDIR/$LISTFILE

# Removing backups ------------------------------
if [[ $BACKUP == false ]]; then
    echo "Removing backup files :"
    NR="$(find . -type f -name *.unc* | grep "" -c)"
    if [[ "" == "$NR" ]]; then
        NR="0"
    fi

    #echo "[DEBUG] NR = $NR"

    if [[ "0" == "$NR" ]]; then
        echo "No backup files to delete !"
    else
        echo "Removing $NR backup files !"
        find $PROJECTDIR -type f -name "*.unc-backup*" | xargs rm -rv
        find $PROJECTDIR -type f -name "*.uncrustify"  | xargs rm -rv
        echo "Removed $NR backup files !"
    fi
fi

# Copying backup files if need be ---------------
if [[ $COPYBACKUP == true  ]] && [[ $BACKUP == false ]]; then
    COPYBACKUP=false
    printf "\n[WARN  ] Cannot copy backups if backups were not created !\n"
    printf "         Incompatible options : --cp-backup & --backup\n"
    exit 1
fi

if [[ $COPYBACKUP == true ]]; then
    printf "\n[INFO] Copying backups to $COPYBACKUPPATH\n"
    if [[ -d $COPYBACKUPPATH ]]; then
        rm -rfv $COPYBACKUPPATH/
    fi
    mkdir $COPYBACKUPPATH

    find $PROJECTDIR -type f -name "*.unc-backup*" | xargs mv -t $COPYBACKUPPATH/
    find $PROJECTDIR -type f -name "*.uncrustify"  | xargs mv -t $COPYBACKUPPATH/
fi
