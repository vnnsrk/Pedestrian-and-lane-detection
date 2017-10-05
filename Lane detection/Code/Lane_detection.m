clc;
clear all;
close all;

% GLOBAL VARIABLES
DrawPoly = 1;
NumRows = 120;
MaxLaneNum = 20;
ExpLaneNum = 2;
Rep_ref   = zeros(ExpLaneNum, MaxLaneNum);
Count_ref = zeros(1, MaxLaneNum);
TrackThreshold = 75;
LaneColors = single([0 0 0;1 1 0; 1 1 0; 1 1 1;1 1 1]);
frameFound = 5;
frameLost = 20;

startIdxRho_R = 415;
NumRhos_R = 11;

startIdxTheta_R = 1;
NumThetas_R = 21;

startIdxRho_L = 380;
NumRhos_L = 36;

startIdxTheta_L = 146;
NumThetas_L = 21;

offset = int32([0, NumRows, 0, NumRows]);


% OPEN VIDEOS

hVideoSrc = vision.VideoFileReader('..\Data\road1080.avi');
hvideo=vision.VideoFileWriter('..\Data\marina1.avi','FrameRate',hVideoSrc.info.VideoFrameRate);

hColorConv1 = vision.ColorSpaceConverter( ...
                    'Conversion', 'RGB to intensity');

hColorConv2 = vision.ColorSpaceConverter( ...
                    'Conversion', 'RGB to YCbCr');

hFilter2D = vision.ImageFilter( ...
                    'Coefficients', [-1 0 1], ...
                    'OutputSize', 'Same as first input', ...
                    'PaddingMethod', 'Replicate', ...
                    'Method', 'Correlation');

hAutothreshold = vision.Autothresholder;

hHough = vision.HoughTransform( ...
                    'ThetaRhoOutputPort', true, ...
                    'OutputDataType', 'single');

hLocalMaxFind1 = vision.LocalMaximaFinder( ...
                        'MaximumNumLocalMaxima', ExpLaneNum, ...
                        'NeighborhoodSize', [301 81], ...
                        'Threshold', 1, ...
                        'HoughMatrixInput', true, ...
                        'IndexDataType', 'uint16');
hLocalMaxFind2 = vision.LocalMaximaFinder( ...
                        'MaximumNumLocalMaxima', 1, ...
                        'NeighborhoodSize', [7 7], ...
                        'Threshold', 1, ...
                        'HoughMatrixInput', true, ...
                        'IndexDataType', 'uint16');
hLocalMaxFind3 = vision.LocalMaximaFinder( ...
                        'MaximumNumLocalMaxima', 1, ...
                        'NeighborhoodSize', [7 7], ...
                        'Threshold', 1, ...
                        'HoughMatrixInput', true, ...
                        'IndexDataType', 'uint16');

hHoughLines1 = vision.HoughLines('SineComputation', 'Trigonometric function');
hHoughLines3 = vision.HoughLines('SineComputation', 'Trigonometric function');

warnText = {sprintf('Right\nDeparture'), '', sprintf(' Left\n Departure')};
warnTextLoc = [120 170;-1 -1; 2 170];

lineText = {'', ...
        sprintf('Yellow\nBroken'), sprintf('Yellow\nSolid'), ...
        sprintf('White\nBroken'), sprintf('White\nSolid')};

hVideoOut = vision.VideoPlayer;

Frame = 0;
NumNormalDriving = 0;
OutMsg = int8(-1);
OutMsgPre = OutMsg;
Broken = false;

warningTextColors = {[1 0 0], [1 0 0], [0 0 0], [0 0 0]};

while ~isDone(hVideoSrc)

    RGB = step(hVideoSrc);
    RGB=imrotate(RGB,90);
    Imlow  = RGB(NumRows+1:end, :, :);

% Edge detection and Hough transform

    Imlow = step(hColorConv1, Imlow); % Convert RGB to intensity
    I = step(hFilter2D, Imlow);

    I(I < 0) = 0;
    I(I > 1) = 1;
    Edge = step(hAutothreshold, I);
    [H, Theta, Rho] = step(hHough, Edge);



% Peak detection

    H1 = H;
    H1(:, 1:12) = 0;
    H1(:, end-12:end) = 0;
    Idx1 = step(hLocalMaxFind1, H1);
    Count1 = size(Idx1,1);

    Line = [Rho(Idx1(:, 2)); Theta(Idx1(:, 1))];
    Enable = [ones(1,Count1) zeros(1, ExpLaneNum-Count1)];

    [Rep_ref, Count_ref] = videolanematching(Rep_ref, Count_ref, ...
                                MaxLaneNum, ExpLaneNum, Enable, Line, ...
                                TrackThreshold, frameFound+frameLost);

    Pts = step(hHoughLines1, Rep_ref(2,:), Rep_ref(1,:), Imlow);

    [TwoValidLanes, NumNormalDriving, TwoLanes, OutMsg] = ...
            videodeparturewarning(Pts, Imlow, MaxLaneNum, Count_ref, ...
                                   NumNormalDriving, OutMsg);


    YCbCr  = step(hColorConv2, RGB(NumRows+1:240, :, :));
    ColorAndTypeIdx = videodetectcolorandtype(TwoLanes, YCbCr);




 % Output
    Frame = Frame + 1;
    if Frame >= 5
        TwoLanes1 = TwoLanes + [offset; offset]';
        if DrawPoly && TwoValidLanes
            if TwoLanes(4,1) >= 239
                Templ = TwoLanes1(3:4, 1);
            else
                Templ = [0 239]';
            end
            if TwoLanes(4,2) >= 239
                Tempr = TwoLanes1(3:4, 2);
            else
                Tempr = [359 239]';
            end
            Pts_poly = [TwoLanes1(:,1); Templ; Tempr; ...
                TwoLanes1(3:4,2); TwoLanes1(1:2,2)];

            RGB = insertShape(RGB,'FilledPolygon',Pts_poly.',...
                              'Color',[0 1 1],'Opacity',0.2);
        end

        RGB = insertShape(RGB,'Line',TwoLanes1',...
            'Color',{'yellow','magenta'});
        txt = warnText{OutMsg+1};
        txtLoc = warnTextLoc(OutMsg+1, :);
        txtColor = single(warningTextColors{mod(Frame-1,4)+1});
        RGB = insertText(RGB,txtLoc,txt,'TextColor', txtColor, ...
                            'FontSize',20, 'BoxOpacity', 0);

        for ii=1:2
            % empty text will not be drawn
           txtLoc = TwoLanes1([1 2], ii)' + int32([0 -35]);
           lineTxt = lineText{ColorAndTypeIdx(ii)};
           txtColor = LaneColors(ColorAndTypeIdx(ii), :);
           RGB = insertText(RGB,txtLoc,lineTxt,'TextColor',txtColor, ...
                              'FontSize',14, 'BoxOpacity', 0);
        end

	if OutMsgPre ~= OutMsg
            ColorType = ColorAndTypeIdx(2-(OutMsg == 2));
            Broken    = ColorType == 2 || ColorType == 4;
        end
        ShowThirdLane = Broken && (OutMsg~=1);

	if ShowThirdLane
            if OutMsg == 0
                Idx2 = step(hLocalMaxFind2, ...
                       H(startIdxRho_R:startIdxRho_R+NumRhos_R-1, ...
                           startIdxTheta_R:startIdxTheta_R+NumThetas_R-1));
                Rhor = Rho(Idx2(:,2) + startIdxRho_R);
                Thetar = Theta(Idx2(:,1) + startIdxTheta_R);
                ThirdLane = step(hHoughLines3, Thetar, Rhor, Imlow);
            else
                Idx3 = step(hLocalMaxFind3, ...
                       H(startIdxRho_L:startIdxRho_L+NumRhos_L-1 , ...
                           startIdxTheta_L:startIdxTheta_L+NumThetas_L-1));
                Rhol = Rho(Idx3(:,2) + startIdxRho_L);
                Thetal = Theta(Idx3(:,1) + startIdxTheta_L);
                ThirdLane = step(hHoughLines3, Thetal, Rhol, Imlow);
            end

            OutThirdLane = videoexclude3rdlane(ThirdLane, ShowThirdLane,...
                                   TwoLanes, TwoValidLanes, YCbCr);
            OutThirdLane = OutThirdLane(:) + offset(:);
            RGB = insertShape(RGB,'Line','OutThirdLane.','Color','green');
        end
    end
    OutMsgPre = OutMsg;
    step(hVideoOut, RGB);    % Display video
    step(hvideo,RGB);
end


release(hVideoSrc);
release(hvideo);

%% Summary
% In the Video Player window, you can see that the example detected the lane
% in front of the vehicle and drew a cyan polygon to mark its location. The
% example also indicates when the vehicle departs from its lane and the type
% of the lane marker lines detected.

displayEndOfDemoMessage(mfilename)
