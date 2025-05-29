function [result] = GetSimulationResults(summary_table, wave_num, wind_num, ship_state, wv_test, wind_test)
    % Фильтрация таблицы по заданным условиям
    mask = (summary_table.wave == 3) & ...
           (summary_table.wind == 7) & ...
           (summary_table.ship_state == 2);
    
    if ~any(mask)
        error('Не найдены данные для указанных условий');
    end
    
    % Создаем структуру с результатами
    result = struct();
    idx = find(mask, 1);
    
    result.calculated_equilibrium = summary_table.calculated_equilibrium{idx};
    result.actual_equilibrium = summary_table.actual_equilibrium{idx};
    result.mean_values = summary_table.mean_values{idx};
    result.corrections = summary_table.corrections{idx};
    result.theta_data = summary_table.theta_data{idx};
    result.calc_error = summary_table.calc_error(idx);
    result.mean_error = summary_table.mean_error(idx);
    result.wave_conditions = wv_test(wave_num, :); % если wv_test доступен
    result.wind_conditions = wind_test(wind_num, :); % если wind_test доступен
end