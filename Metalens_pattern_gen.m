%% Metalens Pattern Generation
% this is a script that uses KLayout to convert the block positions and
% radii calculated from Fresnel_cuts_fixed_grid_3D to a GDS file that can
% be loaded directly for fabrication and simulation. The Ruby script used
% for KLayout needs to be in the same directory. 

clear
clc
close all

tstart = tic;
% replace this with the .mat file that contains outputs from
% Fresnel_cuts_fixed_grid_3D.m
load('Metalens_fresnel_sq.mat');

% options for the write, all units are in microns
% everything goes on layer 1 by default unless otherwise specified
file_name = ['Metalens-' date '.txt']; % dated file name
chip_size = 300; % microns, chip write area in x direction.  2400 gives 17 fields with a 150 field size
write_field = 300; % microns, write field size
field_size = 60000; % number of shots in the field
grid_size = write_field/field_size; % grid size in microns

tol = 1; % tolerance for curve fracturing

R = 14; % cut-off radius
pattern_struct = [];
layer = 1;

element_struct.layer = 1;
for loop_index = 1:length(output_struct.block_radius)
    if output_struct.block_positions(loop_index,1)^2 + output_struct.block_positions(loop_index,2)^2 <= R^2
        [x,y] = arc_cut(output_struct.block_radius(loop_index),grid_size,tol,'circle');
        element_struct.xy = ones(length(x),1)*output_struct.block_positions(loop_index,:) + [x' y'];
        pattern_struct = [pattern_struct element_struct];
    end
end

gds_opts.filename = file_name;
gds_opts.database_unit = 1; % database unit in nm
GDS_write(pattern_struct,gds_opts);

% Ruby script convert.rb needs to be in the same folder and should contain
% the following:
% layout = RBA::Layout.new
% options = RBA::SaveLayoutOptions.new
% layout.read($input)
% options.gds2_multi_xy_records = true
% layout.write($output,options)

dos(['klayout -rd input=' file_name ' -rd output=' file_name(1:end-4) '.GDS -r convert.rb']);

toc(tstart)

%% hex pattern
tstart = tic;
% replace this with the .mat file that contains outputs from
% Fresnel_cuts_fixed_grid_3D.m
load('Metalens_fresnel_hex.mat');

file_name = ['Metalens-hex-' date '.txt']; % dated file name

tol = 1; % tolerance for curve fracturing

R = 14; % cut-off radius
pattern_struct = [];
layer = 1;

element_struct.layer = 1;
for loop_index = 1:length(output_struct.block_radius)
    if output_struct.block_positions(loop_index,1)^2 + output_struct.block_positions(loop_index,2)^2 <= R^2
        [x,y] = arc_cut(output_struct.block_radius(loop_index),grid_size,tol,'circle');
        element_struct.xy = ones(length(x),1)*output_struct.block_positions(loop_index,:) + [x' y'];
        pattern_struct = [pattern_struct element_struct];
    end
end

gds_opts.filename = file_name;
gds_opts.database_unit = 1; % database unit in nm
GDS_write(pattern_struct,gds_opts);

% Ruby script convert.rb needs to be in the same folder and should contain
% the following:
% layout = RBA::Layout.new
% options = RBA::SaveLayoutOptions.new
% layout.read($input)
% options.gds2_multi_xy_records = true
% layout.write($output,options)

dos(['klayout -rd input=' file_name ' -rd output=' file_name(1:end-4) '.GDS -r convert.rb']);

toc(tstart)