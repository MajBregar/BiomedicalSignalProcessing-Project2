function RunCanny3D(image_path_list, canny2d_output_folder, canny3d_output_folder)
    SIGMA = 2.0;
    T_LOW = 0.075;
    T_HIGH = 3 * T_LOW;
    DEBUG_PLOTS = false;

    t = cputime();

    cache_folder = canny2d_output_folder;
    if ~exist(cache_folder, 'dir')
        mkdir(cache_folder);
    end

    if ~exist(canny3d_output_folder, 'dir')
        mkdir(canny3d_output_folder);
    end

    M = numel(image_path_list);
    canny_edges = cell(M, 1);

    for i = 1:M
        fprintf('Processing image %d / %d - ', i, M);

        [~, name, ~] = fileparts(image_path_list{i});
        cache_path = fullfile(cache_folder, [name '.png']);

        if exist(cache_path, 'file')
            fprintf('Loading cached Canny result\n');
            canny_edges{i} = imread(cache_path) > 0;
        else
            fprintf('Running Canny edge detection\n');

            img = imread(image_path_list{i});
            if ndims(img) == 3
                img = rgb2gray(img);
            end
            img = im2double(img);

            canny_edges{i} = CannyEdgeDetection(img, SIGMA, T_LOW, T_HIGH, DEBUG_PLOTS) > 0;
            imwrite(canny_edges{i}, cache_path);
        end
    end


    out_path = fullfile(canny3d_output_folder, sprintf('%04d.png', 1));
    imwrite(canny_edges{1}, out_path);

    for n = 1:M-1
        fprintf('Linking slices %d -> %d\n', n, n+1);

        linked = edge_linking(canny_edges{n}, canny_edges{n+1});

        out_path = fullfile(canny3d_output_folder, sprintf('%04d.png', n+1));
        imwrite(linked, out_path);
    end

    fprintf('FINISHED - Ran for time: %f\n', cputime() - t);
end


function E_next = edge_linking(E_curr, E_next)
    [H, W] = size(E_curr);
    visited = false(H, W);

    for y = 1:H
        for x = 1:W

            if E_curr(y, x) ~= 1 || visited(y, x)
                continue;
            end

            % SAME POS
            if E_next(y, x) == 1
                visited(y, x) = true;
                continue;
            end

            % 3X3 NEIGHBOURHOOD
            found = false;
            for dy = -1:1
                for dx = -1:1
                    ny = y + dy; nx = x + dx;
                    if ny >= 1 && ny <= H && nx >= 1 && nx <= W
                        if E_next(ny, nx) == 1
                            found = true;
                            break;
                        end
                    end
                end
                if found, break; end
            end

            if found
                visited(y, x) = true;
                continue;
            end

            % 5X5 NEIGBOURHOOD
            % LINKING WHEN NOT ALL 0
            for dy = -2:2
                for dx = -2:2
                    ny = y + dy; nx = x + dx;
                    if ny >= 1 && ny <= H && nx >= 1 && nx <= W
                        if E_next(ny, nx) == 1
                            a = dy; b = dx;
                            while a ~= 0 || b ~= 0
                                if a > 0, a = a - 1; end
                                if a < 0, a = a + 1; end
                                if b > 0, b = b - 1; end
                                if b < 0, b = b + 1; end
                                E_next(y + a, x + b) = 1;
                            end
                        end
                    end
                end
            end

            visited(y, x) = true;
        end
    end
end
