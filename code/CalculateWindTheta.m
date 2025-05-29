function [theta_difference] = CalculateWindTheta(DSO, ship_state_i, ...
                                 equilibrium_position, ship_surface_area, ...
                                 wind_shoulder_0, intertia_momentum, ...
                                 wind_avg, accept_layer)

    rho=1.3;

    % ИНИЦИАЛИЗАЦИЯ ОБЩИХ ПЕРЕМЕННЫХ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    correction = accept_layer;
    theta_wind = equilibrium_position;
    
    % Поиск крена от ветра методом итераций. Относительная точность - accept_layer
    while correction >= accept_layer
        old_theta = theta_wind;
        wind_momentum= (-1)*rho/2*wind_avg^2*ship_surface_area*wind_shoulder_0*cos(theta_wind);
        % Выполняется из-за приведения коэффицента при theta'' к 1
        wind_momentum= wind_momentum/ intertia_momentum;
        
        poly_coeffs = DSO(end:-1:1);
        poly_coeffs(end) = poly_coeffs(end)-wind_momentum;
        all_roots = roots(poly_coeffs);
        real_roots = all_roots(imag(all_roots) == 0);
        real_roots = sort (real_roots);
        % Удаляем крайние нули (не являются равновесными положениями, так как находятся за точками заката)
        real_roots(1) = [];
        real_roots(end) = [];
        if(ship_state_i >= 4)
            % Если аварийное состояние 3-5, удаляем центральное равновесное
            % положение, т.к. оно неустойчивое
            if (size(real_roots,1) == 3)
                real_roots(ceil(size(real_roots, 1)/2)) = [];
            end
        end
    
        [~, idx] = min(abs(real_roots-old_theta));
        theta_wind = real_roots(idx);
        correction = abs(theta_wind-old_theta);
    end
    theta_difference = equilibrium_position - theta_wind;
end

