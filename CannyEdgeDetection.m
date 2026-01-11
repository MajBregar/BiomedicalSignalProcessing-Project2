function edges = CannyEdgeDetection(gs_image, SIGMA, T_LOW, T_HIGH, DEBUG_PLOTS)
    pkg load image

    gs_image = double(gs_image);

    G = gaussianKernel1D(SIGMA);
    smoothed = conv2(gs_image, G, 'same');
    smoothed = conv2(smoothed, G', 'same');

    Sx = [ -1 0 1;
           -2 0 2;
           -1 0 1 ];

    Sy = [ -1 -2 -1;
            0  0  0;
            1  2  1 ];

    Ix = conv2(smoothed, Sx, 'same');
    Iy = conv2(smoothed, Sy, 'same');

    Gmag = sqrt(Ix.^2 + Iy.^2);

    % Gdir = atan2(Iy, Ix) * (180 / pi);
    % Gdir_n = mod(Gdir, 180); 
    % Gdir_q = zeros(size(Gdir_n)); 
    % Gdir_q((Gdir_n < 22.5) | (Gdir_n >= 157.5)) = 0; 
    % Gdir_q((Gdir_n >= 22.5) & (Gdir_n < 67.5)) = 45; 
    % Gdir_q((Gdir_n >= 67.5) & (Gdir_n < 112.5)) = 90; 
    % Gdir_q((Gdir_n >= 112.5) & (Gdir_n < 157.5))= 135;

    nms = nonMaxSuppression_INTERPOLATION(Gmag, Ix, Iy);

    strong = nms >= T_HIGH;
    weak   = (nms >= T_LOW) & ~strong;
    canny_edges  = hysteresis(strong, weak);

    thinned = bwmorph(canny_edges, 'thin', Inf);

    linked_edges = edge_linking_IMPROVED(thinned, 4);
    linked_edges = edge_linking_IMPROVED(linked_edges, 8);

    edges = linked_edges;

    if DEBUG_PLOTS
        imwrite(gs_image, 'detector_output_debug/0_original.png');
        imwrite(smoothed, 'detector_output_debug/1_smoothed.png');
        imwrite(abs(Ix) / max(abs(Ix(:))), 'detector_output_debug/2_dX.png');
        imwrite(abs(Iy) / max(abs(Iy(:))), 'detector_output_debug/3_dY.png');
        imwrite(Gmag, 'detector_output_debug/4_grad_mag.png');
        imwrite(nms, 'detector_output_debug/5_nms.png');
        imwrite(strong, 'detector_output_debug/6_strong.png');
        imwrite(weak, 'detector_output_debug/7_weak.png');
        imwrite(canny_edges, 'detector_output_debug/8_edges.png');
        imwrite(thinned, 'detector_output_debug/9_thinned.png');
        imwrite(linked_edges, 'detector_output_debug/10_linked.png');
    end
end

function G = gaussianKernel1D(sigma)
    radius = ceil(3 * sigma);
    x = -radius:radius;
    G = exp(-(x.^2) / (2 * sigma^2));
    G = G / sum(G);
end



function Gsup = nonMaxSuppression_INTERPOLATION(Gmag, Ix, Iy)
    [H, W] = size(Gmag);
    Gsup = zeros(H, W);

    for y = 2:H-1
        for x = 2:W-1

            if Gmag(y, x) <= 0
                continue;
            end

            gx = Ix(y, x);
            gy = Iy(y, x);
            m  = Gmag(y, x);

            ax = abs(gx);
            ay = abs(gy);

            if ax >= ay
                w = ay / ax;

                if gx * gy > 0
                    n1 = w*Gmag(y-1, x-1) + (1-w)*Gmag(y, x-1);
                    n2 = w*Gmag(y+1, x+1) + (1-w)*Gmag(y, x+1);
                else
                    n1 = w*Gmag(y+1, x-1) + (1-w)*Gmag(y, x-1);
                    n2 = w*Gmag(y-1, x+1) + (1-w)*Gmag(y, x+1);
                end

            else
                w = ax / ay;

                if gx * gy > 0
                    n1 = w*Gmag(y-1, x-1) + (1-w)*Gmag(y-1, x);
                    n2 = w*Gmag(y+1, x+1) + (1-w)*Gmag(y+1, x);
                else
                    n1 = w*Gmag(y+1, x-1) + (1-w)*Gmag(y+1, x);
                    n2 = w*Gmag(y-1, x+1) + (1-w)*Gmag(y-1, x);
                end
            end

            if (m >= n1) && (m >= n2)
                Gsup(y, x) = m;
            end
        end
    end
end

function Gsup = nonMaxSuppression_ORIGINAL(Gmag, Edir_q)
    [H, W] = size(Gmag);
    Gsup = zeros(H, W);

    for y = 2:H-1
        for x = 2:W-1

            m = Gmag(y, x);

            switch Edir_q(y, x)

                case 0
                    n1 = Gmag(y, x-1);
                    n2 = Gmag(y, x+1);

                case 45
                    n1 = Gmag(y+1, x-1);
                    n2 = Gmag(y-1, x+1);

                case 90
                    n1 = Gmag(y-1, x);
                    n2 = Gmag(y+1, x);

                case 135
                    n1 = Gmag(y-1, x-1);
                    n2 = Gmag(y+1, x+1);

                otherwise
                    n1 = 0;
                    n2 = 0;
            end

            if (m >= n1) && (m >= n2)
                Gsup(y, x) = m;
            else
                Gsup(y, x) = 0;
            end

        end
    end
end


function edges = hysteresis(strong, weak)
    [H, W] = size(strong);

    edges = zeros(H, W);
    visited = false(H, W);
    nbrs = [-1 -1; -1 0; -1 1;
             0 -1;        0 1;
             1 -1;  1 0;  1 1];

    for y = 1:H
        for x = 1:W
            if strong(y, x) && ~visited(y, x)
                stack = [y, x];

                while ~isempty(stack)
                    p = stack(end, :);
                    stack(end, :) = [];
                    py = p(1); px = p(2);

                    if visited(py, px)
                        continue;
                    end

                    visited(py, px) = true;
                    edges(py, px) = 1;

                    for k = 1:8
                        ny = py + nbrs(k, 1);
                        nx = px + nbrs(k, 2);

                        if ny < 1 || ny > H || nx < 1 || nx > W
                            continue;
                        end

                        if ~visited(ny, nx) && (strong(ny, nx) || weak(ny, nx))
                            stack(end+1, :) = [ny, nx];
                        end
                    end
                end
            end
        end
    end
end


function linked = edge_linking_ORIGINAL(canny_edges, screen_percentage)
    g = canny_edges ~= 0;

    [H, W] = size(g);
    K = round(screen_percentage * W);

    g1 = fill_row_gaps(g, K);

    g_rot = rot90(g, 1);
    g2_rot = fill_row_gaps(g_rot, K);
    g2 = rot90(g2_rot, -1);

    linked = g1 | g2;
end


function out = fill_row_gaps(img, K)
    out = img;
    [H, W] = size(img);

    for r = 1:H
        row = img(r, :);

        c = 1;
        while c <= W
            if row(c) == 0
                gap_start = c;

                while c <= W && row(c) == 0
                    c = c + 1;
                end
                gap_end = c - 1;

                gap_len = gap_end - gap_start + 1;

                left_ok  = (gap_start > 1) && (row(gap_start - 1) == 1);
                right_ok = (gap_end < W)  && (row(gap_end + 1) == 1);

                if left_ok && right_ok && gap_len <= K
                    out(r, gap_start:gap_end) = 1;
                end
            else
                c = c + 1;
            end
        end
    end
end





function linked = edge_linking_IMPROVED(canny_edges, kernel_search)

    E = canny_edges ~= 0;
    linked = E;

    [H, W] = size(E);

    edge_id = zeros(H, W);
    endpoints = {};
    next_id = 1;

    nbrs = [-1 -1; -1 0; -1 1;
             0 -1;        0 1;
             1 -1;  1 0;  1 1];

    % CONNECTED COMPONENT LABELING
    for y0 = 1:H
        for x0 = 1:W
            if E(y0,x0) == 0 || edge_id(y0,x0) ~= 0
                continue;
            end

            stack = [y0 x0];
            pixels = [];

            edge_id(y0,x0) = next_id;

            while ~isempty(stack)
                p = stack(end,:); stack(end,:) = [];
                y = p(1); x = p(2);
                pixels(end+1,:) = [y x];

                for k = 1:8
                    ny = y + nbrs(k,1);
                    nx = x + nbrs(k,2);

                    if ny < 1 || ny > H || nx < 1 || nx > W
                        continue;
                    end

                    if E(ny,nx) == 1 && edge_id(ny,nx) == 0
                        edge_id(ny,nx) = next_id;
                        stack(end+1,:) = [ny nx];
                    end
                end
            end

            eps = [];
            for i = 1:size(pixels,1)
                y = pixels(i,1); x = pixels(i,2);
                cnt = 0;
                for k = 1:8
                    ny = y + nbrs(k,1);
                    nx = x + nbrs(k,2);
                    if ny>=1 && ny<=H && nx>=1 && nx<=W && E(ny,nx)
                        cnt = cnt + 1;
                    end
                end
                if cnt <= 1
                    eps(end+1,:) = [y x];
                end
            end

            endpoints{next_id} = eps;
            next_id = next_id + 1;
        end
    end

    num_segments = next_id - 1;

    % SELF-ENDPOINT CLOSURE
    for id = 1:num_segments
        eps = endpoints{id};
        if size(eps,1) < 2
            continue;
        end

        used = false(size(eps,1),1);

        for i = 1:size(eps,1)
            if used(i), continue; end
            y1 = eps(i,1); x1 = eps(i,2);

            for j = i+1:size(eps,1)
                if used(j), continue; end
                y2 = eps(j,1); x2 = eps(j,2);

                d = sqrt((y1-y2)^2 + (x1-x2)^2);
                if d <= kernel_search
                    [linked, edge_id] = draw_bresenham_path(linked, edge_id, y1, x1, y2, x2, id);

                    used(i) = true;
                    used(j) = true;
                    break;
                end
            end
        end

        endpoints{id} = eps(~used,:);
    end

    % FOREIGN ENDPOINT LINKING
    for id1 = 1:num_segments
        eps1 = endpoints{id1};
        if isempty(eps1), continue; end

        for e = 1:size(eps1,1)
            y = eps1(e,1);
            x = eps1(e,2);

            [id2, ty, tx] = find_nearest_foreign_pixel(edge_id, id1, y, x, kernel_search);

            if id2 ~= -1
                kept = min(id1, id2);
                repl = max(id1, id2);

                [linked, edge_id] = draw_bresenham_path(linked, edge_id, y, x, ty, tx, kept);

                edge_id(edge_id == repl) = kept;
            end
        end
    end
end


function [best_id, ty, tx] = find_nearest_foreign_pixel(edge_id, my_id, y, x, R)

    [H, W] = size(edge_id);

    best_d = inf;
    best_id = -1;
    ty = -1; tx = -1;

    for dy = -R:R
        for dx = -R:R
            if dy == 0 && dx == 0
                continue;
            end

            ny = y + dy;
            nx = x + dx;

            if ny < 1 || ny > H || nx < 1 || nx > W
                continue;
            end

            other_id = edge_id(ny, nx);

            if other_id ~= 0 && other_id ~= my_id
                d = sqrt(dy^2 + dx^2);
                if d < best_d
                    best_d = d;
                    best_id = other_id;
                    ty = ny;
                    tx = nx;
                end
            end
        end
    end
end




function [img, edge_id] = draw_bresenham_path(img, edge_id, y1, x1, y2, x2, eid)
    x = x1; y = y1;
    dx = abs(x2 - x1);
    dy = abs(y2 - y1);

    sx = sign(x2 - x1);
    sy = sign(y2 - y1);

    if dy <= dx
        err = dx / 2;
        while x ~= x2
            img(y, x) = 1;
            edge_id(y, x) = eid;

            x = x + sx;
            err = err - dy;
            if err < 0
                y = y + sy;
                err = err + dx;
            end
        end
    else
        err = dy / 2;
        while y ~= y2
            img(y, x) = 1;
            edge_id(y, x) = eid;

            y = y + sy;
            err = err - dx;
            if err < 0
                x = x + sx;
                err = err + dy;
            end
        end
    end

    img(y2, x2) = 1;
    edge_id(y2, x2) = eid;
end





