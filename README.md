# Test data handling in docker 

* To create a new image
   - `docker build . -t nodedata2:initial`
* Start a container
   -p - expose internal port 80 to external 3000
   -d detached mode so the terminal is usable
   --rm remove after exiting
   - `docker run -p 3000:80 -d --name feedback-app --rm nodedata2:initial`
   - Once started
      - Go to localhost:3000 to see the app
         - Once feedback is inserted it can be accessed using title. 
         - `http://localhost:3000/feedback/title01.txt`
         - The app is insanely simple as the purpose is to test docker not write an app.
      - `docker ps` will show you the container
      - The `temp` or `feedback` folders in the code structure will not contain any files at this point as we haven't started using volumes. The data is stored inside the container.
