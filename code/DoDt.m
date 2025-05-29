% ДИФФЕРЕНЦИАЛЬНОЕ УРАВНЕНИЕ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DoDt реализует дифур 2-ого порядка в виде системы с заменой переменных:
% {d th(1)/ dt = th(2)
% {d th(2)/ dt = A*cos(omega*time) - nu*th(2) - recovery(th(1))

function DthetaDtime = DoDt(t, th, fun_waves, nu, recovery)
    DthetaDtime = [th(2);fun_waves(t) - nu*th(2) - (recovery(1)+recovery(2)*th(1)+recovery(4)*th(1).^3+recovery(6)*th(1).^5)];
end