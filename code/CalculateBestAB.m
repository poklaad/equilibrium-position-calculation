function [best_A, best_B] = CalculateBestAB(DSOs, nu, alltime, ...
                                   A_values, B_values, ...
                                   wv_train, equilibrium_window_size)
    
    

    

    % Исходная формула в радианах, исходная формула в градусах, формула с +- в
    % радианах, формула с +- в градусах, формула без 1 в радианах, формула без
    % 1 в градусах
    AB_table = zeros(size(wv_train,1), size(DSOs,2), length(A_values), length(B_values));
    % Радианы, градусы
    mean_table = zeros(size(wv_train,1), size(DSOs,2));
    
    for file_i = 1:size(wv_train,1)
        % Функция, задающая волнение

        fun_waves = @(new_x) interp1(1:alltime, wv_train{file_i}, new_x, 'spline');
    
        for ship_state_i = 1:size(DSOs,2)
            
            % Set shipwreck state
            DSO = DSOs(:, ship_state_i);
    
            % ПОИСК РЕАЛЬНЫХ РАВНОВЕСНЫХ ПОЛОЖЕНИЙ
            r = roots(DSO(end:-1:1));
            not_im = imag(r)==0;
            r = r(not_im);
            r_count = length(r);
            r = sort (r);
            % Удаляем крайние нули (не являются равновесными положениями, так как находятся за точками заката)
            r(1) = [];
            r(end) = [];
            r_radians = r;
            if(ship_state_i >= 4)
                % Если аварийное состояние 3-5, удаляем центральное равновесное
                % положение, т.к. оно неустойчивое
                if (size(r,1) == 3)
                    r(ceil(size(r, 1)/2)) = [];
                end
            end
            
            % ИНИЦИАЛИЗАЦИЯ ОБЩИХ ПЕРЕМЕННЫХ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % theta_data и d_theta_data - массивы для хранения функции колебаний корабля и ее производной соответственно
            theta_data = zeros(1, alltime);
            d_theta_data = zeros(1, alltime);
            % Списки локальных минимумов и максимумов
            minimas_theta = [];
            maximas_theta = [];
            % y0_1, y0_2 - начальные условия для решения дифура
            y0_1 = 0;
            y0_2 = 0;
    
            for time = 1:alltime
                % ВЫЧИСЛЕНИЕ ПОЛОЖЕНИЯ СУДНА %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % DoDt - вспомогательная функция (расположена в конце программы) для
                % вычисления дифура
                [time_dif,theta_dif] = ode45(@(t,y) DoDt(t, y, fun_waves, nu, DSO),[(time-1) time],[y0_1 y0_2]);
            
                % ЗАПИСЬ ПОЛОЖЕНИЯ КОРОБЛЯ В МОМЕНТ TIME %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
                % Каждому моменту времени соответствует одна точка на графике.
                theta_data(time) = theta_dif(end, 1);
    %             d_theta_data(time) = theta_dif(end, 2);
            
                % При решении дифура на следующем шаге цикла будет использоваться его
                % состояние в конце нынешнего шага цикла
                y0_1 = theta_dif(end, 1);
                y0_2 = theta_dif(end, 2);
    
                
                
            end
    
            theta_data_radians = theta_data;
            
            window_theta_data_radians = theta_data_radians(equilibrium_window_size:alltime);
            
            % ПОИСК МАКСИМУМОВ И МИНИМУМОВ (ИГНОРИРОВАНИЕ ПОБОЧНЫХ)
            equilibrium_positions_radians = r_radians;
            [minimas_theta, maximas_theta] = FindExtremesWithThreshold(window_theta_data_radians, equilibrium_positions_radians);
            if(size(maximas_theta,1) == 0 || size(minimas_theta,1) == 0)
                continue
            end

    
            % ВЫЧИСЛЕНИЕ РАВНОВЕСНОГО ПОЛОЖЕНИЯ ПО НЕЧАЕВУ
            % В РАДИАНАХ
            % Реальное равновесное положение на момент времени time
            [~, current_equilibrium_index] = min(abs(theta_data_radians(end) - equilibrium_positions_radians)); % Находим индекс ближайшего элемента
            actual_equilibrium_radians = equilibrium_positions_radians(current_equilibrium_index);
    
            % Элементы, необходимые для расчетов
            theta_mean_radians = mean(window_theta_data_radians);
            theta_range_radians = mean(window_theta_data_radians(maximas_theta(:,1)) - window_theta_data_radians(minimas_theta(:,1)));
            d2_window_theta_data_radians = diff(diff(window_theta_data_radians));
            [minimas_d2_theta, maximas_d2_theta] = FindLocalExtrema(d2_window_theta_data_radians);
            if size(minimas_d2_theta, 1) ~= size(maximas_d2_theta, 1)
                if size(minimas_d2_theta, 1) > size(maximas_d2_theta, 1)
                    minimas_d2_theta(1,:) = [];
                else
                    maximas_d2_theta(1,:) = [];
                end
            end
            acceleration_max_radians = abs(mean(d2_window_theta_data_radians(maximas_d2_theta(:,1))));
            acceleration_min_radians = abs(mean(d2_window_theta_data_radians(minimas_d2_theta(:,1))));
            acceleration_part_radians = (acceleration_max_radians - acceleration_min_radians) / (acceleration_max_radians + acceleration_min_radians);
            
            % Расчет равновесного положения
            % Со знаком после 1
            calculated_equilibrium_radians_with_sign = theta_mean_radians * (1 + sign(theta_mean_radians)*(A_values' .* theta_range_radians + B_values .* theta_range_radians^2) * acceleration_part_radians);
            

            % ЗАПИСЬ ДАННЫХ
            % В РАДИАНАХ
            % Разница между реальным и рассчитанным равновесным положением
            AB_table(file_i, ship_state_i, :, :) = abs(calculated_equilibrium_radians_with_sign - actual_equilibrium_radians);

            % % Разница между реальным равновесным положением и средним
            mean_table(file_i, ship_state_i) = abs(theta_mean_radians - actual_equilibrium_radians);

            text = ['Ship state: ', num2str(ship_state_i), '/', num2str(size(DSOs,2)), ...
                ' Wave file: ', num2str(file_i), '/', num2str(size(wv_train,1))];
            disp(text)

        end
    end


    % ГЛОБАЛЬНЫЕ ОПТИМАЛЬНЫЕ ВАРИАНТЫ
    AB_mean = squeeze(mean(AB_table(:,:,:,:), [1 2]));
    Mean_mean = squeeze(mean(mean_table(:,:), [1 2]));
    AB_diff_mean = AB_mean - Mean_mean;

    % ВЫБОР ОПТИМАЛЬНЫХ A И B
    [index_A, index_B] = find(AB_mean==min(AB_mean,[],'all'));
    best_A = A_values(index_A);
    best_B = B_values(index_B);
    
    fig = figure;
    heatmap(B_values, A_values, AB_diff_mean)
    xlabel('B')
    ylabel('A')
    text = {["Настройка А и В."],...
        ["Разница между погрешностями рассчитанного равновесного положения и среднего угла крена."],...
        ["Осреднение по авариям и волнениям."],...
        ["Оптимальные параметры алгоритма Нечаева."], ...
        ['А ', num2str(best_A), '. B ',num2str(best_B)]};
    title(text)
    savefig(fig, 'ABSelection_MeanCalcDiff.fig');
    
    fig = figure;
    heatmap(B_values, A_values, AB_mean)
    xlabel('B')
    ylabel('A')
    text = {["Настройка А и В."],...
        ["Разница между рассчитанным равновесным положением и реальным."],...
        ["Осреднение по авариям и волнениям."],...
        ["Оптимальные параметры алгоритма Нечаева. "], ...
        ['А ', num2str(best_A), '. B ',num2str(best_B)]};
    title(text)
    savefig(fig, 'ABSelection_CalcError.fig');

    text = ['Оптимальные параметры алгоритма Нечаева. ', ...
        'А = ', num2str(best_A), ', B = ', num2str(best_B)];
    disp(text);

end