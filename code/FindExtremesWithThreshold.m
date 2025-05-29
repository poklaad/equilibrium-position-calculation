function [minima, maxima] = FindExtremesWithThreshold(time_series, thresholds)
    % Находим все локальные минимумы и максимумы
    [all_minima, all_maxima] = FindLocalExtrema(time_series);
    
    % Сортируем пороги по возрастанию
    thresholds = sort(thresholds, 'ascend');
    
    minima = [];
    maxima = [];
    last_saved_extreme_type = ''; % 'min' или 'max'
    last_max_value = NaN;
    last_max_pos = NaN;
    last_max_treshold = NaN;
    last_min_value = NaN;
    last_min_pos = NaN;
    last_min_treshold = NaN;
    
    % Создаем массив всех экстремумов с метками (1 для минимума, 2 для максимума)
    if ~isempty(all_minima)
        min_extrema = [all_minima, ones(size(all_minima, 1), 1)];
    else
        min_extrema = [];
    end
    
    if ~isempty(all_maxima)
        max_extrema = [all_maxima, 2*ones(size(all_maxima, 1), 1)];
    else
        max_extrema = [];
    end
    
    % Объединяем и сортируем все экстремумы по позиции
    if(size([min_extrema; max_extrema], 1) == 0)
        return
    end
    all_extrema = sortrows([min_extrema; max_extrema], 1);
    
    for i = 1:size(all_extrema, 1)
        pos = all_extrema(i, 1);
        value = all_extrema(i, 2);
        is_min = all_extrema(i, 3) == 1;
        
        if is_min
            below_thresholds = value < thresholds;
            % Для первого экстремума (если это минимум) проверяем, что он
            % ниже хотя бы одного порога. 
            if isnan(last_max_treshold)
                % Первый экстремум
                if any(below_thresholds)
                    last_min_value = value;
                    last_min_pos = pos;
                    last_min_treshold = min(thresholds(below_thresholds));
                    last_saved_extreme_type = 'max';
                end
            else
                % Не первый экстремум. Тогда проверяем, что он перешел
                % наибольший порог последнего максимума. Если не перешел,
                % этот минимум можно игнорировать (он побочный)
                if value < last_max_treshold
                    if strcmp(last_saved_extreme_type, 'min')
                        % Последний раз сохранили минимум, значит максимум
                        % перешел хотя бы один порог. Надо его сохранить
                        maxima = [maxima; last_max_pos, last_max_value];
                        last_saved_extreme_type = 'max';

                        % Записываем минимум
                        last_min_value = value;
                        last_min_pos = pos;
                        last_min_treshold = min(thresholds(below_thresholds));
                    else
                        % Последний раз сохранили максимум, значит сейчас
                        % ищем минимум. Если минимум меньше предыдущего,
                        % надо его записать (предыдущий минимум оказался побочным) 
                        if value < last_min_value
                            last_min_value = value;
                            last_min_pos = pos;
                            last_min_treshold = min(thresholds(below_thresholds));
                        end
                    end
                else
                    % Игнорируем этот минимум (побочный)
                end
            end
        else
            % Для первого экстремума (если это максимум) проверяем, что он
            % выше хотя бы одного порога 
            above_thresholds = value > thresholds;
            if isnan(last_min_treshold)
                if any(above_thresholds)
                    % Первый экстремум
                    last_max_value = value;
                    last_max_pos = pos;
                    last_max_treshold = max(thresholds(above_thresholds));
                    last_saved_extreme_type = 'min';
                end
            else
                % Не первый экстремум. Тогда проверяем, что он перешел
                % наименьший порог последнего минимума. Если не перешел,
                % этот максимум можно игнорировать (он побочный)
                if value > last_min_treshold
                    if strcmp(last_saved_extreme_type, 'max')
                        % Последний раз сохранили максимум, значит минимум
                        % перешел хотя бы один порог. Надо его сохранить
                        minima = [minima; last_min_pos, last_min_value];
                        last_saved_extreme_type = 'min';

                        % Записываем максимум
                        last_max_value = value;
                        last_max_pos = pos;
                        last_max_treshold = max(thresholds(above_thresholds));
                    
                    else
                        % Последний раз сохранили минимум, значит сейчас
                        % ищем максимум. Если максимум больше предыдущего,
                        % надо его записать (предыдущий максимум оказался побочным) 
                        if value > last_max_value
                            last_max_value = value;
                            last_max_pos = pos;
                            last_max_treshold = max(thresholds(above_thresholds));
                        end
                    end
                else
                    % Игнорируем этот максимум (побочный)
                end
            end
        end
    end

    if size(minima, 1) ~= size(maxima, 1)
        if size(minima, 1) > size(maxima, 1)
            minima(1, :) = [];
        else
            maxima(1, :) = [];
        end
    end
end