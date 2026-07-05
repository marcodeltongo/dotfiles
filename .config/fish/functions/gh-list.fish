function gh-list
    for d in ~/Developer/*/*/
        if test -d "$d.git"
            string replace "$HOME/Developer/" "" "$d" | string trim -r -c /
        end
    end
end
