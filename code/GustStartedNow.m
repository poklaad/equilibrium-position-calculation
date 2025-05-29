function gust_start_idx = GustStartedNow(dispersion, disp_jump_diff)

    % Находим локальные минимумы и максимумы
    local_mins = islocalmin(dispersion);
    local_maxs = islocalmax(dispersion);
    
    % Индексы локальных минимумов и максимумов
    min_indices = find(local_mins);
    max_indices = find(local_maxs);

    % Ищем начало порыва. Для этого ищем всплески дисперсии
    window_index = 1;
    
    % Вычисляем среднее значение разницы между соседними минимумами и максимумами
    window_mins = min_indices(min_indices >= window_index);
    window_maxs = max_indices(max_indices >= window_index);
    
    if (isempty(window_mins) || isempty(window_maxs))
        gust_start_idx = -1;
        return
    end
    % Заканчиваться должно максимумом
    if (window_mins(end) > window_maxs(end))
        window_mins(end) = [];
        if (isempty(window_mins))
            gust_start_idx = -1;
            return
        end
    end
    
    diffs = [];
    for j = 1:min(length(window_mins), length(window_maxs))-1
        diffs = [diffs, abs(dispersion(window_maxs(j)) - dispersion(window_mins(j)))];
    end
    
    mean_diff = mean(diffs);
    
    % Проверяем, появился ли порыв в окне
    if abs(dispersion(window_maxs(end)) - dispersion(window_mins(end))) > mean_diff * disp_jump_diff
        gust_start_idx = window_mins(end);
        return
    end 
    gust_start_idx = -1;
end