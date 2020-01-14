function generate_test_data(filepath, n=10)
    # Generate a table with data
    tbl = table((id = ["0"*string(i) for i in 1:n],
                 IntField = [1000*i for i in 1:n],
                 FloatField = [i/10.0 for i in 1:n],
                 StringField = join.([collect(Iterators.take(string.('A':'E'), rand(0:10))) for _ in 1:n], " "),
                 StringField2 = join.([collect(Iterators.take(["abc", "abcd", "def", "ghi", "xyz", "αβγ", "ω"], rand(0:3))) for _ in 1:n], " "),
                 RandFloat = rand(n),
                 RandString = [randstring(rand(1:10)) for _ in 1:n],
                ),
                pkey=:id)

    # Write file
    open(filepath, "w") do io
        println(io, join(colnames(tbl), ','))
        for row in collect(tbl)
            println(io, join(row, ','))
        end
    end
end
