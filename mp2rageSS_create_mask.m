function mask_path = mp2rageSS_create_mask(INV1_info,INV2_info)
% siya Sherif
% 05OCT2020
% create mask from the binary
% threshold the INV1 and INV2 at 40, sum it and threshold
% erode + dilate + smooth

tt= 1

Y_INV1 = double(spm_read_vols(INV1_info));
Y_INV2 = double(spm_read_vols(INV2_info));

Y_thresh = ((Y_INV1 > 40) + (Y_INV2 > 40))>0;

INV1_info.fname = 'NewData.nii';  % This is where you fill in the new filename
INV1_info.private.dat.fname = INV1_info.fname;  % This just replaces the old filename in another location within the header.

% Step 2.  Now use spm_write_vol to write out the new data.  You need to give spm_write_vol the new header information and corresponding data matrix
spm_write_vol(INV1_info,Y_thresh);  % where HeaderInfo is your header information for the new file, and Data is the image matrix corresponding to the image you'll be writing out.

end