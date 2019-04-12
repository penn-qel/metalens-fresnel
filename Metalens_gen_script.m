%% Phase Grid Script
% this is an example script for running the MATLAB function
% Fresnel_cuts_fixed_grid_3D. This function has the followin outputs:
%     output_struct.theta0 % phase shift of minimum allowed diameter
%     output_struct.theta_target % vector of desired phase shift
%     output_struct.R % vector of radii that corresponds to theta_target
%     output_struct.phase % phase difference between theta_target and theta_opt
%     output_struct.P0  % transmitted power
%     output_struct.theta_opt % actual phase shifts induced by R
%     output_struct.block_positions % meshgrid with resolution given by Per
%     output_struct.block_phases % Fresnel phase profile interpolated over
%     the meshgrid in block_positions
%     output_struct.block_radius % radii required to cover the phase shifts
%     in block_phases
%--------------------------------------------------------------------------
sim_options.lambda0 = 0.7; % wavelength in µm
sim_options.n = 2.4; % material refractive index
sim_options.f = 20; % lens focal length in µm
sim_options.m = 20; % number of zones to include
sim_options.res = .001; % spatial resolution in µm
sim_options.Per = 0.3; % range of allowable periodicities in µm
sim_options.R_min = 0.025; % minimum allowable pillar/trench width
sim_options.R_max = 0.125; % minimum allowable pillar/trench width

sim_options.G = 64; % number of harmonics, use powers of 2
sim_options.height = 1; % fixed pillar height in um
sim_options.theta0 = 0; % phase shift induced by minimum pillar diameter
sim_options.grid = 'square'; % either square or hexagonal grid mesh
sim_options.distribution = 'fresnel'; % either fresnel or rand phase profile
sim_options.phase_flag = true; % whether you want to use the function to 
% calculate the radii required for the phase vector linspace(0,2*pi,25)
sim_options.phase_file = ''; % if you decided to let phase_flag be false,
% you need to supply your own phase vs radii .mat file. This file should  
% contain a struct with the following fields:
%       R              vector of pillar radii
%       theta_opt      the relative theta correspond to each element in R
%       P0             transmitted power correspond to each element in R


[output_struct, options] = Fresnel_cuts_fixed_grid_3D(sim_options);

%% plot results
theta = output_struct.theta_opt./pi;
d = 2.*output_struct.R.*1e3;
% relative phase shift vs. pillar diameter
figure;
plot(d, theta);
xlabel('d (nm)');
ylabel('\phi');
% transmitted power vs. pillar diameter
figure;
plot(d, output_struct.P0)
xlabel('d (nm)');
ylabel('T');

%% Metalens Pattern Generation
% this is a script that uses KLayout to convert the block positions and
% radii calculated from Fresnel_cuts_fixed_grid_3D to a GDS file that can
% be loaded directly for fabrication and simulation. The Ruby script used
% for KLayout needs to be in the same directory. 

% square mesh grid
tstart = tic;


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

%% Hexagonal mesh grid 
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