function edges = CannyEdgeDetection(gs_image, SIGMA, T_LOW, T_HIGH, DEBUG_PLOTS)
    gs_image = double(gs_image);

    G = gaussianKernel1D(SIGMA);
    smoothed = conv2(gs_image, G, 'same');
    smoothed = conv2(smoothed, G', 'same');

    Sx = [ -1 0 1;
           -2 0 2;
           -1 0 1 ] / 4;

    Sy = [ -1 -2 -1;
            0  0  0;
            1  2  1 ] / 4;

    Ix = conv2(smoothed, Sx, 'same');
    Iy = conv2(smoothed, Sy, 'same');

    Gmag = abs(Ix) + abs(Iy);
    Gmag = Gmag / max(Gmag(:));

    nms = nonMaxSuppression_INTERPOLATION(Gmag, Ix, Iy);

    strong = nms >= T_HIGH;
    weak   = (nms >= T_LOW) & ~strong;
    edges  = hysteresis(strong, weak);

    if DEBUG_PLOTS
        imwrite(gs_image, 'detector_output_debug/0_original.png');
        imwrite(smoothed, 'detector_output_debug/1_smoothed.png');
        imwrite(abs(Ix) / max(abs(Ix(:))), 'detector_output_debug/2_dX.png');
        imwrite(abs(Iy) / max(abs(Iy(:))), 'detector_output_debug/3_dY.png');
        imwrite(Gmag, 'detector_output_debug/4_grad_mag.png');
        imwrite(nms, 'detector_output_debug/5_nms.png');
        imwrite(strong, 'detector_output_debug/6_strong.png');
        imwrite(weak, 'detector_output_debug/7_weak.png');
        imwrite(edges, 'detector_output_debug/8_edges.png');
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

            gx = Ix(y, x);
            gy = Iy(y, x);
            m  = Gmag(y, x);

            ax = abs(gx);
            ay = abs(gy);

            if ax > ay
                w = ay / ax;
                n1 = w*Gmag(y-1, x+1) + (1-w)*Gmag(y, x+1);
                n2 = w*Gmag(y+1, x-1) + (1-w)*Gmag(y, x-1);
            else
                w = ax / ay;
                n1 = w*Gmag(y-1, x+1) + (1-w)*Gmag(y-1, x);
                n2 = w*Gmag(y+1, x-1) + (1-w)*Gmag(y+1, x);
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
