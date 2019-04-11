function [dphase, params] = phase_opt_3D(Per,R,input_options)
% Maximize transmission and maintain fixed phase for a given diffracted
% order m using S4.  "file_name" is the name of the .lua file used for the
% S4 simulation
%
% Ensure that Periodicity and duty cycle values are withn a resonable range
%
%Per = max([X 2*w]); % periodicity cannot go below 200 nm
%--------------------------------------------------------------------------
    %Parse the input options
    if (nargin ~= 0)
        params.parser = parse_options(input_options);
    else
        params.parser = parse_options;
    end
    
    options = params.parser.Results;
    
    params.R = R; % pillars are no less than 100 nm

    params.file_name = options.file_name;
    
    for loop_index = 1:length(R)
        output_file_ampl = 'order_opt_raw_ampl_3D.out';
        output_file_pow = 'order_opt_raw_pow_3D.out';
        
        system(['$S4 -a "{' num2str(params.R(loop_index),'%1.3f') ',' ...
            num2str(Per,'%1.3f') ',' ...
            num2str(options.height,'%1.2f') ',' ...
            num2str(options.G,'%1.1f') ', ''Pow''}" ' ...
            options.file_name ' > ' output_file_ampl ' 2> ' output_file_pow]);

        dat = importdata(output_file_ampl);

        [dat.textdata{1:4,1}]

        params.t(loop_index) = dat.data(1,2) + 1j*dat.data(1,3); % complex amplitude transmission for order m
    
        dat2 = importdata(output_file_pow);

        params.P0(loop_index) = dat2.data(1,2);
        
    end

    dphase = abs(wrapTo2Pi(angle(params.t)- options.theta0)  - options.theta_target); % optimal FOM is 0

end

function parser = parse_options(input_options)

    % Create the input parser
    parser = inputParser;

    % Set the default options
   % default_options.Per = 0.25; % wavelength in µm
    default_options.height = 1.0; % material refractive index
    default_options.G = 128; % number of harmonics 
   % default_options.w = 0.15; % number of zones to include
    default_options.theta0 = 0;
    default_options.theta_target = 0;
    default_options.file_name = 'diamond_grating_2d_square.lua';
    
    %Address no input case by assigning to defaults
    if (nargin == 0)
        input_options = default_options;
    end

%     addParameter(parser, 'Per', default_options.Per, ...
%         @(x)validateattributes(x, {'numeric'}, {'size',[1 1],'nonnegative','real','finite'}));
    
    addParameter(parser, 'height', default_options.height, ...
        @(x)validateattributes(x, {'numeric'}, {'size',[1 1],'nonnegative','real','finite'}));

    addParameter(parser, 'G', default_options.G, ...
        @(x)validateattributes(x, {'numeric'}, {'size',[1 1],'real','finite','nonnegative','integer'}));
    
%     addParameter(parser, 'w', default_options.w, ...
%         @(x)validateattributes(x, {'numeric'}, {'size',[1 1],'nonnegative','real','finite'}));

    addParameter(parser, 'theta0', default_options.theta0, ...
        @(x)validateattributes(x, {'numeric'}, {'size',[1 1],'nonnegative','real','finite'}));
    
    addParameter(parser, 'theta_target', default_options.theta_target, ...
        @(x)validateattributes(x, {'numeric'}, {'size',[1 1],'nonnegative','real','finite'}));
    
    addParameter(parser, 'file_name', default_options.file_name, ...
        @(x) strcmp(x,regexp(x,'.+lua','match')));
    
    parser.parse(input_options)

end
