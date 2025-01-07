fn main() {
    let easy_grid = [
        [2, 9, -1,   -1, -1, -1,   8, 7, 1],
        [7, 4, 3,   -1, -1, -1,   -1, 5, -1],
        [5, 8, -1,   -1, -1, -1,   -1, 4, 9],

        [-1, -1, 5,   4, 7, -1,   1, 3, -1],
        [-1, 7, -1,   -1, -1, 2,   -1, -1, -1],
        [-1, 2, 9,    -1, -1, -1,   -1, -1, 4],

        [6, -1, -1,   9, -1, 3,   4, -1, 7],
        [4, 3, 2,    6, 8, -1,    -1, -1, -1],
        [9, -1, -1,   2, 5, -1,   6, -1, 3]
    ];

    let extreme_grid: [[i8; 9];9] = [
        [-1, -1, 6,     1, -1, -1,     -1, -1, -1],
        [-1, -1, 7,    5, -1, -1,     3, -1, -1],
        [-1, -1, 4,     -1, -1, 8,    6, -1, 7],

        [-1, -1, -1,    -1, -1, -1,    -1, -1, -1],
        [-1, -1, 3,     -1, 4, -1,     2, -1, -1],
        [-1, 5, -1,    8, -1, -1,     7, -1, -1],

        [-1, 3, -1,     -1, -1, 1,    -1, 2, -1],
        [-1, 9, -1,    2, -1, -1,    8, -1, -1],
        [-1, -1, -1,     -1, -1, -1,   -1, 6, 1]
    ];

    /* Solved grid
    easy_grid = [
        [2, 9, 6,   3, 4, 5,   8, 7, 1],
        [7, 4, 3,   8, 9, 1,   2, 5, 6],
        [5, 8, 1,   7, 2, 6,   3, 4, 9],

        [8, 6, 5,   4, 7, 9,   1, 3, 2],
        [3, 7, 4,   1, 6, 2,   5, 9, 8],
        [1, 2, 9,   5, 3, 8,   7, 6, 4],
        
        [6, 5, 8,   9, 1, 3,   4, 2, 7],
        [4, 3, 2,   6, 8, 7,   9, 1, 5],
        [9, 1, 7,   2, 5, 4,   6, 8, 3],
    ];
    */
    
    let mut puzzle_grid = extreme_grid;

    solve(&mut puzzle_grid);

    println! ("Solved grid: ");
    for r in puzzle_grid {
        println!("{:?}", r);  
    } 
}

fn check_grid(grid: [[i8; 9]; 9]) -> bool {
    let mut done = false;
    let number_set: [i8; 9]= [1, 2, 3, 4, 5, 6, 7, 8, 9];

    // Check each row of the grid to make sure they match the number set
    let mut row_idx = 0;
    for r in grid {
        let mut sorted_r = [0i8; 9];
        sorted_r.copy_from_slice(&r[0..]);
        sorted_r.sort();
        
        if sorted_r != number_set {
           println!("Row idx {row_idx} did not have all the numbers: {:?}", r);
           return done
        }

        row_idx += 1;
    }

    // Check each column of the grid to make sure they match the number set
    let mut col_idx = 0;
    for c in 0..9 {
        let col = [grid[0][c], grid[1][c], grid[2][c], grid[3][c], grid[4][c], grid[5][c], grid[6][c], grid[7][c], grid[8][c]];
        let mut sorted_c = [0i8; 9];
        sorted_c.copy_from_slice(&col[0..]);
        sorted_c.sort();
        if sorted_c != number_set {
           println!("col {col_idx} did not have all the numbers: {:?}", col);
           return done
        }
        col_idx += 1;
    }
    
    // Check each subgrid
    let mut r_base = 0;
    let mut c_base = 0;
    let mut subgrid_idx = 0;

    for r in 0..3 {
        for c in 0..3 {
            let mut subgrid = [0i8; 9];
            let mut subgrid_c = [0i8; 9];
            r_base = r * 3;
            c_base = c * 3;

            subgrid = [
                grid[r_base][c_base], grid[r_base][c_base + 1], grid[r_base][c_base + 2],
                grid[r_base + 1][c_base], grid[r_base + 1][c_base + 1], grid[r_base + 1][c_base + 2],
                grid[r_base + 2][c_base], grid[r_base + 2][c_base + 1], grid[r_base + 2][c_base + 2]
            ];

            subgrid_c.copy_from_slice(&subgrid[0..]);
            subgrid_c.sort();

            if subgrid_c != number_set {
                println!("subgrid {subgrid_idx} did not have all the numbers: {:?}", subgrid);
                return done
            }

            subgrid_idx += 1;
        }
    }

    done = true;
    done
}

fn solve(grid: &mut [[i8; 9]; 9])  {

    if check_grid(*grid) == true {
        println!("Grid is good! {:?}", grid);
        return 
    }

    for r in 0..9 {
        for c  in 0..9 {
            if grid[r][c] == -1 {
                let vals = generate_possible_values(*grid, r, c);
                
                if vals.len() > 0 {
                    for v in vals {
                        grid[r][c] = v;
                        solve(grid);
                        
                        if check_grid(*grid) == true {
                            return
                        }
                    }

                    println!("Resetting cell {r} x {c}");
                    grid[r][c] = -1;
                    return

                } else {
                    println!("No possible values in current solution for cell {r} x {c}. Returning");
                    return
                }
            }
        }
    }

}

fn generate_possible_values(grid: [[i8; 9]; 9], row_in: usize, col_in: usize) -> Vec<i8> {
    let mut possible_values: Vec<i8> = Vec::new();
    let mut existing_values: Vec<i8> = Vec::new();
    let legal_values: [i8; 9] = [1, 2, 3, 4, 5, 6, 7, 8, 9];
    let invalid_num = -1;


    // Get all values in the row
    let grid_r = grid[row_in];
    for val in grid_r {
        if val != invalid_num {
            existing_values.push(val);
        }
    }

    // Get all values in the column
    for r in 0..9 {
        if grid[r][col_in] != invalid_num {
            existing_values.push(grid[r][col_in]); 
        }
    }

    // Get all values in the subgrid
    let r_base = (row_in / 3) * 3; // Works because it is integer division and the remainder is thrown away before multiplication
    let c_base = (col_in / 3) * 3;
    let subgrid: [i8; 9] = [
        grid[r_base][c_base], grid[r_base][c_base + 1], grid[r_base][c_base + 2],
        grid[r_base + 1][c_base], grid[r_base + 1][c_base + 1], grid[r_base + 1][c_base + 2],
        grid[r_base + 2][c_base], grid[r_base + 2][c_base + 1], grid[r_base + 2][c_base + 2]
    ];

    for val in subgrid {
        if val != invalid_num {
            existing_values.push(val);
        }
    }

    // Uniquify the elements in existing_values
    existing_values.sort(); // First sorts the existing values in order
    existing_values.dedup(); // Removes duplicates that are next to each other

    // Diff existing_values and legal_values, populate the set in possible_values
    for val in legal_values {
        // TODO: Possible optimization, since existing_values is sorted, is to use existing_values.binary_search()
        if existing_values.contains(&val) == false {
            possible_values.push(val);
        }
    }

    println!("Cell {} x {} = {}. Possible values = {:?}", row_in, col_in, grid[row_in][col_in], possible_values);

    possible_values 
}