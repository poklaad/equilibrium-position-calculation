function gust_end_index = GustEndedNow(dispersion, disp_jump_diff, wind_mean_speed)
    if (wind_mean_speed == 0)
        gust_end_index = 0;
        return
    end
    % Минимальный перерыв между порывами
    min_gust_brake = 1000/wind_mean_speed;
    % Запас времени для поиска конца порыва
    reserve_length = min_gust_brake/4;
    % Максимальная длина порыва с небольшим запасом
    max_gust_length = reserve_length + 600/wind_mean_speed;

    % Если набранная статистика короче длины максимального порыва, выходим
    % из функции
    if (length(dispersion) < max_gust_length)
        gust_end_index = -1;
        return
    end

    % Берем кусок  массива, равный максимальной длине порыва 
    % max_gust_length, разворачиваем его и ищем всплеск с конца
    gust_containing_part = fliplr(dispersion);


    % На полученном развернутом массиве набираем статистику в
    % течение reserve_length секунд, затем в оставшейся части ищем
    % конец порыва - первый порыв
    reversed_local_mins = islocalmin(gust_containing_part);
    reversed_local_msxs = islocalmax(gust_containing_part);
    
    % Индексы локальных минимумов и максимумов
    reversed_min_indices = find(reversed_local_mins);
    reversed_max_indices = find(reversed_local_msxs);

    for i = reserve_length : length(gust_containing_part)

        % Вычисляем среднее значение разницы между соседними минимумами и максимумами
        reversed_window_mins = reversed_min_indices(reversed_min_indices <= i);
        reversed_window_maxs = reversed_max_indices(reversed_max_indices <= i);
        
        if (isempty(reversed_window_mins) || isempty(reversed_window_maxs))
            continue
        end
        % Заканчиваться должно максимумом
        if (reversed_window_mins(end) > reversed_window_maxs(end))
            reversed_window_mins(end) = [];
            if (isempty(reversed_window_mins))
                continue
            end
        end
        
        reversed_diffs = [];
        for j = 1:min(length(reversed_window_mins), length(reversed_window_maxs))-1
            reversed_diffs = [reversed_diffs, abs(gust_containing_part(reversed_window_maxs(j)) - gust_containing_part(reversed_window_mins(j)))];
        end
        
        reversed_mean_diff = mean(reversed_diffs);
        
        % Проверяем, появился ли порыв в окне
        if abs(gust_containing_part(reversed_window_maxs(end)) - gust_containing_part(reversed_window_mins(end))) > reversed_mean_diff * disp_jump_diff
            gust_end_index = length(dispersion) - reversed_min_indices(length(reversed_window_mins));
            return
        end
            
    end
    gust_end_index = 600/wind_mean_speed;
    return
end