function [output_struct, options] = Fresnel_cuts_fixed_grid_3D(input_options)
% Calculate the phase distribution of a Fresnel lens at wavelength lambda
% with index n for a focal length of f and number of zones m. Right now it
% can either calculate a Fresnel phase profile or a randomized phase
% profile. It has the option to either calculate pillar dimensions needed
% for given phase shift using fminbnd, or loads a pre-calculated .mat file
% with the following fields:
%     output_struct.R % vector of radii that corresponds to theta_target
%     output_struct.P0  % transmitted power
%     output_struct.theta_opt % actual phase shifts induced by R
%
% options and their default values:
%     default_options.lambda0 = 0.7; % wavelength in µm
%     default_options.n = 2.4; % material refractive index
%     default_options.f = 20; % lens focal length in µm
%     default_options.m = 20; % number of zones to include
%     default_options.res = .001; % spatial resolution in µm
%     default_options.Per = 0.3; % range of allowable periodicities in µm
%     default_options.R_min = 0.025; % minimum allowable pillar/trench width
%     default_options.R_max = 0.125; % minimum allowable pillar/trench width
%     default_options.G = 64; % number of harmonics, use powers of 2
%     default_options.height = 1; % height of each pillar
%     default_options.theta0 = 0; % phase shift induced by minimum pillar diameter
%     default_options.grid = 'square'; % square or hexagonal mesh grid
%     default_options.distribution = 'fresnel'; %fresnel or rand phase
%     profile
%     default_options.phase_flag = 'true'; %flag for whether to calculate
%       the pillar radii necessary for phase profile or use pre-existing file
%     default_options.phase_file = ''; % if you decided to let phase_flag be false,
%       you need to supply your own phase vs radii .mat file. This file should  
%       contain a struct with the following fields:
%       R              vector of pillar radii
%       theta_opt      the relative theta correspond to each element in R
%       P0             transmitted power correspond to each element in R
%-------------------------------------------------------------------------%
    %Parse the input options
    if (nargin ~= 0)
        params.parser = parse_options(input_options);
    else
        params.parser = parse_options;
    end
    options = params.parser.Results;
    
    % create a vector of zone indices
    m = 1:options.m;
    
    % calculate the zone positions
    zones = sqrt((options.lambda0.*m./options.n)...
        .*(options.lambda0.*m./options.n + 2*options.f));
    
    % duplicate zones x < 0
    output_struct.zones = zones; %[-fliplr(zones) zones];

    % create a position vector
    output_struct.x = 0:options.res:max(zones);

    k0 = (2*pi)/options.lambda0;

    N = 50;
    % high resolution meshes
    [X,Y] = meshgrid(-2*N*options.Per:.01:2*N*options.Per,...
        -2*N*options.Per:.01:2*N*options.Per);

    if strcmp(options.grid,'square')
        % square grid mesh
        [X_interp,Y_interp] = meshgrid(-N*options.Per:options.Per:N*options.Per);
    else
    % hexagonal grid mesh
        [X_interp,Y_interp] = ...
            meshgrid(-2/sqrt(3)*N*options.Per:options.Per:2/sqrt(3)*N*options.Per,...
            -N*options.Per:options.Per:N*options.Per);
        X_interp = (sqrt(3)/2)*X_interp;
        shift_mat = repmat([0 0.5],[size(X_interp,1),round(size(X_interp,2)/2)]);
        Y_interp = Y_interp + options.Per.*shift_mat(:,1:end);
        phase_input_opts.file_name = 'diamond_grating_2d_hex.lua'; % use hexagonal lattice in RCWA
    end
    
    if strcmp(options.distribution,'rand')
        % Generate uniformly distrubted random phases on a square or
        % hexagonal grid
        phi_interp = 2*pi.*rand(size(X_interp));
    
        output_struct.Phi = phi_interp;
    else
        % Fresnel lens
        % Ideal phase response
        phi = wrapTo2Pi(options.n*k0.*(options.f - sqrt(options.f^2 + X.^2 + Y.^2)));

        phi(round(length(phi)/2),round(length(phi)/2)) = 2*pi; % don't wrap the 0 point

        % interpolated on a square or hexagonal grid
        phi_interp = interp2(X,Y,phi,X_interp,Y_interp);

        output_struct.Phi = phi;
    end
    
    % Generate the look-up table of radii that give 0 to 2*pi phase shift
    % for a given height and periodicity
    if options.phase_flag
        phase_input_opts.G = options.G;
        phase_input_opts.height = options.height;
        phase_input_opts.theta0 = options.theta0;
        
        % calculate phase shift from minimum allowed pillar diameter
        [theta0, phase_params] = phase_opt_3D(options.Per,options.R_min,phase_input_opts);
        
        options.file_name = phase_params.file_name;
        phase_input_opts.theta0 = theta0;
        output_struct.theta0 = theta0;
        
        % setting options for minimization function
        fmin_opts = optimset('fminbnd');
        fmin_opts.TolX = 1e-6;
        
        % generate target phase vector
        target_phase = linspace(0,2*pi,25);
        output_struct.theta_target = target_phase;
        
        for loop_index = 1:length(target_phase)
            disp(['optimizing for phase = ' num2str(target_phase(loop_index))])
            phase_input_opts.theta_target = target_phase(loop_index);
            
            % get optimized R that matches the target phase shift given
            [R(loop_index), phase(loop_index)] = ...
                fminbnd(@(R) phase_opt_3D(options.Per,R,phase_input_opts),...
                options.R_min,options.R_max,fmin_opts);
            
            output_struct.R(loop_index) = R(loop_index);
            output_struct.phase(loop_index) = phase(loop_index);
            
            % feed the optimized R back into S4 to get the relative phase shift
            phase_input_opts.theta_target = 0;
            [phase_rel,phase_params] = phase_opt_3D(options.Per,R(loop_index),phase_input_opts);
            
            output_struct.P0(loop_index) = phase_params.P0;
            output_struct.theta_opt(loop_index) = phase_rel;
            phase_params.P0
        end
    else
        phase_calc = load(options.phase_file);
        %output_struct.theta0 = phase_calc.output_struct.theta0;
        %output_struct.theta_target = phase_calc.output_struct.theta_target;
        output_struct.R = phase_calc.output_struct.R;
        %output_struct.phase = phase_calc.output_struct.phase;
        output_struct.P0 = phase_calc.output_struct.P0;
        output_struct.theta_opt = phase_calc.output_struct.theta_opt;
    end

    % reshape phase values and radii
    output_struct.block_positions = [X_interp(:) Y_interp(:)];
    output_struct.block_phases = reshape(phi_interp,length(output_struct.block_positions),1);
    output_struct.block_radius = reshape(pchip(output_struct.theta_opt,...
        output_struct.R,output_struct.block_phases(:)),...
        length(output_struct.block_positions),1);
end

function parser = parse_options(input_options)

    % Create the input parser
    parser = inputParser;

    % Set the default options
    default_options.lambda0 = 0.7; % wavelength in µm
    default_options.n = 2.4; % material refractive index
    default_options.f = 20; % lens focal length in µm
    default_options.m = 20; % number of zones to include
    default_options.res = .001; % spatial resolution in µm
    default_options.Per = 0.3; % range of allowable periodicities in µm
    default_options.R_min = 0.025; % minimum allowable pillar/trench width
    default_options.R_max = 0.125; % minimum allowable pillar/trench width
   
    default_options.G = 64; % number of harmonics, use powers of 2
    default_options.height = 1;
    default_options.theta0 = 0; % phase shift induced by minimum pillar diameter
    default_options.grid = 'square';
    default_options.distribution = 'fresnel';
    default_options.phase_flag = 'true';
    default_options.phase_file = 'ML_fresnel_sq_Per_300.mat';
    
    %Address no input case by assigning to defaults
    if (nargin == 0)
        input_options = default_options;
    end

    addParameter(parser, 'lambda0', default_options.lambda0, ...
        @(x)validateattributes(x, {'numeric'}, {'size',[1 1],'nonnegative','real','finite'}));
    
    addParameter(parser, 'n', default_options.n, ...
        @(x)validateattributes(x, {'numeric'}, {'size',[1 1],'nonnegative','real','finite'}));

    addParameter(parser, 'f', default_options.f, ...
        @(x)validateattributes(x, {'numeric'}, {'size',[1 1],'nonnegative','real','finite'}));

    addParameter(parser, 'm', default_options.m, ...
        @(x)validateattributes(x, {'numeric'}, {'size',[1 1],'real','finite','nonnegative','integer'}));
    
    addParameter(parser, 'res', default_options.res, ...
        @(x)validateattributes(x, {'numeric'}, {'size',[1 1],'nonnegative','real','finite'}));

    addParameter(parser, 'Per', default_options.Per, ...
        @(x)validateattributes(x, {'numeric'}, {'size',[1 1],'nonnegative','real','finite'}));
    
    addParameter(parser, 'R_min', default_options.R_min, ...
        @(x)validateattributes(x, {'numeric'}, {'size',[1 1],'nonnegative','real','finite'}));
        
    addParameter(parser, 'R_max', default_options.R_max, ...
        @(x)validateattributes(x, {'numeric'}, {'size',[1 1],'nonnegative','real','finite'}));
    
    addParameter(parser, 'G', default_options.G, ...
        @(x)validateattributes(x, {'numeric'}, {'size',[1 1],'real','finite','nonnegative','integer'}));
    
    addParameter(parser, 'height', default_options.height, ...
        @(x)validateattributes(x, {'numeric'}, {'size',[1 1],'nonnegative','real','finite'}));

    addParameter(parser, 'theta0', default_options.theta0, ...
        @(x)validateattributes(x, {'numeric'}, {'size',[1 1],'nonnegative','real','finite'}));
    
    addParameter(parser, 'grid', default_options.grid, ...
        @(x) ~isempty(validatestring(x, {'square','hex'})));
    
    addParameter(parser, 'distribution', default_options.distribution, ...
        @(x) ~isempty(validatestring(x, {'fresnel','rand'})));
    
    addParameter(parser, 'phase_flag', default_options.phase_flag,...
        @(x)validateattributes(x, {'logical'}, {'size',[1 1]}));
    
    addParameter(parser, 'phase_file', default_options.phase_file,...
        @(x)validateattributes(x, {'char'}, {'scalartext'}));
    
    parser.parse(input_options)

end
