type
    test_arr = array[3, array[3, int]]
    vec = tuple[x: int, y: int]

let temp: vec = (x: 1, y: 2)
var what: test_arr = default(test_arr)
what[temp] = 3
echo what