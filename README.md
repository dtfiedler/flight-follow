# FlightFollow for iOS
Experimental iOS app that uses Computer Vision techniques to track the path of a golf ball

<div align="center">
    <img src="./demo.gif" height=450/>
</div>

# Project Report
You can view the final project report and pipeline details [here](./report.pdf).

# Steps to install and run
```
git clone git@github.com:dtfiedler/flight-follow-ios.git
```
- open FlightFollow.xcodeproject in XCode
- You must ensure that opencv2.framework and [FlightFollow_iOS-Bridging-Header](FlightFollow/FlightFollow_ios-Bridging-Header.h) are attached to project, otherwise OpenCV C++ library will not be accessible