function [DSOs, nu, y0_1, y0_2, ship_surface_area, wind_shoulder_0, ...
    intertia_momentum, wv_all, wind_all, wind_avgs, A_values, ...
    B_values, alltime, disturbance_step, quas_window_size, ...
    stat_size, disp_jump_diff, accept_layer, wave_file_list] = SetParams()

    % ПАРАМЕТРЫ АЛГОРИТМА НЕЧАЕВА
    A_min = -5;
    A_max = 5;
    B_min = -5;
    B_max = 5;
    A_steps = 200;
    B_steps = 200;
    A_values = A_min:(A_max - A_min)/A_steps:A_max;
    B_values = B_min:(B_max - B_min)/B_steps:B_max;
    
    alltime = 5000;
    quas_window_size = 6*60;
    
    ship_length = 100;
    ship_height = 15;
    ship_surface_area = ship_length * ship_height;
    wind_shoulder_0 = 15;
    % nu - параметр из дифференциального уравнения при theta'
    nu = 0.01;
    D = 8000*1000;
    J_xx = D*4;
    lambda_44 = 0.25 * J_xx;
    intertia_momentum = J_xx + lambda_44;

    % Размер окна для вычисления статистик
    stat_size = 10;
    % Относительное пороговое значение величины скачка дисперсии при поиске 
    % порывов ветра
    disp_jump_diff = 10;

    % ФУНКЦИЯ ВОССТАНАВЛИВАЮЩЕГО МОМЕНТА %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % a0, a1, a3, a5 - коэффициенты полинома пятого порядка, задающего диаграмму статической остойчивости коробля.
    % Порядок типов остойчивости: 
    % 	     неповрежденный      1-ый		 2-ой		 3-ий		 4-ый		 5-ый
    
    a0=[		 0               0          -0.2		 0       	-0.2 		 -0.07]; 
    a1=[		 0.64            0.25		 0.64		-0.64		-0.64		-0.64]; 
    a3=[    	-0.1            -0.1		-0.1 		 2.5 		 2.5 		 2.5]; 
    a5=[		-0.07           -0.05		-0.07		-1.3		-1.3		-1.3];

    % Диаграммы статической остойчивости для каждого аварийного случая
    DSOs = [a0; a1; zeros(1,6); a3; zeros(1,6); a5;];

    % y0_1, y0_2 - начальные условия для решения дифура
    y0_1 = 0.7;
    y0_2 = 0;

    disturbance_step = 4000;
    
    %%%%%%%%%%%%%%%%%%% ВОЛНЕНИЕ %%%%%%%%%%%%%%%%%%%
    % Файлы с волнением. Содержат углы волнового склона в градусах с шагом 1 секунда
    %file_id = fopen('ANG4.DAT','r'); % волновой склон 4 балла
    %file_id = fopen('ANG5.DAT','r'); % волновой склон 5 баллов
    %file_id = fopen('ANG6.DAT','r'); % волновой склон 6 баллов
    %file_id = fopen('ANG7.DAT','r'); % волновой склон 7 баллов
    %file_id = fopen('ANG8.DAT','r'); % волновой склон 8 баллов
    %file_id = fopen('anglM.DAT','r'); % ветровое волнение
    %file_id = fopen('anglS.DAT','r');% зыбь
    %file_id = fopen('anglWW.DAT','r'); % смешанное волнение
    wave_file_list = ["ANG4.DAT" "ANG5.DAT" "ANG6.DAT" "anglM.DAT" "anglS.DAT" "anglWW.DAT"];
    
    num_files = length(wave_file_list);
    wv_all = cell(num_files, 1);
    % wave_amplitude  - амплитуда волнения для реального волнения.
    wave_amplitude = 0.015;
    
    for file_i = 1:length(wave_file_list)
        % Функция, задающая волнение
    
        % angle_waves - углы волнового склона в градусах с шагом 1 секунда
        file_id = fopen(wave_file_list(file_i),'r');
        angle_waves = fscanf(file_id,'%f');
        fclose(file_id);
        
        % wv - все доступное волнение, полученное из файла
        
        % Вычисление высоты волны в каждый момент времени
        wv = [0; tand(angle_waves(1:end-1))];
        
        % Масштабирование волнения. A_real - максимальная по модулю волна
        [tmp, ~] = max(abs(wv(:)));
        scale_wave = wave_amplitude / tmp;
        wv = scale_wave * wv;
    
        wv_all{file_i} = wv;
    end

    %%%%%%%%%%%%%%%%%%% ВЕТЕР %%%%%%%%%%%%%%%%%%%
    wind_length = 10000;
    wind_avgs = 0:2:10;
    wind_all = zeros(length(wind_avgs), wind_length);
    for i = 2:length(wind_avgs)
        wind_all(i, :) = WindGeneration(wind_length, wind_avgs(i));
    end

    % Для поиска крена от ветра
    accept_layer = 1.0000e-05;
end