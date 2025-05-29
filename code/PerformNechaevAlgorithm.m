function [summary_table] = PerformNechaevAlgorithm(DSOs, nu, y0_1_start, y0_2_start, ...
                                      ship_surface_area, wind_shoulder_0, ...
                                      intertia_momentum, alltime, ...
                                      best_A, best_B, quas_window_size, ...
                                      wv_test, wind_test, wind_avgs, ...
                                      stat_size, disp_jump_diff, accept_layer)
    % Плотность воздуха
    rho = 1.3;

    % Инициализация сводной таблицы
    summary_table = table();
    row_counter = 1;

    for wave_i = 1:size(wv_test, 1)
        % Функция, задающая волнение
%         fun_waves = @(new_x) interp1(1:alltime, wv_test{wave_i}, new_x, 'spline');
        
        for wind_i = 4:size(wind_test, 1)
            % Скорость ветра
            wind_speed = wind_test(wind_i, :);

            for ship_state_i = 3:length(DSOs)

                % Задание состояния судна
                DSO = DSOs(:, ship_state_i);
        
                % ПОИСК РЕАЛЬНЫХ РАВНОВЕСНЫХ ПОЛОЖЕНИЙ
                r = roots(DSO(end:-1:1));
                not_im = imag(r)==0;
                r = r(not_im);
                r = sort (r);
                % Удаляем крайние нули (не являются равновесными положениями, так как находятся за точками заката)
                r(1) = [];
                r(end) = [];
                if(ship_state_i >= 4)
                    % Если аварийное состояние 3-5, удаляем центральное равновесное
                    % положение, т.к. оно неустойчивое
                    if (size(r,1) == 3)
                        r(ceil(size(r, 1)/2)) = [];
                    end
                end
                equilibrium_positions = r;

%                 % Окно сбора статистики зависит от периода качки
%                 if(ship_state_i == 2)
%                     stat_size=12;
%                 end
                
                % ИНИЦИАЛИЗАЦИЯ ОБЩИХ ПЕРЕМЕННЫХ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                y0_1 = equilibrium_positions(end);
                y0_2 = 0;
                % theta_data - массив для хранения функции колебаний корабля
                % wind_momentum - момент силы ветра
                theta_data = zeros(1, alltime);
                theta_data(1) = y0_1;
                wind_momentum = zeros(1, alltime);
                array_calculated_equilibrium = zeros(1, alltime);
                array_correction = zeros(1, alltime);
                array_actual_equilibrium = zeros(1, alltime);
                array_mean = zeros(1, alltime);
                dispersion = zeros(1,alltime);
                expectation = zeros(1,alltime);
                operatable_theta_data = [y0_1];
                new_actual_equilibrium = 0;
                actual_equilibrium = 0;
                % Булева переменная для отслеживания состояния порыва
                is_gust_active = false;
                gust_starts = [];
                gust_ends = [];
                
                % Списки локальных минимумов и максимумов
                minimas_theta = [];
                maximas_theta = [];

                
                try

                    for time = 2:alltime
    
                        % Вычисление момента силы ветра
                        % Ветер дует в направлении противоположном от
                        % аварийного крена, чтобы судно не перевернулось
                        wind_momentum(time) = (-1)*rho/2*wind_speed(time)^2*ship_surface_area*wind_shoulder_0*cos(theta_data(time-1));
                        % Выполняется из-за приведения коэффицента при theta'' к 1
                        wind_momentum(time) = wind_momentum(time) / intertia_momentum + wv_test{wave_i}(time);
        
                        fun_general= @(new_x) interp1([time-1, time], [wind_momentum(time-1), wind_momentum(time)], new_x, 'spline');
        
                        % ВЫЧИСЛЕНИЕ ПОЛОЖЕНИЯ СУДНА %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        
                        
                        [~, theta_dif] = ode45(@(t,y) DoDt(t, y, fun_general, nu, DSO), [(time-1) time], [y0_1 y0_2]);
                    
                        % ЗАПИСЬ ПОЛОЖЕНИЯ КОРОБЛЯ В МОМЕНТ TIME %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        % Каждому моменту времени соответствует одна точка на графике.
                        theta_data(time) = theta_dif(end, 1);
                        stat_index = max(1, time - stat_size);
                        expectation(time) = mean(theta_data(stat_index : time));
                        dispersion(time) = var(expectation(stat_index : time));
                        % В первые секунды процесса дисперсия очень большая и
                        % мешает поиску порывов
                        if time < 60
                            dispersion(time) = 0;
                        end

                        if time < quas_window_size
                            stat_size = 3*CalculateAverageExtremumDistance(theta_data(1:time));
                        end
                    
                        % При решении дифура на следующем шаге цикла будет использоваться его
                        % состояние в конце нынешнего шага цикла
                        y0_1 = theta_dif(end, 1);
                        y0_2 = theta_dif(end, 2);
    
    
    
    
                        % Переменная для случая, когда находим конец порыва и
                        % нужно "post factum" обработать данные. 
                        skipped_part_start = time;
                        % На время действия порыва отключаем алгоритм
                        if (is_gust_active)
                            gust_containing_part = dispersion(gust_starts(end):time);
    
                            gust_end_idx = GustEndedNow(gust_containing_part, disp_jump_diff, wind_avgs(wind_i));
    
                            if(gust_end_idx < 0)
                                continue
                            end
                            % Конец порыва искали от его начала, поэтому
                            % добавляем индекс начала порыва
                            gust_ends(end+1) = gust_starts(end) + gust_end_idx;
                            % Для поиска конца порыва набирается статистика с
                            % запасом. Эту статистику тоже нужно обработать
                            % алгоритмом Нечаева, но "post factum"
                            skipped_part_start = gust_ends(end);
                            is_gust_active = false;
                        else
    
                            % Выделение участка для поиска начала порыва (от конца
                            % предыдущего порыва, либо от самого начала)
                            if (isempty(gust_ends))
                                last_gust_idx = 1;
                            else
                                last_gust_idx = gust_ends(end);
                            end
    
                            % Выделяем качку вне порывов
                            if (isempty(gust_starts))
                                first_indx = time;
                            else
                                first_indx = gust_starts(1);
                            end
                            working_part = dispersion(1:first_indx);
                            for i = 1:length(gust_starts)
                                % Получаем текущие начальный и конечный индексы
                                if (i == length(gust_starts))
                                    start_idx = time;
                                else
                                    start_idx = gust_starts(i+1);
                                end
                                end_idx = gust_ends(i);
                                
                                % Вырезаем отрезок и добавляем к результату
                                segment = dispersion(end_idx:start_idx);
                                working_part = [working_part segment];
                                
                                % Увеличиваем суммарную длину
                            end
    
                            gust_start_idx = GustStartedNow(working_part, disp_jump_diff);
                            % Если начало порыва найдено, запоминаем его. Возможно,
                            % что начало порыва не совпадает с текущим моментом
                            % времени на несколько итераций. Тогда прошедшие
                            % итерации зануляем (дисперсия запаздывает).
                            % Также считаем, что порыв начался на 5 секунд
                            % раньше найденного момента, тк статистика
                            % запаздывает, но влияние сказывается
                            if(gust_start_idx > 0)
                                gust_start_idx = gust_start_idx - 5;
                                gust_starts(end+1) = (time - length(working_part)) + gust_start_idx;
                                array_calculated_equilibrium(gust_starts(end):time) = 0;
                                array_correction(gust_starts(end):time) = 0;
                                array_actual_equilibrium(gust_starts(end):time) = 0;
                                array_mean(gust_starts(end):time) = 0;
                                operatable_theta_data(end - (length(working_part) - gust_start_idx):end) = [];
                                is_gust_active = true;
                                continue
                            end
                        end
    
    
    
                        
                        % Для поиска конца порыва набирается статистика с
                        % запасом. Эту статистику тоже нужно обработать
                        % алгоритмом Нечаева, но "post factum"
                        for oper_idx = skipped_part_start:time
                            % Реальное равновесное положение на момент времени time
                            [~, current_equilibrium_index] = min(abs(theta_data(oper_idx) - equilibrium_positions)); % Находим индекс ближайшего элемента
                            new_actual_equilibrium = equilibrium_positions(current_equilibrium_index);
                            if (actual_equilibrium ~= new_actual_equilibrium)
                                operatable_theta_data = [];
                                actual_equilibrium = new_actual_equilibrium;
                                continue
                            end
                            
                            operatable_theta_data(end+1) = theta_data(oper_idx);
                            equilibrium_window_index = max(1, length(operatable_theta_data) - quas_window_size);
                            window_theta_data = operatable_theta_data(equilibrium_window_index:end);
                            if(length(window_theta_data) < 3)
                                continue
                            end
                            
                            % ПОИСК МАКСИМУМОВ И МИНИМУМОВ (ИГНОРИРОВАНИЕ ПОБОЧНЫХ)
                            
                            [minimas_theta, maximas_theta] = FindExtremesWithThreshold(window_theta_data, mean(window_theta_data));
                            
                            if(size(maximas_theta,1) == 0 || size(minimas_theta,1) == 0)
                                continue
                            end
                            
                
                
                            % ВЫЧИСЛЕНИЕ РАВНОВЕСНОГО ПОЛОЖЕНИЯ ПО НЕЧАЕВУ    
                            % Элементы, необходимые для расчетов
                            theta_mean = mean(window_theta_data);
                            theta_range = mean(window_theta_data(maximas_theta(:,1)) - window_theta_data(minimas_theta(:,1)));
                            d2_window_theta_data = diff(diff(window_theta_data));
                            [minimas_d2_theta, maximas_d2_theta] = FindLocalExtrema(d2_window_theta_data);
                            if size(minimas_d2_theta, 1) ~= size(maximas_d2_theta, 1)
                                if size(minimas_d2_theta, 1) > size(maximas_d2_theta, 1)
                                    minimas_d2_theta(1,:) = [];
                                else
                                    maximas_d2_theta(1,:) = [];
                                end
                            end
                            if(size(minimas_d2_theta,1) == 0 || size(maximas_d2_theta,1) == 0)
                                continue
                            end
                            acceleration_max = abs(mean(d2_window_theta_data(maximas_d2_theta(:,1))));
                            acceleration_min = abs(mean(d2_window_theta_data(minimas_d2_theta(:,1))));
                            acceleration_part = (acceleration_max - acceleration_min) / (acceleration_max + acceleration_min);
                
                            % Расчет равновесного положения
                            calculated_equilibrium = theta_mean * (1 + sign(theta_mean)*(best_A * theta_range + best_B * theta_range^2) * acceleration_part);
                            
    
                            array_calculated_equilibrium(oper_idx) = calculated_equilibrium;
                            array_actual_equilibrium(oper_idx) = new_actual_equilibrium;
                            array_mean(oper_idx) = theta_mean;
                            array_correction(oper_idx) = CalculateWindTheta(DSO, ship_state_i, new_actual_equilibrium, ...
                                                                    ship_surface_area, wind_shoulder_0, ...
                                                                    intertia_momentum, wind_avgs(wind_i), accept_layer);
    
                        end
                        
                        
                    end

                    array_calculated_equilibrium(1:quas_window_size) = 0;
                    array_actual_equilibrium(1:quas_window_size) = 0;
                    array_mean(1:quas_window_size) = 0;
                    array_correction(1:quas_window_size) = 0;
    
                    not_calculated_length = quas_window_size;
                    for gusts_idx = 1:length(gust_starts)-1
                        if (gust_starts(gusts_idx) >= quas_window_size)
                            not_calculated_length = not_calculated_length + gust_ends(gusts_idx) - gust_starts(gusts_idx);
                        else
                            if (gust_ends(gusts_idx) > quas_window_size)
                                not_calculated_length = not_calculated_length + gust_ends(gusts_idx) - quas_window_size;
                            else
                                continue
                            end
                        end
                    end
                    % Если к концу моделирования порыв не закончился, считаем
                    % его до конца
                    if length(gust_starts) ~= length(gust_ends)
                        not_calculated_length = not_calculated_length + alltime - gust_starts(end);
                    else
                        if ~isempty(gust_starts)
                            not_calculated_length = not_calculated_length + gust_ends(end) - gust_starts(end);
                        end
                    end
    
                    cacl_diff = mean(abs(array_calculated_equilibrium+array_correction-array_actual_equilibrium))*(length(array_calculated_equilibrium)/(length(array_calculated_equilibrium)-not_calculated_length));
                    mean_diff = mean(abs(array_mean+array_correction-array_actual_equilibrium))*(length(array_calculated_equilibrium)/(length(array_calculated_equilibrium)-not_calculated_length));
    
                    % ЗАПИСЬ ДАННЫХ
                    % После завершения расчетов для текущих условий сохраняем данные
                    summary_table.wave(row_counter) = wave_i;
                    summary_table.wind(row_counter) = wind_i;
                    summary_table.ship_state(row_counter) = ship_state_i;
                    
                    % Сохраняем массивы в ячейки таблицы
                    summary_table.calculated_equilibrium{row_counter} = array_calculated_equilibrium;
                    summary_table.actual_equilibrium{row_counter} = array_actual_equilibrium;
                    summary_table.mean_values{row_counter} = array_mean;
                    summary_table.corrections{row_counter} = array_correction;
                    summary_table.theta_data{row_counter} = theta_data;
                    
                    % Сохраняем метрики ошибок
                    summary_table.calc_error(row_counter) = cacl_diff;
                    summary_table.mean_error(row_counter) = mean_diff;
                    
                    row_counter = row_counter + 1;
                    text = ['Ship state: ', num2str(ship_state_i), '/', num2str(size(DSOs,2)), ...
                        ' Wind speed: ', num2str(wind_i), '/', num2str(length(wind_avgs)), ...
                        ' Wave file: ', num2str(wave_i), '/', num2str(size(wv_test,1))];
                    disp(text)
    %                 figure
    %                 hold on
    %                 plot(theta_data)
    %                 plot(array_calculated_equilibrium)
    %                 plot(array_actual_equilibrium)
    %                 plot(array_mean)
    %                 hold off
                catch ME
                    a=1;
                    rethrow(ME)
                end
            end
        end
    end
end