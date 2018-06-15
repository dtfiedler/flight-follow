# FlightFollow for iOS
<div align="center">
    <img src="./demo.gif" height=450/>
</div>

Experimental iOS app that uses Computer Vision techniques to track the path of a golf ball

# Project Report
You can view the final project report and pipeline details [here](./report.pdf).

# Steps to install and run
```
git clone git@github.com:dtfiedler/flight-follow-ios.git
```
- Open FlightFollow.xcodeproject in XCode
- Ensure [FlightFollow_iOS-Bridging-Header](FlightFollow/FlightFollow_ios-Bridging-Header.h) is attached to project, otherwise OpenCV C++ library will not be accessible
