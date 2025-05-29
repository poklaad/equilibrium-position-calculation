% Параметры судна
% Возмущения внешней среды.
% Параметры алгоритма Нечаева
% Временной промежуток моделирования, отступ в данных возмущения 
... между тренировочной и тестовой выборками, размер окна квазистационарности
% Параметры для поиска порывов ветра
[   DSOs, nu, y0_1, y0_2, ship_surface_area, wind_shoulder_0, intertia_momentum, ...
    wv_all, wind_all, wind_avgs, ...
    A_values, B_values, ...
    alltime, disturbance_step, quas_window_size, ...
    stat_size, disp_jump_diff, accept_layer, wave_file_list] = SetParams();




% Выделение волнения и ветра для обучения
wv_train= cellfun(@(x) x(1:alltime), wv_all, 'UniformOutput', false);
wind_train= wind_all(:, 1:alltime);

% Расчет лучших значений параметров алгоритма Нечаева для заданного судна.
% Обучение происходит только на неаварийном, 1-ом и 2-ом аварийном
% состояниях судна. 
% реализовать функцию
% best_A=-1.5;
% best_B=0.05;


[best_A, best_B] = CalculateBestAB(DSOs(:, 1:3), nu, alltime, ...
                                   A_values, B_values, ...
                                   wv_train, quas_window_size);



% Выделение волнения и ветра для тестирования
wv_test= cellfun(@(x) x(disturbance_step:disturbance_step+alltime-1), wv_all, 'UniformOutput', false);
wind_test= wind_all(:, disturbance_step:disturbance_step+alltime-1);

% Запуск алгоритма Нечаева
summary_table = PerformNechaevAlgorithm(DSOs, nu, y0_1, y0_2, ship_surface_area, ...
                                        wind_shoulder_0, intertia_momentum, alltime, best_A, best_B, ...
                                        quas_window_size, wv_test, wind_test, wind_avgs, stat_size, ...
                                        disp_jump_diff, accept_layer);

PlotEveryErrorHeatmaps(summary_table, wave_file_list, wind_avgs);

[f1, f2] = PlotErrorHeatmaps(summary_table, wave_file_list, wind_avgs);

fig = figure(f1);
savefig(fig, 'simulation_results_heatmap.fig');

fig = figure(f2);
savefig(fig, 'calc_error_heatmap.fig');

filename = 'error_comparison.txt';
SaveErrorComparison(summary_table, filename);

% for wave_num = 1:size(wv_test, 1)
%     for wind_num = 1:size(wind_test, 1)
%         for ship_state = 1:length(DSOs)
%             sim_data = GetSimulationResults(summary_table, wave_num, wind_num, ship_state, wv_test, wind_test);
%             % Визуализация результатов
%             figure;
%             hold on;
%             plot(sim_data.theta_data);
%             plot(sim_data.calculated_equilibrium);
%             plot(sim_data.actual_equilibrium);
%             plot(sim_data.mean_values);
%             legend('Theta data', 'Calculated equilibrium', 'Actual equilibrium', 'Mean values');
%             title(sprintf('Wave: %d, Wind: %d, Ship state: %d', wave_num, wind_num, ship_state));
%             hold off;
%         end
%     end
% end









