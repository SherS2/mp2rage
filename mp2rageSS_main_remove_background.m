function mp2rageSS_main_remove_background(rmbg)
%MP2RAGE_MAIN_REMOVE_BACKGROUND Executable job that removes background noise for mp2rage UNI image.
%
% The core code of this function is an implementation of https://github.com/JosePMarques/MP2RAGE-related-scripts/blob/master/func/RobustCombination.m
% Based on the article http://journals.plos.org/plosone/article?id=10.1371/journal.pone.0099676

fname = rmbg.fname;

fprintf('[%s]: Final output = %s \n', mfilename, fname) % for diagnostic


% maskSS  =   "/media/data/ss_mp2rage_reg_test/out_process/t00063/mp2rage_local_reg/smooth_mask_dilate_erode.nii";


%% Load volumes

V_INV1 = spm_vol(rmbg.INV1{1});
Y_INV1 = double(spm_read_vols(V_INV1));

V_INV2 = spm_vol(rmbg.INV2{1});
Y_INV2 = double(spm_read_vols(V_INV2));

V_UNI = spm_vol(rmbg.UNI{1});
Y_UNI = double(spm_read_vols(V_UNI));

% commenting for testing ; this part is for thersholding and smoothing  
% % % % % % threshold , add, binarize 
% % % % % Y_thresh = double(((Y_INV1 > 30) + (Y_INV2 > 30)) > 0);
% % % % % % erode
% % % % % Y_erode = spm_erode(Y_thresh);
% % % % % % dilate
% % % % % Y_dilate = spm_dilate(Y_erode);
% % % % % 
% % % % % [fold_path,~,~]  = fileparts(V_INV1.fname); 
% % % % % 
% % % % % V_temp  = V_INV1;
% % % % % V_temp.fname = [fold_path '/thresh_erode_dilate.nii'];
% % % % % V_temp.private.dat.fname = V_temp.fname; 
% % % % % spm_write_vol(V_temp,Y_dilate); 
% % % % % 
% % % % % mask_name = strrep(V_temp.fname,'thresh_erode_dilate.nii','smoothed_mask.nii');
% % % % % 
% % % % % % smoothing
% % % % % spm_smooth(V_temp.fname,mask_name,[rmbg.smooth rmbg.smooth rmbg.smooth]);
% % % % % 
% % % % %  
% % % % % V_mask  =   spm_vol(mask_name);
% % % % % Y_mask  =   double(spm_read_vols(V_mask));


% ---------------------------------------------------------------------
% % % % % for using the mask from the multi channel segmentation 
% % % % % get the path to the multi channel seg folder  
% % % % path_multi_seg = '/media/siya/CRC_DATA_ss/mp2rage_noise_ATAG/middle_age/MultiChannel_seg/';
% % % % 
% % % % % get the subjname 
% % % % [~,ff,~]=fileparts(V_INV1.fname);
% % % % 
% % % % fl_path = dir([path_multi_seg ff(1:4) '/' ff(1:4) '*_mask_from_seg.nii' ]);
% % % % 
% % % % V_mask  =   spm_vol([fl_path.folder '/' fl_path.name]);
% % % % Y_mask  =   double(spm_read_vols(V_mask));


% PART 3
% path_multi_seg = '/media/siya/CRC_DATA_ss/mp2rage_noise_ATAG/middle_age/MultiChannel_seg/';
path_multi_seg = '/media/siya/CRC_DATA_ss/mp2rage_noise_ATAG/middle_age/MultiChannel_seg_eTPM_moreGauss/';

% get the subjname 
[~,ff,~]=fileparts(V_INV1.fname);
c1 = dir([path_multi_seg ff(1:4) '/c1' ff(1:4) '*'  ]);
c2 = dir([path_multi_seg ff(1:4) '/c2' ff(1:4) '*'  ]);
c3 = dir([path_multi_seg ff(1:4) '/c3' ff(1:4) '*'  ]);

v_c1 = spm_vol([c1.folder '/' c1.name]);
v_c2 = spm_vol([c2.folder '/' c2.name]);
v_c3 = spm_vol([c3.folder '/' c3.name]);

Y_c1  =   double(spm_read_vols(v_c1));
Y_c2  =   double(spm_read_vols(v_c2));
Y_c3  =   double(spm_read_vols(v_c3));

Y_mask1  =  double(Y_c1 + Y_c2 + Y_c3 );
Y_mask2  =  1-Y_mask1;
% ---------------------------------------------------------------------


%% Prepare some local functions

% MP2RAGErobustfunc = @(INV1,INV2,beta,mask) (conj(INV1).*INV2-(beta.*(1-mask)))./(INV1.^2+INV2.^2+2*(beta.*(1-mask)));

%mask c4 c5 c6 
MP2RAGErobustfunc = @(INV1,INV2,beta,mask) (conj(INV1).*INV2-[(beta.*(mask1)) + (beta.*(mask1))])./...
    (INV1.^2+INV2.^2 + 2 * [(beta.*(mask)) - (beta.*(mask))]);


% MP2RAGErobustfunc = @(INV1,INV2,beta,maskSS) (conj(INV1).*INV2-beta)./(INV1.^2+INV2.^2+2*beta);
rootsquares_pos   = @(a,b,c)          (-b+sqrt(b.^2 -4 *a.*c))./(2*a);
rootsquares_neg   = @(a,b,c)          (-b-sqrt(b.^2 -4 *a.*c))./(2*a);


%% Converts MP2RAGE to -0.5 to 0.5 scale

[ Y_UNI, integerformat ] = mp2rageSS_scale_UNI( Y_UNI );


%% Computes correct INV1 dataset

% Give the correct polarity to INV1;
Y_INV1 = sign(Y_UNI).*Y_INV1;

% "because the INV1 and INV2 is a summ of squares data, while the UNI is a
% phase sensitive coil combination.. some more maths has to be performed to
% get a better INV1 estimate which here is done by assuming both INV2 is
% closer to a real phase sensitive combination"

INV1pos = rootsquares_pos(-Y_UNI,Y_INV2,-Y_INV2.^2.*Y_UNI);
INV1neg = rootsquares_neg(-Y_UNI,Y_INV2,-Y_INV2.^2.*Y_UNI);

Y_INV1( abs(Y_INV1-INV1pos)> abs(Y_INV1-INV1neg) ) = INV1neg( abs(Y_INV1-INV1pos)> abs(Y_INV1-INV1neg) );
Y_INV1( abs(Y_INV1-INV1pos)<=abs(Y_INV1-INV1neg) ) = INV1pos( abs(Y_INV1-INV1pos)<=abs(Y_INV1-INV1neg) );


%% lambda calculation

% "usually the multiplicative factor shouldn't be greater then 10, but that
% is not the case when the image is bias field corrected, in which case the
% noise estimated at the edge of the image might not be such a good
% measure"

reg2noise = @(reg,INV2) reg * mean(mean(mean( INV2(1:end,end-10:end,end-10:end) )));
noiselevel = reg2noise(rmbg.regularization,Y_INV2);

Y_T1w = MP2RAGErobustfunc(Y_INV1, Y_INV2, noiselevel.^2,Y_mask);


%% Convert the final image to uint (if necessary)

Y_T1w = mp2rageSS_unscale_UNI( Y_T1w, integerformat );


%% Save volume

% Prepare volume info
V_out                = V_UNI; % copy info from UNI image
V_out.fname          = fname;
V_out.descrip        = sprintf('[mp2rage] background removed with regularization=%g',rmbg.regularization);

% Security check :
% I already messed up with volumes by overwriting the original volumes, instead of writing a new one...
assert( ~strcmp(V_UNI .fname,V_out.fname), '[%s]: The output filename is the same as the input UNI  filename. Do not overwrite your input  UNI', mfilename )
assert( ~strcmp(V_INV1.fname,V_out.fname), '[%s]: The output filename is the same as the input INV1 filename. Do not overwrite your input INV1', mfilename )
assert( ~strcmp(V_INV2.fname,V_out.fname), '[%s]: The output filename is the same as the input INV2 filename. Do not overwrite your input INV2', mfilename )

% Write volume
V_out = spm_write_vol(V_out,Y_T1w);


%% Check the results with spm_check_registration

if any(strcmpi(rmbg.show,{'Yes','Interactive'}))
    
    spm_check_registration( V_UNI.fname, V_out.fname )
    
    if strcmpi(rmbg.show,'Interactive')
        
        Fiter = spm_figure('GetWin', 'Interactive'); % classic popup menu from SPM
        
        iter_data                   = struct;
        iter_data.MP2RAGErobustfunc = MP2RAGErobustfunc;
        iter_data.integerformat     = integerformat;
        iter_data.Y_INV1            = Y_INV1;
        iter_data.Y_INV2            = Y_INV2;
        iter_data.reg2noise         = reg2noise;
        iter_data.V_out             = V_out;
        
        % Add a text box where the user can edit
        uicontrol(Fiter,...
            'Style','edit',...
            'Units', 'Normalized',...
            'Position', [0.25 0.25 0.5 0.5],...
            'String',num2str(rmbg.regularization),...
            'BackgroundColor',[0.9 0.9 0.9],...
            'TooltipString','Set a value here for the noise regularization',...
            'Tag','edit_rmbg_regularization',...
            'UserData',iter_data,...
            'Callback',@edit_rmbg_regularization_Callback);
        
    end
    
end


end % function


function edit_rmbg_regularization_Callback(src,~)
% Callback when you ask for a new value in SPM Interactive UI

%% Check the reg value entered

reg = str2double(src.String);
if ~isscalar(reg) || reg<0 || isnan(reg)
    warning('wrong value : must be positive scalar');
    src.String = num2str(mp2rage_get_defaults('interactive.regularization'));
    reg = str2double(src.String);
end
fprintf('[%s]: new regularization = %g \n', mfilename, reg);


%% Fetch iter data

iter_data = src.UserData;


%% Perform

fprintf('[%s]: computing new T1w \n', mfilename);
noiselevel = iter_data.reg2noise(reg,iter_data.Y_INV2);
Y_T1w = iter_data.MP2RAGErobustfunc(iter_data.Y_INV1, iter_data.Y_INV2, noiselevel.^2,Y_mask);

fprintf('[%s]: saving volume ... ', mfilename);
if iter_data.integerformat, Y_T1w = round( 4095*(Y_T1w+0.5) ); end                          % Convert the final image to uint (if necessary)
iter_data.V_out.descrip = sprintf('[mp2rage] background removed with regularization=%g',reg); % Prepare volume info
spm_write_vol(iter_data.V_out,Y_T1w);                                                       % Write volume
fprintf('done => %s \n', iter_data.V_out.fname);

pos = spm_orthviews('Pos');      % Get last cursor position
spm_orthviews('Reposition',pos); % Refresh the display @ last cursor position


%% Save changes

src.UserData = iter_data;


end % function
