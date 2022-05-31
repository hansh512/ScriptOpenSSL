###############################################################################
# Code Written by Hans Halbmayr
# Created On: 14.04.2022
# Last change on: 25.05.2022
#
# Script: request-certificate.sh 
#
#
# Version 1.0
#
# Purpose: Script for requesting certificate
################################################################################

##  init variables/constants
sourceFileDir=$(dirname "$0");                  # directory files and sub directoris for installation of CA
caRootDir="$(dirname $sourceFileDir)";          # get the root ca root directory
clear;
## get the vars for the name of the issuing ca cert and key
helperScriptDir="${caRootDir}/scripts/helperScripts";
source "${helperScriptDir}/initCAinstallVars.sh";                   # read vars from input sh file
source "${helperScriptDir}/colorCodes.sh";                          # loading constants for color codes (echo commad)
source "${helperScriptDir}/customVars.sh";                          # loading custom variables
source "${helperScriptDir}/commonFunctions.sh";                     # loading common functions

templateDir="${caRootDir}/${signingCADirName}/conf-templates";      # directory with cert templates (conf files)
scriptTmpDir="${caRootDir}/scripts/tmp";
dirlist=`ls -1 $templateDir/`
tmpFileName="${scriptTmpDir}/$(uuidgen)";                           # tmp file for template list and san entries

if [ -f  "${helperScriptDir}/customDef.sh" ]                        # test if file exist
then        
    source "${helperScriptDir}/customDef.sh";                                   # loading  value(s) for default behaviour
else
    echo 'skipProcessOrgSettings=false;' > "${helperScriptDir}/customDef.sh";   # write file if not exists
    echo "issuedCertsDir=${caRootDir}/${signingCADirName}/issuedcerts;" >> "${helperScriptDir}/customDef.sh";   # write file if not exists
    source "${helperScriptDir}/customDef.sh";                                   # loading  value(s) for default behaviour
fi;

echo $dirlist > $tmpFileName;                                       # write list of templates to tmp file

IN=$(cat ${tmpFileName})
dirList=(${IN// / });
selIsValid=0; 

counter=1;                                                          # init counter
echo -e "${Y_Blk}Please select the tempalte for the certificate request${COLOR_Off}"
for dirEntry in "${dirList[@]}"
do
    echo -e "Press ${G_Blk}${counter}${COLOR_Off} for  ${dirEntry}";
    ((counter++));       # inc counter var   
done;
echo -e "Press ${Y_Blk}c${COLOR_Off} to cancel";
echo 'Type the number of the template or c to cancel and press enter.';
##### start menu loop
while [ $selIsValid -eq 0 ]
do
    if [ $counter -gt 10 ]                              # check if mor than 9 entries
    then
        read  -p "Input selection: " templateNum;
    else
        read -n 1 -p "Input selection: " templateNum;   # if less than 10 accept only one char
    fi;
    echo ''; 

    rm -f $tmpFileName;                                                # delete tmp file with templates
    maxDirs=${#dirList[@]};
    case $templateNum in
        [1-${maxDirs}])
        selIsValid=1;
    ;;
    'c')
        echo -e "${Y_Blk}Certificate request canceled by user.${COLOR_Off}"
        exit;
    ;;
    *)
        echo -e "${R_Blk}Error: Invalid selection${COLOR_Off}";
        selIsValid=0;    
    ;;
    esac;
done;
##### end menu loop
templateName=${dirList[((templateNum-1))]};
echo -e "Selected tmplate: ${G_Blk}${templateName}${COLOR_Off}";
rqFile="${templateDir}/${templateName}/${templateName}_req.conf";    
if [ -f $rqFile ]                           # template file exist
then        
    fheader=$(head -n $baseInfoHeaderLineNum $rqFile | tail -1); 
    certExtension=$(echo $(head -n $extInfoHeaderLineNum $rqFile | tail -1) | cut -c 2-);  # get the name of the extension to use
    certExtension=$(echo $certExtension | tr -d '\r')
    useCN=0;
    useSNA=0; 
    useMail=0;          
    if [[ $fheader = *"copyissuing"* ]]
    then
        copyTemplateFromIssuing=1;
    else
        copyTemplateFromIssuing=0;
    fi;
    doLoop=1;        
    outerLoop=1
    
    # collecting cn and san data for cert
    while [ $outerLoop -eq 1 ]
    do                        
        echo -e "${Y_Blk}Collecting common name for certificate${COLOR_Off}";       
        if [[ $fheader = *"cn"* ]]
        then 
            useCN=1;
            readVarInfo 'Please enter the value for the cn  (max. 64 alphanumeric characters are allowed)' 'certCN' 64 2 0 false; 
        
            certName=$certCN;               # assign the cn to the certificate name var
        else
            readVarInfo 'Please enter a name for the certificate (max. 20 alphanumeric characters are allowed)' 'certName' 20 2 0 false;  # code should never run
        fi; # end if useCN
        if [[ $fheader = *"san"* ]]
        then 
            useSAN=true;
            sanEntry=$certCN;                       # copy the var certCN to sanEntry and preserve the var certCN for later use                           
            echo $certCN > $tmpFileName;            # create tmp file with first entry (re-using var for file with templates)
            echo -e "${Y_Blk}Collecting SAN entries for certificate, leave the entry blank if you are finished.\n(only entries with max. 64 alphanumeric characters are allowed)${COLOR_Off}";      # create an empty line
            while [ -n "$sanEntry" ]
            do
                sanEntry='';                                    # reset var
                readVarInfo 'Please enter an entry' 'sanEntry' 64 2 0 false; 
                if [ -n "$sanEntry" ]                           # if entry not empty (last entry is empty)
                then
                    echo $sanEntry >> $tmpFileName;             # add entry to tmp file
                fi;                    
            done; # loop sanEntry                        
        else
            useSAN=false;
        fi; # san entries
        if [[ $fheader = *"email"* ]]
        then
            readVarInfo 'Please enter the e-mail address (e.g. your.name@domain.tld)' 'emailAddress' 40 2 0 false;  
        fi;

        # now list data
        echo -e "\n${Y_Blk}Please review the entries (the first entry in the list represents the common name).${COLOR_Off}"
        echo -e "${Y_Blk}Common name:${COLOR_Off}          $certCN";
        if [ $useSAN = true ] # check if SAN entries are used
        then
            echo -e "${Y_Blk}SAN enties:${COLOR_Off}";
            cat $tmpFileName;
        fi;
        if [[ $fheader = *"email"* ]]
        then
            echo "E-mail address:       $emailAddress";
        fi;
        giveYesNoConfirmation 'Is the list with cn and san entries correct? [y/n]: ' 'outerLoop' 0;  
    done; # outer loop get cert data (name, cn san entries)
    # create dir, copy templates, update template vars
    
    # replace some characters for creating directroy and file name
    tmpCertName=$(echo $certName | sed "s/^https:\/\///g");
    tmpCertName=$(echo $certName | sed "s/^http:\/\///g");
    tmpCertName=$(echo $certName | sed "s/^ldap:\/\///g");
    tmpCertName=$(echo $tmpCertName | sed 's/ /_/g');
    tmpCertName=$(echo $tmpCertName | sed 's/*/_/g');
    
    dirName="${issuedCertsDir}/${tmpCertName}";                                                 # create directory name for cert files
    confDirName="${issuedCertsDir}/${tmpCertName}/conf";                                        # create directory name for cert request and conf files
    clear;
   
    verifyDirectory "${issuedCertsDir}" true false;                                             # verfiy if directory for issuing certs exist
    verifyDirectory "${issuedCertsDir}/_archive" false false;                                   # verfiy if arcive directory for issued certs exist
    verifyDirectory $dirName false true;                                                        # create directory for for cert files    
    verifyDirectory $confDirName false false;                                                   # create directory for cert request and conf files    
    reqConfFile="${confDirName}/${templateName}_req.conf";                              # conf file for csr
    certConfFile="${confDirName}/${templateName}_cert.conf";                            # conf file for csr
    csrFile="${confDirName}/${tmpCertName}.csr";                                        # csr file 
    cp "${templateDir}/${templateName}/${templateName}_req.conf" "${confDirName}/";     # copy templates to cert directory
    
    if test -f $tmpFileName 
    then        
        mv $tmpFileName $dirName;                                                       # move file with san entries
        tmpFileName="${dirName}/$(basename ${tmpFileName})";                            # update the var for the tmp file (file was moved)
    fi;  # move file
    
    certValidDays=$(getValFromConfFile $rqFile 'default_days');                         # search for default cert validity in conf file
    if [ -z "$certValidDays" ]    
    then
        certValidDays=$defCertValidInDays;
    fi;
    certPrivateKeyLength=$(getValFromConfFile $rqFile 'default_bits');                  # search for the default key length
    if [ -z "$certPrivateKeyLength" ]    
    then
        certPrivateKeyLength=$defCertPrivateKeyLength;
    fi;

    getCertData true; # query cert date (key length, validity period, protect key with passphrase)
        
    doLoop=$([[  -v skipProcessOrgSettings ]] && [[  $skipProcessOrgSettings = true ]] && echo 0 || echo 1);
    while [ $doLoop -eq 1 ]
    do            
        # readVarInfo promptText variableName numOfChar isInteger removeTrailingSlash
        clear;
        readVarInfo 'Country code, enter a value or hit ENTER if ok' 'customDefault_defCountryCode' 2 0 0 true; 
        readVarInfo 'Provice, enter a value or hit ENTER if ok' 'customDefault_defProvince' 0 0 0 true; 
        readVarInfo 'Location, enter a value or hit ENTER if ok' 'customDefault_defLocation' 0 0 0 true; 
        readVarInfo 'Organizational unit, enter a value or hit ENTER if ok' 'customDefault_defOU' 0 0 0 true; 
        readVarInfo 'Organization, enter a value or hit ENTER if ok' 'customDefault_defOrganization' 0 0 0 true; 
        echo 
        echo -e "${Y_Blk}Please verify if the following values are correct. A dot means not present in certificate subject.${COLOR_Off}";
        echo "Country code:     ${customDefault_defCountryCode}";
        echo "Province:         ${customDefault_defProvince}";
        echo "Location:         ${customDefault_defLocation}";
        echo "OU:               ${customDefault_defOU}";
        echo "Organization:     ${customDefault_defOrganization}";
        giveYesNoConfirmation 'Are the entries correct? [y/n]: ' 'doLoop' 0;                    
    done; # doLoop check CN entries
    # cleanup entries in request conf file
    performDNCleanUp $reqConfFile 'certCN';
    cleanUpDN 'customDefault_defOU' 'organizationalUnitName' 'def_OU' $reqConfFile;
    #cleanUpDN 'customDefault_defCountryCode' 'countryName' 'def_CountryCode' $reqConfFile;
    #cleanUpDN 'customDefault_defProvince' 'stateOrProvinceName' 'def_Province' $reqConfFile;
    #cleanUpDN 'customDefault_defLocation' 'localityName' 'def_Location' $reqConfFile;
    #cleanUpDN 'customDefault_defOrganization' 'organizationName' 'def_Organization' $reqConfFile;
    #cleanUpDN 'certCN' 'commonName' 'def_CommonName' $reqConfFile;

    declare -a filelist;                                                                # declare array for list of conf files        
    echo -e "${COLOR_Off}Writing configuration file(s).";       
    if test -f "${reqConfFile}"
    then 
        filelist["${#filelist[@]}"]="${reqConfFile}";              # add file path to array            
        updateTemplate "${reqConfFile}" 'signing' true;
    fi;
      
else # all files present
    echo -e "${R_Blk}Error: Necessary conf file(s) not found, stopping.${COLOR_Off}";
    exit;
fi;

signingCAConfFile="${caRootDir}/${signingCADirName}/${confFileSigningCAName}";
# verify if san entries are used
if [[ $fheader = *"email"* ]]
then
    echo "${emailAddress}" >> ${tmpFileName};     # write e-mail entry to tmp file
fi;

if [ $useSAN = true ]
then
    addSanEntriesToFile $tmpFileName $reqConfFile;
fi;

echo "Creating certificate request and certificate key."
openssl req -new -config "${reqConfFile}" -out "${csrFile}" -keyout "${dirName}/${tmpCertName}.key";
if [ $? -ne 0 ]
then
    echo -e "${R_Blk}Failed to create the certificate request, stoppeing.${COLOR_Off}";
    exit;
fi;

addExtension "${certExtension}" "${certConfFile}" "${templateDir}/${templateName}/${templateName}_req.conf" "${csrFile}"; # add extension to conf field
echo -e "${G_Blk}Creating certificate and signing certificte with ${customDefault_SigningCAName} key.${COLOR_Off}\nUsing extension ${G_Blk}${certExtension}\nPass phrase for ${Y_Blk}${customDefault_SigningCAName} key${COLOR_Off} required."

openssl ca -config "${signingCAConfFile}" -in "${csrFile}" -out "${dirName}/${tmpCertName}.crt" -extfile ${certConfFile} -extensions ${certExtension} -days "${certValidDays}";
errCode=$?
# create directory for conf and csr files and move the files
if [ $errCode -ne 0 ]
then
    echo -e "${R_Blk}Failed to create the certificate, stopping.${COLOR_Off}";
else
    echo -e "${G_Blk}Successfully created certificate $certName.${COLOR_Off}";    
    ## convert to pem
    openssl x509 -outform PEM -in "${dirName}/${tmpCertName}.crt" -out "${dirName}/${tmpCertName}.pem";
    if [ $? -ne 0 ]
    then
        echo -e "${Y_Blk}Warning: Failed to create the pem version of the certificate.${COLOR_Off}";
    fi;
    newCertsDir="${caRootDir}/${signingCADirName}/newcerts";
    tmpStr=$(tail -n 1 "${caRootDir}/${signingCADirName}/db/${signingCADirName}.db");
    IFS=$'\t';
    tmp=($tmpStr);
    pemCertName="${tmp[2]}";        # get the number of issuied cert
    cp "${newCertsDir}/${pemCertName}.pem" "${dirName}/";
    if [ $? -ne 0 ]
    then
        
        echo -e "${Y_Blk}Warning: Failed to copy the ${pemCertName}.pem file from directory ${newCertsDir}.${COLOR_Off}"
    fi;
    
    giveYesNoConfirmation 'Do you want to create a PKCS#12 bundle? [y/n]: ' 'createP12' 0;
    addTrustChain=1;
    if [ $createP12 -eq 0 ]
    then
        outFile="${dirName}/${tmpCertName}.p12";
        trustChainFileName="${caRootDir}/trust-chain/${customDefault_defOrganization}-trust-chain.pem";
        echo "Creating  PKCS#12 bundle"
        if test -f $trustChainFileName
        then 
            giveYesNoConfirmation 'Do you want to include the trust chain? [y/n]: ' 'addTrustChain' 0;
        fi;
        if [ $addTrustChain -eq 0 ]
        then 
            openssl pkcs12 -export -name $certName -caname $customDefault_SigningCAName -caname $customDefault_RootCAName -inkey "${dirName}/${tmpCertName}.key"  -in "${dirName}/${tmpCertName}.crt"  -out "${dirName}/${tmpCertName}.p12" -certfile $trustChainFileName;
        else
            openssl pkcs12 -export -name $certName -caname $customDefault_SigningCAName -caname $customDefault_RootCAName -inkey "${dirName}/${tmpCertName}.key"  -in "${dirName}/${tmpCertName}.crt"  -out "${dirName}/${tmpCertName}.p12"
        fi;
        if [ $? -eq 0 ]
        then
            echo -e "${G_Blk}Successfully created PKCS#12 bundle ${tmpCertName}.p12.${COLOR_Off}"
        else
            echo -e "${R_Blk}Failed to create the certificate the PKCS#12 bundle.${COLOR_Off}";
        fi; # end if create pkcs#12 bundle
    fi; # end if include trust chain in pkcs#12 bundle
    certFileList=($(find ${dirName} -maxdepth 1 -type f));
    tmpFileName="${scriptTmpDir}/$(uuidgen)";                           # tmp file for file list
    echo $certFileList > $tmpFileName;
    i=0;
    echo -e "\n${Y_Blk}Key and certificates created in directory ${G_Blk}${dirName}${COLOR_Off}";
    while IFS= read -r line; 
    do
        echo "$(basename $line)"; #${certFileList[$i]})";
        ((i++));
    done <$tmpFileName;
    rm -f $tmpFileName;
fi; # end if end if create certiicate
