function SaveSimulationDataFull(summary_table, wv_test, wind_test, filename, f1)
    % Получаем все параметры
    [DSOs, nu, y0_1, y0_2, ship_surface_area, wind_shoulder_0, ...
     intertia_momentum, wv_all, wind_all, wind_avgs, A_values, ...
     B_values, alltime, disturbance_step, quas_window_size, ...
     stat_size, disp_jump_diff, accept_layer, wave_file_list] = SetParams();
    
    % Открываем файл для записи
    fid = fopen(filename, 'w');
    if fid == -1
        error('Не удалось открыть файл для записи');
    end
    
    % Записываем заголовок с информацией о дате и времени
    fprintf(fid, '%% Данные моделирования от %s\n\n', datetime('now'));
    
    % Сохраняем основные параметры
    fprintf(fid, '%% Основные параметры\n');
    SaveVariable(fid, 'nu', nu);
    SaveVariable(fid, 'y0_1', y0_1);
    SaveVariable(fid, 'y0_2', y0_2);
    SaveVariable(fid, 'ship_surface_area', ship_surface_area);
    SaveVariable(fid, 'wind_shoulder_0', wind_shoulder_0);
    SaveVariable(fid, 'intertia_momentum', intertia_momentum);
    SaveVariable(fid, 'alltime', alltime);
    SaveVariable(fid, 'disturbance_step', disturbance_step);
    SaveVariable(fid, 'quas_window_size', quas_window_size);
    SaveVariable(fid, 'stat_size', stat_size);
    SaveVariable(fid, 'disp_jump_diff', disp_jump_diff);
    SaveVariable(fid, 'accept_layer', accept_layer);
    
    % Сохраняем массивы параметров
    fprintf(fid, '\n%% Массивы параметров\n');
    SaveVariable(fid, 'A_values', A_values);
    SaveVariable(fid, 'B_values', B_values);
    SaveVariable(fid, 'wind_avgs', wind_avgs);
    
    % Сохраняем списки файлов
    fprintf(fid, '\n%% Списки файлов\n');
    SaveVariable(fid, 'wave_file_list', wave_file_list);
    
    % Сохраняем DSOs (специальная обработка для матрицы)
    fprintf(fid, '\n%% Диаграммы статической остойчивости (DSOs)\n');
    fprintf(fid, 'DSOs = [\n');
    for i = 1:size(DSOs, 1)
        fprintf(fid, '    ');
        fprintf(fid, '%.6f ', DSOs(i, :));
        fprintf(fid, '\n');
    end
    fprintf(fid, '];\n');
    
    % Сохраняем данные волнения (wv_all) полностью
    fprintf(fid, '\n%% Данные волнения (wv_all) - полные\n');
    fprintf(fid, 'wv_all = cell(%d, 1);\n', length(wv_all));
    for i = 1:length(wv_all)
        fprintf(fid, 'wv_all{%d} = [\n', i);
        fprintf(fid, '    %.6f\n', wv_all{i});
        fprintf(fid, '];\n');
    end
    
    % Сохраняем данные ветра (wind_all) полностью
    fprintf(fid, '\n%% Данные ветра (wind_all) - полные\n');
    fprintf(fid, 'wind_all = zeros(%d, %d);\n', size(wind_all, 1), size(wind_all, 2));
    for i = 1:size(wind_all, 1)
        fprintf(fid, 'wind_all(%d, :) = [\n', i);
        fprintf(fid, '    %.6f\n', wind_all(i, :));
        fprintf(fid, '];\n');
    end
    
    % Сохраняем тестовые данные (wv_test и wind_test) полностью
    fprintf(fid, '\n%% Тестовые данные волнения (wv_test) - полные\n');
    fprintf(fid, 'wv_test = cell(%d, 1);\n', length(wv_test));
    for i = 1:length(wv_test)
        fprintf(fid, 'wv_test{%d} = [\n', i);
        fprintf(fid, '    %.6f\n', wv_test{i});
        fprintf(fid, '];\n');
    end
    
    fprintf(fid, '\n%% Тестовые данные ветра (wind_test) - полные\n');
    fprintf(fid, 'wind_test = [\n');
    for i = 1:size(wind_test, 1)
        fprintf(fid, '    %.6f\n', wind_test(i, :));
    end
    fprintf(fid, ']; %% size: %d x %d\n', size(wind_test, 1), size(wind_test, 2));
    
    % Сохраняем summary_table (упрощенная версия)
    fprintf(fid, '\n%% Сводная таблица результатов (summary_table)\n');
    fprintf(fid, '%% Таблица содержит %d записей\n', height(summary_table));
    fprintf(fid, '%% Столбцы: wave, wind, ship_state, calc_error, mean_error\n');
    
    % Сохраняем график в формате .fig
    fig = figure(f1);
    savefig(fig, [filename(1:end-4) '_heatmap.fig']);
    fprintf(fid, '\n%% График тепловых карт сохранен как: %s_heatmap.fig\n', filename(1:end-4));
    
    % Также сохраняем как PNG для быстрого просмотра
    print(fig, '-dpng', [filename(1:end-4) '_heatmap.png']);
    
    fclose(fid);
    disp(['Данные успешно сохранены в файл: ' filename]);
    disp(['График сохранен как: ' filename(1:end-4) '_heatmap.fig и .png']);
end

% Вспомогательная функция для сохранения переменных
function SaveVariable(fid, varname, value)
    if ischar(value)
        fprintf(fid, '%s = ''%s'';\n', varname, value);
    elseif isnumeric(value) && isscalar(value)
        fprintf(fid, '%s = %.6f;\n', varname, value);
    elseif isstring(value) || iscellstr(value)
        if isstring(value)
            value = cellstr(value);
        end
        fprintf(fid, '%s = {', varname);
        fprintf(fid, '''%s'' ', value{:});
        fprintf(fid, '};\n');
    else
        fprintf(fid, '%s = %s; %% size: %s\n', varname, mat2str(value), mat2str(size(value)));
    end
end