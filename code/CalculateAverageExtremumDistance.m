function avg_distance = CalculateAverageExtremumDistance(data)
    % Находим индексы локальных экстремумов (и минимумов, и максимумов)
    extremum_indices_min = [];
    
    % Ищем локальные максимумы (точки, которые больше своих соседей)
    local_max = islocalmax(data);
    
    % Ищем локальные минимумы (точки, которые меньше своих соседей)
    local_min = islocalmin(data);
    
    % Объединяем индексы максимумов и минимумов
    extremum_indices_min = find(local_min);
    extremum_indices_max = find(local_max);
    
    % Вычисляем расстояния между последовательными экстремумами
    distances_min = diff(extremum_indices_min);
    distances_max = diff(extremum_indices_max);
    
    % Вычисляем среднее расстояние
    avg_distance = round(mean([distances_min distances_max]));
end