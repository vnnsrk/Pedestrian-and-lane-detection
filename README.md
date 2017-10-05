# Pedestrian-and-lane-detection
Implementation of pedestrian and lane detection on Indian roads and measuring performance

This project covers a novice implementation of pedestrian detection using HoG and SIFT features, and Lane detection using Hough transform and image morphology (dilation and erosion). The project was not intended to identify better algorithms, but rather intended to explain how well the algorithm behaves in a non-ideal environment like Chennai, India, where the traffic is too high, occlusion is high and the camera isn't steady. Also when lane markings arent clear it is tough to employ the algorithm. The experiments were conducted in the Summer of 2013, and are for referential use only.

Each experiment shows a ideal case, and a real-world not-so-ideal case with mp4 video examples. The inference leads us to conclude that the algorithms though developed for first world countries and work well, have a long way to go in sub-optimal environments and should handle occlusion, traffic, crowded roads and other real-world conditions.
