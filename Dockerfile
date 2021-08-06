FROM node:14

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

EXPOSE 80

# VOLUME ["/app/feedback"] - Removed to use a named volume

# Anonymous volume for the node_modules folder
VOLUME [ "/app/node_modules" ]
# Anonymous volume for the temp folder
VOLUME [ "/app/temp" ]

CMD [ "npm", "start" ]