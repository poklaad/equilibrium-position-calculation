% num_samples - длина генерируемого интервала ветра
% V_average - средняя скорость ветра

function WindGustsGeneration = WindGustsGeneration(wind_length, V_average)
    warning('off')
    WindGustsGeneration = zeros(wind_length, 1);
    i = 1;
    while i < wind_length
        % Начало и конец порыва
        start_gust = min(i + randi([floor(1000/V_average) floor(6000/V_average)]), wind_length);
        length_gust = randi([floor(100/V_average) floor(600/V_average)]);
        end_gust = min(start_gust + length_gust, wind_length);
        
        % Начало и конец нарастания и спада порыва
        end_gust_rising = min(wind_length, floor(start_gust + length_gust * 0.05));
        start_gust_decreasing = min(wind_length, ceil(start_gust + length_gust * 0.85));

        amplitude_gust = V_average * (0.2 + 0.3*rand(1));
    
        for j = start_gust : end_gust_rising
            passed_part_of_gust_rising = (j - start_gust) / (length_gust * 0.05);
            WindGustsGeneration(j) = WindGustsGeneration(j) + amplitude_gust * passed_part_of_gust_rising;
        end
        for j = end_gust_rising+1 : start_gust_decreasing-1
            WindGustsGeneration(j) = WindGustsGeneration(j) + amplitude_gust;
        end
        for j = start_gust_decreasing : end_gust
            passed_part_of_gust_decreasing = 1 - (j - start_gust_decreasing) / (length_gust * 0.15);
            WindGustsGeneration(j) = WindGustsGeneration(j) + amplitude_gust * passed_part_of_gust_decreasing;
        end
        i = end_gust + 1;
    end
end