function PlotEveryErrorHeatmaps(summary_table, wave_file_list, wind_avgs)
    % Определение аварийных состояний для подписей
    ship_states = {'неповрежденный', '1-ое аварийное', '2-ое аварийное', ...
                  '3-ье аварийное', '4-ое аварийное', '5-ое аварийное'};
    
    all_errors = [];
    
    % Сначала собираем все данные для определения глобальных границ
    for wind_idx = 1:length(wind_avgs)
        error_diff_matrix = zeros(length(ship_states), length(wave_file_list));
        
        for wave_idx = 1:length(wave_file_list)
            for state_idx = 1:length(ship_states)
                mask = (summary_table.wave == wave_idx) & ...
                       (summary_table.wind == wind_idx) & ...
                       (summary_table.ship_state == state_idx);
                
                if any(mask)
                    error_diff = summary_table.mean_error(mask) - summary_table.calc_error(mask);
                    error_diff_matrix(state_idx, wave_idx) = error_diff;
                end
            end
        end
        all_errors = [all_errors; error_diff_matrix(:)];
    end
    
    % Определяем глобальные границы
    global_min = (-1)*max(abs(all_errors));
    global_max = max(abs(all_errors));
    
    % Если все значения одинаковые, немного расширяем диапазон
    if global_min == global_max
        global_min = global_min - 0.1;
        global_max = global_max + 0.1;
    end
    
    % Теперь строим тепловые карты с установленными границами
    for wind_idx = 1:length(wind_avgs)
        % Создаем матрицу для тепловой карты
        error_diff_matrix = zeros(length(ship_states), length(wave_file_list));
        
        % Заполняем матрицу разницами ошибок
        for wave_idx = 1:length(wave_file_list)
            for state_idx = 1:length(ship_states)
                mask = (summary_table.wave == wave_idx) & ...
                       (summary_table.wind == wind_idx) & ...
                       (summary_table.ship_state == state_idx);
                
                if any(mask)
                    error_diff = summary_table.mean_error(mask) - summary_table.calc_error(mask);
                    error_diff_matrix(state_idx, wave_idx) = error_diff;
                end
            end
        end
        
        % Создаем subplot для текущей скорости ветра
        fig = figure
        
        % Строим тепловую карту с установленными границами
        h = heatmap(wave_file_list, ship_states, error_diff_matrix);
        
        % Настройки отображения
        h.Title = ['Скорость ветра: ' num2str(wind_avgs(wind_idx)) ' м/с'];
        h.XLabel = 'Волнение';
        h.YLabel = 'Аварийное состояние';
        h.ColorbarVisible = 'on';
        h.Colormap = parula;
        h.ColorLimits = [global_min, global_max]; % Устанавливаем общие границы
        
        % Подписи значений в ячейках
        h.FontSize = 8;
        
        % Поворачиваем подписи по оси X для лучшей читаемости
        h.XDisplayLabels = wave_file_list;

        % Общий заголовок
        h = sgtitle({'Разница между ошибкой среднего и расчетного положения'; '(mean_error - calc_error)'}, ...
                    'Interpreter', 'none', ...
                    'FontSize', 12, ...
                    'FontWeight', 'bold');

        savefig(fig, ['simulation_results_heatmap',num2str(wind_idx),'.fig']);
    end
    
    



    % ВТОРОЙ ГРАФИК

    all_errors = [];
    
    % Сначала собираем все данные для определения глобальных границ
    for wind_idx = 1:length(wind_avgs)
        error_diff_matrix = zeros(length(ship_states), length(wave_file_list));
        
        for wave_idx = 1:length(wave_file_list)
            for state_idx = 1:length(ship_states)
                mask = (summary_table.wave == wave_idx) & ...
                       (summary_table.wind == wind_idx) & ...
                       (summary_table.ship_state == state_idx);
                
                if any(mask)
                    error_diff = summary_table.calc_error(mask);
                    error_diff_matrix(state_idx, wave_idx) = error_diff;
                end
            end
        end
        all_errors = [all_errors; error_diff_matrix(:)];
    end
    
    % Определяем глобальные границы
    global_min = (-1)*max(abs(all_errors));
    global_max = max(abs(all_errors));
    
    % Если все значения одинаковые, немного расширяем диапазон
    if global_min == global_max
        global_max = global_max + 0.1;
    end
    
    % Теперь строим тепловые карты с установленными границами
    for wind_idx = 1:length(wind_avgs)
        % Создаем матрицу для тепловой карты
        error_diff_matrix = zeros(length(ship_states), length(wave_file_list));
        
        % Заполняем матрицу разницами ошибок
        for wave_idx = 1:length(wave_file_list)
            for state_idx = 1:length(ship_states)
                mask = (summary_table.wave == wave_idx) & ...
                       (summary_table.wind == wind_idx) & ...
                       (summary_table.ship_state == state_idx);
                
                if any(mask)
                    error_diff = summary_table.calc_error(mask);
                    error_diff_matrix(state_idx, wave_idx) = error_diff;
                end
            end
        end
        
        % Создаем subplot для текущей скорости ветра
        fig = figure
        
        % Строим тепловую карту с установленными границами
        h = heatmap(wave_file_list, ship_states, error_diff_matrix);
        
        % Настройки отображения
        h.Title = ['Скорость ветра: ' num2str(wind_avgs(wind_idx)) ' м/с'];
        h.XLabel = 'Волнение';
        h.YLabel = 'Аварийное состояние';
        h.ColorbarVisible = 'on';
        h.Colormap = parula;
        h.ColorLimits = [0, global_max]; % Устанавливаем общие границы
        
        % Подписи значений в ячейках
        h.FontSize = 8;
        
        % Поворачиваем подписи по оси X для лучшей читаемости
        h.XDisplayLabels = wave_file_list;

        % Общий заголовок
        h = sgtitle({'Ошибка расчетного положения'; 'calc_error'}, ...
                    'Interpreter', 'none', ...
                    'FontSize', 12, ...
                    'FontWeight', 'bold');
        savefig(fig, ['calc_error_heatmap',num2str(wind_idx),'.fig']);
    end
    
    
end