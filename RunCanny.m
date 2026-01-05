function RunCanny(image_path)
    t = cputime();

    img = imread(image_path);
    if ndims(img) == 3
        img = rgb2gray(img);
    end
    img = im2double(img);

    edges = CannyEdgeDetection(img);

    fprintf('FINISHED - Ran for time: %f\n', cputime() - t);

    %imwrite(edges, 'detector_output_debug/edges.png');
end
