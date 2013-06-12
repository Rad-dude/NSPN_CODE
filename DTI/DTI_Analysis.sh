#!/bin/bash

#==============================================================================
#               NAME:  DTI_Analysis
#
#        DESCRIPTION:  This script takes an input directory that must contain
#                      dti.nii.gz, bvals and bvecs_orig, and then runs  
#                      eddy current correction, rotate bvecs, brain extraction,
#                      dtifit, bedpostX and tbss 1 and 2
#
#        PARAMETER 1:  DTI data folder (full path)
#                       eg: /home/kw401/UCHANGE/ANALYSES/SUB_DATA/UCL/12385/DTI
#        PARAMETER 2:  sub_id
#                       eg: 12385
#              USAGE:  dti_analysis <dti_data_folder> <sub_id>
#                       (miss out the ... for this example!)
#                        eg: dti_analysis /home/kw401/UCHANGE/ANALYSES/ ... 
#                                              ... SUB_DATA/UCL/12385/DTI 12385
#
#             AUTHOR:  Kirstie Whitaker
#                          kw401@cam.ac.uk
#            CREATED:  19th February 2013
#==============================================================================

# Define some variables
dir=$1
sub=$2

# Create the log directory
logdir=${dir}/LOGS
mkdir -p ${logdir}

# Get going!
echo ${dir}

# If the dti.nii.gz, bvals and bvecs files don't exist then
# print an error message and exit
if [[ ! -f ${dir}/dti.nii.gz ]]; then
    echo "    No dti.nii.gz file"
    exit=1
fi
if [[ ! -f ${dir}/bvals ]]; then
    echo "    No bvals file"
    exit=1
fi
if [[ ! -f ${dir}/bvecs_orig ]]; then
    echo "    No bvecs file"
    exit=1
fi
if [[ ${exit} == 1 ]]; then
    exit
fi

# Eddy correct
if [[ ! -f ${dir}/dti_ec.nii.gz ]]; then
    echo "    Starting eddy correction step"
    rm -f ${dir}/dti_ec.ecclog
    eddy_correct ${dir}/dti.nii.gz ${dir}/dti_ec.nii.gz 0 > ${logdir}/eddycorrect
else
    echo "    Eddy correction step already completed"
fi

# Rotate bvecs
# NOTE - the path to this script is hard coded
# If you don't have it, go get it from:
# 
rot_bvecs_script=(/home/kw401/CAMBRIDGE_SCRIPTS/FSL_SCRIPTS/fdt_rotate_bvecs.sh)

if [[ ! -f ${dir}/bvecs ]]; then
    echo "    Rotating bvecs"
    ${rot_bvecs_script} ${dir}/bvecs_orig ${dir}/bvecs \
        ${dir}/dti_ec.ecclog >> ${logdir}/eddycorrect
else
    echo "    Bvecs already rotated"
fi

# Brain extract
if [[ ! -f ${dir}/dti_ec_brain.nii.gz ]]; then
    echo "    Brain extracting"
    bet ${dir}/dti_ec.nii.gz ${dir}/dti_ec_brain.nii.gz -f 0.15 -m > ${logdir}/bet
else
    echo "    Brain already extracted"
fi

# DTIfit (FDT)
if [[ ! -f ${dir}/FDT/${sub}_MO.nii.gz ]]; then
    echo "    Fitting tensor"
    mkdir -p ${dir}/FDT
    dtifit -k ${dir}/dti_ec.nii.gz \
        -m ${dir}/dti_ec_brain_mask.nii.gz \
        -r ${dir}/bvecs \
        -b ${dir}/bvals \
        -o ${dir}/FDT/${sub} \
        > ${logdir}/dtifit
    
    fslmaths ${dir}/FDT/${sub}_L2.nii.gz -add ${dir}/FDT/${sub}_L3.nii.gz -div 2 \
        ${dir}/FDT/${sub}_L23.nii.gz
else
   echo "    Tensor already fit"
fi

# BedpostX
if [[ ! -f ${dir}/BEDPOSTX.bedpostX/dyads2.nii.gz ]]; then
    echo "    Now starting bedpostX"
    mkdir -p ${dir}/BEDPOSTX
    cp ${dir}/bvals ${dir}/BEDPOSTX/
    cp ${dir}/bvecs ${dir}/BEDPOSTX/
    cp ${dir}/dti_ec_brain_mask.nii.gz \
    ${dir}/BEDPOSTX/nodif_brain_mask.nii.gz
    cp ${dir}/dti_ec.nii.gz ${dir}/BEDPOSTX/data.nii.gz
    bedpostx ${dir}/BEDPOSTX/ > ${logdir}/bedpostx
else
    echo "    bedpostX already complete"
fi

# TBSS 1 and 2
if [[ ! -f ${dir}/TBSS/FA/reverse_fnirt_warp.nii.gz ]]; then
    echo "    Now starting tbss"
    if [[ ! -f ${dir}/TBSS/FA/${sub}_FA_FA_to_target_warp.nii.gz ]]; then
        echo "    Running TBSS"
        rm -rf ${dir}/TBSS
        mkdir -p ${dir}/TBSS
        cp ${dir}/FDT/*FA* ${dir}/TBSS/
        cd ${dir}/TBSS/
        tbss_1_preproc * > ${logdir}/tbss
        tbss_2_reg -T >> ${logdir}/tbss
    fi
    # Now create the inverse fnirt warp
    echo "    Inverting FNIRT warp"
    if [[ -d ${dir}/TBSS/FA && \
           ! -f ${dir}/TBSS/FA/reverse_fnirt_warp.nii.gz ]]; then
        invwarp -r ${dir}/TBSS/FA/${sub}_FA_FA.nii.gz \
                -w ${dir}/TBSS/FA/${sub}_FA_FA_to_target_warp.nii.gz \
                -o ${dir}/TBSS/FA/reverse_fnirt_warp.nii.gz
    fi
else
    echo "    TBSS already complete"
fi

echo "--------------------------------"
