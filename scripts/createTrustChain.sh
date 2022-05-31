###############################################################################
# Code Written by Hans Halbmayr
# Created On: 14.04.2022
# Last change on: 25.05.2022
#
# Script: createTrustChain.sh 
#
#
# Version 1.0
#
# Purpose: Script for creating certificate trust chain
################################################################################

sourceFileDir=$(dirname "$0")                                                     # get source directory of script
source ${sourceFileDir}/helperScripts/colorCodes.sh;                              # loading var caRootDir
source ${sourceFileDir}/helperScripts/customVars.sh;                              # loading vars needed in script
source ${sourceFileDir}/helperScripts/initCAinstallVars.sh;                       # loading vars needed in script

# init some vars
rootCAcertPath="${caRootDir}/${rootCADirName}/certs/${rootCAcertName}";
signingCACertPath="${caRootDir}/${signingCADirName}/certs/${signingCAcertName}";
trustChainFileName="${caRootDir}/trust-chain/${customDefault_defOrganization}-trust-chain.pem";
tmpDir="${caRootDir}/scripts/tmp";

## create trust chain in pem format
openssl x509 -in $rootCAcertPath -out "${tmpDir}/${rootCADirName}.pem"
if [ $? -ne 0 ]
then
    echo -e "${R_Blk}Failed to create the root certificate.${COLOR_Off}";
    exit;
fi;
openssl x509 -in $signingCACertPath -out "${tmpDir}/${signingCADirName}.pem"
if [ $? -ne 0 ]
then
    echo -e "${R_Blk}Failed to create the issuing certificate.${COLOR_Off}";
    exit;
fi;
cat "${tmpDir}/${rootCADirName}.pem" "${tmpDir}/${signingCADirName}.pem"> $trustChainFileName
if [ $? -ne 0 ]
then
    echo -e "${R_Blk}Failed to create the trust chain certificate.${COLOR_Off}";
    exit;
else
    echo -e "${G_Blk}Successfully created trust chain certificate.${COLOR_Off}";
    ls $trustChainFileName;
fi;

# clean up tmp directoy
rm "${tmpDir}/${rootCADirName}.pem"
if [ $? -ne 0 ]
then
    echo -e "${R_Blk}Failed to remove the temporary certificate ${tmpDir}/${rootCADirName}.pem${COLOR_Off}";
    exit;
fi;
rm "${tmpDir}/${signingCADirName}.pem"
if [ $? -ne 0 ]
then
    echo -e "${R_Blk}Failed to remove the temporary certificate ${tmpDir}/${signingCADirName}.pem${COLOR_Off}";
    exit;
fi;