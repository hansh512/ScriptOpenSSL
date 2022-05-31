###############################################################################
# Code Written by Hans Halbmayr
# Created On: 14.04.2022
# Last change on: 27.05.2022
#
# Script: commonFunctions.sh 
#
#
# Version 1.0
#
# Purpose: Script with function used in various scripts and functions
################################################################################

function getTypOfSanEntry()
{
    local  entry=$1
    local  stat=0 # init var, if 2 no ip address (FQDN)

    local ipv6Pattern='^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$';
    if [[ $entry =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]];
    then
        IFS='.' read -ra ip_array <<< $entry
        OIFS=$IFS
        IFS='.'
        ip=($entry)
        IFS=$OIFS        
        # verify if the ip address is valid
        stat=0 ;            # entry of type IP        
        if [[ ${ip[0]} -le 223 &&  ${ip[0]} -gt 0 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 &&  ${ip[3]} -gt 0 ]]
        then
            stat=0;     # valid ip address
        else
            stat=8;     # invalid ip address
        fi;        
    elif  [[ $entry =~ $ipv6Pattern ]];
    then
        stat=0       
    else
        #invalidChars='*/*:*\*';
        case $entry in
           http://* )
            
                stat=1;     # entry of tpye URI
                break;
            ;;
            https://* )
            
                stat=1;     # entry of tpye URI
                break;
            ;;
            ldap://* )
            
                stat=1;     # entry of tpye URI
                break;
            ;;
            */* )
            
                stat=9;      # wrong entry
                break;
            ;;
            *:* )
            
                stat=9;      # wrong entry
                break;
            ;;
            *\\* )
            
                stat=9;      # wrong entry
                break;
            ;;
            *@*.* )
            
                stat=2;     # entry of type email
                break;
            ;;
            *.* )
            
                stat=3;     # entry of type DNS
                break;
            ;;
            *)
                stat=9;     # wrong entry 
            ;;
        esac;
    fi;    
    echo $stat
} # end function getTypOfSanEntry


function updateTemplate()
{
    # assign arguments to vars
    tFileName=$1;                # name of the conf file to edit
    caType=$2;                  # ca type (root or signing)
    certEnroll=$3;              # ca conf file or conf file for cert enrollment

    case $caType in
    'root')
        # vars for root ca
        local caDirName=$rootCADirName;
        local caCrlName=$rootCACrlName;
        local caCertName=$rootCAcertName;
        local caAiaName=$rootCAaiaName;
        local caKeyName=$rootCAKeyName;
        local defCN=$customDefault_RootCAName;
        echo 'Updating root CA conf files'
        break;
    ;;
    'signing')
        # vars for signing ca and cert rollout
        local caDirName=$signingCADirName;
        local caCrlName=$signingCACrlName;
        local caCertName=$signingCAcertName;
        local caAiaName=$signingCAaiaName;
        local caKeyName=$signingCAKeyName;
        if $certEnroll
        then
            defCN=$certCN;
        else
            defCN=$customDefault_SigningCAName;
            echo 'Updating signing CA conf files'
        fi;
        break;
    ;;
    *)
        echo -e "${R_Blk}Incorrect ca tpye.${COLOR_Off}"
        return false;
    ;;
    esac;
    # replacing strings with slashes
    local confFileReplacementString='_replaceThis-2f56e75f-4e09-4370-bb8c-e32b747170e3'  # sting for replancing placehoder values in root and issuing ca conf files
    local tmpConfFileName="${scriptTmpDir}/$(uuidgen)";   # name for tmp file  
    local strDelim='€';                                   # delimiter for search and replacement string           
    local sStr[0]="__rootDir${confFileReplacementString}${strDelim}${caRootDir}";
    local sStr[1]="__CRLbaseURL${confFileReplacementString}${strDelim}${crlBaseDir}";
    local sStr[2]="__AIAbaseURL${confFileReplacementString}${strDelim}${aiaBaseDir}";
    
    local maxIt=${#sStr[@]};                              # get numver of array entries
    local i=0;                                            # set num for iterations to 0    
    while [ $i -lt $maxIt ]
    do        
        tmpArray=(${sStr[$i]//€/ });                # split line in array         
        rv=$(grep -n ${tmpArray[0]} $tFileName)
        if [[ -n $rv ]]                                                         # check if string was found
        then
            local lineNumRootDir="$(cut -d':' -f1 <<<"$rv")";                         # extract line number of string
            local tmpTxt="$(cut -d':' -f2 <<<"$rv")";                                 # extract rest of the string
            local tmpConfFileName="${scriptTmpDir}/$(uuidgen)";                       # create name for temp file         a
            awk "FNR < $lineNumRootDir" $tFileName >> $tmpConfFileName;         # copy first part of conf file
            echo "${tmpTxt/${tmpArray[0]}/${tmpArray[1]}}" >> $tmpConfFileName; # add var for root pat                             
            awk "FNR > $lineNumRootDir" $tFileName >> $tmpConfFileName;             
            mv $tmpConfFileName $tFileName;                                     # copy tmp file to conf file                                                
        fi;
        ((i++));                                                                # inc counter i
    done;

    # writing custom entries to conf files
    # ca     settings
    sed -i "s/^.*\__caDirName${confFileReplacementString}\b.*$/ca = ${caDirName}/" $tFileName;
    sed -i "s/^.*\__crlName${confFileReplacementString}\b.*$/ca_crlFile = ${caCrlName}/" $tFileName;    
    sed -i "s/^.*\__certName${confFileReplacementString}\b.*$/ca_certFile = ${caCertName}/" $tFileName;
    sed -i "s/^.*\__keyName${confFileReplacementString}\b.*$/ca_keyFile = ${caKeyName}/" $tFileName;
    sed -i "s/^.*\__AIAFileName${confFileReplacementString}\b.*$/ca_aiaFile = ${caAiaName}/" $tFileName;
    sed -i "s/^.*\__privKeyEncrypt${confFileReplacementString}\b.*$/privKeyEncrypt = ${privKeyEncrypt}/" $tFileName;
    sed -i "s/^.*\__certPrivateKeyLength${confFileReplacementString}\b.*$/certPrivateKeyLength = ${certPrivateKeyLength}/" $tFileName;
    
    # org settings    
    sed -i "s/^.*\__countryCode${confFileReplacementString}\b.*$/def_CountryCode = ${customDefault_defCountryCode}/" $tFileName;
    sed -i "s/^.*\__province${confFileReplacementString}\b.*$/def_Province = ${customDefault_defProvince}/" $tFileName;
    sed -i "s/^.*\__location${confFileReplacementString}\b.*$/def_Location = ${customDefault_defLocation}/" $tFileName;
    sed -i "s/^.*\__OU${confFileReplacementString}\b.*$/def_OU = ${customDefault_defOU}/" $tFileName;
    sed -i "s/^.*\__organization${confFileReplacementString}\b.*$/def_Organization = ${customDefault_defOrganization}/" $tFileName;
    sed -i "s/^.*\__cn${confFileReplacementString}\b.*$/def_CommonName = ${defCN}/" $tFileName; 
    sed -i "s/^.*\__mailAddress${confFileReplacementString}\b.*$/def_mailAddress = ${emailAddress}/" $tFileName; 

}; # end function updateTemplate

function readVarInfo()
{
    # creating variables from arguments
    local infoText=$1;                  # text displayed before the read prompt
    local numOfChars=$3;                # num of charachter for read (if 0 unlimited)
    local testVar=$4;                   # if >0, variable must be tested if chars are valid. Old var name testIfInt
    local removeTrailingSlash=$5        # if 1, trailing slash is removed from variable
    local -n ref=$2;                    # referencing variable from calling function/script
    local showDelMsg=$6

    local intCheckLoop=1;
    
    while [ $intCheckLoop -eq 1 ]
    do 
        echo -e "${Y_Blk}${infoText}${COLOR_Off}";
        if [ -n "$ref" ] 
        then
            if [ $showDelMsg = true ]
            then
            echo 'To delete the value enter .';
            fi;
            local tmpDefString="Press ENTER to accept ${ref}: ";
        else
            local tmpDefString='';
        fi;
        
        if [ $numOfChars -eq 1 ]
        then
            read -n $numOfChars -p "$tmpDefString" tmpAnswer;
            echo '';
        else
            read -p "$tmpDefString" tmpAnswer;
        fi;

        if [[ "$numOfChars" -gt 0   &&  "${#tmpAnswer}" -gt "$numOfChars" ]]
        then 
            echo -e "${R_Blk}${tmpAnswer} is too long. Only ${numOfChars} characters are allowed.${COLOR_Off}";
            continue ; # restart loop, string too long
        fi;
               
        case $testVar in
            '0')
                local intCheckLoop=0;                                             # no int check required
                break;               
            ;;
            '1')
                rv=$(testIfInteger $tmpAnswer)                              # check if integer                                   
                if [ $rv -gt 0 ]
                then
                    local intCheckLoop=0;                                         # if empty or integer
                else
                    echo -e "${R_Blk}${tmpAnswer} is not an integer value.${COLOR_Off}";
                fi;
            ;;
            '2')                                
                if [[ "$tmpAnswer" =~ ^[a-zA-Z0-9_-.=@\ *]*$ ]]               
                then
                    local intCheckLoop=0;
                else                        
                    echo -e "${R_Blk}The name is invalid!\nOnly the following characters are allowed: a-zA-Z0-9_-.=@\ *${COLOR_Off}";
                fi;            
            ;;
        esac;           
    done; # end integer check loop
    
    if [ -n "$tmpAnswer" ]                              # if a non blank value was provided, store it in variable
    then                    
        # assigning value to ref varaibale
        if [ $removeTrailingSlash -gt 0 ]
        then
            ref=$(echo $tmpAnswer | sed "s,/$,,");      # declare global var and remove trailing slashes
        else            
            ref=$tmpAnswer;                                          # assign value to reference variable            
        fi;
    fi;
}; # end function readVarInfo


function testIfInteger()
{
    local valToCheck=$1;
    if [[ "$valToCheck" =~ [0-9]+$ ]]
    then
        # value is integer
        echo 1;
        return 0;
    elif [ -n "$valToCheck" ] 
    then
        # val is not an integer        
        echo 0;
        return 0;
    fi;
        # val is an empty val
        echo 2;
        return 2;
}; # end function testIfIntegerOrEmpty


function giveYesNoConfirmation
{
    local readPrompt=$1;
    local -n ref=$2;                # referencing variable from calling function/script
    local whiteText=$3;

    local localLoop=1;
    while [ $localLoop -eq 1 ]
    do
        if [ $whiteText -eq 1 ]
        then
            read  -n 1 -p "$readPrompt" tmpAnswer;
        else
            read  -n 1 -p $'\e[33m'"$readPrompt" tmpAnswer;
            echo -e "${COLOR_Off}"
        fi;
        echo
        case $tmpAnswer in
            'y')
                local localLoop=0;
                ref=0;
                break;
            ;;
            'n')                            
                local localLoop=0;            
                ref=1;            
            ;;
            *)
                echo -e "${R_Blk}Wrong choice. Please type y for Yes or n for No.${COLOR_Off}"
            ;;
        esac; # case y/n
    done; # end while loop
}; # end function giveConfirmation

function addExtension()
{
    local extName=$1;           # name of the extension
    local targetFile=$2;        # target conf file (used to create the cert)
    local sourceFile=$3;        # source conf fiel (used for the cert request) 
    local signingReqFile=$4;    # signing request file 
    
    local tmpFileName="${scriptTmpDir}/$(uuidgen)"
    grep -n '^\[' $sourceFile > $tmpFileName;                                               # get a list of sections in conf file and pipe to temp file
    local tmpVar=$(grep -n "$extName" $tmpFileName);                                        # get the entry with the extension from temp file
    local lnInTmp=$(echo $tmpVar | awk -F':' '{print $1}');                                 # get the line number of the entry in temp file
    local lnInConf=$(echo $tmpVar | awk -F':' '{print $2}');                                # get the line number where the extension starts from conf file
    local tmpNextLine=$(head -n $((lnInTmp+1)) $tmpFileName | tail -n 1);                   # get the entry for the next section from temp file
    local lnEndExt=$(echo $tmpNextLine | awk -F':' '{print $1}');                           # get the line number where the next section starts in conf file
    rm $tmpFileName;                                                                        # remove temp file
    if [ $lnInConf -eq $lnEndExt ]
    then
        local lnEndExt=$(wc -l < $sourceFile);                                              # get the line count of file
        ((lnEndExt++));                                                                     # add 1 to line count
    fi;
    
    echo "aia_url = ${aiaBaseDir}/${signingCAaiaName}" > $targetFile;
    echo "crl_url = ${crlBaseDir}/${signingCACrlName}" >> $targetFile;  
    echo  $(grep 'default_days' $signingReqFile $targetFile);
    head -n $((lnEndExt-1)) $sourceFile | tail -n $((lnEndExt - lnInConf)) >> $targetFile;   # create file and add extension to conf file    
    echo 'authorityInfoAccess     = @issuer_info' >> $targetFile;                           # add issuer ingo
    echo 'crlDistributionPoints   = @crl_info' >> $targetFile;                              # add crl dist point

    addSanEntries $targetFile $signingReqFile;                                              # verify if san entries to add

    echo '';
    echo '' >> $targetFile;
    echo '[ issuer_info ]' >> $targetFile;
    echo '';
    echo '';
    echo 'caIssuers;URI.0         		= $aia_url' >> $targetFile;
    echo '';
    echo '[ crl_info ]' >> $targetFile;
    echo 'URI.0                   		= $crl_url' >> $targetFile;
    #cleanUpDN $targetFile;    
}; # end function addExtension

function cleanUpDN
{
    local varname=$1;
    local searchStr=$2;
    local varSearchStr=$3;
    local confFileName=$4;
    
    if [ ${!varname} = '.' ]            # verify if var is equal a dot    
    then
        sed -i "/^${searchStr}.*=.*\$$varSearchStr/d" $confFileName;   # remove entry from subject name
    fi;
}; # end function cleanUpDN


function addSanEntries()
{
    local outFile=$1;
    local csrf=$2;
    
    local searchStr='Subject Alternative Name: ';
    local sanContent=$(openssl req -in "${csrf}" -text -noout | grep "$searchStr" -A 1 | tail -n 1);
    if [[ -n $sanContent ]]                                             # check if string was found
    then        
        local sanContent=$(echo $sanContent | tr -d '\r');              # remove CR
        local tmpFileName="${scriptTmpDir}/$(uuidgen)";
        declare -a local tmp1san_array;
        local sanContent=$(echo ${sanContent//, /'€'});                 # replace , and space with €, so string can be splitted easily        
        IFS='€' read -ra  tmp1san_array <<< $sanContent;                # split string of san entries
        
        i=0;    # init counter
        while [ $i -lt ${#tmp1san_array[@]} ]
        do            
            echo ${tmp1san_array[$i]} | awk -F: '{ st = index($0,":");print substr($0,st+1)}' >> $tmpFileName;  # write entry to file
            ((i++));    # inc counter
        done;        
        addSanEntriesToFile $tmpFileName $outFile;
        
    fi;
}; # end function addSanEntries

function addSanEntriesToFile
{
    local sanEntrySourceFile=$1;
    local sanEntryTargetFile=$2;
 
    declare -a sanEntries=();       # init array for san entries
    i=0;                            # init var for array index
    ipCount=0;                      # init var for count of IP addresses
    fqdnCount=0;                    # init var for count of DNS entries
    declare -A sanEntryTypeCount;
    sanEntryTypeCount['ip']=0;      # count IP entries
    sanEntryTypeCount['uri']=0;     # count URI entries
    sanEntryTypeCount['email']=0;   # count email entries
    sanEntryTypeCount['dns']=0;     # count DNS entries
    
    while IFS= read -r line; 
        do            
        creteSanEntry "$line" $i
        ((i++))  
    done < "${sanEntrySourceFile}";    
    rm -f $sanEntrySourceFile;      
    
    echo 'subjectAltName          = @alt_names' >> $sanEntryTargetFile;            # add entry to newly added section in conf file
    echo '' >> $sanEntryTargetFile;
    echo '[ alt_names ]' >> $sanEntryTargetFile;
    i=0;                                                                     # init var to iterate through array
    while [ $i -lt ${#sanEntries[@]} ] 
    do            
        # add san entries to conf
        echo ${sanEntries[$i]} >> $sanEntryTargetFile;
        ((i++));    
    done ;       
}; # end function addSanEntriesToFile


function getValFromConfFile()
{
    local fileName=$1;
    local searchStr=$2;
        
    local tmpVal=$(grep "^.*${searchStr}" $fileName);                                       # get default cert validity
    local tmpVal=${tmpVal[0]};
    local -a cfgValue='';                                
    IFS='=' read -ra cfgValue <<< $tmpVal;
    local rv=$(echo "${cfgValue[1]}" | awk -F'#' '{print $1}');               
    local rv=$(echo ${rv//[[:blank:]]/});                                                   # get default value and remove blanks         
    local rv=$(echo $rv | tr -d '\r');                                                      # for to be on the save side, remove CR    
    echo  $rv;                                                                              # return value found
 
}; # end function getValFromConfFile

function verifyDirectory()
{
    local directoryName=$1;
    local displayMessage=$2;        # if false, it is not expected, that the directory exists
    local archiveExisistingDir=$3   # if the directory exists, rename it in an arcive directory

    if [ !  -d $directoryName ]
    then
        if $displayMessage -eq true     # should the directory exist
        then
            echo -e "${Y_Blk}WARNING: Missing directroy $directoryName${COLOR_Off}";
        fi; # end if display warning
        mkdir $directoryName;
        if [ $? -eq 0 ]
        then
            if [ $displayMessage = true ]
            then
            echo -e "${G_Blk}Successuflly created directory $directoryName${COLOR_Off}";
            fi; # end if, display message
        else
            echo -e "${R_Blk}ERROR: Failed to create directory $directoryName, stopping${COLOR_Off}";
            exit;
        fi; # end if, dir successful created
    else    # directory exists
        if $archiveExisistingDir            # should an existing directory be archived?
        then
            local archiveExt=1;                       
            if [ -d $directoryName ]    
            then
                local renDirName="${caRootDir}/${signingCADirName}/issuedcerts/_archive/${tmpCertName}_${archiveExt}";
                while [ -d $renDirName ]
                do
                    ((archiveExt++));
                    local renDirName="${caRootDir}/${signingCADirName}/issuedcerts/_archive/${tmpCertName}_${archiveExt}"; # recalulate name of archiving directory
                done;
                
                mv $directoryName $renDirName;                    
                if [ $? -ne 0 ]             # check for error
                then
                    echo -e "${R_Blk}A certificate with the name $tmpCertName already exists. Failed to rename the directory\n$directoryName$ to \n${renDirName}${COLOR_Off}";                        
                    exit; # exit script
                else
                    mkdir $directoryName;
                    if [ $? -eq 0 ]
                    then
                        if $displayMessage -eq true
                        then
                        echo -e "${G_Blk}Successuflly created directory $directoryName${COLOR_Off}";
                        fi; # end if, display message
                    else
                        echo -e "${R_Blk}ERROR: Failed to create directory $directoryName, stopping${COLOR_Off}";
                        exit;
                    fi; # end if, dir successful created
                fi; 
            fi; # check if directory exists            
        fi;
    fi; # end if dir exists
    verifyIfDirIsWriteable $directoryName;
}; # end function verifyDirectory

function verifyIfDirIsWriteable
{
    local dirName=$1;
    local tmpFName=$(uuidgen);

    echo 'test' > "${dirName}/${tmpFName}";
    if [ $? -eq 0 ]
    then
        rm -f "${dirName}/${tmpFName}";
        if [ $? -ne 0 ]
        then
            echo -e "${Y_Blk}Warning: faild to delete test file ${tmpFName} in directory ${dirName}.${COLOR_Off}";
            sleep 2s;
        fi;
        
    else
        echo -e "${R_Blk}ERROR: Failed to write to directoy $dirName, stopping.${COLOR_Off}";
        exit;
    fi; # end if
}; # end function verifyIfDirIsWriteable

function creteSanEntry()
{
	local nameString=$1  # get first argument 
    local arrIndex=$2
    local rv="$(getTypOfSanEntry $nameString)";   # verify the type of san entry    
    # san entry types:
    # 0 IP
    # 1 URI
    # 2 email
    # 3 DNS
    # 8 invalid IP address string
    # 9 invalid
    case $rv in
			0)
				((sanEntryTypeCount['ip']++))
                sanEntries[$arrIndex]="IP.${sanEntryTypeCount['ip']} = $nameString";
                break;
				;;
            1)
				((sanEntryTypeCount['uri']++))                
                sanEntries[$arrIndex]="URI.${sanEntryTypeCount['uri']} = $nameString";
                break;
				;;
            2)
				((sanEntryTypeCount['email']++))
                #sanEntries[$arrIndex]="email.$ipCount = $nameString";
                sanEntries[$arrIndex]="email.${sanEntryTypeCount['email']} = $nameString";
                break;
				;;
            3)
				((sanEntryTypeCount['dns']++))
                sanEntries[$arrIndex]="DNS.${sanEntryTypeCount['dns']} = $nameString";
                break
				;;
			8)
				echo -e "${R_Blk}ERROR: IP address $nameString is invalid. The IP address will not be added to the subject alternative names.${COLOR_Off}";
				break
				;;
			9)
				echo -e "${R_Blk}ERROR: Entry $nameString has an unknown format. It will not be added to the subject alternative names.${COLOR_Off}";                
				;;
	esac    
} # end function creteSanEntry

function getCertData
{
    local askForKeyData=$1;
    
    certValLoop=1;                                                                      # set loop var    
    while [ $certValLoop -eq 1 ]
    do        
        certValidDays=$(echo $certValidDays | tr -d '\r');                              # remove carriage return from string
        readVarInfo 'Verifiying how long the certificate is valid. Enter the number of days or hit ENTER to accept the default' 'certValidDays' 0 1 0 false; 
        
        if [ $askForKeyData = true ]
        then
            dummyLoop=0;  
            echo -e "${Y_Blk}Do you wish to protect private key of the certificate with a pass phrase?${COLOR_Off}";       
            giveYesNoConfirmation 'Protect the private key oft the certificate? [y/n]: ' 'dummyLoop' 1;
            if [ $dummyLoop -eq 0 ]
            then
                privKeyEncrypt='yes';
            else
                privKeyEncrypt='no';
            fi; # end encrypt priv key of cert
        
            keyLengthLoop=1;
            while [ $keyLengthLoop -eq 1 ]
            do
                tmpVal=$certPrivateKeyLength;
                readVarInfo 'Key lenght for certificate private key. Enter 2 for 2048 or 4 for 4096 bit' 'certPrivateKeyLength' 1 1 0 false;         
                case  $certPrivateKeyLength in 
                    2)
                        certPrivateKeyLength=2048;
                        keyLengthLoop=0;
                    ;;
                    2048)
                        keyLengthLoop=0;
                    ;;
                    4)
                        certPrivateKeyLength=4096;
                        keyLengthLoop=0;
                    ;;
                    4096)
                        keyLengthLoop=0;
                    ;;
                    *)
                        echo -e "${R_Blk}ERROR: Only the values 2 or 4 are as input accepted.${COLOR_Off}";
                        certPrivateKeyLength=$tmpVal;
                    ;;
                esac;       
            done;
        fi; # ask for key passphrase       
        echo -e "${Y_Blk}Please verify if the following values are correct.${COLOR_Off}";
        echo "Days valid:                           ${certValidDays}";
        if [ $askForKeyData = true ]
        then
            echo "Encrypt private key of certificate    $privKeyEncrypt";        
            echo "Certificate Private key length        $certPrivateKeyLength";
            queryLoop=1;
            giveYesNoConfirmation 'Are the values correct? [y/n]: ' 'certValLoop' 0;    
        fi; # ask for key passphrase           
    done;

}; # end function getCertData

function configOrganizationData
{

    getInfoLoopCustom=1; #$custLoopVal;        
    echo -e "${Y_Blk}Collecting organizational information${COLOR_Off}" ;
    while [ $getInfoLoopCustom -eq 1 ]
    do                                   
        # readVarInfo promptText variableName numOfChar isInteger removeTrailingSlash            
        readVarInfo 'Please enter the country code (ISO 3166-1 2 letter)' 'customDefault_defCountryCode' 2 0 0 true;
        if [ -z "$customDefault_defCountryCode" ]; then customDefault_defCountryCode='.' ;fi;      
        readVarInfo 'Please enter the name of your province' 'customDefault_defProvince' 0 0 0 true;
        if [ -z "$customDefault_defProvince" ]; then customDefault_defProvince='.' ;fi;  
        readVarInfo 'Please enter the name of your location' 'customDefault_defLocation' 0 0 0 true;
        if [ -z "$customDefault_defLocation" ]; then customDefault_defLocation='.' ;fi;  
        readVarInfo 'Please enter the name of your organizational unit' 'customDefault_defOU' 0 0 0 true;
        if [ -z "$customDefault_defOU" ]; then customDefault_defOU='.' ;fi;  
        readVarInfo 'Please enter the name of your organization' 'customDefault_defOrganization' 0 0 0 true;
        if [ -z "$customDefault_defOrganization" ]; then customDefault_defOrganization='.' ;fi;  

        echo -e "${Y_Blk}Please verify if the following values are correct. A dot means not present in certificate subject.${COLOR_Off}";
        echo -e "Country code:              ${customDefault_defCountryCode}";
        echo -e "Provice:                   ${customDefault_defProvince}";
        echo -e "Location:                  ${customDefault_defLocation}";
        echo -e "Organizational unit:       ${customDefault_defOU}";
        echo -e "Organization:              ${customDefault_defOrganization}";

        confirmLoop=1;
        giveYesNoConfirmation 'Is the organizational information correct? [y/n]: ' 'getInfoLoopCustom' 0;
        #clear;
    done; # end get custom info

}; # end function configOrganizationData

function saveConfigData
{
     #convert ca validity period from years to days
    tmpDate=$(date "+%F"); 
    cDate=$(echo $tmpDate | tr -d '-');
    tmpExpDate=$(date -d "+${rootCADaysValid} years" "+%F");
    expDate=$(echo $tmpExpDate | tr -d '-');
    let rootCADaysValid=(`date +%s -d $expDate`-`date +%s -d $cDate`)/86400;
    tmpExpDate=$(date -d "+${signingCADaysValid} years" "+%F");
    expDate=$(echo $tmpExpDate | tr -d '-');
    let signingCADaysValid=(`date +%s -d $expDate`-`date +%s -d $cDate`)/86400;
    
    filename="${helperScriptDir}/customVars.sh";
    echo -e "\nWriting configuration to $filename";                    
    echo "caRootDir='$caRootDir'" > $filename;
    echo "crlBaseDir='$crlBaseDir'" >> $filename;
    echo "aiaBaseDir='$aiaBaseDir'" >> $filename;
    echo "rootCADaysValid=$rootCADaysValid" >> $filename;
    echo "rootCACRLDaysValid=$rootCACRLDaysValid" >> $filename;
    echo "customDefault_RootCAName='$customDefault_RootCAName'" >> $filename;
    echo "rootCACrlName='$rootCACrlName'" >> $filename;
    echo "rootCAaiaName='$rootCAaiaName'"  >> $filename;
    echo "signingCADaysValid=$signingCADaysValid" >> $filename;
    echo "signingCACRLDaysValid=$signingCACRLDaysValid" >> $filename;
    echo "signingCACrlName='$signingCACrlName'" >> $filename;
    echo "signingCAaiaName='$signingCAaiaName'" >> $filename;
    echo "customDefault_SigningCAName='$customDefault_SigningCAName'" >> $filename;
    echo "customDefault_defCountryCode='$customDefault_defCountryCode'" >> $filename;
    echo "customDefault_defProvince='$customDefault_defProvince'" >> $filename;
    echo "customDefault_defLocation='$customDefault_defLocation'" >> $filename;
    echo "customDefault_defOU='$customDefault_defOU'" >> $filename;
    echo "customDefault_defOrganization='$customDefault_defOrganization'" >> $filename;
    if  [ $? -eq 0 ]
    then
        echo -e "\n${G_Blk}Successfully saved configuration to ${filename}${COLOR_Off}";
    fi;
}; # end function saveConfigData

function performDNCleanUp
{
    local templateFile=$1;
    local certCNVarName=$2;

    cleanUpDN 'customDefault_defOU' 'organizationalUnitName' 'def_OU' $templateFile;
    cleanUpDN 'customDefault_defCountryCode' 'countryName' 'def_CountryCode' $templateFile;
    cleanUpDN 'customDefault_defProvince' 'stateOrProvinceName' 'def_Province' $templateFile;
    cleanUpDN 'customDefault_defLocation' 'localityName' 'def_Location' $templateFile;
    cleanUpDN 'customDefault_defOrganization' 'organizationName' 'def_Organization' $templateFile;
    cleanUpDN 'certCNVarName' 'commonName' 'def_CommonName' $templateFile;

}; # end function performDNCleanUp