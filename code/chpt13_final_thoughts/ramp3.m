function res = find_zero()
    res = fzero(@ramp_func, 9);
end

function res = ramp_func(v)
    % run the simulation until the ramp touches the ground
    % and return the x coordinate of the rider relative to
    % the end of the ramp

    % ramp_height is the height of the ramp in meters
    % ramp_dist is the horizontal distance from the tip of the
    % ramp to the post, so half_length is half the length of the ramp
    ramp_height = 2.5;
    ramp_dist = 10;
    half_length = norm([ramp_height,ramp_dist]);

    % compute the max and min angles
    maxth = atan2(ramp_height, ramp_dist);
    minth = -maxth;

    % compute the initial unit vectors
    ihat = [1 0]';
    jhat = [0 1]';
    rhat = [cos(maxth) sin(maxth)]';
    that = [-sin(maxth) cos(maxth)]';

    m = 75;        % mass of rider/board in kg
    g = 9.8;       % acceleration of gravity in m/s^2
    d = 1.0;       % height of the rider's CG in m
    %v = 8.9;
    I = 1000.0;       % moment of inertia of the ramp

    % left side of a ramp tilted up, velocity horizontal
    IP = -half_length * rhat + d * that;
    IV = v * ihat;
    init = [IP; maxth; IV; 0];

    % run the simulation, then show the results
    tend = 5;
    options = odeset('Events', @events_func);
    [T, M] = ode45(@slope_func, [0:0.05:tend], init);

    speedup=100;
    animate_func(T,M);

    xend = M(end,1);
    res = ramp_dist - xend;

    function animate_func(T,M)
        % show an animation of the data in M in real time (if possible)
        X = M(:,1);
        Y = M(:,2);
        TH = M(:,3);

        for i=1:length(T)
            clf;
            hold on;
            f = 1.5;
            unit = f*half_length;
            axis([-unit, unit, -unit, unit]);

            % draw the rider
            plot(X(i), Y(i), 'r.', 'MarkerSize', 50);

            % draw the ramp
            th = TH(i);
            rhat = [cos(th) sin(th)]';

            left = -half_length * rhat;
            right = half_length * rhat;
            line_func(left, right);

            orig = [0,0];
            bottom = -ramp_height * jhat;
            line_func(orig, bottom);

            hold off;
            drawnow;
            if i < length(T)
                dt = T(i+1) - T(i);
                %speedup = 100.0;
                pause(dt / speedup);
            end
        end
    end

    function line_func(A, B)
        % draw a blue line from point A to point B
        plot([A(1), B(1)], [A(2), B(2)], 'b-', 'LineWidth', 5)
    end

    function res = slope_func(t, W)
        % this is a slope function invoked by ode45
        n = length(W)/2;
        P = W(1:n);
        V = W(n+1:end);

        dRdt = V;
        dVdt = acceleration_func(t, P, V);

        res = [dRdt; dVdt];
    end

    function res = acceleration_func(t, P, V)
        % unpack P
        R = P(1:2);
        th = P(3);
        thdot = V(3);

        % compute rhat and that
        rhat = [cos(th) sin(th)]';
        that = [-sin(th) cos(th)]';

        % compute r, the distance from the pivot to the contact point
        r = dot(R, rhat);

        % find the restoring force that moves the center of mass
        % toward where it is supposed to be.
        dx = dot(R, that) - d;
        k = 10000.0;
        Fr = -k * dx * that;

        % if the rider is too high, the ramp doesn't pull down.
        if dx > 0 || r > half_length
            Fr = 0 * that;
        end

        % compute the total acceleration
        Ag = -g * jhat;
        Ar = Fr / m;
        A = Ag + Ar;

        % torque calculation can be scalar because we
        % know that R and Fr are in the plane of the ramp
        % and rhat perpendicular to that.
        aa = r * dot(-Fr, that) / I;

        % if the ramp is touching the ground, simulate
        % a restoring torque
        k = 100000.0;
        if th > maxth
            dth = th - maxth;
        elseif th < minth
            dth = th - minth;
        else
            dth = 0;
        end
        ar = -k * dth / I;

        % add some damping to the ramp
        c = 100;
        adamp = -c * thdot^2 * sign(thdot);

        % add up the angular accelerations
        aa = aa + ar + adamp;

        % pack the acceleration vector
        res = [A; aa];
    end

    function [value,isterminal,direction] = events_func(t,W)
        R = W(1:2);
        th = W(3);
        rhat = [cos(th) sin(th)]';
        r = dot(R, rhat);
        value = th - minth;
        isterminal = 1;
        direction = 0;
    end


end
