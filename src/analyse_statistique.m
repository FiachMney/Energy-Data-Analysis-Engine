function analyse_statistique(Tableau, annees, mode)
    nomsPays = string(table2cell(Tableau(:,1)));
    donnees = table2array(Tableau(:, 2:end));
    
    isNewFigure = any(strcmpi(mode, {'deriv', 'cumul', 'base100', 'volatility', 'anomaly'}));
    
    if isNewFigure
        figure('Name', ['Analyse : ' upper(mode)], 'Color', 'white');
        title(['Analyse : ' upper(mode)]);
        grid on; 
    else
        figure(gcf); 
    end
    hold on;
    
    fprintf('\n--- ANALYSE AVANCÉE : %s ---\n', upper(mode));
    
    for i = 1:height(Tableau)
        Y = donnees(i, :);
        X = annees;
        
        masqueValide = ~isnan(Y);
        X_clean = X(masqueValide);
        Y_clean = Y(masqueValide);
        
        if length(X_clean) < 3
            continue;
        end
        
        couleurs = lines(height(Tableau));
        thisColor = couleurs(i, :);
        
        if strcmpi(mode, 'regression') || strcmpi(mode, 'prediction')
            [P, ~] = polyfit(X_clean, Y_clean, 1);
            
            if strcmpi(mode, 'regression')
                Y_fit = polyval(P, X_clean);
                plot(X_clean, Y_fit, '--', 'LineWidth', 2, 'Color', thisColor, ...
                     'DisplayName', sprintf('Tend. %s', nomsPays(i)));
                 
                fprintf('> %s : Croissance moyenne = %.2f unités/an\n', nomsPays(i), P(1));
            else
                annees_futur = [X_clean(end), X_clean(end)+5];
                Y_futur = polyval(P, annees_futur);
                plot(annees_futur, Y_futur, ':', 'LineWidth', 2.5, 'Color', thisColor, ...
                     'DisplayName', sprintf('Préd. %s (+5 ans)', nomsPays(i)));
                fprintf('> %s : Prédiction à +5 ans = %.2f\n', nomsPays(i), Y_futur(2));
            end
            
        elseif strcmpi(mode, 'poly2')
            [P, ~] = polyfit(X_clean, Y_clean, 2);
            X_fine = linspace(min(X_clean), max(X_clean), 100);
            Y_poly = polyval(P, X_fine);
            plot(X_fine, Y_poly, '-.', 'LineWidth', 2, 'Color', thisColor, ...
                 'DisplayName', sprintf('Poly2 %s', nomsPays(i)));
                 
        elseif strcmpi(mode, 'smooth')
            Y_smooth = movmean(Y_clean, 5);
            plot(X_clean, Y_smooth, '-', 'LineWidth', 3, 'Color', thisColor, ...
                 'DisplayName', sprintf('Lissé (5 ans) %s', nomsPays(i)));
                 
        elseif strcmpi(mode, 'deriv')
            dY = diff(Y_clean) ./ diff(X_clean);
            X_mid = X_clean(1:end-1) + diff(X_clean)/2; 
            plot(X_mid, dY, '-o', 'LineWidth', 2, 'Color', thisColor, ...
                 'DisplayName', sprintf('Vitesse %s', nomsPays(i)));
            ylabel('Variation Annuelle');
            fprintf('> %s : Pic de variation = %.2f\n', nomsPays(i), max(abs(dY)));
            
        elseif strcmpi(mode, 'cumul')
            Y_cum = cumtrapz(X_clean, Y_clean);
            plot(X_clean, Y_cum, '-^', 'LineWidth', 2, 'Color', thisColor, ...
                 'DisplayName', sprintf('Cumul %s', nomsPays(i)));
            ylabel('Total Cumulé');
            fprintf('> %s : Total = %.2f\n', nomsPays(i), Y_cum(end));
        
        elseif strcmpi(mode, 'cagr')
            if Y_clean(1) > 0 && Y_clean(end) > 0
                N = length(X_clean) - 1;
                cagr_val = (Y_clean(end) / Y_clean(1))^(1/N) - 1;
                
                Y_theo = Y_clean(1) * (1 + cagr_val) .^ (0:N);
                plot(X_clean, Y_theo, '--', 'LineWidth', 1.5, 'Color', thisColor, ...
                     'DisplayName', sprintf('CAGR %.1f%% %s', cagr_val*100, nomsPays(i)));
                 
                fprintf('> %s : CAGR = %.2f%%\n', nomsPays(i), cagr_val*100);
            else
                fprintf('> %s : CAGR impossible (valeurs <= 0)\n', nomsPays(i));
            end
        elseif strcmpi(mode, 'base100')
            Y_b100 = (Y_clean / Y_clean(1)) * 100;
            plot(X_clean, Y_b100, '-', 'LineWidth', 2, 'Color', thisColor, ...
                 'DisplayName', sprintf('Base100 %s', nomsPays(i)));
            ylabel('Indice (Base 100)');
            
            if i == 1; yline(100, '--k', 'Alpha 0.5'); end
        elseif strcmpi(mode, 'volatility')
            Y_vol = movstd(Y_clean, 5);
            plot(X_clean, Y_vol, '-', 'LineWidth', 2, 'Color', thisColor, ...
                 'DisplayName', sprintf('Volatilité %s', nomsPays(i)));
            ylabel('Écart-type mobile (5 ans)');
            fprintf('> %s : Volatilité Moyenne = %.2f\n', nomsPays(i), mean(Y_vol));
        elseif strcmpi(mode, 'anomaly')
            [TF, ~] = isoutlier(Y_clean, 'movmedian', 5);
            
            plot(X_clean, Y_clean, '-', 'Color', [thisColor, 0.4], 'LineWidth', 1, ...
                'HandleVisibility', 'off'); 
            
            if any(TF)
                plot(X_clean(TF), Y_clean(TF), 'o', 'MarkerSize', 8, ...
                     'MarkerFaceColor', thisColor, 'Color', 'k', ...
                     'DisplayName', sprintf('Anomalies %s', nomsPays(i)));
                fprintf('> %s : %d anomalies détectées\n', nomsPays(i), sum(TF));
            end
        end
    end
    
    legend('show', 'Location', 'bestoutside', 'Interpreter', 'none');
    xlabel('Année');
    hold off;
end