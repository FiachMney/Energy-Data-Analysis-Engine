function selection = demander_choix(listeOptions, nomContexte, activerRecherche)
    if nargin < 3, activerRecherche = false; end
    
    while true
        message = sprintf('>> Choix %s (ou ''q''=quitter, ''r''=retour): ', nomContexte);
        if activerRecherche
              message = sprintf('>> Recherche %s (ex: "Solar") ou ''r''=retour: ', nomContexte);
        end
        
        entreeUtilisateur = input(message, 's');
        
        if strcmpi(entreeUtilisateur, 'q'), selection = 'QUITTER'; return; end
        if strcmpi(entreeUtilisateur, 'r'), selection = 'RETOUR'; return; end
        
        if activerRecherche
            masque = contains(listeOptions, entreeUtilisateur, 'IgnoreCase', true);
            correspondances = listeOptions(masque);
            
            if isempty(correspondances)
                fprintf('(!) Aucun résultat pour "%s".\n', entreeUtilisateur); continue;
            elseif isscalar(correspondances)
                selection = correspondances{1}; return;
            else
                fprintf('Résultats multiples :\n');
                for k=1:length(correspondances)
                    fprintf(' %d. %s\n', k, correspondances{k});
                end
                idx = input('>> Numéro: ');
                if isempty(idx) || idx < 1 || idx > length(correspondances), continue; end
                selection = correspondances{idx}; return;
            end
        else
            if any(strcmpi(listeOptions, entreeUtilisateur))
                idx = find(strcmpi(listeOptions, entreeUtilisateur), 1);
                selection = listeOptions{idx}; return;
            else
                fprintf('(!) Choix invalide. Tapez le nom exact ou une partie.\n');
                disp(listeOptions(1:min(5,end))');
            end
        end
    end
end