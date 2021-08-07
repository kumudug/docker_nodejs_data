FROM node:14

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

# Set environment variable which can then be used in server.js
# The default value 80 can be overriden during image creation in command line
ENV PORT 80 

EXPOSE $PORT

# VOLUME ["/app/feedback"] - Removed to use a named volume

# Anonymous volume for the node_modules folder
VOLUME [ "/app/node_modules" ]
# Anonymous volume for the temp folder
VOLUME [ "/app/temp" ]

CMD [ "npm", "start" ]