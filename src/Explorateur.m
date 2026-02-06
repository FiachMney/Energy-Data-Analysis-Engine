function Explorateur()
    persistent BaseDeDonnees; 
    
    clc;
    fprintf('==============================================\n');
    fprintf('      EXPLORATEUR DE DONNÉES ÉNERGÉTIQUES     \n');
    fprintf('==============================================\n');
    if isempty(BaseDeDonnees)
        fprintf('Veuillez sélectionner votre fichier de base de données (.mat)...\n');
        [nomFichier, cheminFichier] = uigetfile('*.mat', 'Choisir la Base Complète');
        
        if isequal(nomFichier, 0)
            fprintf('Annulation par l''utilisateur.\n');
            return;
        end
        
        fichierComplet = fullfile(cheminFichier, nomFichier);
        fprintf('Chargement de "%s" en cours... ', nomFichier);
        try
            data = load(fichierComplet);
            nomsVars = fieldnames(data);
            BaseDeDonnees = data.(nomsVars{1}); 
            fprintf('Terminé.\n\n');
        catch
            error('Erreur: Impossible de lire le fichier ou structure incorrecte.');
        end
    end
    
    anneeCourante = [];
    
    while true
        if isempty(anneeCourante)
            anneesDispo = keys(BaseDeDonnees);
            fprintf('\n--- MENU PRINCIPAL ---\n');
            choix = demander_choix(anneesDispo, 'Année du rapport');
            
            if strcmp(choix, 'QUITTER'), break; end
            anneeCourante = choix;
        end
        
        MapRapport = BaseDeDonnees(anneeCourante);
        
        feuilles = keys(MapRapport);
        fprintf('\n--- RAPPORT %s ---\n', anneeCourante);
        
        choixFeuille = demander_choix(feuilles, 'Feuille de données', true);
        
        if strcmp(choixFeuille, 'QUITTER'), break; end
        if strcmp(choixFeuille, 'RETOUR')
            anneeCourante = []; 
            continue; 
        end
        
        Tableau = MapRapport(choixFeuille);
        
        typeDonnees = 'Wide';
        if isfield(Tableau.Properties.UserData, 'Structure')
            typeDonnees = Tableau.Properties.UserData.Structure;
        end
        
        if ~strcmp(typeDonnees, 'Long')
             Tableau.Properties.VariableNames{1} = 'Pays';
        end
        
        Tableau.Properties.UserData.NomFeuille = choixFeuille;

        if isempty(Tableau)
            fprintf('(!) Tableau vide.\n'); continue;
        end

        boucle_analyse_pays(Tableau);
    end
    
    fprintf('\nFermeture de l''Explorateur.\n');
end