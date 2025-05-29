function SaveErrorComparison(summary_table, filename)
    % Открываем файл для записи
    fid = fopen(filename, 'w');
    if fid == -1
        error('Не удалось открыть файл для записи: %s', filename);
    end
    
    % Записываем заголовок
    fprintf(fid, '%% Сравнение ошибок (mean_error - calc_error)\n');
    fprintf(fid, '%% Данные сохранены: %s\n\n', datetime('now'));
    
    % Записываем заголовки столбцов
    fprintf(fid, 'Wave\tWind\tShipState\tcalc_error\tmean_error\tdifference\n');
    
    % Записываем данные построчно
    for i = 1:height(summary_table)
        wave = summary_table.wave(i);
        wind = summary_table.wind(i);
        ship_state = summary_table.ship_state(i);
        calc_err = summary_table.calc_error(i);
        mean_err = summary_table.mean_error(i);
        diff_err = mean_err - calc_err;
        
        fprintf(fid, '%d\t%d\t%d\t%.6f\t%.6f\t%.6f\n', ...
                wave, wind, ship_state, calc_err, mean_err, diff_err);
    end
    
    % Закрываем файл
    fclose(fid);
    fprintf('Данные об ошибках сохранены в файл: %s\n', filename);
end