function [minima, maxima] = FindLocalExtrema(time_series)
    % Находим локальные минимумы
    [min_vals, min_pos] = findpeaks(-time_series);
    if ~isempty(min_vals)
        minima = [min_pos', -min_vals'];
    else
        minima = [];
    end
    
    % Находим локальные максимумы
    [max_vals, max_pos] = findpeaks(time_series);
    if ~isempty(max_vals)
        maxima = [max_pos', max_vals'];
    else
        maxima = [];
    end
end