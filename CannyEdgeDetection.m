function edges = CannyEdgeDetection(gs_image)
    debug = true;

    sigma = 1.0;
    dG = gaussianDerivKernel(sigma);

    Ix = convolveX(gs_image, dG);
    Iy = convolveY(gs_image, dG);

    Gmag = sqrt(Ix.^2 + Iy.^2);
    Gdir = atan2(Iy, Ix);
    Gdir_deg = Gdir * (180 / pi);


    edges = Gmag;



    if (debug)
        imwrite(gs_image, 'detector_output_debug/0_original.png')
        imwrite(Ix, 'detector_output_debug/1_dX.png')
        imwrite(Iy, 'detector_output_debug/2_dY.png')
        imwrite(Gmag, 'detector_output_debug/3_grad_mag.png')

    end


end



function dG = gaussianDerivKernel(sigma)
    radius = ceil(3 * sigma);
    x = -radius:radius;
    G = exp(-(x.^2) / (2 * sigma^2));
    G = G / sum(G);
    dG = -(x / sigma^2) .* G;
    dG = dG - mean(dG);
end


function Ix = convolveX(img, dG)
    Ix = conv2(img, dG, 'same');
end

function Iy = convolveY(img, dG)
    Iy = conv2(img, dG', 'same');
end
