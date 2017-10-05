#include <iostream>
#include <opencv2/opencv.hpp>

using namespace std;
using namespace cv;

void rotate(cv::Mat& src, double angle, cv::Mat& dst)
{
    int len = std::max(src.cols, src.rows);
    cv::Point2f pt(len/2., len/2.);
    cv::Mat r = cv::getRotationMatrix2D(pt, angle, 1.0);

    cv::warpAffine(src, dst, r, cv::Size(len, len));
}

int main (int argc, const char * argv[])
{
    VideoCapture cap(argv[1]);

    cap.set(cv::CAP_PROP_FRAME_WIDTH, 320);
    cap.set(cv::CAP_PROP_FRAME_HEIGHT, 240);

    Mat img;
    HOGDescriptor hog;
    hog.setSVMDetector(HOGDescriptor::getDefaultPeopleDetector());

    Size S = Size((int) cap.get(cv::CAP_PROP_FRAME_WIDTH),    // Acquire input size
                     (int) cap.get(cv::CAP_PROP_FRAME_HEIGHT));

    VideoWriter out(argv[2],cap.get(cv::CAP_PROP_FOURCC),cap.get(cv::CAP_PROP_FPS),S,true);
    namedWindow("video capture", cv::WINDOW_AUTOSIZE);
    while (true)
    {
        cap >> img;

        if (!img.data)
            continue;

        vector<Rect> found, found_filtered;
        hog.detectMultiScale(img, found, 0, Size(8,8), Size(32,32), 1.05, 2);

        size_t i, j;
        for (i=0; i<found.size(); i++)
        {
            Rect r = found[i];
            for (j=0; j<found.size(); j++)
                if (j!=i && (r & found[j])==r)
                    break;
            if (j==found.size())
                found_filtered.push_back(r);
        }
        for (i=0; i<found_filtered.size(); i++)
        {
            Rect r = found_filtered[i];
            r.x += cvRound(r.width*0.1);
            r.width = cvRound(r.width*0.8);
            r.y += cvRound(r.height*0.06);
            r.height = cvRound(r.height*0.9);
            rectangle(img, r.tl(), r.br(), cv::Scalar(0,255,0), 2);
        }

	    imshow("video capture", img);
    if (waitKey(20) >= 0)

    break;
    }
    out.release();
    cap.release();
    return 0;
}
