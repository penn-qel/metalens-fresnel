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
