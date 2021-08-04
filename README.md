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

## Anonymous Volumes

* Stop the current running container
   - `docker stop feedback-app`
   - Since we used -rm this will clean up the container as well
* Add an anonymous volume in the docker file
   - `VOLUME ["/app/feedback"]`
* Create a new image with the new code
   - `docker build . -t nodedata2:volumes`
* Run a container from this image
   - `docker run -p 3000:80 -d --name feedback-app --rm nodedata2:volumes`
   - When trying to enter feedback the app crashes. Checked logs using `docker logs feedback-app`
      - Errors out when trying to copy the temp file to the feedback volume just created
          ```
          UnhandledPromiseRejectionWarning: Error: EXDEV: cross-device link not permitted, rename '/app/temp/test.txt' -> '/app/feedback/test.txt'
         ```
      - The root cause is the fs.rename method which doesn't like the file being moved out of the container, cause we are moving it to a volume. 
      - Solution, copy and delete
         ```
         //await fs.rename(tempFilePath, finalFilePath);
         await fs.copyFile(tempFilePath, finalFilePath);
         await fs.unlink(tempFilePath);
         ```
      



