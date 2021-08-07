# Testing Docker 

# Data Handling

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
      - Now 
         - Stop the container - `docker stop feedback-app`
         - Remove the image - `docker rmi nodedata2:volumes`
         - Rebuild the image - `docker build . -t nodedata2:volumes`
         - Run a container from this image again - `docker run -p 3000:80 -d --name feedback-app --rm nodedata2:volumes`
      - Enter feedback "Example: test"
         - go to `http://localhost:3000/feedback/test.txt` and you can see feedback
         - Stop the container - `docker stop feedback-app` (This will delete the container as we used the --rm)
         - Run a container from this image again - `docker run -p 3000:80 -d --name feedback-app --rm nodedata2:volumes`
         - go to `http://localhost:3000/feedback/test.txt` and you can not see it, thus the volume was not shared
         - This is because anonymous volumes are removed when the container r is removed. 
            - If you didn't use the --rm option we can stop start the container and keep the data in tact.
            - In other words anonymous volumes live for the life of the container.

## Named Volumes

* Can't be specified in the docker file. Needs to be specified when running the container from the image.
   - Removed the anonymous volume `VOLUME ["/app/feedback"]` from the Docker file to use a named volume instead.
   - Remove the image and rebuild
      - `docker rmi nodedata2:volumes`
      - `docker build . -t nodedata2:volumes`
   - Run a container with the new image including the named volume
      - `docker run -p 3000:80 -d --name feedback-app --rm -v feedback:/app/feedback nodedata2:volumes`
   - Test
      - Go to `http://localhost:3000/` and enter feedback with title "test"
      - Go to `http://localhost:3000/feedback/test.txt` to test
      - Stop the container. This will remove is as we specified `--rm`
         - `docker stop feedback-app`
      - Run again with the same named volume
         - `docker run -p 3000:80 -d --name feedback-app --rm -v feedback:/app/feedback nodedata2:volumes`
      - Go to `http://localhost:3000/feedback/test.txt` to test
         - Last entered feedback is present
      - Start a new container from the same image with a different name and port. 
         - `docker run -p 3001:80 -d --name feedback-app2 --rm -v feedback:/app/feedback nodedata2:volumes`
         - Now you can save and access feedback across these 2 images


## Bind Mounts

* Trying to put source code into a bind mount so that we can do changes without rebuilding the image
   - Bind mounts are not set inside the docker file because it's specific to a container you run and not to an image
   - Stop the container - `docker stop feedback-app` (This will delete the container as we used the --rm)
* Creating a container with a bind mount
   - `docker run -p 3000:80 -d --name feedback-app --rm -v feedback:/app/feedback -v /home/kumudu/code_repoes/git/docker_nodejs_data2:/app nodedata2:volumes`
   - If we do this then the following commands in docker file become useless
   ```
   WORKDIR /app

   COPY package.json .

   RUN npm install
   ```
   - The npm install will be overridden by the bind mount we are specifying for the `/app` folder
   - To work around this we can add an anonymous volume for the `node_modules` folder
      `VOLUME [ "/app/node_modules" ]` - Instead of adding to Docker file this can be done in command line during container run `-v /app/node_modules`
   - This works because when volume locations clash the longer internal path wins. So `node_modules` will be winning in the anonymous volume path
   - Stop the container and recreate as we changed the Docker file
      - `docker stop feedback-app` (This will delete the container as we used the --rm)
      - Remove the image and rebuild
         - `docker rmi nodedata2:volumes`
         - `docker build . -t nodedata2:volumes`
      - Start the container again
         - `docker run -p 3000:80 -d --name feedback-app --rm -v feedback:/app/feedback -v /home/kumudu/code_repoes/git/docker_nodejs_data2:/app nodedata2:volumes`
* With these changes now code changes are reflected in the container as we do changes
   - This works for everything except for the server.js file. Cause the node server is already started
   - For server.js file changes we need to restart the container. At least we don't need to recreate the image. (If you didn't use --rm)
      - `docker stop feedback-app`
      - `docker start feedback-app`

* We can also use Nodemon to refresh server.js
   - Make sure to recrate the image after the changes
      - `docker stop feedback-app`
      - `docker rm feedback-app`
      - `docker rmi nodedata2:volumes`
      - `docker build . -t nodedata2:volumes`
      - `docker run -p 3000:80 -d --name feedback-app --rm -v feedback:/app/feedback -v /home/kumudu/code_repoes/git/docker_nodejs_data2:/app nodedata2:volumes`

### Making the bind mount read only

* We can/should make the bind mount directed to the source read only. We don't need docker to write to it.
   - Before we do this we need to make sure all other referenced writable folders are mapped. Thus create a anonymous volume for the temp folder
   ```
   VOLUME [ "/app/temp" ]
   ```
   - To make a bind mount read only we add `:ro` after the folder. Lets recreate this to add the bind mount as read only. (As we changed the docker file)
      - `docker stop feedback-app`
      - `docker rmi nodedata2:volumes`
      - `docker build . -t nodedata2:volumes`
      - `docker run -p 3000:80 -d --name feedback-app --rm -v feedback:/app/feedback -v $pwd:/app:ro nodedata2:volumes`

# ARGuments and ENVironment Variables

## ENVironment Variables

* Specify an environment variable for the port so it can be overridden during container creation from the image.
   - Set with a default value in Dockerfile
      ```
      ENV PORT 80 

      EXPOSE $PORT
      ```
   - Use in server.js
      ```
      app.listen(process.env.PORT);
      ```
   - When creating image we can override in the command line
      `docker run -p 3000:8080 -e PORT=8080 -d --name feedback-app --rm -v feedback:/app/feedback -v $pwd:/app:ro nodedata2:volumes`

* If needed you can specify your environment variables in a file as well
   - Create a file (for example .env)
      ```
      PORT=8080
      ```
   - Use --env-file flag
      `docker run -p 3000:8080 --env-file ./.env -d --name feedback-app --rm -v feedback:/app/feedback -v $pwd:/app:ro nodedata2:volumes`







      



