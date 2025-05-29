% num_samples - длина генерируемого интервала ветра
% V_average - средняя скорость ветра
function WindGeneration = WindGeneration(wind_length, V_average)
    warning('off')
    % Моделирование составляющих ветра
    wind_turb = WindTurbGeneration(wind_length, V_average);
    wind_gusts = WindGustsGeneration(wind_length, V_average);

    % Конечная модель ветра
    WindGeneration = wind_turb + wind_gusts;
end
