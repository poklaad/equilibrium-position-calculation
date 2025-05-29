function fun_waves = ReadWaves(wave_file, wave_start, alltime, A_real)
    % ВОЛНЕНИЕ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Файлы с волнением. Содержат углы волнового склона в градусах с шагом 1 секунда
    %file_id = fopen('ANG4.DAT','r'); % волновой склон 4 балла
    %file_id = fopen('ANG5.DAT','r'); % волновой склон 5 баллов
    %file_id = fopen('ANG6.DAT','r'); % волновой склон 6 баллов
    %file_id = fopen('ANG7.DAT','r'); % волновой склон 7 баллов
    %file_id = fopen('ANG8.DAT','r'); % волновой склон 8 баллов
    %file_id = fopen('anglM.DAT','r'); % ветровое волнение
    %file_id = fopen('anglS.DAT','r');% зыбь
    %file_id = fopen('anglWW.DAT','r'); % смешанное волнение

    % wv - величина волнения по оси ординат
    % x_waves - моменты измерения волнения во времени
    x_waves = 1:alltime;
    
    % angle_waves - углы волнового склона в градусах с шагом 1 секунда
    file_id = fopen(wave_file,'r');
    angle_waves = fscanf(file_id,'%f');
    fclose(file_id);
    
    % all_wv - все доступное волнение, полученное из файла
    all_wv = [0];
    
    % Вычисление высоты волны в каждый момент времени
    for i = 2:length(angle_waves)
        all_wv(i) = tand(angle_waves(i-1));
    end
    wv = all_wv(wave_start:wave_start+length(x_waves)-1);
    
    % Масштабирование волнения. A_real - максимальная по модулю волна
    [tmp, ind1] = max(abs(wv));
    scale_wave = A_real / tmp;
    wv = scale_wave * wv;

    % Интерполирование волнения
    fun_waves = @(new_x) interp1(x_waves, wv, new_x, 'spline');
end