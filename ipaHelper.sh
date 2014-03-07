#!/bin/bash

#pulls Resources folder and plist editor from a separate, editable script
#. ~/.publishingresource #no longer necessary

#unzips $ipa and returns the .app directory inside the Payload directory
function make_ad
{
cd $bd
unzip -q $ipa -d .ipa_payload
if [ ! -d ".ipa_payload" ];then
    problem_encountered "problem unzipping ipa folder"
fi

cd .ipa_payload/Payload
find ./ -type d -d 1 -iname "*.app*" | while read f; do
        f=${f:3}
        f=.ipa_payload/Payload/$f
        echo "$f"
done
}

#if $ipa is "" then there's a problem, exit if $1 is passed in, it is another possible required item (instead of the ipa file)
function assert_ipa
{
if [ "$ipa" = "" ];then
	message="no ipa file"
	if [ "$1" != "" ];then
		message="$message or $1"
	fi
        problem_encountered "$message"
fi
}

#returns ipa file name in the working directory
function ipa_in_wd
{
find ./ -type f -depth 1 -iname "*.ipa" | while read f; do
echo 'in main'
	f=${f:3}
	echo "$f"
	return
done
}

#called to end the script with success
function script_done
{
clean_up
exit 0
}

#called to end script in error
function problem_encountered
{
if [ "$1" != "" ];then
	echo "**** $1 ****" >&2
fi
clean_up
echo 'type "help" for usage page' >&2
exit 1
}

#display usage information

##Help Functions##
function help_help
{
echo '*****HELP*****

help [-v] [commands]

Displays usage information for the different commands.  If -v option is present it shows the usage information for all of the commands.
'

echo "COMMANDS:"$'\t'"Help"$'\t'"Get"$'\t'"Certs"$'\t'"Profile "$'\t'"Info"$'\t'"Resign"
echo
}

function help_get
{
echo '*****GET*****

[directory path] get [-options]

Moves files into directory path.  If no path is inputed, the working directory is used.

Options:
[-p | --prof | --profile | -- profiles] copies .mobileprovision profiles to the directory. 
If no profiles are specified after the option flag, all .mobileprovision files in the Downloads folder are used.
    
[-e | --entitlements] copies Entitlements.plist from the Publishing Resources folder into the directory.  
    No arguments are taken for this option.
    '
}

function help_certs
{
echo '*****CERTS*****

certs

Displays the BMW certificates, both common names and IDS.
'
}

function help_profile
{
echo '*****PROFILE*****

[ipa file] [-U] profile [-options]
[mobileprovision file] profile [-options]

checks the profile of an .ipa file, or shows the information about a .mobileprovision file

If an .ipa file is provided, that ipa is unzipped (unless the -U option was present, in which case the available Payload folder in that directory is used)
    
If a .mobileprovision file is provided, this profile is used instead.
        
If no .movileprovision or .ipa file is provided, the first (alphabetically) ipa file in the working directory is used.
            
If no options are present, a summary of the provisioning profile is displayed.
                
Options:
                
[-v | --verbose] display the entire profile in xml format
                
[-i | --id] display the application identifier
                
[-n | --name] display the app id name
                
[-c | --certificate] display the certificate name
                
[-t | --team] display the team name on the certificate
                
[-u | --uuid] display the profiles UUID
                
[-r | --version] display the apps version
                
[-e | --entitlements] display the entitlements on the profile
                
[-k | --key] takes a key as an argument, returns the value for that key on the profile   
'
}

function help_info
{
echo '*****INFO*****

[ipa file] [-U] info [-options]
[Info.plist file] info [-options]

checks the Info.plist of an .ipa file, or shows the information about an Info.plist file

If an .ipa file is provided, that ipa is unzipped (unless the -U option was present, in which case the available Payload folder in that directory is used)
    
If an Info.plist file is provided, this is used instead.
        
If no Info.plist or .ipa file is provided, the first (alphabetically) ipa file in the working directory is used.
            
If no options are present, a summary of the Info.plist is displayed.
                
Options:
                
[-v | --verbose] display the entire Info.plist in xml format
                
[-n | --name] display the CFBundleName
                
[-d | --display] display the CFBundleDisplayName
                
[-i | --identifier] display the CFBundleIdentifier
                
[-r | --version] display the CFBundleVersion
                
[-s | --short | --shortVersion] display the CFBundleShortVersionString
                
[-k | --key] takes a key as an argument, returns the value for that key on the Info.plist
'
}

function help_resign
{
echo '*****RESIGN*****

[ipa file] [-U] resign [-options]

removes the code signature from the ipa file, and replaces it with the provided profile (uses the first profile in the directory with the ipa file if none is provided), resigns the ipa file using the certificate on the profile, zips the resigned ipa file with the name [ipa filename]-resigned.ipa

If an .ipa file is provided, that ipa is unzipped (unless the -U option was present, in which case the available Payload folder in that directory     is used)
    
If no .ipa file is provided, the first (alphabetically) ipa file in the working directory is used.
        
Options:
        
[-p | -profile] takes a specific profile as an argument, uses this profile for resigning the ipa
        
[-e | --entitlements] creates a new Entitlements.plist file and uses this file to resign the ipa.  Takes "Push" as an argument if the Entitlements need to include Apple Push Notifications

[-dc | --doublecheck] displays information about the ipa, its Info.plist, and the provisioning profile and offers a choice to continue or quit
'
}

#if $needsclean deletes the Payload folder, moves the _Payload folder back to Payload if it exists
function clean_up
{
if [ -d "$bd/.ipa_payload" ];then
    rm -rf "$bd/.ipa_payload"
fi
if [ -f "$bd/.Info.plist" ]; then
	rm "$bd/.Info.plist"
fi
if [ -f "$bd/.Entitlements.plist" ]; then
	rm "$bd/.Entitlements.plist" 
fi
}

#returns the last $1 characters of $2 (used to check extension of an arg)
function last
{
echo -n "$2" | tail -c "$1"
}

##Parsing Functions##

#takes a string ($1) and returns a value for the key (passed in a $2)
function value_for_key
{
tmp="${1##*<key>"$2"</key>}"
tmp="${tmp%%</*}"
tmp="${tmp##*>}"
echo "$tmp"
}

#returns useful information from an Info.plist
function parse_info
{
echo "              CFBundleName: $(value_for_key "$1" "CFBundleName")"
echo "       CFBundleDisplayName: $(value_for_key "$1" "CFBundleDisplayName")"
echo "        CFBundleIdentifier: $(value_for_key "$1" "CFBundleIdentifier")"
echo "           CFBundleVersion: $(value_for_key "$1" "CFBundleVersion")"
echo "CFBundleShortVersionString: $(value_for_key "$1" "CFBundleShortVersionString")"
}

#returns useful information from a profile
function parse_profile
{
echo "           App ID Name: $(value_for_key "$1" "AppIDName")"
echo "Application Identifier: $(value_for_key "$1" "application-identifier")"
echo "      Certificate Name: $(value_for_key "$1" "Name")"
echo "             Team Name: $(value_for_key "$1" "TeamName")"
echo "                  UUID: $(value_for_key "$1" "UUID")"
echo "               Version: $(value_for_key "$1" "Version")"
}

#returns profile name from a list of resign args
function profile_from_args
{
tmp=
while [ "$1" != "" ];do
	case "$1" in
		-p | --profile )	if [ "${2:0:1}" = "-" -o "$2" = "" ];then
		        				break
				        	fi
				        	cd $wd
				        	tmp=$2
				        	if [ "$2" = "*/*" ]; then
					    	cd $(dirname ${2})
					    	tmp=$(basename ${2})
    				    	fi
    					    dir=$(pwd)
    				    	echo $dir/$tmp
    			    		break;;
		* )			        shift;;
	esac
done
if [ "$tmp" != "" ]; then
	return
fi
cd $bd
find ./ -type f -d 1 -iname "*.mobileprovision" | while read f; do
        f=${f:3}
        echo "$bd/$f"
        break
done
}

#returns "dc" if -d -c -dc --check or --doublecheck option in args list
function dc_from_args
{
while [ "$1" != "" ];do
	case "$1" in
		-d | -c | -dc | --check | --doublecheck ) 	echo "dc"
								break;;
		* )						shift
	esac
done
}

#Make Entitlements.plist - $1 is the full profile text
function make_entitlements_from_profile
{
echo '<?xml version="1.0" encoding="UTF-8"?>'
echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
echo '<plist version="1.0">'
echo '<dict>'
tmp="${1##*Entitlements</key>}"
tmp="${tmp#*<dict>}"
tmp="${tmp%%</dict>*}"
echo "$tmp"
echo '</dict>'
echo '</plist>'
}

#### MAIN ####
#if the first arg is an ipa file, use the ipa's directory as the basedirectory ($bd) and the ipa as the ($ipa)
#if the first arg is a path, use that path as the bd, otherwise use the working directory as the bd
#if the first arg is a mobileprovision file, use that file as the profile ($profile) and the profile's directory as the bd
#if the first arg is an Info.plist file, use that file as the $(infoplist) and the Info.plist's directory as the bd
#otherwise use the first ipa file (alphabetically) in the bd as the ipa.

## COMMANDS THAT DON'T NEED AN IPA OR PATH ##

#first arg should be the command ($cmd) 
cmd="$1"

#if there was no command, exit
if [ "$cmd" = "" ];then
    problem_encountered "no command"
else
    shift
fi

#if cmd was "help" or "h" show the usage page
if [ "$cmd" = "help" -o "$cmd" = "h" ];then
    if [ "$1" = "" ]; then
        help_help
        script_done
    fi
    if [ "$1" = "-v" ]; then
        help_get
        help_certs
        help_profile
        help_info
        help_resign
        script_done
    fi
    while [ "$1" != "" ]; do
        case "$1" in
            [hH]* ) help_help;;
            [gG]* ) help_get;;
            [cC]* ) help_certs;;
            [pP]* ) help_profile;;
            [iI]* ) help_info;;
            [rR]* ) help_resign;;
            * ) problem_encountered "Not a valid command";;
        esac
        shift
    done
    script_done
fi

#if the cmd is "c" or "certs" or "certificates", display the information about certificates in the keychain
#if there is a following argument, it limits the certificates shown to ones matching this substring
if [ "$cmd" = "c" -o "$cmd" = "certs" -o "$cmd" = "certficiates" ];then
    tmp=
    if [ "$1" != "" ]; then
        tmp=" -c $1"
    fi
    certs="$(security find-certificate$tmp -a)"
    echo '********************** Certificates **********************' 
    while read line; do
        if [ "$line" != "${line#*'labl"<blob>="'}" ]; then
            tmp="${line#*'labl"<blob>="'}"
            echo ${tmp%?}
        fi
    done <<< "$certs"
    script_done
fi

#if the cmd is "get" or "g, move following args to the working directory if they are mobileprovision files.  If no args specified, pull all mobileprovision files from the ~/Downloads/ folder
if [ "$cmd" = "get" -o "$cmd" = "g" ];then
    echo "moving..."
    if [ "$1" = "" ];then
        find ~/Downloads/ -type f -iname "*.mobileprovision" | while read f; do
            echo "$f"
            profilename="$(basename ${f})"
            mv "$f" "./$profilename"
        done
        script_done
    fi
    while [ "$1" != "" ];do
        if [ "${1%.mobileprovision}" != "$1" ];then
            echo "$1"
            profilename="$(basename ${1})"
            mv "$1" "$bd/$profilename"
        else
            problem_encountered "Not a profile"
        fi
        shift
    done
    script_done
fi

# get ipa/profile/info.plist/directory for the following commands that need one of these.

wd=$(pwd)
bd=$(pwd)
ipa=
profile=
infoplist=
if [ "${1%.ipa}" != "$1" ];then
	bd=$(dirname ${1})
	ipa=$(basename ${1})
	shift
	cd $bd
	bd=$(pwd)
elif [ "${1%.mobileprovision}" != "$1" ];then
	bd=$(dirname ${1})
    profile=$(basename ${1})
    shift
    cd $bd
    bd=$(pwd)
	profile="$bd/$profile"
elif [ "${1%Info.plist}" != "$1" ];then
	bd=$(dirname ${1})
    infoplist=$(basename ${1})
    shift
    cd $bd
    bd=$(pwd)
	infoplist="$bd/$infoplist"
else
	if [ "${1: -1}" = "/" ];then
		cd $1
		bd=$(pwd)
		shift
	fi
	ipa=$(ipa_in_wd)
fi 

## COMMANDS THAT DO NEED AN IPA (or profile or info.plist)##

#profile commands
if [ "$cmd" = "p" -o "$cmd" = "prof" -o "$cmd" = "profile" ];then
	#if the first arg wasn't a profile, then an ipa file is necessary
	if [ "$profile" = "" ];then
		assert_ipa mobileprovision
		ad=$(make_ad)
		profile="$bd/$ad/embedded.mobileprovision"
	fi
	profile=$(security cms -D -i "$profile")
	if [ "$1" = "" ];then
		echo '*********************************************************'
		parse_profile "$profile"
		echo '*********************************************************'
		script_done
	fi
	while [ "$1" != "" ];do
		case "$1" in
			-v | --verbose )	echo "$profile";;
			-i | --id )		echo "Application Identifier: $(value_for_key "$profile" "application-identifier")";;
			-n | --name )		echo "App ID Name: $(value_for_key "$profile" "AppIDName")";;
			-c | --certificate ) 	echo "Certificate Name: $(value_for_key "$profile" "Name")";;
			-t | --team )		echo "Team Name: $(value_for_key "$profile" "TeamName")";;
			-u | --uuid )		echo "UUID: $(value_for_key "$profile" "UUID")";;
			-r | --version )	echo "Version: $(value_for_key "$profile" "Version")";;
			-e | --entitlements )	tmp="${profile##*Entitlements}"
						tmp="${tmp#*<dict>}"
						tmp="${tmp%%</dict>*}"
						tmp="${tmp//?[[:space:]]</<}"
						tmp="${tmp:1}"
						echo '***************ENTITLEMENTS***************'
						echo "$tmp"
						echo '******************************************';;	
			-k | --key )		shift
						if [ "$1" = "" ];then
							problem_encountered "key option needs a parameter"
						fi
						echo "$1: $(value_for_key "$profile" "$1")";;
			* )			problem_encountered "Invalid Option"
		esac
		shift
	done
	script_done
fi

#Info.plist commands
if [ "$cmd" = "i" -o "$cmd" = "info" ];then
	if [ "$infoplist" = "" ];then
		assert_ipa Info.plist
    	ad=$(make_ad)
		infoplist="$bd/$ad/Info.plist"
	fi
	cp $infoplist $bd/.Info.plist
	infoplist="$bd/.Info.plist"
	plutil -convert xml1 "$infoplist"
	infoplist="$(cat "$infoplist")"
	if [ "$1" = "" ];then
                echo '*********************************************************'
                parse_info "$infoplist"
                echo '*********************************************************'
                script_done
    fi
    while [ "$1" != "" ];do
            case "$1" in
                        -v | --verbose )		echo "$infoplist";;
                        -n | --name )			echo "CFBundleName: $(value_for_key "$infoplist" "CFBundleName")";;
                        -d | --display )        	echo "CFBundleDisplayName: $(value_for_key "$infoplist" "CFBundleDisplayName")";;
                        -i | --identifier )   		echo "CFBundleIdentifier: $(value_for_key "$infoplist" "CFBundleIdentifier")";;
                        -r | --version )          	echo "CFBundleVersion: $(value_for_key "$infoplist" "CFBundleVersion")";;
                        -s | --short | --shortVersion ) echo "CFBundleShortVersionString: $(value_for_key "$infoplist" "CFBundleShortVersionString")";;
                        -k | --key )            	shift
                                                	if [ "$1" = "" ];then
                                                        	problem_encountered "key option needs a parameter"
                                                	fi
                                                	echo "$1: $(value_for_key "$infoplist" "$1")";;
                        * )                     	problem_encountered "Invalid Option"
                esac
                shift
        done
        script_done

fi

#verify command, to see if an ipa is signed
if [ "$cmd" = "v" -o "$cmd" = "verify" ];then
	assert_ipa
	ad=$(make_ad)
	cd $(dirname $bd/$ad)
	base=$(basename ${ad})	
	codesign --verify -vvvv $base
	script_done
fi

#resign command, to resign an ipa
if [ "$cmd" = "r" -o "$cmd" = "resign" ];then
	assert_ipa
	ad=$(make_ad)
	profile=$(profile_from_args $@)
	if [ "$profile" = "" ];then
		problem_encountered "No Provisioning profile"
	fi
	fullprofile=$(security cms -D -i "$profile")
	cert="$(value_for_key "$fullprofile" TeamName)"
	appid="$(value_for_key "$fullprofile" application-identifier)"
	cp "$bd/$ad/Info.plist" "$bd/.Info.plist"
    plutil -convert xml1 "$bd/.Info.plist"
    infoplist="$(cat "$bd/.Info.plist")"
	bundleid="$(value_for_key "$infoplist" CFBundleIdentifier)"
	entitlementsstring="--entitlements .Entitlements.plist"
    tent=$(make_entitlements_from_profile "$fullprofile")
    echo "$tent" > .Entitlements.plist
	dc=$(dc_from_args $@)
	if [ "$dc" = "dc" ];then
		echo '*************************IPA File*************************'
		echo "IPA: $ipa"
		echo '************************Info.plist************************'
        parse_info "$infoplist"
        echo '*************************Profile**************************'	
		parse_profile "$fullprofile"
		echo '**********************************************************'	
		echo -n 'Continue with resign? (Y or N):'
        read input
		while [ "$input" != "Y" ];do
			case "$input" in
				[nN]* )	script_done;;
				[yY]* ) break;;
				* )	echo -n 'Continue with resign? (Y or N):'
					read input;;
			esac
		done			
	fi
	#make sure AppID and CFBundleID match
	bundlestring=
	if [[ "${appid#*.}" != "$bundleid" ]]; then
		echo '**********************************************************'
		echo "The profile's App ID: $appid and the"
		echo "ipa file's Bundle ID: $bundleid do not match."
		echo "Continue with resign using the profile's"
		echo -n "bundle ID: ${appid#*.} or the ipa's ? (Y or N or E to edit Info.plist):"
		read input
                while [ "$input" != "Y" ];do
                        case "$input" in
                                [nN]* ) script_done;;
                                [yYeE]* ) break;;
                                * )     echo -n 'Continue with resign? (Y, N or E):'
                                        read input;;
                        esac
                done
		xml=Y
		newbundleID=
		#check to see if the info.plist is a binary
		plist="$(cat $bd/$ad/Info.plist)"
		if [ "${plist:0:5}" != "<?xml" ]; then
			xml=N
			plutil -convert xml1 $bd/$ad/Info.plist
		fi
		case "$input" in
			[yY]* ) tmp="${infoplist#*<key>CFBundleIdentifier</key>}"
				tmp="${infoplist#*<key>CFBundleIdentifier</key>}"
				tmp="${tmp#*</}"
				tbck="</$tmp"
				tmp="${infoplist%$tbck}"
				tmp="${tmp%>*}"
				tfrt="$tmp>"	
				newbundleID="${appid#*.}"
				echo "$tfrt$newbundleID$tbck" > "$bd/$ad/Info.plist";;
			[eE]* )	vi $bd/$ad/Info.plist
				newbundleID="$(value_for_key "$(cat "$bd/$ad/Info.plist")" "CFBundleIdentifier")";;
		esac		
		if [ "$xml" = "N" ]; then
			plutil -convert binary1 "$bd/$ad/Info.plist"
		fi
		bundlestring="-i $newbundleID"
		echo "bundlestring: $bundlestring"
	fi
	####
	#see if they specified another cert - I don't think this is necessary
	####
	cd $bd
	rm -rf "$ad/_CodeSignature/"
	cp $profile "$bd/$ad/embedded.mobileprovision"
	codesign -f -s "$cert" $entitlementsstring $bundlestring $ad
	newipa="${ipa%.*}-resigned.ipa"
	echo $newipa
	zip -qr $newipa .ipa_payload/Payload/
	script_done
fi


#cmd was not a valid command
if [ "${cmd:0:1}" = "-" ];then
	problem_encountered "Missing Command"
fi

problem_encountered 'not a valid command'

