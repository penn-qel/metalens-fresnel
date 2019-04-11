% updated by RG on 2/27/17

function [x, y, dev] = arc_cut(r,grid,tol,cut)
% Fracture curves on a square grid for e-beam writing according to the
% integer cut algorithm given in "Best Approximate Circles on Integer
% Grids," M. D. McIlroy ACM Transactions on Graphics, Vol. 2 pgs. 237-263 (1983).
% input arguments are:
% r: radius
% grid: grid spacing, square grid in x and y is assumed
% cut: 'arc+', 'arc-', or 'circle', which give a positive half circle, a
% negative half circle, or a full circle.  All units must be consistent,
% for CAD purposes microns should be used

    rsq = round((r/grid))^2; % radius of the curve squared, rounded to an integer
    x(1) = round(sqrt(rsq)); % start at x = integer radius
    y(1) = 0; % start at y = 0
    delx = -1; % begin by moving in the first quadrant
    dely = 1;
    
    % starting residuals, see paper for details
    eps = x^2 + y^2 - rsq; 
    
    dev(1) = eps;
    
    deps_x = 2*x*delx + 1;
    deps_y = 2*y*dely + 1;
    deps_xy = 2;
    
    eps_x = eps + deps_x;
    eps_y = eps + deps_y;
    eps_xy = eps + deps_xy;
 
    % loop for more points than we need, and then break when we have traversed 180 degress.
    %There is probably a more elegant way to do this.
    for loop_index = 2:8*round(sqrt(rsq));

        eps_x = eps + deps_x;
        eps_y = eps + deps_y;
        eps_xy = eps + deps_x + deps_y;
        
        if (-eps_xy < eps_y)
            x(loop_index) = x(loop_index-1) + delx;
            eps = eps + deps_x;
            deps_x = deps_x + deps_xy;
        else
            x(loop_index) = x(loop_index-1);
        end
        
        if (eps_xy < -eps_x)
            y(loop_index) = y(loop_index-1) + dely;
            eps = eps + deps_y;
            deps_y = deps_y + deps_xy;
        else
            y(loop_index) = y(loop_index-1);
        end
        
        if(x(loop_index) == 0) % && x(loop_index-1) == 0)
            dely = -dely;
            deps_y = -eps_y + deps_xy;
            eps = -eps;
            deps_x = -deps_x;
            deps_y = -deps_y;
            deps_xy = -deps_xy;
        end
        
        if(y(loop_index) == 0)% && y(loop_index-1) == 0)
            delx = -delx;
            deps_x = -eps_x + deps_xy;
            eps = -eps;
            deps_x = -deps_x;
            deps_y = -deps_y;
            deps_xy = -deps_xy;
        end
        
        dev(loop_index) = x(loop_index)^2 + y(loop_index)^2 - rsq;
        
        if (x(loop_index) <= 0 && y(loop_index) <= round(sqrt(rsq)))% && loop_index > 10) %(x(loop_index) == -x(1) && y(loop_index) == y(1) && loop_index > 10)
            break
        end

    end
    clear loop_index
    
    % reduce the number of points as set by some tolerance for the
    % deviation from a perfect circle
    
    x = x(abs(dev) < (tol/grid));
    y = y(abs(dev) < (tol/grid));
    
    % renormalize the vector of points to actual units using the specified
    % grid size, and perform the appropriate transformations.
    if strcmp(cut,'arc+')
        % arc starts at (r,0) and goes to (-r,0) CCW
        x = [x -fliplr(x(1:end-1))].*grid;
        y = [y fliplr(y(1:end-1))].*grid;
    elseif strcmp(cut,'arc-')
        % arc starts at (r,0 and goes to (-r,0) CW
        x = [x -fliplr(x(1:end-1))].*grid;
        y = [-y -fliplr(y(1:end-1))].*grid;
    else
        x = [x -fliplr(x(1:end-1)) -x(2:end) fliplr(x(1:(end-1)))].*grid;
        y = [y fliplr(y(1:end-1)) -y(2:end) -fliplr(y(1:(end-1)))].*grid;
    end

end
