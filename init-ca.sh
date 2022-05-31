###############################################################################
# Code Written by Hans Halbmayr
# Created On: 14.04.2022
# Last change on: 25.05.2022
#
# Script: init-ca.sh 
#
#
# Version 1.0
#
# Purpose: Conigures two tier CA with OpenSSL
################################################################################

## init variables
clear;
sourceFileDir=$(dirname "$0")                                       # get source directory of script
certConfSourceTemplateDir="${sourceFileDir}/confTemplates"          # set var for template sub directory
scriptRoot="${sourceFileDir}/scripts";                              # root directory for scripts
source "${scriptRoot}/helperScripts/initCAinstallVars.sh";          # read vars from input file
source "${scriptRoot}/helperScripts/colorCodes.sh";                 # loading constants for color codes (echo)
source "${scriptRoot}/helperScripts/customVars.sh";                 # loading variables for ca config
source "${scriptRoot}/helperScripts/commonFunctions.sh";            # loading functions

if test -f "${scriptRoot}/helperScripts/customVars.sh"
then
    source "${scriptRoot}/helperScripts/customVars.sh";                    # loading vars for default values creating cn (root and issuing ca)
    lineCount=$(sed -n '$=' ${scriptRoot}/helperScripts/customVars.sh);  # get number of vars from file
    minLineCount=18;
    if [ $lineCount -lt $minLineCount ]
    then
        echo -e "${Y_Blk}Expecting more variables in file ${COLOR_Off}${scriptRoot}/helperScripts/customVars.sh.";
        echo -e "${Y_Blk}Only ${G_Blk}$lineCount${Y_Blk} variables found.${COLOR_Off}";
        echo -e "${R_Blk}Stopping script!${COLOR_Off}"
        exit
    fi;    
else
    echo -e "${R_Blk}\nMissing file ${COLOR_Off}${scriptRoot}/helperScripts/customVars.sh. ${R_Blk}Stopping!${COLOR_Off}";
    echo -e "${Y_Blk}Please run the script ${G_Blk}${sourceFileDir}/createCAconf.sh${Y_Blk} to create the missing file.${COLOR_Off}";
    exit;
fi;

scriptTmpDir="${caRootDir}/scripts/tmp";                                        # var for tmp directory for scripts
echo 'Verifying existing directory structure.';
if [ -e $caRootDir ];    # verify if the ca root directory exist and is empty
then 
    if ! [ -z "$(ls -A $caRootDir)" ]; then
        echo -e "${R_Blk}The directory $caRootDir is not empty. An empty directory is required.${COLOR_Off}";
        exit;
    fi;
else 
    echo -e "${R_Blk}Missing directory $caRootDir. Please create the directory structure.${COLOR_Off}"; 
    exit
fi;
echo -e "${G_Blk}Existing directory structure is OK.${COLOR_Off}";

caRootDir=$(echo $caRootDir | sed 's:/*$::')                    # remove trailing slash if exist
echo 'Creating directory structure for ca'
mkdir -p $caRootDir/{${rootCADirName},${signingCADirName}}/{private,certs,newcerts,crl,csr,db}  # create directory stucture for root and issuing ca

mkdir $caRootDir/scripts/tmp -p                             # create script directory and tmp sub directory
mkdir $caRootDir/scripts/helperScripts                      # create script directory and tmp sub directory
mkdir $caRootDir/trust-chain                                # create the directory used for the trust chain
mkdir $caRootDir/${signingCADirName}/issuedcerts            # create directory for issued certs
echo '1.0' > "${caRootDir}/scripts/helperScriptsver.sh";    # create file with version number

# init files for CA
echo 'Creating files for CAs'
cp /dev/null "${caRootDir}/${rootCADirName}/db/${rootCADirName}.db";
cp /dev/null "${caRootDir}/${rootCADirName}/db/${rootCADirName}.db.attr";
cp /dev/null "${caRootDir}/${signingCADirName}/db/${signingCADirName}.db";
cp /dev/null "${caRootDir}/${signingCADirName}/db/${signingCADirName}.db.attr";
## create serial and crl file root ca
echo 01 > "${caRootDir}/${rootCADirName}/db/${rootCADirName}.crt.srl";
echo 01 > "${caRootDir}/${rootCADirName}/db/${rootCADirName}.crl.srl";
## create serial and crl file issuing ca
openssl rand -hex 16 > "${caRootDir}/${signingCADirName}/db/serial";
echo 01 > "${caRootDir}/${signingCADirName}/db/${signingCADirName}.crt.srl";
echo 01 > "${caRootDir}/${signingCADirName}/db/${signingCADirName}.crl.srl";
## end init files for CA

## copy conf files root and issuing ca
echo "Copy conf file for root ca to ${caRootDir}/${rootCADirName}/${confFileRootCAName}"
cp "${sourceFileDir}/caConf/${confFileRootCAName}"  "${caRootDir}/${rootCADirName}/${confFileRootCAName}"           # copy config file root ca

echo "Copy conf file for issuing ca to ${caRootDir}/${signingCADirName}/${confFileSigningCAName}"
cp "${sourceFileDir}/caConf/${confFileSigningCAName}"  "${caRootDir}/${signingCADirName}/${confFileSigningCAName}"  # copy config file issuing ca
echo "Copy templates to ${caRootDir}/${signingCADirName}/conf-templates";
######cp -r "${sourceFileDir}/conf-templates" "${caRootDir}/${signingCADirName}/conf-templates";
cp -r "${certConfSourceTemplateDir}" "${caRootDir}/${signingCADirName}/conf-templates";

# store names of conf files in variable
rootCAConf="${caRootDir}/${rootCADirName}/${confFileRootCAName}";
issuingCAConf="${caRootDir}/${signingCADirName}/$confFileSigningCAName";

updateTemplate "${caRootDir}/${rootCADirName}/${confFileRootCAName}" 'root' false;                              # write config to root ca template
performDNCleanUp "${caRootDir}/${rootCADirName}/${confFileRootCAName}" 'customDefault_RootCAName';              # update DN in root ca template
updateTemplate "${caRootDir}/${signingCADirName}/${confFileSigningCAName}" 'signing' false;                     # write config to signing ca template
performDNCleanUp "${caRootDir}/${signingCADirName}/${confFileSigningCAName}" 'customDefault_SigningCAName';     # update DN in signing ca tempalte


echo "Copy file createTrustChain.sh to ${caRootDir}/scripts";
cp -r "${sourceFileDir}/scripts" "${caRootDir}/";

## create keys
# create key for root ca
echo -e "${G_Blk}Create key for root ca - ${R_Blk}key pass phrase for root ca requiered${COLOR_Off}"
openssl req -new -config "${caRootDir}/${rootCADirName}/${confFileRootCAName}" -out "${caRootDir}/${rootCADirName}/csr/${rootCACSRName}" -keyout "${caRootDir}/${rootCADirName}/private/${rootCAKeyName}";
if [ $? -ne 0 ]
then
    echo -e "${R_Blk}Failed to create the key for the root ca, stopping.${COLOR_Off}";
    exit;
fi;

## init vars CA validity period
## create root-ca
echo -e "${G_Blk}Signing certificate for root ca - ${R_Blk}key pass phrase for root ca requiered${COLOR_Off}"
openssl ca -selfsign -config "${caRootDir}/${rootCADirName}/${confFileRootCAName}" -in "${caRootDir}/${rootCADirName}/csr/${rootCACSRName}" -out "${caRootDir}/${rootCADirName}/certs/${rootCAcertName}"  -extensions root_ca_ext -days $rootCADaysValid -notext;
if [ $? -ne 0 ]
then
    echo -e "${R_Blk}Failed to create the certificate for the root CA, stopping.${COLOR_Off}";
    exit;
fi;
## verify certificate
#### -- openssl x509 -noout -in "${caRootDir}/${rootCADirName}/certs/${rootCAcertName}" -text;

## create issuing ca
## create certificate signing request
echo -e "${G_Blk}Create key and signing request for signing ca - ${Y_Blk}key pass phrase for signing ca requiered${COLOR_Off}"

openssl req -new -config "${caRootDir}/${signingCADirName}/${confFileSigningCAName}" -out "${caRootDir}/${signingCADirName}/csr/${signingCACSRName}" -keyout "${caRootDir}/${signingCADirName}/private/${signingCAKeyName}"
if [ $? -ne 0 ]
then
    echo -e "${R_Blk}Failed to create the key for the signing CA, stopping.${COLOR_Off}";
    exit;
fi;
## request certificate
echo -e "${G_Blk}Signing certificate for signing ca with ${R_Blk}key pass phrase for root ca requiered${COLOR_Off}"

openssl ca -config "${caRootDir}/${rootCADirName}/${confFileRootCAName}" -in "${caRootDir}/${signingCADirName}/csr/${signingCACSRName}" -out "${caRootDir}/${signingCADirName}/certs/${signingCAcertName}" -extensions signing_ca_ext -days $signingCADaysValid -notext;
if [ $? -ne 0 ]
then
    echo -e "${R_Blk}Failed to create the certificate for the signing CA, stopping.${COLOR_Off}";
else
    echo -e "${G_Blk}Successfully created root and signing CA.${COLOR_Off}";
fi;
