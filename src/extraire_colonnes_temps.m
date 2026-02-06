function [annees, idxCols] = extraire_colonnes_temps(T)
    cols = string(T.Properties.VariableNames);
    
    annees = [];
    idxCols = [];
    
    for i = 2:length(cols)
        match = regexp(cols(i), '(18|19|20)\d{2}', 'match', 'once');
        
        if ~isempty(match)
            val = str2double(match);
            if val >= 1800 && val <= 2100
                annees = [annees, val];
                idxCols = [idxCols, i];
            end
        end
    end
end