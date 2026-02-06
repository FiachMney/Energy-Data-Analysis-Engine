function afficher_statistiques(SousTableau, annees)
    fprintf('\n--- RÉSUMÉ STATISTIQUE (%d - %d) ---\n', min(annees), max(annees));
    
    noms = string(table2cell(SousTableau(:,1)));
    donnees = table2array(SousTableau(:, 2:end));
    
    fprintf('%-15s | %-10s | %-10s | %-10s\n', 'PAYS', 'MOYENNE', 'MAX', 'MIN');
    fprintf('------------------------------------------------------\n');
    
    for i = 1:height(SousTableau)
        ligne = donnees(i, :);
        moy = mean(ligne, 'omitnan');
        maximum = max(ligne, [], 'omitnan');
        minimum = min(ligne, [], 'omitnan');
        
        fprintf('%-15s | %-10.2f | %-10.2f | %-10.2f\n', noms(i), moy, maximum, minimum);
    end
    fprintf('------------------------------------------------------\n');
end