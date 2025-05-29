% num_samples - длина генерируемого интервала ветра
% V_average - средняя скорость ветра

function WindTurbGeneration = WindTurbGeneration(wind_length, V_average)
    warning('off')
    
    % Порядок авторегрессии
    regression_degree = 8;
    % Значения задержки
    tau = 0:regression_degree+1;
    
    % Спектр ветра
    S = @(f) (13.5 / V_average) ./ (1 + (f * 900 / V_average)).^(5/3);
    
    % Вычисление корреляционной функции
    K = zeros(size(tau));
    for i = 1:length(tau)
        K(i) = integral(@(f) S(f) .* cos(f * tau(i)), 0, Inf);
    end    
    
    % ПОСТРОЕНИЕ УРАВНЕНИЙ ЮЛА-УОКЕРА
    % Матрица автокорреляции
    R = zeros(regression_degree, regression_degree);
    for i = 1:regression_degree
        for j = 1:regression_degree
            R(i, j) = K(abs(i-j)+1)/K(1);
        end
    end
    % Вектор автокорреляций для правой части
    r = zeros(regression_degree, 1);
    for i = 1:regression_degree
        r(i) = K(i+1)/K(1);
    end
    
    % Получение коэффициентов авторегрессии
    Phi = R \ r;
    Phi = Phi';

    % Генерация случайных чисел чисел
    epsilon = sqrt(0.0225) * randn(wind_length + regression_degree, 1);
    
    % Моделирование турбулентной составляющей
    V_turb = zeros(wind_length+regression_degree, 1);
    for i = 2:wind_length
        num_coefs_active = min(regression_degree, i-1);
        V_turb(i) = Phi(1:num_coefs_active) * V_turb(i-1:-1:i - num_coefs_active) + epsilon(i);
    end
    
    V_turb = V_turb(regression_degree+1:end);
    
    % Полная скорость ветра
    WindTurbGeneration = V_average + V_turb;
end