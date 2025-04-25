# Gesture Tracking Known Issues
- when the anchor finger stops too abruptly, there isn't enough time to re-calculate and re-enable swiping. We have a timeout threshold of 200ms where if a new pointer goes down and the anchor finger has not been updated, we reset it and re-enable swiping
- maybe consider the # of onPointerMove events we are willing to receive for a pointer before disqualifying it. If a pointer is constantly moving, but is under the velocity threshold, the individual is likely moving their hand across the screen or something


# Future Improvements
- Currently always in immersive mode. When you at library step, should be edge-to-edge. Once inside reader view, should be immersive