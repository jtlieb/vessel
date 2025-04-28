# Gesture Tracking Known Issues
- when the anchor finger stops too abruptly, there isn't enough time to re-calculate and re-enable swiping. We have a timeout threshold of 200ms where if a new pointer goes down and the anchor finger has not been updated, we reset it and re-enable swiping
- maybe consider the # of onPointerMove events we are willing to receive for a pointer before disqualifying it. If a pointer is constantly moving, but is under the velocity threshold, the individual is likely moving their hand across the screen or something
- swiping between pages, it should be past some time threshold 

# Future Improvements
- Currently always in immersive mode. When you at library step, should be edge-to-edge. Once inside reader view, should be immersive


# User Views
- the down-up-down gesture can be a little finnicky when someone is starting out. People will probably rely on the dobule tap gesture to get started. 


# Known Limitations of EPUBX
- loads entire book into memory. If this becomes an issue, may need to fork

# Known Limitations of FLUTTER_HTML
- For pagination to work, I need to implement a custom version where I use a text painter to determine how much to show on a single page. 
- For now, a quick solution will be to use a VisibilityDetector, add more and more elements until the visibility detector fires, then remove the last one that fired and start the next page with it (calvin_and_hobbes_bridge_comic.jpg). This will mean the current page will end at sort of jagged heights, but it's good enough to test this concept out.
- For now, I will also only be rendering text. I'm going to start out with <p>, and move on to the rest of them. Images will come later
- I will also need to extend this library to make the text selectable. As of now there is no way. 