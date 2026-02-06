function T = stocker_unite(T)
    if isstruct(T.Properties.UserData) && isfield(T.Properties.UserData, 'Unit') && ~isempty(T.Properties.UserData.Unit)
        unitePropre = T.Properties.UserData.Unit;
        
    else
        unitePropre = 'Unknown Unit';
    end
    
    if width(T) > 1
        units = repmat({''}, 1, width(T));
        units(2:end) = {unitePropre};
        T.Properties.VariableUnits = units;
    end
    
    T.Properties.UserData.Unit = unitePropre;
end