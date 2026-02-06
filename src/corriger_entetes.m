function T = corriger_entetes(T)
    if width(T) > 1
        nomCol2 = T.Properties.VariableNames{2};
        if startsWith(nomCol2, 'A') && ~isnan(str2double(extractAfter(nomCol2, 1)))
            return; 
        end
    end
    nomsActuels = T.Properties.VariableNames;
    ligneBrute1 = table2cell(T(1, :));
    nouveauxEntetes = string(ligneBrute1);
    nouveauxEntetes(ismissing(nouveauxEntetes)) = "";
    
    if nouveauxEntetes(1) == "" || nouveauxEntetes(1) == "NaN"
        nouveauxEntetes(1) = nomsActuels{1}; 
    else
        nouveauxEntetes(1) = matlab.lang.makeValidName(nouveauxEntetes(1));
    end
    
    if length(nouveauxEntetes) > 1
        nouveauxEntetes(2:end) = "A" + nouveauxEntetes(2:end);
    end
    T.Properties.VariableNames = matlab.lang.makeUniqueStrings(nouveauxEntetes);
    T(1, :) = []; 
end