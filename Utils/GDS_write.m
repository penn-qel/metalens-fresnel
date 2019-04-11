% Last updated on 4/26/16 by RG

function params = GDS_write(pattern_struct,input_options)
% Write a text readable GDSII file from a structure of polygon vertices

    %Parse the input options
    if (nargin == 1)
       params.parser = parse_options; 
    else
       params.parser = parse_options(input_options);
    end
    options = params.parser.Results;
    
    fileID = fopen(options.filename,'w');
    fprintf(fileID,['HEADER ' options.version '\n']);  
    fprintf(fileID,['BGNLIB ' datestr(now,2) datestr(now,13) '\n']);
    fprintf(fileID,['LIBNAME ' options.lib_name '\n']);
    fprintf(fileID,['UNITS ' num2str(options.database_unit*1e-3) ' ' num2str(options.database_unit*1e-9) '\n\n']);
    fprintf(fileID,'BGNSTR\n');
    fprintf(fileID,'STRNAME TOP\n');
        for loop_index1 = 1:length(pattern_struct)
            fprintf(fileID,'\n\nBOUNDARY\n'); 
            fprintf(fileID,['LAYER ' num2str(pattern_struct(loop_index1).layer) '\n']);
            fprintf(fileID,'DATATYPE 0\n'); 
            fprintf(fileID,'XY \n') ;
            for loop_index2 = 1:length(pattern_struct(loop_index1).xy)
                fprintf(fileID,strcat(toGDSnum(round(pattern_struct(loop_index1).xy(loop_index2,1),3)), ...
                    ': ', toGDSnum(round(pattern_struct(loop_index1).xy(loop_index2,2),3)), '\n'));  
            end
            fprintf(fileID,'ENDEL\n');
        end
    fprintf(fileID,'ENDSTR\n');
    
    fprintf(fileID,'ENDLIB');
    fclose(fileID);
end

function out = toGDSnum(num)
% Somebody should comment their code.

    X = num;

    if X >= 0
        Xl = floor(X);
    else
        Xl = ceil(X);
    end
    Xr = round((X-Xl)*1000);
      
    if Xl == 0 && Xr == 0 
        Xstring = '0';
    elseif Xl == 0 && Xr ~= 0
        if abs(Xr) >= 100
            Xstring = strcat(int2str(Xr));
        elseif abs(Xr) < 10
            if Xr > 0
                Xstring = strcat('00', int2str(Xr));
            else
                Xstring = strcat('-00', int2str(abs(Xr)));
            end
        else
            if Xr > 0
                Xstring = strcat('0', int2str(Xr));
            else
                Xstring = strcat('-0', int2str(abs(Xr)));
            end
        end
    elseif Xl ~= 0 && Xr == 0
        Xstring = strcat(int2str(Xl),'000');
    elseif Xl ~=0 && Xr ~= 0
        if abs(Xr) >= 100
            Xstring = strcat(int2str(Xl),int2str(abs(Xr)));
        elseif abs(Xr) < 10
            Xstring = strcat(int2str(Xl),'00', int2str(abs(Xr)));
        else
            Xstring = strcat(int2str(Xl),'0', int2str(abs(Xr)));
        end
    end

    out = Xstring;

end

function parser = parse_options(input_options)

    % Create the input parser
    parser = inputParser;

    %Set the default options
    default_options.version = '600'; % GDS file version
    default_options.lib_name = 'LIB'; % GDS library name
    default_options.str_name = 'pattern'; % ASCII string: contains a string which is the structure name. A structure name may be up to 32 characters long. Legal characters are 'A' through 'Z', 'a' through 'z', '0' through '9', underscore, question mark, and the dollar sign, '$'.
    default_options.filename = ['AutoGen-' date '.txt']; % file name
    default_options.database_unit = 1; % database unit in nm

    %Address no input case by assigning to defaults
    if (nargin == 0)
        input_options = default_options;
    end

    addParameter(parser, 'version', default_options.version, ...
        @(x) ~isempty(validatestring(x, {'0','3','4','5','600'}))); % Indicates version 6.0 other options are 0, 3, 4, 5, and 600

    addParameter(parser, 'lib_name', default_options.lib_name);

    addParameter(parser, 'str_name', default_options.str_name);

    addParameter(parser, 'filename', default_options.filename);

    addParameter(parser, 'database_unit', default_options.database_unit, ...
        @(x)validateattributes(x, {'numeric'}, {'size',[1 1],'nonnegative','real','finite'}));
    
    parser.parse(input_options)

end
