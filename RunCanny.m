function RunCanny(image_path)
    SIGMA = 3;
    T_LOW = 0.08;
    T_HIGH = 0.24;
    DEBUG_PLOTS = true;

    t = cputime();

    img = imread(image_path);
    if ndims(img) == 3
        img = rgb2gray(img);
    end
    img = im2double(img);

    edges = CannyEdgeDetection(img, SIGMA, T_LOW, T_HIGH, DEBUG_PLOTS);

    fprintf('FINISHED - Ran for time: %f\n', cputime() - t);
end
