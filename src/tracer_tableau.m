function tracer_tableau(T)
    nomsCols = string(T.Properties.VariableNames(2:end));
    
    annees = double.empty(0, length(nomsCols));
    for i = 1:length(nomsCols)
        strAnnee = regexp(nomsCols(i), '(18|19|20)\d{2}', 'match', 'once');
        if ~isempty(strAnnee)
            annees(i) = str2double(strAnnee);
        else
            annees(i) = i; 
        end
    end
    
    if ~isempty(T.Properties.VariableUnits)
        texteLabelY = T.Properties.VariableUnits{2};
    else
        texteLabelY = "Valeurs"; 
    end
    
    matriceDonnees = table2array(T(:, 2:end));
    
    figure('Color', 'white', 'Name', 'Visualisation');
    
    estSerieTemporelle = all(annees > 1800 & annees < 2100);
    
    if estSerieTemporelle
        plot(annees, matriceDonnees', '-o', 'LineWidth', 2); 
        xlabel('Année', 'FontWeight', 'bold');
        xlim([min(annees)-1, max(annees)+1]); 
    else
        bar(matriceDonnees');
        set(gca, 'XTickLabel', nomsCols, 'XTickLabelRotation', 45);
        xlabel('Catégorie', 'FontWeight', 'bold');
    end
    
    ylabel(texteLabelY, 'FontWeight', 'bold');
    grid on;
    
    if isstruct(T.Properties.UserData) && isfield(T.Properties.UserData, 'NomFeuille')
        titreBase = T.Properties.UserData.NomFeuille;
    else
        titreBase = strrep(T.Properties.VariableNames{1}, '_', ' ');
    end
    
    if estSerieTemporelle
        title(sprintf('Évolution: %s (%d - %d)', titreBase, min(annees), max(annees)), ...
              'Interpreter', 'none', 'FontSize', 12);
    else
         title(sprintf('Comparaison: %s', titreBase), ...
              'Interpreter', 'none', 'FontSize', 12);
    end
    
    if height(T) <= 20
        legend(string(table2cell(T(:,1))), 'Location', 'bestoutside', 'Interpreter', 'none');
    end
end