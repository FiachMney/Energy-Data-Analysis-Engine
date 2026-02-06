function boucle_analyse_pays(T)
    if isfield(T.Properties.UserData, 'Structure') && strcmpi(T.Properties.UserData.Structure, 'Long')
        fprintf('\n[AUTO-PIVOT] Conversion des données verticales en format horizontal...\n');
        
        colAnneeRaw = T{:, 1};
        
        if ~isnumeric(colAnneeRaw)
            colAnneeRaw = str2double(string(colAnneeRaw));
        end
        
        validMask = ~isnan(colAnneeRaw);
        annees = colAnneeRaw(validMask);
        
        anneesUniques = unique(annees);
        if isempty(anneesUniques)
            fprintf('(!) Erreur Auto-Pivot: Aucune année valide trouvée en Col 1.\n');
            return;
        end
        
        nomsSeries = T.Properties.VariableNames(2:end);
        numSeries = length(nomsSeries);
        numYears = length(anneesUniques);
        
        newData = nan(numSeries, numYears);
        
        for i = 1:numSeries
            colIdx = i + 1;
            seriesDataRaw = T{:, colIdx};
            
            if iscell(seriesDataRaw) || isstring(seriesDataRaw)
                seriesDataRaw = str2double(string(seriesDataRaw));
            end
            
            currentData = seriesDataRaw(validMask);
            
            for k = 1:length(currentData)
                val = currentData(k);
                year = annees(k);
                
                idxYear = find(anneesUniques == year, 1);
                if ~isempty(idxYear)
                    newData(i, idxYear) = val;
                end
            end
        end
        
        varNamesNew = "x" + string(anneesUniques');
        varNamesNew = matlab.lang.makeValidName(varNamesNew);
        
        T_new = array2table(newData, 'VariableNames', varNamesNew);
        
        T_new.Pays = string(nomsSeries');
        T_new = movevars(T_new, 'Pays', 'Before', 1);
        
        T_new.Properties.UserData = T.Properties.UserData;
        T_new.Properties.UserData.Structure = 'Wide_Converted'; 
        
        T = T_new;
    end
    
    if isnumeric(T{:,1})
        listePays = string(T{:,1});
    else
        listePays = string(table2cell(T(:,1)));
    end
    
    nomFeuille = 'Données';
    if isfield(T.Properties.UserData, 'NomFeuille'), nomFeuille = T.Properties.UserData.NomFeuille; end
    
    unite = 'N/A';
    if isfield(T.Properties.UserData, 'Unit'), unite = T.Properties.UserData.Unit; end
    
    DernierSousTableau = []; 
    AnneesSelectionnees = [];
    
    while true
        fprintf('\n[Analyse: %s | Unité: %s]\n', nomFeuille, unite);
        fprintf('Graphiques : "reg" (Tendances), "pred", "smooth", "poly2", "base100"\n');
        fprintf('Calculs    : "deriv", "cumul", "cagr", "vol" (Volatilité), "anom" (Anomalies)\n');
        fprintf('Système    : "export", "list", "r" (retour)\n');
        
        entreeUtilisateur = input('>> Votre choix : ', 's');
        
        if strcmpi(entreeUtilisateur, 'r'), return; end
        
        if strcmpi(entreeUtilisateur, 'list')
            disp(listePays); continue;
        end
        
        if strcmpi(entreeUtilisateur, 'export')
            if isempty(DernierSousTableau)
                fprintf('(!) Aucune donnée à exporter. Faites d''abord un graphique.\n');
            else
                nomFichier = 'Resultats_Export.xlsx';
                try
                    writetable(DernierSousTableau, nomFichier);
                    fprintf('SUCCÈS : Données exportées vers "%s"\n', nomFichier);
                catch ME
                    fprintf('Erreur lors de l''export : %s\n', ME.message);
                end
            end
            continue;
        end
        
        modeAnalyse = '';
        if strcmpi(entreeUtilisateur, 'reg'), modeAnalyse = 'regression'; end
        if strcmpi(entreeUtilisateur, 'pred'), modeAnalyse = 'prediction'; end
        if strcmpi(entreeUtilisateur, 'smooth'), modeAnalyse = 'smooth'; end
        if strcmpi(entreeUtilisateur, 'poly2'), modeAnalyse = 'poly2'; end
        if strcmpi(entreeUtilisateur, 'deriv'), modeAnalyse = 'deriv'; end
        if strcmpi(entreeUtilisateur, 'cumul'), modeAnalyse = 'cumul'; end
        if strcmpi(entreeUtilisateur, 'cagr'), modeAnalyse = 'cagr'; end
        if strcmpi(entreeUtilisateur, 'base100'), modeAnalyse = 'base100'; end
        if strcmpi(entreeUtilisateur, 'vol'), modeAnalyse = 'volatility'; end
        if strcmpi(entreeUtilisateur, 'anom'), modeAnalyse = 'anomaly'; end
        
        if ~isempty(modeAnalyse)
            if isempty(DernierSousTableau)
                fprintf('(!) Sélectionnez d''abord des pays et affichez un graphique.\n');
            else
                analyse_statistique(DernierSousTableau, AnneesSelectionnees, modeAnalyse);
            end
            continue;
        end
        
        nomsDemandes = strtrim(split(string(entreeUtilisateur), ','));
        idxLignes = find(contains(listePays, nomsDemandes, 'IgnoreCase', true));
        
        if isempty(idxLignes)
            fprintf('(!) Commande inconnue ou Pays non trouvés.\n'); continue;
        end
        
        [annees, idxCols] = extraire_colonnes_temps(T); 
        
        if isempty(annees)
            fprintf('(!) Pas de données temporelles détectées. Tentative d''affichage simple...\n'); 
             try
                SousTableau = T(idxLignes, :);
                tracer_tableau(SousTableau);
             catch
             end
            continue;
        end
        
        fprintf('Plage: %d - %d\n', min(annees), max(annees));
        entreeDeb = input('>> Année Début (Entrée=Min): ');
        entreeFin = input('>> Année Fin   (Entrée=Max): ');
        
        if isempty(entreeDeb), entreeDeb = min(annees); end
        if isempty(entreeFin), entreeFin = max(annees); end
        
        masqueTemps = (annees >= entreeDeb) & (annees <= entreeFin);
        if ~any(masqueTemps), fprintf('(!) Hors plage.\n'); continue; end
        
        colsAGarder = idxCols(masqueTemps);
        SousTableau = T(idxLignes, [1, colsAGarder]);
        
        DernierSousTableau = SousTableau; 
        AnneesSelectionnees = annees(masqueTemps);
        
        afficher_statistiques(SousTableau, AnneesSelectionnees);
        
        try
            tracer_tableau(SousTableau);
        catch ME
            fprintf('Erreur dessin: %s\n', ME.message);
        end
    end
end