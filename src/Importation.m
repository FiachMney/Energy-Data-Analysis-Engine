function Importation()
    % --- CONFIGURATION ---
    dossierExcel = '.'; % Dossier contenant vos fichiers xlsx
    fichierLog = 'Rapport_Importation.txt';
    
    % Initialisation du journal (Log)
    fid = fopen(fichierLog, 'w');
    fprintf(fid, '--- RAPPORT D''IMPORTATION : %s ---\n', datestr(now));
    
    % Liste des fichiers
    files = dir(fullfile(dossierExcel, '*.xls*'));
    if isempty(files)
        error('Aucun fichier Excel trouvé dans le dossier.');
    end
    
    % Structure principale de stockage (Map : Année -> (Map : Feuille -> Table))
    BaseDeDonnees = containers.Map();
    
    fprintf('Début du traitement de %d fichiers...\n', length(files));
    
    % --- BOUCLE PRINCIPALE (Fichiers) ---
    for i = 1:length(files)
        nomFichier = files(i).name;
        cheminFichier = fullfile(files(i).folder, nomFichier);
        
        % Extraction de l'année du fichier (ex: "2023")
        anneeReport = regexp(nomFichier, '\d{4}', 'match', 'once');
        if isempty(anneeReport), anneeReport = ['Inconnu_' num2str(i)]; end
        
        fichierCache = fullfile(dossierExcel, ['Cache_' anneeReport '.mat']);
        
        % 1. VÉRIFICATION DU CACHE (Gain de temps énorme)
        if exist(fichierCache, 'file')
            fprintf('[CACHE] Chargement rapide de %s...\n', nomFichier);
            charge = load(fichierCache);
            DonneesAnnee = charge.DonneesAnnee;
        else
            % 2. TRAITEMENT SI PAS DE CACHE
            fprintf('[TRAITEMENT] Lecture de %s...\n', nomFichier);
            try
                DonneesAnnee = TraiterUnFichier(cheminFichier, fid);
                % Sauvegarde du cache
                save(fichierCache, 'DonneesAnnee');
            catch ME
                fprintf(fid, '[ERREUR FATALE] Fichier %s : %s\n', nomFichier, ME.message);
                warning('Erreur sur %s. Voir log.', nomFichier);
                continue;
            end
        end
        
        % 3. STOCKAGE
        BaseDeDonnees(anneeReport) = DonneesAnnee;
    end
    
    fclose(fid);
    fprintf('Traitement terminé. Consultez %s pour les détails.\n', fichierLog);
    
    % Sauvegarde finale de tout
    save('Base_Complete_Energy.mat', 'BaseDeDonnees');
    
    % --- EXEMPLE D'ACCÈS ---
    Exemple_Manipulation(BaseDeDonnees);
end

% -------------------------------------------------------------------------
% FONCTION CŒUR : Traite un fichier Excel entier
% -------------------------------------------------------------------------
% ... (Gardez votre fonction principale Pipeline_Importation_Energy telle quelle) ...

% REMPLACEZ JUSTE LA FONCTION TraiterUnFichier PAR CELLE-CI :

function MapFeuilles = TraiterUnFichier(cheminFichier, fidLog)
    MapFeuilles = containers.Map();
    feuilles = sheetnames(cheminFichier);
    ignore = {'Contents', 'Definitions', 'Methodology', 'Conversion factors'};
    
    for k = 1:length(feuilles)
        nomFeuille = feuilles{k};
        if any(contains(nomFeuille, ignore, 'IgnoreCase', true)), continue; end
        
        try
            % =================================================================
            % STEP 1: READ EVERYTHING RAW
            % =================================================================
            rawGrid = readcell(cheminFichier, 'Sheet', nomFeuille);
            if isempty(rawGrid), continue; end
            
            numRows = size(rawGrid, 1);
            
            % =================================================================
            % STEP 2: FIND HEADER ROW
            % =================================================================
            rowHeaderIdx = 0;
            
            for r = 1:min(30, numRows)
                rowRaw = rawGrid(r, :);
                rowStr = string(rowRaw);
                rowStr(ismissing(rowStr)) = "";
                
                validCells = sum(rowStr ~= "");
                
                if validCells >= 2
                    rowHeaderIdx = r;
                    break;
                end
            end
            
            if rowHeaderIdx == 0 
                fprintf(fidLog, '[SKIP] %s - %s : Structure illisible.\n', cheminFichier, nomFeuille);
                continue; 
            end
            
            % =================================================================
            % STEP 3: EXTRACT METADATA (FIXED: CHECK HEADER ROW FIRST)
            % =================================================================
            unite = 'Unknown';
            
            % STRATEGY A: Check the first cell of the Header Row itself
            % (Example: Cell A3 contains "Million tonnes", B3 contains "1981")
            firstCellRaw = rawGrid(rowHeaderIdx, 1);
            firstCellStr = string(firstCellRaw);
            firstCellStr(ismissing(firstCellStr)) = "";
            
            if firstCellStr ~= ""
                unite = firstCellStr;
            
            % STRATEGY B: If A3 is empty, scan UPWARDS (Fallback)
            elseif rowHeaderIdx > 1
                for r = (rowHeaderIdx - 1) : -1 : 1
                    rowRaw = rawGrid(r, :);
                    rowStr = string(rowRaw);
                    rowStr(ismissing(rowStr)) = "";
                    
                    idxUnit = find(rowStr ~= "", 1);
                    if ~isempty(idxUnit)
                        unite = rowStr(idxUnit);
                        break;
                    end
                end
            end
            
            % --- CLASSIFICATION ---
            headerData = rawGrid(rowHeaderIdx, :);
            txtHeader = string(headerData);
            countYearsHeader = sum(~cellfun(@isempty, regexp(txtHeader, '^\d{4}$', 'once')));
            
            limitScan = min(numRows, rowHeaderIdx + 10);
            col1Data = rawGrid(rowHeaderIdx+1:limitScan, 1);
            txtCol1 = string(col1Data);
            countYearsCol1 = sum(~cellfun(@isempty, regexp(txtCol1, '^\d{4}$', 'once')));

            structureType = 'Category';
            if countYearsHeader >= 2
                structureType = 'Wide'; 
            elseif countYearsCol1 >= 2
                structureType = 'Long'; 
            end

            % =================================================================
            % STEP 4: MANUAL TABLE CONSTRUCTION
            % =================================================================
            headers = string(headerData);
            headers(ismissing(headers) | headers == "") = "Var"; 
            headers = matlab.lang.makeUniqueStrings(headers, {}, namelengthmax);
            
            if rowHeaderIdx >= numRows, continue; end
            bodyData = rawGrid(rowHeaderIdx+1:end, :);
            
            widthHeader = length(headers);
            widthBody = size(bodyData, 2);
            
            if widthBody > widthHeader
                bodyData = bodyData(:, 1:widthHeader);
            elseif widthBody < widthHeader
                padding = cell(size(bodyData, 1), widthHeader - widthBody);
                padding(:) = {NaN};
                bodyData = [bodyData, padding];
            end
            
            T = cell2table(bodyData, 'VariableNames', headers);
            
            % =================================================================
            % STEP 5: CLEANING
            % =================================================================
            T.Properties.UserData.Unit = unite;
            T.Properties.UserData.Structure = structureType;
            T.Properties.UserData.SheetName = nomFeuille;
            
            if strcmp(structureType, 'Long')
                T.Properties.VariableNames{1} = 'Year';
            else
                T.Properties.VariableNames{1} = 'Entity';
            end
            
            col1 = T{:, 1};
            if isnumeric(col1)
                 mask = isnan(col1);
            else
                 col1Str = string(col1);
                 mask = ismissing(col1Str) | col1Str == "";
            end
            T(mask, :) = [];
            
            vars = T.Properties.VariableNames;
            for c = 2:width(T)
                colContent = T.(vars{c});
                if ~isnumeric(colContent)
                    strCol = string(colContent);
                    strCol = replace(strCol, {'n/a', '-', ' ', '%', '^', ','}, '');
                    T.(vars{c}) = str2double(strCol);
                end
            end
            
            MapFeuilles(nomFeuille) = T;
            
        catch ME
            fprintf(fidLog, '[SKIP] %s - %s : %s\n', cheminFichier, nomFeuille, ME.message);
        end
    end
end