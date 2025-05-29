% Дифур 2-ого порядка в виде системы с заменой переменных.
% h - метацентрическая высота, задается как значение производной 
% полинома с коэффициентами recovery в точке theta
% {d theta(1)/ dt = theta(2)
% {d theta(2)/ dt = fun_wind - nu*theta(2) - h*theta(1)

function DifEqWind = DifEqWind(t, theta, fun_wind_momentum, nu, h)
    DifEqWind = [theta(2);fun_wind_momentum(t) - nu*theta(2) - h*theta(1)];
end